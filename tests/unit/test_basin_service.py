import pytest
from unittest.mock import MagicMock, patch
from datetime import date, timedelta
import pandas as pd

from api.services.basin_service import BasinService
from api.core.exceptions import ONSClientError
from api.models.basin import BasinSilverData

# Dados de mock realistas para o BigQuery
mock_bq_df = pd.DataFrame({
    'nom_bacia': ['SUDESTE', 'SUL'],
    'ena_data': [date(2023, 1, 1), date(2023, 1, 2)],
    'ena_bruta_bacia_mwmed': [100.5, 200.0],
    'ena_bruta_bacia_percentualmlt': [50.5, 60.0],
    'ena_armazenavel_bacia_mwmed': [80.0, 150.0],
    'ena_armazenavel_bacia_percentualmlt': [40.0, 50.5]
})

@pytest.fixture
def mock_gcs_repository():
    return MagicMock()

@pytest.fixture
def mock_bq_repository():
    repo = MagicMock()
    # Configura o mock para retornar o DataFrame e o total de itens
    repo.find_by_date_range.return_value = (mock_bq_df, 2)
    return repo

@pytest.fixture
def mock_ons_client():
    return MagicMock()

@pytest.fixture
def basin_service(mock_gcs_repository, mock_bq_repository, mock_ons_client):
    """Fixture que cria uma instância do BasinService com dependências mockadas."""
    return BasinService(gcs_repo=mock_gcs_repository, bq_repo=mock_bq_repository, ons_client=mock_ons_client)

def test_ingest_data_success_and_skip(basin_service, mock_ons_client, mock_gcs_repository):
    """
    Testa o processo de ingestão, cobrindo um ano com novos dados e um que é pulado.
    """
    start_date = date(2022, 1, 1)
    end_date = date(2023, 1, 1)
    today = date.today()

    # Cenário: Ano 2022 já existe, será pulado. Ano 2023 não existe, será baixado.
    mock_gcs_repository.historical_data_exists.side_effect = lambda year: True if year == 2022 else False
    
    # Mock do DataFrame retornado pelo ONS client para o ano de 2023
    mock_df_2023 = pd.DataFrame({'ena_data': [date(2023, 1, 1)]})
    mock_ons_client.get_data_for_year.return_value = mock_df_2023

    # Executa o serviço
    result = basin_service.ingest_data(start_date, end_date)

    # Verificações
    assert result['summary']['total_rows_ingested'] == 1
    assert len(result['details']) == 2

    # Verifica o ano que foi pulado
    assert result['details'][0]['year'] == 2022
    assert result['details'][0]['status'] == 'PULADO'

    # Verifica o ano que teve sucesso
    assert result['details'][1]['year'] == 2023
    assert result['details'][1]['status'] == 'SUCESSO'
    assert result['details'][1]['rows_ingested'] == 1
    
    # Garante que o ONS client só foi chamado para o ano necessário
    mock_ons_client.get_data_for_year.assert_called_once_with(2023)
    mock_gcs_repository.save_dataframe.assert_called_once_with(mock_df_2023, 2023, today)

def test_ingest_data_current_year_already_ingested_today(basin_service, mock_gcs_repository, mock_ons_client):
    """
    Testa o cenário onde a ingestão para o ano corrente é pulada porque já foi feita hoje.
    """
    today = date.today()
    start_date = date(today.year, 1, 1)
    end_date = date(today.year, 12, 31)

    # Cenário: a última ingestão foi hoje
    mock_gcs_repository.get_latest_ingestion_date.return_value = today
    
    result = basin_service.ingest_data(start_date, end_date)
    
    assert result['summary']['total_rows_ingested'] == 0
    assert result['details'][0]['status'] == 'PULADO'
    mock_ons_client.get_data_for_year.assert_not_called()

def test_ingest_data_ons_client_fails(basin_service, mock_gcs_repository, mock_ons_client):
    """
    Testa o tratamento de erro quando o ONS Client falha ao baixar os dados.
    """
    start_date = date(2023, 1, 1)
    end_date = date(2023, 1, 1)
    
    # Cenário: ONS client levanta uma exceção
    mock_gcs_repository.historical_data_exists.return_value = False
    mock_ons_client.get_data_for_year.side_effect = ONSClientError("Erro de rede")
    
    result = basin_service.ingest_data(start_date, end_date)
    
    assert result['summary']['total_rows_ingested'] == 0
    assert result['details'][0]['status'] == 'FALHA'
    assert "Erro de rede" in result['details'][0]['detail']

def test_get_historical_volume_success(basin_service, mock_bq_repository):
    """
    Testa o caso de sucesso para obter dados históricos.
    """
    start_date = date(2023, 1, 1)
    end_date = date(2023, 1, 10)
    
    result = basin_service.get_historical_volume(start_date, end_date, 1, 10)
    
    assert result['total_items'] == 2
    assert result['items_on_page'] == 2
    assert len(result['items']) == 2
    assert isinstance(result['items'][0], BasinSilverData)
    assert result['items'][0].nom_bacia == 'SUDESTE'
    # Verifica se a chamada ao repositório foi feita com os parâmetros corretos
    mock_bq_repository.find_by_date_range.assert_called_once_with(start_date, end_date, 1, 10)

def test_get_historical_volume_no_data_found(basin_service, mock_bq_repository):
    """
    Testa o cenário onde o repositório não retorna nenhum dado.
    """
    start_date = date(2023, 1, 1)
    end_date = date(2023, 1, 10)
    
    # Configura o mock para não retornar nada
    mock_bq_repository.find_by_date_range.return_value = (pd.DataFrame(), 0)
    
    result = basin_service.get_historical_volume(start_date, end_date, 1, 10)
    
    assert result['total_items'] == 0
    assert result['items_on_page'] == 0
    assert len(result['items']) == 0

def test_get_historical_volume_with_validation_error(basin_service, mock_bq_repository):
    """
    Testa se o serviço pula dados inválidos e continua processando os válidos.
    """
    # DataFrame com uma linha válida e uma inválida (nom_bacia está faltando)
    invalid_df = pd.DataFrame({
        'ena_data': [date(2023, 1, 1), date(2023, 1, 2)],
        'nom_bacia': ['SUDESTE', None],  # Linha 2 é inválida
        'ena_bruta_bacia_mwmed': [100.5, 200.0]
    })
    mock_bq_repository.find_by_date_range.return_value = (invalid_df, 2)

    start_date = date(2023, 1, 1)
    end_date = date(2023, 1, 10)
    
    result = basin_service.get_historical_volume(start_date, end_date, 1, 10)
    
    # Apenas o item válido deve ser retornado
    assert result['total_items'] == 2 # O total bruto ainda é 2
    assert result['items_on_page'] == 1 # Mas apenas 1 foi validado
    assert len(result['items']) == 1
    assert result['items'][0].nom_bacia == 'SUDESTE'
