from datetime import date
from typing import List
from fastapi import HTTPException
from pydantic import ValidationError
import logging
from concurrent.futures import ThreadPoolExecutor
import math
from functools import partial

from api.models.basin import BasinVolume
from api.repositories.gcs_repository import GCSRepository
from api.core.ons_client import ONSClient
from api.core.exceptions import ONSClientError, ONSDataProcessingError, ONSResourceNotFoundError
from api.core.logging_decorator import logging_it

class BasinService:
    """
    The service layer that contains the core business logic of the application.
    It orchestrates the ONS client and the repository to fulfill use cases.
    """
    def __init__(self, repository: GCSRepository, ons_client: ONSClient):
        self.repository = repository
        self.ons_client = ons_client

    def _fetch_and_save_year(self, year: int, ingestion_date: date) -> int:
        """
        A helper method to fetch and save data for a single year.
        Designed to be run in parallel by a thread pool.

        Args:
            year (int): The year to process.

        Returns:
            int: The number of rows ingested for the year, or 0 on failure.
        """
        try:
            df = self.ons_client.get_data_for_year(year)
            if df is not None and not df.empty:
                self.repository.save_dataframe_for_ingestion(df, year, ingestion_date)
                return{
                    "year": year,
                    "status": "SUCESSO",
                    "detail": "Dados salvos com sucesso.",
                    "rows_ingested": len(df)
                }
            return {
                "year": year,
                "status": "FALHA",
                "detail": "Nenhum dado retornado pelo cliente ONS.",
                "rows_ingested": 0
            }
        except ONSClientError as e:
            logging.error(f"Falha ao processar o ano {year}: {e}")
            return {
                "year": year,
                "status": "FALHA",
                "detail": str(e),
                "rows_ingested": 0
            }

    @logging_it
    def ingest_data(self, start_date: date, end_date: date) -> int:
        """
        Ingests data from the ONS for a given date range by fetching data for each
        year in parallel using a thread pool.

        Args:
            start_date (date): The start of the ingestion period.
            end_date (date): The end of the ingestion period.

        Returns:
            int: The total number of rows ingested across all years.
        """
        ingestion_date = date.today()
        years_to_fetch = list(range(start_date.year, end_date.year + 1))
        fetch_with_date = partial(self._fetch_and_save_year, ingestion_date=ingestion_date)
        
        # Use a ThreadPoolExecutor to run downloads in parallel, speeding up ingestion.
        details = []
        with ThreadPoolExecutor(max_workers=5) as executor:
            results = executor.map(fetch_with_date, years_to_fetch)
            details = list(results)
        
        total_rows_ingested = sum(r.get("rows_ingested", 0) for r in details)

        summary = {
            "years_requested": years_to_fetch, 
            "total_rows_ingested": total_rows_ingested
        }
        
        return { "summary": summary, "details": details }
    
    @logging_it
    def get_historical_volume(self, start_date: date, end_date: date, page: int, size: int) -> dict:
        """
        Retrieves historical basin data from the repository and formats it
        into a paginated response.

        Args:
            start_date (date): The start of the query period.
            end_date (date): The end of the query period.
            page (int): The page number to retrieve.
            size (int): The number of items per page.

        Returns:
            dict: A dictionary containing the paginated data and metadata.
        """
        result_df = self.repository.find_by_date_range(start_date, end_date)
        
        # Handle the case where the repository returns no data
        if result_df.empty:
            return {"total_items": 0, "total_pages": 0, "current_page": page, "items_on_page": 0, "items": []}

        valid_volumes = []
        for index, row in result_df.iterrows():
            try:
                # Validate each row against the Pydantic model
                volume = BasinVolume.model_validate(row, from_attributes=True)
                valid_volumes.append(volume)
            except ValidationError as e:
                # If a row is invalid, log the error and skip it instead of failing the request.
                logging.error(f"Validation error on data row (skipping): {row.to_dict()}. Error: {e}")
                continue
        
        # --- Pagination Logic ---
        total_items = len(valid_volumes)
        if total_items == 0:
             return {"total_items": 0, "total_pages": 0, "current_page": page, "items_on_page": 0, "items": []}
            
        start_index = (page - 1) * size
        end_index = start_index + size
        
        paginated_items = valid_volumes[start_index:end_index]
        
        return {
            "total_items": total_items,
            "total_pages": math.ceil(total_items / size),
            "current_page": page,
            "items_on_page": len(paginated_items),
            "items": paginated_items
        }