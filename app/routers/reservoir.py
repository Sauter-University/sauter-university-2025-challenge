import os
from datetime import date
from fastapi import APIRouter, Query, HTTPException, Depends, status

from app.models.reservoir import ReservoirVolume, IngestDataRequest, PaginatedResponse
from app.repositories.gcs_repository import GCSRepository
from app.services.reservoir_service import ReservoirService
from app.core.ons_client import ONSClient

# Create an API router to organize endpoints related to reservoir data
router = APIRouter(
    prefix="/api/v1",
    tags=["Reservoir Volume"],
)

# --- Dependency Injection ---
# These functions allow FastAPI to automatically create and provide instances
# of our services and repositories to the endpoint functions.

def get_ons_client():
    """Dependency provider for the ONSClient."""
    return ONSClient()

def get_repository():
    """
    Dependency provider for the GCSRepository.
    It reads the GCS bucket name from an environment variable, which is a best
    practice for configuring applications in cloud environments.
    """
    bucket_name = os.getenv("GCS_BUCKET_NAME") 
    return GCSRepository(bucket_name=bucket_name)

def get_reservoir_service(
        repo: GCSRepository = Depends(get_repository),
        client: ONSClient = Depends(get_ons_client)
) -> ReservoirService:
    """
    Dependency provider for the ReservoirService.
    It depends on the repository and the client, which FastAPI will provide.
    """
    return ReservoirService(repository=repo, ons_client=client)
# -----------------------------

@router.post("/ingest", status_code=status.HTTP_201_CREATED)
async def ingest_data(
    request: IngestDataRequest,
    service: ReservoirService = Depends(get_reservoir_service)
):
    """
    (POST) Triggers the data ingestion process for a specified date range.
    This endpoint downloads data from the ONS and stores it in GCS.
    """
    rows_ingested = service.ingest_data(request.start_date, request.end_date)
    return {
        "message": "Data ingestion completed.",
        "rows_ingested": rows_ingested
    }

@router.get(
    "/reservoir-volume/historical",
    response_model=PaginatedResponse[ReservoirVolume]
)
async def get_historical_volume(
    start_date: date = Query(..., description="Start date for the query in YYYY-MM-DD format."),
    end_date: date = Query(..., description="End date for the query in YYYY-MM-DD format."),
    page: int = Query(1, ge=1, description="The page number, starting from 1."),
    size: int = Query(100, ge=1, le=1000, description="The number of items per page."),
    service: ReservoirService = Depends(get_reservoir_service)
):
    """
    (GET) Retrieves paginated historical reservoir volume for a given date range
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