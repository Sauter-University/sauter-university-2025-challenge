class ONSClientError(Exception):
    """
    Base exception for errors originating from the ONSClient.
    This allows for centralized error handling of client-related issues.
    """
    pass

class ONSResourceNotFoundError(ONSClientError):
    """
    Raised when a specific resource (e.g., a data file for a given year)
    is not found in the ONS data package.
    """
    pass

class ONSDataProcessingError(ONSClientError):
    """
    Raised when an error occurs during the download or processing
    of data from the ONS.
    """
    pass