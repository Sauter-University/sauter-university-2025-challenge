import pytest
import httpx
import pandas as pd
from unittest.mock import MagicMock, patch

from api.core.ons_client import ONSClient, ONS_API_URL, PACKAGE_ID
from api.core.exceptions import ONSClientError, ONSResourceNotFoundError, ONSDataProcessingError

@pytest.fixture
def mock_httpx_client():
    """Mock da biblioteca httpx.Client"""
    with patch('api.core.ons_client.httpx.Client') as mock_client_class:
        mock_client_instance = MagicMock()
        mock_client_class.return_value = mock_client_instance
        yield mock_client_instance

@pytest.fixture
def ons_client(mock_httpx_client):
    """Fixture que cria uma instância do ONSClient com cliente httpx mockado."""
    return ONSClient()

# Mock da resposta da API de metadados
mock_metadata_response = {
    "result": {
        "resources": [
            {"name": "Dados de 2022", "format": "CSV", "url": "http://example.com/2022.csv"},
            {"name": "Dados de 2023", "format": "CSV", "url": "http://example.com/2023.csv"},
        ]
    }
}

def test_get_data_for_year_success(ons_client, mock_httpx_client):
    """
    Testa o fluxo completo de sucesso: obter metadados e baixar o CSV.
    """
    # Configura o mock para as duas chamadas HTTP
    mock_metadata = MagicMock()
    mock_metadata.status_code = 200
    mock_metadata.json.return_value = mock_metadata_response
    
    mock_csv_data = MagicMock()
    mock_csv_data.status_code = 200
    mock_csv_data.text = "ena_data;nom_bacia\n2023-01-01;SUDESTE"
    
    mock_httpx_client.get.side_effect = [mock_metadata, mock_csv_data]

    df = ons_client.get_data_for_year(2023)

    assert not df.empty
    assert df.iloc[0]['nom_bacia'] == 'SUDESTE'
    assert mock_httpx_client.get.call_count == 2

def test_get_csv_url_resource_not_found(ons_client, mock_httpx_client):
    """
    Testa se ONSResourceNotFoundError é levantado quando o ano não é encontrado nos metadados.
    """
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_metadata_response
    mock_httpx_client.get.return_value = mock_response

    with pytest.raises(ONSResourceNotFoundError, match="No resource found for year 2025."):
        ons_client.get_data_for_year(2025)

def test_network_error_on_metadata(ons_client, mock_httpx_client):
    """
    Testa se ONSClientError é levantado em caso de falha de rede ao buscar metadados.
    """
    mock_httpx_client.get.side_effect = httpx.RequestError("Network error")
    
    with pytest.raises(ONSClientError, match="A network error occurred"):
        ons_client.get_data_for_year(2023)

def test_network_error_on_csv_download(ons_client, mock_httpx_client):
    """
    Testa se ONSDataProcessingError é levantado em caso de falha de rede ao baixar o CSV.
    """
    mock_metadata = MagicMock()
    mock_metadata.status_code = 200
    mock_metadata.json.return_value = mock_metadata_response
    
    mock_httpx_client.get.side_effect = [mock_metadata, httpx.RequestError("Network error")]

    with pytest.raises(ONSDataProcessingError, match="Network failure while downloading data"):
        ons_client.get_data_for_year(2023)