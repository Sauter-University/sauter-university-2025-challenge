import pandas as pd
from datetime import date
from google.cloud import bigquery

class BigQueryRepository:
    """
    Repository for interacting with Google BigQuery.
    Abstracts query logic to the historical data table.
    """
    def __init__(self, project_id: str, dataset_id: str, table_id: str):
        if not all([project_id, dataset_id, table_id]):
            raise ValueError("IDs de Projeto, Dataset e Tabela são necessários para o BigQuery.")
        self.client = bigquery.Client(project=project_id)
        self.table_ref = f"`{project_id}.{dataset_id}.{table_id}`"

    def find_by_date_range(self, start_date: date, end_date: date, page: int, size: int) -> tuple[pd.DataFrame, int]:
        """
        Fetches paginated data directly from BigQuery using SELECT *.
        Delegates filtering, sorting, and pagination to the BQ engine.
        """
        offset = (page - 1) * size

        # Query para contar o total de itens (para metadados da paginação)
        count_query = f"""
            SELECT COUNT(*) as total
            FROM {self.table_ref}
            WHERE ena_data BETWEEN @start_date AND @end_date
        """
        query_params_count = [
            bigquery.ScalarQueryParameter("start_date", "DATE", start_date),
            bigquery.ScalarQueryParameter("end_date", "DATE", end_date),
        ]
        job_config_count = bigquery.QueryJobConfig(query_parameters=query_params_count)
        
        total_items_result = self.client.query(count_query, job_config=job_config_count).to_dataframe()
        total_items = total_items_result['total'][0] if not total_items_result.empty else 0

        if total_items == 0:
            return pd.DataFrame(), 0

        # Query to fetch all columns from the current page
        data_query = f"""
            SELECT
                *
            FROM {self.table_ref}
            WHERE ena_data BETWEEN @start_date AND @end_date
            ORDER BY ena_data, nom_bacia
            LIMIT @size OFFSET @offset
        """
        query_params_data = [
            bigquery.ScalarQueryParameter("start_date", "DATE", start_date),
            bigquery.ScalarQueryParameter("end_date", "DATE", end_date),
            bigquery.ScalarQueryParameter("size", "INT64", size),
            bigquery.ScalarQueryParameter("offset", "INT64", offset),
        ]
        job_config_data = bigquery.QueryJobConfig(query_parameters=query_params_data)

        paginated_df = self.client.query(data_query, job_config=job_config_data).to_dataframe()
        
        return paginated_df, total_items