import functools
import logging
import time
from typing import Callable
import sys

# Basic logging configuration to ensure messages are displayed in the console.
# This is essential for visibility when running in environments like Cloud Run.
logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def logging_it(func: Callable) -> Callable:
    """
    A decorator that logs the entry, exit (success or error), and execution time
    of a function.
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        """Wrapper function that adds logging capabilities."""
        logger = logging.getLogger(func.__module__)

        start_time = time.time()
        logger.info(f"Starting execution of '{func.__name__}'...")

        try:
            # Execute the original function
            result = func(*args, **kwargs)

            # Log success and execution time
            execution_time = time.time() - start_time
            logger.info(f"Function '{func.__name__}' executed successfully in {execution_time:.2f}s.")
            return result
        except Exception as e:
            # Log any exception that occurs
            execution_time = time.time() - start_time
            # exc_info=True adds the full traceback to the log, which is invaluable for debugging.
            logger.error(f"Error in function '{func.__name__}' after {execution_time:.2f}s: {e}", exc_info=True)
            raise  # Re-raise the exception to not alter the program's behavior
    return wrapper