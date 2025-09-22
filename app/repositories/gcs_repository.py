# app/repositories/gcs_repository.py
import pandas as pd
from datetime import date
from typing import List
from google.cloud import storage
import io

class GCSRepository:
    """
    Repository for interacting with Google Cloud Storage (GCS).
    This class abstracts all the logic for reading and writing data
    to a GCS bucket, treating it as our data persistence layer.
    """

    def __init__(self, bucket_name: str):
        """
        Initializes the repository with a specific GCS bucket.

        Args:
            bucket_name (str): The name of the GCS bucket to interact with.
        """
        if not bucket_name:
            raise ValueError("GCS bucket name is required.")
        self.client = storage.Client()
        self.bucket_name = bucket_name
        self.bucket = self.client.bucket(self.bucket_name)

    def _get_blob_name_for_year(self, year: int) -> str:
        """
        Constructs the file path (blob name) for a given year's data.
        
        Args:
            year (int): The year of the data.

        Returns:
            str: The full path of the object in the GCS bucket.
        """
        return f"reservoir_data/reservoir_data_{year}.parquet"

    def save_for_year(self, df: pd.DataFrame, year: int):
        """
        Saves a DataFrame as a Parquet file to GCS for a specific year.
        The data is written to a buffer in memory before being uploaded.

        Args:
            df (pd.DataFrame): The DataFrame to save.
            year (int): The year the data corresponds to.
        """
        blob_name = self._get_blob_name_for_year(year)
        blob = self.bucket.blob(blob_name)

        # Convert DataFrame to Parquet format in an in-memory buffer
        buffer = io.BytesIO()
        df.to_parquet(buffer, index=False)
        buffer.seek(0) # Rewind the buffer to the beginning before uploading

        # Upload the buffer content to the GCS blob
        blob.upload_from_file(buffer, content_type="application/octet-stream")
        print(f"Data for year {year} saved to gs://{self.bucket_name}/{blob_name}")

    def find_by_date_range(self, start_date: date, end_date: date) -> pd.DataFrame:
        """
        Fetches and combines data from multiple yearly Parquet files in GCS
        that fall within a given date range.

        Args:
            start_date (date): The start of the date range.
            end_date (date): The end of the date range.

        Returns:
            pd.DataFrame: A single DataFrame containing the filtered and sorted data.
        """
        all_dfs: List[pd.DataFrame] = []
        for year in range(start_date.year, end_date.year + 1):
            blob_name = self._get_blob_name_for_year(year)
            blob = self.bucket.blob(blob_name)

            if blob.exists():
                # Download blob content into an in-memory buffer
                buffer = io.BytesIO()
                blob.download_to_file(buffer)
                buffer.seek(0) # Rewind buffer to be read by pandas
                
                df = pd.read_parquet(buffer)
                all_dfs.append(df)
        
        if not all_dfs:
            return pd.DataFrame()

        # Combine all yearly data into a single DataFrame
        combined_df = pd.concat(all_dfs, ignore_index=True)
        combined_df['ear_data'] = pd.to_datetime(combined_df['ear_data']).dt.date
        
        # Filter the combined data by the precise date range
        mask = (combined_df['ear_data'] >= start_date) & (combined_df['ear_data'] <= end_date)
        filtered_df = combined_df[mask]

        # Sort the results to ensure stable and predictable pagination
        sorted_df = filtered_df.sort_values(by=['ear_data', 'nom_reservatorio'], ascending=[True, True])
        
        return sorted_df