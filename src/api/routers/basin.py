import os
from datetime import date
from fastapi import APIRouter, Query, HTTPException, Depends, status

from api.models.basin import BasinSilverData, IngestDataRequest, PaginatedResponse
from api.repositories.gcs_repository import GCSRepository
from api.repositories.bigquery_repository import BigQueryRepository
from api.services.basin_service import BasinService
from api.core.ons_client import ONSClient

# Create an API router to organize endpoints related to basin data
router = APIRouter(
    prefix="/api/basin",
    tags=["Basin Data"],
)

# --- Dependency Injection ---
# These functions allow FastAPI to automatically create and provide instances
# of our services and repositories to the endpoint functions.

def get_ons_client():
    """Dependency provider for the ONSClient."""
    return ONSClient()

def get_gcs_repository():
    """
    Dependency provider for the GCSRepository.
    It reads the GCS bucket name from an environment variable, which is a best
    practice for configuring applications in cloud environments.
    """
    bucket_name = os.getenv("GCS_BUCKET_NAME") 
    return GCSRepository(bucket_name=bucket_name)

def get_bigquery_repository():
    """
    Dependency provider for the BigQueryRepository.
    It reads configuration from environment variables to connect to the correct
    BigQuery project, dataset, and table.
    """
    project_id = "sauter-university-472416"
    dataset_id = "ons_silver"
    table_id = "ena_basin_silver"
    return BigQueryRepository(project_id=project_id, dataset_id=dataset_id, table_id=table_id)

def get_basin_service(
    gcs_repo: GCSRepository = Depends(get_gcs_repository),
    bq_repo: BigQueryRepository = Depends(get_bigquery_repository),
    client: ONSClient = Depends(get_ons_client)
) -> BasinService:
    """
    Dependency provider for the BasinService.
    It depends on the repository and the client, which FastAPI will provide.
    """
    return BasinService(gcs_repo=gcs_repo, bq_repo=bq_repo, ons_client=client)

@router.post("/ingest", status_code=status.HTTP_200_OK)
async def ingest_data(
    request: IngestDataRequest,
    service: BasinService = Depends(get_basin_service)
):
    """
    (POST) Triggers the data ingestion process for a specified date range.
    This endpoint downloads data from the ONS and stores it in GCS, and returns a
    detailed report of the operation for each requested year.
    """
    ingestion_report = service.ingest_data(request.start_date, request.end_date)
    return ingestion_report

@router.get(
    "/historical-data",
    response_model=PaginatedResponse[BasinSilverData]
)
async def get_historical_volume(
    start_date: date = Query(..., description="Start date for the query in YYYY-MM-DD format."),
    end_date: date = Query(..., description="End date for the query in YYYY-MM-DD format."),
    page: int = Query(1, ge=1, description="The page number, starting from 1."),
    size: int = Query(100, ge=1, le=1000, description="The number of items per page."),
    service: BasinService = Depends(get_basin_service)
):
    """
    (GET) Retrieves paginated historical Basin volume for a given date range
    from the data stored in GCS.
    """
    if start_date > end_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Start date cannot be after the end date.",
        )
    
    paginated_results = service.get_historical_volume(start_date, end_date, page, size)
    
    # If no valid items are found for the given filters, return a 404.
    if not paginated_results["items"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No data found for the applied filters. Please run the POST /ingest for the desired period.",
        )
    return paginated_results