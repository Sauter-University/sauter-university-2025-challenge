import pytest
from unittest.mock import MagicMock, patch
from datetime import date
import pandas as pd

from api.repositories.gcs_repository import GCSRepository

@pytest.fixture
def mock_storage_client():
    with patch('api.repositories.gcs_repository.storage.Client') as mock_client:
        yield mock_client

@pytest.fixture
def gcs_repository(mock_storage_client):
    bucket_name = "test-bucket"
    repo = GCSRepository(bucket_name=bucket_name)
    repo.bucket = MagicMock()
    repo.client = mock_storage_client # Garante que o cliente mockado seja usado
    return repo

def test_save_dataframe_success(gcs_repository):
    df = pd.DataFrame({'data': [1, 2]})
    year = 2023
    ingestion_date = date(2023, 10, 26)
    
    mock_blob = MagicMock()
    gcs_repository.bucket.blob.return_value = mock_blob
    
    gcs_repository.save_dataframe(df, year, ingestion_date)
    
    # CORREÇÃO: O caminho real no seu código é este
    expected_blob_name = f"basin_data/historical/basin_data_{year}.parquet"
    gcs_repository.bucket.blob.assert_called_once_with(expected_blob_name)
    mock_blob.upload_from_file.assert_called_once()

def test_historical_data_exists(gcs_repository):
    mock_blob = MagicMock()
    mock_blob.exists.return_value = True
    gcs_repository.bucket.blob.return_value = mock_blob
    
    assert gcs_repository.historical_data_exists(2022) is True
    # CORREÇÃO: O caminho real no seu código é este
    expected_blob_name = "basin_data/historical/basin_data_2022.parquet"
    gcs_repository.bucket.blob.assert_called_once_with(expected_blob_name)

def test_historical_data_does_not_exist(gcs_repository):
    mock_blob = MagicMock()
    mock_blob.exists.return_value = False
    gcs_repository.bucket.blob.return_value = mock_blob
    
    assert gcs_repository.historical_data_exists(2022) is False

def test_get_latest_ingestion_date_found(gcs_repository):
    blob1 = MagicMock()
    blob1.name = "basin_data/bronze/2023-10-25/file.parquet"
    blob2 = MagicMock()
    blob2.name = "basin_data/bronze/2023-10-26/file.parquet"
    
    # CORREÇÃO: O mock deve ser no método list_blobs do cliente
    gcs_repository.client.list_blobs.return_value = [blob1, blob2]
    
    latest_date = gcs_repository.get_latest_ingestion_date()
    
    assert latest_date == date(2023, 10, 26)
    gcs_repository.client.list_blobs.assert_called_once_with("test-bucket", prefix="basin_data/bronze/")

def test_get_latest_ingestion_date_not_found(gcs_repository):
    gcs_repository.client.list_blobs.return_value = []
    latest_date = gcs_repository.get_latest_ingestion_date()
    assert latest_date is None

def test_gcs_repository_initialization_requires_bucket_name():
    with pytest.raises(ValueError, match="The GCS bucket name is required."):
        GCSRepository(bucket_name=None)