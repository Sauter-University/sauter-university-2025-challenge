import math
from typing import Any, List, Generic, TypeVar
from datetime import date
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict


class IngestDataRequest(BaseModel):
    """
    Defines the structure for the data ingestion request body.
    Ensures that start and end dates are provided and valid.
    """
    start_date: date = Field(..., description="Start date in YYYY-MM-DD format.")
    end_date: date = Field(..., description="End date in YYYY-MM-DD format.")

    @model_validator(mode='after')
    def validate_date_range(self):
        """Validates that the end_date is not before the start_date."""
        if self.start_date and self.end_date and self.end_date < self.start_date:
            raise ValueError('End date cannot be earlier than start date.')
        return self

# --- Data Transfer Object (DTO) Models ---

class BasinVolume(BaseModel):
    """
    Represents the structure of a single basin data point.
    This model is used as the response item in the API.
    """
    model_config = ConfigDict(from_attributes=True) # Enables ORM-like data mapping

    basin_name: str = Field(alias="nom_bacia")
    recorded_date: date = Field(alias="ena_data")
    volume_percent_useful: float = Field(alias="ena_armazenavel_bacia_percentualmlt")

    @field_validator("volume_percent_useful", mode='before')
    @classmethod
    def clean_volume_percent(cls, v: Any) -> float:
        """
        A pre-validator that cleans the 'volume_percent_useful' field.
        It handles None, NaN, and comma-decimal values before the main validation.
        """
        if v is None or (isinstance(v, float) and math.isnan(v)):
            return 0.0
        try:
            # Convert comma-separated decimals to dot-separated and then to float
            return float(str(v).replace(',', '.'))
        except (ValueError, TypeError):
            # If conversion fails (e.g., for an empty string), return 0.0
            return 0.0

# --- Paginated Response Models ---

T = TypeVar('T') # Generic type variable for paginated items

class PaginatedResponse(BaseModel, Generic[T]):
    """
    A generic model for offset/limit paginated API responses.
    Provides metadata about the pagination state along with the data items.
    """
    total_items: int
    total_pages: int
    current_page: int
    items_on_page: int
    items: List[T]