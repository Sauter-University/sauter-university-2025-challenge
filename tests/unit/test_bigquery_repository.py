# tests/unit/test_bigquery_repository.py

import pytest
from unittest.mock import MagicMock, patch, call
from datetime import date
import pandas as pd

from api.repositories.bigquery_repository import BigQueryRepository

@pytest.fixture
def mock_bigquery_client():
    """Mock da biblioteca google.cloud.bigquery.Client"""
    with patch('api.repositories.bigquery_repository.bigquery.Client') as mock_client:
        yield mock_client

@pytest.fixture
def bq_repository(mock_bigquery_client):
    """Fixture que cria uma instância do BigQueryRepository com cliente mockado."""
    return BigQueryRepository(project_id="proj", dataset_id="data", table_id="tab")

def test_find_by_date_range_success(bq_repository, mock_bigquery_client):
    """
    Testa o caso de sucesso onde dados são encontrados.
    """
    mock_client_instance = mock_bigquery_client.return_value
    
    # Mock para a query de contagem
    mock_count_df = pd.DataFrame({'total': [10]})
    
    # Mock para a query de dados
    mock_data_df = pd.DataFrame({'col1': ['data']})
    
    # Configura o mock para retornar os DFs na ordem correta das chamadas
    mock_client_instance.query.side_effect = [
        MagicMock(to_dataframe=MagicMock(return_value=mock_count_df)),
        MagicMock(to_dataframe=MagicMock(return_value=mock_data_df))
    ]
    
    start = date(2023, 1, 1)
    end = date(2023, 1, 31)
    
    df, total = bq_repository.find_by_date_range(start, end, page=2, size=5)

    assert total == 10
    assert not df.empty
    assert mock_client_instance.query.call_count == 2
    
    # Verifica se a query de dados foi chamada com o OFFSET correto (page 2, size 5 -> offset 5)
    second_call_args = mock_client_instance.query.call_args_list[1]
    assert "LIMIT @size OFFSET @offset" in second_call_args.args[0]
    # Extrai o valor do offset do objeto de configuração do job
    job_config = second_call_args.kwargs['job_config']
    offset_param = next(p for p in job_config.query_parameters if p.name == "offset")
    assert offset_param.value == 5


def test_find_by_date_range_no_items_found(bq_repository, mock_bigquery_client):
    """
    Testa o cenário onde a query de contagem retorna 0.
    """
    mock_client_instance = mock_bigquery_client.return_value
    mock_count_df = pd.DataFrame({'total': [0]})
    
    mock_client_instance.query.return_value.to_dataframe.return_value = mock_count_df

    df, total = bq_repository.find_by_date_range(date(2023, 1, 1), date(2023, 1, 31), 1, 10)

    assert total == 0
    assert df.empty
    # Apenas a query de contagem deve ser chamada
    mock_client_instance.query.assert_called_once()