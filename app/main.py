from fastapi import FastAPI
from app.routers import reservoir

# Initialize the FastAPI application
app = FastAPI(
    title="Sauter Reservoir Data API",
    description="An API to download and query reservoir data from Brazil's National System Operator (ONS).",
    version="1.0.0",
)

# Include the routes defined in the reservoir router module.
# This keeps the main application file clean and organized.
app.include_router(reservoir.router)

@app.get("/")
async def read_root():
    """
    Root endpoint for health checks.
    Provides a simple welcome message to indicate that the API is online.
    """
    return {"message": "Welcome to the Reservoir Data API. See /docs for more information."}