from typing import Optional
import httpx
import pandas as pd
from io import StringIO
import logging
from api.core.exceptions import ONSClientError, ONSResourceNotFoundError, ONSDataProcessingError

ONS_API_URL = "https://dados.ons.org.br/api/3/action/package_show"
PACKAGE_ID = "a0ec7472-1da3-4bb5-b501-5bfd2fdf26a8"
class ONSClient:
    """
    A client responsible for all interactions with the ONS (National System Operator)
    open data API. It handles fetching metadata and downloading data files.
    """

    def __init__(self, timeout: int = 40):
        """
        Initializes the client with a shared httpx.Client instance for connection pooling.

        Args:
            timeout (int): The timeout in seconds for HTTP requests.
        """
        self.client = httpx.Client(timeout=timeout)

    def _get_csv_url_for_year(self, year: int) -> str:
        """
        Fetches the metadata for the ONS data package and finds the specific CSV file URL
        for a given year.

        Args:
            year (int): The year for which to find the data URL.

        Returns:
            str: The direct download URL for the CSV file.

        Raises:
            ONSResourceNotFoundError: If no resource matching the year is found.
            ONSClientError: For network issues or unexpected API responses.
        """
        try:
            logging.info(f"Fetching metadata for package: {PACKAGE_ID}")
            response = self.client.get(ONS_API_URL, params={"id": PACKAGE_ID})
            response.raise_for_status()
            package_data = response.json()
            
            for resource in package_data["result"]["resources"]:
                if str(year) in resource["name"]:
                    url = resource['url']
                    logging.info(f"Found resource for year {year}: {url}")
                    return url
            
            raise ONSResourceNotFoundError(f"No resource found for year {year}.")

        except httpx.RequestError as e:
            raise ONSClientError("A network error occurred while communicating with the ONS API.") from e
        except KeyError as e:
            raise ONSClientError("Unexpected response format from the ONS API.") from e

    def get_data_for_year(self, year: int) -> pd.DataFrame:
        """
        Downloads the basin data for a specific year and loads it into a pandas DataFrame.

        Args:
            year (int): The year of the data to download.

        Returns:
            pd.DataFrame: A DataFrame containing the basin data.

        Raises:
            ONSDataProcessingError: If the data fails to download or be parsed into a DataFrame.
        """
        csv_url = self._get_csv_url_for_year(year)
        
        try:
            logging.info(f"Downloading data from: {csv_url}")
            response = self.client.get(csv_url)
            response.raise_for_status()
            
            # Read the CSV content from memory
            csv_data = StringIO(response.text)
            df = pd.read_csv(csv_data, delimiter=';')

            # Standardize the date column format
            df['ena_data'] = pd.to_datetime(df['ena_data'], format='%Y-%m-%d').dt.date
            df = df.astype(str) #Converting to String
            
            logging.info(f"Data for year {year} processed successfully.")
            return df

        except httpx.RequestError as e:
            raise ONSDataProcessingError(f"Network failure while downloading data for year {year}.") from e
        except (pd.errors.ParserError, KeyError) as e:
            raise ONSDataProcessingError(f"Failed to parse or process data for year {year}.") from e