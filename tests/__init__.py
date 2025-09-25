
import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from datetime import date

from api.main import app
from api.services.basin_service import BasinService
from api.routers.basin import get_basin_service
from api.models.basin import BasinSilverData

# Create a TestClient instance for making requests to the app
client = TestClient(app)

# Fixture for a mock BasinService
@pytest.fixture
def mock_basin_service():
    """Provides a mock of the BasinService for dependency override."""
    service = MagicMock(spec=BasinService)
    return service

# Apply the dependency override for all tests in this module
@pytest.fixture(autouse=True)
def override_basin_service_dependency(mock_basin_service):
    """Fixture to override the get_basin_service dependency with a mock."""
    app.dependency_overrides[get_basin_service] = lambda: mock_basin_service
    yield
    # Clean up the override after the test finishes
    app.dependency_overrides.clear()

# --- Integration Tests for the Root Endpoint ---

def test_read_root():
    """
    Test the root endpoint '/' to ensure it returns the correct welcome message.
    """
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the Basin Data API. See /docs for more information."}

# --- Integration Tests for POST /api/basin/ingest ---

def test_ingest_data_success(mock_basin_service):
    """
    Test the POST /ingest endpoint for a successful data ingestion trigger.
    The service should be called with the correct dates and return a 200 OK status.
    """
    # Mock the service's response
    mock_report = {
        "summary": {"years_requested": [2023], "total_rows_ingested": 100},
        "details": [{"year": 2023, "status": "SUCESSO", "rows_ingested": 100}]
    }
    mock_basin_service.ingest_data.return_value = mock_report

    # Make the request
    request_payload = {"start_date": "2023-01-01", "end_date": "2023-12-31"}
    response = client.post("/api/basin/ingest", json=request_payload)

    # Assertions
    assert response.status_code == 200
    assert response.json() == mock_report
    mock_basin_service.ingest_data.assert_called_once_with(
        date(2023, 1, 1), date(2023, 12, 31)
    )

def test_ingest_data_invalid_payload():
    """
    Test the POST /ingest endpoint with an invalid payload (e.g., missing end_date).
    FastAPI should automatically return a 422 Unprocessable Entity error.
    """
    request_payload = {"start_date": "2023-01-01"} # Missing end_date
    response = client.post("/api/basin/ingest", json=request_payload)
    assert response.status_code == 422 # Unprocessable Entity

# --- Integration Tests for GET /api/basin/historical-data ---

def test_get_historical_data_success(mock_basin_service):
    """
    Test the GET /historical-data endpoint for a successful data retrieval.
    The service should return paginated data, resulting in a 200 OK response.
    """
    # Mock the service's response
    mock_item = BasinSilverData(
        id_subsistema=1, nom_subsistema="SE", id_bacia=1, nom_bacia="Grande",
        din_instante=date(2023, 1, 1),
        ena_data={
            "val_ena_bruta_mw_mes": 1.0,
            "val_ena_armazenada_mw_mes": 1.0,
            "val_ena_armazenada_percentual": 1.0
        }
    )
    mock_response = {
        "total_items": 1, "total_pages": 1, "current_page": 1, "items_on_page": 1,
        "items": [mock_item.model_dump(mode='json')]
    }
    mock_basin_service.get_historical_volume.return_value = mock_response

    # Make the request
    response = client.get("/api/basin/historical-data?start_date=2023-01-01&end_date=2023-01-31")

    # Assertions
    assert response.status_code == 200
    assert response.json() == mock_response
    mock_basin_service.get_historical_volume.assert_called_once_with(
        date(2023, 1, 1), date(2023, 1, 31), 1, 100 # Default page and size
    )

def test_get_historical_data_not_found(mock_basin_service):
    """
    Test the GET /historical-data endpoint when the service finds no data.
    The endpoint should return a 404 Not Found error.
    """
    # Mock the service to return an empty result
    mock_response = {
        "total_items": 0, "total_pages": 0, "current_page": 1, "items_on_page": 0, "items": []
    }
    mock_basin_service.get_historical_volume.return_value = mock_response

    # Make the request
    response = client.get("/api/basin/historical-data?start_date=2023-01-01&end_date=2023-01-31")

    # Assertions
    assert response.status_code == 404
    assert "No data found" in response.json()["detail"]

def test_get_historical_data_invalid_date_range():
    """
    Test the GET /historical-data endpoint with a start_date after the end_date.
    The endpoint should return a 400 Bad Request error.
    """
    response = client.get("/api/basin/historical-data?start_date=2023-02-01&end_date=2023-01-31")

    # Assertions
    assert response.status_code == 400
    assert "Start date cannot be after the end date" in response.json()["detail"]

def test_get_historical_data_missing_query_params():
    """
    Test the GET /historical-data endpoint with missing required query parameters.
    FastAPI should return a 422 Unprocessable Entity error.
    """
    # Missing end_date
    response = client.get("/api/basin/historical-data?start_date=2023-01-01")
    assert response.status_code == 422

    # Missing start_date
    response = client.get("/api/basin/historical-data?end_date=2023-01-31")
    assert response.status_code == 422