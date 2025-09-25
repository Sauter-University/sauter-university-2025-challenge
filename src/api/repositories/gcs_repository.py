import pandas as pd
from datetime import date, datetime
from typing import List, Optional
from google.cloud import storage
import io

class GCSRepository:
    """
    Repository for interacting with Google Cloud Storage (GCS),
    abstracting the logic for reading and writing data in the bucket.
    """

    def __init__(self, bucket_name: str):
        if not bucket_name:
            raise ValueError("The GCS bucket name is required.")
        self.client = storage.Client()
        self.bucket_name = bucket_name
        self.bucket = self.client.bucket(self.bucket_name)
        self.current_year = date.today().year

    def _get_historical_blob_name(self, year: int) -> str:
        """Constructs the file path for a historical year."""
        return f"basin_data/historical/basin_data_{year}.parquet"

    def _get_current_blob_name(self, ingestion_date: date, year: int) -> str:
        """Constructs the partitioned path for the current year's data."""
        date_folder = ingestion_date.strftime('%Y-%m-%d')
        # Hive-style partitioning for compatibility with BigQuery and other tools
        return f"basin_data/current/year={year}/dt={date_folder}/basin_data_{year}.parquet"

    def historical_data_exists(self, year: int) -> bool:
        """Checks if the Parquet file for a historical year already exists."""
        blob_name = self._get_historical_blob_name(year)
        blob = self.bucket.blob(blob_name)
        return blob.exists()

    def get_latest_ingestion_date(self) -> Optional[date]:
        """
        Finds the most recent ingestion date (data_carga_bronze) for the current year
        by listing the partition "directories" in GCS.
        """
        prefix = f"basin_data/current/year={self.current_year}/dt="
        # Usa 'delimiter' para tratar os "diretórios" como entidades únicas
        blobs = self.client.list_blobs(self.bucket_name, prefix=prefix, delimiter="/")
        
        prefixes = list(blobs.prefixes)
        if not prefixes:
            return None

        try:
            # Extrai as datas dos prefixes (que estão no formato '.../dt=YYYY-MM-DD/') e encontra a mais recente
            dates = [datetime.strptime(p.split('dt=')[-1].strip('/'), '%Y-%m-%d').date() for p in prefixes]
            return max(dates)
        except (ValueError, IndexError):
            return None

    def save_dataframe(self, df: pd.DataFrame, year: int, ingestion_date: date):
        """
        Saves a DataFrame as a Parquet file in GCS, using the
        correct path for historical or current year data.
        """
        is_current = (year == self.current_year)
        
        if is_current:
            # Adiciona a coluna de data de carga para o ano corrente
            df['data_carga_bronze'] = ingestion_date.strftime('%Y-%m-%d')
            blob_name = self._get_current_blob_name(ingestion_date, year)
        else:
            blob_name = self._get_historical_blob_name(year)

        blob = self.bucket.blob(blob_name)

        buffer = io.BytesIO()
        df.to_parquet(buffer, index=False)
        buffer.seek(0)

        blob.upload_from_file(buffer, content_type="application/octet-stream")
        print(f"Dados para o ano {year} salvos em gs://{self.bucket_name}/{blob_name}")