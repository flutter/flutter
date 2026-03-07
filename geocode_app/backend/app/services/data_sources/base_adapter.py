"""
Base adapter interface for all satellite data sources.
All specific adapters inherit from this abstract base class.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
import logging
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class DataReading(BaseModel):
    """Standard data reading structure"""
    location_name: str
    latitude: float
    longitude: float
    timestamp: datetime
    data_source: str
    value: float
    confidence: Optional[float] = None
    unit: str
    grid_cell_id: Optional[str] = None
    raw_data: Optional[Dict[str, Any]] = None


class BaseDataAdapter(ABC):
    """
    Abstract base class for all satellite data source adapters.

    Provides standardized interface for fetching, validating, and parsing
    satellite data from various sources (NASA, JAXA, ESA, IMD).
    """

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """
        Initialize adapter with credentials.

        Args:
            credentials: Dictionary containing authentication credentials
                        (username, password, API keys, etc.)
        """
        self.credentials = credentials or {}
        self.name = self.__class__.__name__
        self.logger = logging.getLogger(self.name)
        self.tamil_nadu_bbox = (8.0, 76.7, 13.3, 80.4)  # (south, west, north, east)

    @abstractmethod
    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch data from source for given bounding box and date range.

        Args:
            bbox: Bounding box (south_lat, west_lon, north_lat, east_lon)
            date_from: Start date for data retrieval
            date_to: End date for data retrieval
            **kwargs: Additional parameters specific to each adapter

        Returns:
            List of DataReading objects
        """
        pass

    @abstractmethod
    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate and quality check data readings.

        Args:
            readings: List of readings to validate

        Returns:
            List of validated readings (invalid ones removed)
        """
        pass

    @abstractmethod
    async def parse_response(self, response: Any) -> List[DataReading]:
        """
        Parse response from API/data source into standard format.

        Args:
            response: Raw response from data source

        Returns:
            List of DataReading objects
        """
        pass

    def _is_in_bbox(self, lat: float, lon: float, bbox: Tuple[float, float, float, float]) -> bool:
        """Check if coordinate is within bounding box."""
        south, west, north, east = bbox
        return south <= lat <= north and west <= lon <= east

    def _handle_error(self, error: Exception, context: str) -> None:
        """Standardized error handling."""
        self.logger.error(f"{self.name} error in {context}: {str(error)}", exc_info=True)

    async def retry_fetch(
        self,
        max_retries: int = 3,
        retry_delay: int = 60,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch with retry logic for transient failures.

        Args:
            max_retries: Maximum number of retry attempts
            retry_delay: Delay between retries in seconds
            **kwargs: Arguments to pass to fetch_data

        Returns:
            List of DataReading objects or empty list on failure
        """
        import asyncio

        for attempt in range(max_retries):
            try:
                self.logger.info(f"{self.name} fetch attempt {attempt + 1}/{max_retries}")
                data = await self.fetch_data(**kwargs)
                self.logger.info(f"{self.name} successfully fetched {len(data)} readings")
                return data
            except Exception as e:
                self._handle_error(e, f"fetch attempt {attempt + 1}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff

        self.logger.warning(f"{self.name} failed after {max_retries} retries")
        return []

    async def get_data(
        self,
        bbox: Optional[Tuple[float, float, float, float]] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        **kwargs
    ) -> List[DataReading]:
        """
        Wrapper method: fetch → validate → return.

        Args:
            bbox: Bounding box (defaults to Tamil Nadu)
            date_from: Start date (defaults to 3 days ago)
            date_to: End date (defaults to now)
            **kwargs: Additional parameters

        Returns:
            List of validated DataReading objects
        """
        from datetime import datetime, timedelta

        # Use defaults
        if bbox is None:
            bbox = self.tamil_nadu_bbox
        if date_from is None:
            date_from = datetime.utcnow() - timedelta(days=3)
        if date_to is None:
            date_to = datetime.utcnow()

        self.logger.info(
            f"{self.name} fetching data: bbox={bbox}, "
            f"date_from={date_from}, date_to={date_to}"
        )

        # Fetch data
        readings = await self.fetch_data(bbox, date_from, date_to, **kwargs)
        self.logger.info(f"{self.name} fetched {len(readings)} raw readings")

        # Validate data
        validated = await self.validate_data(readings)
        self.logger.info(f"{self.name} validated {len(validated)}/{len(readings)} readings")

        return validated


class DataSourceFactory:
    """Factory for creating and managing data source adapters."""

    _adapters: Dict[str, type] = {}

    @classmethod
    def register(cls, name: str, adapter_class: type) -> None:
        """Register a new adapter."""
        cls._adapters[name] = adapter_class
        logging.getLogger(__name__).info(f"Registered adapter: {name}")

    @classmethod
    def create(cls, name: str, credentials: Optional[Dict[str, str]] = None) -> BaseDataAdapter:
        """Create adapter instance by name."""
        if name not in cls._adapters:
            raise ValueError(f"Unknown adapter: {name}. Available: {list(cls._adapters.keys())}")
        return cls._adapters[name](credentials)

    @classmethod
    def list_adapters(cls) -> List[str]:
        """List all registered adapters."""
        return list(cls._adapters.keys())
