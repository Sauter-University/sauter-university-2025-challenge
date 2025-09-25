from datetime import date
from typing import List
import logging
from concurrent.futures import ThreadPoolExecutor
import math
from functools import partial
from pydantic import ValidationError

from api.models.basin import BasinSilverData
from api.repositories.gcs_repository import GCSRepository
from api.repositories.bigquery_repository import BigQueryRepository 
from api.core.ons_client import ONSClient
from api.core.exceptions import ONSClientError
from api.core.logging_decorator import logging_it

class BasinService:
    def __init__(self, gcs_repo: GCSRepository, bq_repo: BigQueryRepository, ons_client: ONSClient):
        self.gcs_repository = gcs_repo
        self.bq_repository = bq_repo
        self.ons_client = ons_client    
        self.current_year = date.today().year

    def _process_year_ingestion(self, year: int, ingestion_date: date) -> dict:
        """
        Processes the ingestion for a single year, applying the new verification logic.
        """
        try:
            if year < self.current_year:
                if self.gcs_repository.historical_data_exists(year):
                    logging.info(f"Dados históricos para o ano {year} já existem. Pulando download.")
                    return {"year": year, "status": "PULADO", "detail": "Dados históricos já existem no GCS."}
                logging.info(f"Dados históricos para o ano {year} não encontrados. Baixando...")

            #  --- LOGIC FOR THE CURRENT YEAR (2025) ---
            if year == self.current_year:
                latest_ingestion = self.gcs_repository.get_latest_ingestion_date()
                if latest_ingestion and latest_ingestion == ingestion_date:
                    logging.info(f"Dados para o ano corrente ({year}) já foram ingeridos hoje. Pulando download.")
                    return {"year": year, "status": "PULADO", "detail": f"Os dados já foram carregados hoje ({latest_ingestion})."}
                logging.info(f"Dados para o ano corrente ({year}) precisam de atualização. Baixando...")

            # --- EXECUTE DOWNLOAD AND SAVE (if not skipped) ---
            df = self.ons_client.get_data_for_year(year)
            if df is not None and not df.empty:
                self.gcs_repository.save_dataframe(df, year, ingestion_date)
                return {
                    "year": year,
                    "status": "SUCESSO",
                    "detail": "Novos dados baixados e salvos no GCS.",
                    "rows_ingested": len(df)
                }
            return {"year": year, "status": "FALHA", "detail": "Nenhum dado retornado pelo cliente ONS.", "rows_ingested": 0}

        except Exception as e:
            # Captura qualquer exceção inesperada durante o processamento do ano
            logging.error(f"Falha inesperada ao processar o ano {year}: {e}", exc_info=True)
            return {"year": year, "status": "FALHA", "detail": str(e), "rows_ingested": 0}

    @logging_it
    def ingest_data(self, start_date: date, end_date: date) -> dict:
        ingestion_date = date.today()
        years_to_fetch = list(range(start_date.year, end_date.year + 1))
        process_func = partial(self._process_year_ingestion, ingestion_date=ingestion_date)
        
        details = []
        with ThreadPoolExecutor(max_workers=5) as executor:
            results = executor.map(process_func, years_to_fetch)
            details = list(results)
        
        total_rows_ingested = sum(r.get("rows_ingested", 0) for r in details if r.get("status") == "SUCESSO")

        summary = { "years_requested": years_to_fetch, "total_rows_ingested": total_rows_ingested }
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
        result_df, total_items = self.bq_repository.find_by_date_range(start_date, end_date, page, size)
        
        # Handle the case where the repository returns no data
        if total_items == 0 or result_df.empty:
            return {"total_items": 0, "total_pages": 0, "current_page": page, "items_on_page": 0, "items": []}

        valid_items = []
        for index, row in result_df.iterrows():
            try:
                # Validate each row against the Pydantic model
                item = BasinSilverData.model_validate(row, from_attributes=True)
                valid_items.append(item)
            except ValidationError as e:
                # If a row is invalid, log the error and skip it instead of failing the request.
                logging.error(f"Validation error on data row (skipping): {row.to_dict()}. Error: {e}")
                continue
        
        
        return {
            "total_items": total_items,
            "total_pages": math.ceil(total_items / size),
            "current_page": page,
            "items_on_page": len(valid_items),
            "items": valid_items
        }