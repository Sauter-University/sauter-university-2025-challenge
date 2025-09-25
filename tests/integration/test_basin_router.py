import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

from api.main import app
from api.services.basin_service import BasinService
from api.routers.basin import get_basin_service

client = TestClient(app)

# Mock realista da resposta do serviço para o endpoint GET
mock_response = {
    "total_items": 1,
    "total_pages": 1,
    "current_page": 1,
    "items_on_page": 1,
    "items": [
        {
            "nom_bacia": "SUDESTE",
            "ena_data": "2023-01-01",
            "ena_bruta_bacia_mwmed": 100.5,
            "ena_bruta_bacia_percentualmlt": 50.5,
            "ena_armazenavel_bacia_mwmed": 80.0,
            "ena_armazenavel_bacia_percentualmlt": 40.0,
        }
    ],
}

@pytest.fixture
def mock_basin_service():
    """Cria um mock genérico para o BasinService."""
    return MagicMock(spec=BasinService)

@pytest.fixture(autouse=True)
def override_basin_service(mock_basin_service):
    """
    Fixture que aplica o mock do BasinService a todos os testes deste arquivo.
    O `autouse=True` garante que ele seja executado automaticamente.
    """
    app.dependency_overrides[get_basin_service] = lambda: mock_basin_service
    yield
    app.dependency_overrides.clear()

def test_get_historical_data_success(mock_basin_service):
    mock_basin_service.get_historical_volume.return_value = mock_response
    response = client.get("/api/basin/historical-data?start_date=2023-01-01&end_date=2023-01-10")
    
    assert response.status_code == 200
    assert response.json()["items"][0]["nom_bacia"] == "SUDESTE"

def test_get_historical_data_not_found(mock_basin_service):
    mock_basin_service.get_historical_volume.return_value = {"items": []}
    response = client.get("/api/basin/historical-data?start_date=2023-01-01&end_date=2023-01-10")
    
    assert response.status_code == 404

def test_get_historical_data_invalid_date_range():
    # Este teste agora funcionará porque o mock já foi aplicado pelo autouse fixture
    response = client.get("/api/basin/historical-data?start_date=2023-01-11&end_date=2023-01-10")
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Start date cannot be after the end date."

def test_ingest_data_success(mock_basin_service):
    mock_basin_service.ingest_data.return_value = {"summary": {"total_rows_ingested": 100}}
    response = client.post("/api/basin/ingest", json={"start_date": "2023-01-01", "end_date": "2023-01-02"})

    assert response.status_code == 200
    assert response.json()["summary"]["total_rows_ingested"] == 100

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200