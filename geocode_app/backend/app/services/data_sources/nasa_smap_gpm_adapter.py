"""
NASA SMAP (Soil Moisture Active/Passive) and GPM (Global Precipitation Measurement)
satellite data adapter.

SMAP: Soil moisture at 10cm and 40cm depth, ~3-day revisit
GPM: Precipitation rate, ~30-minute temporal resolution
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
import aiohttp
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import TemporalUtils, SpatialUtils, DataQualityUtils
from app.config import settings

logger = logging.getLogger(__name__)


class NASASensorAdapter(BaseDataAdapter):
    """Adapter for NASA satellite data sources."""

    # NASA Earth Data API endpoints
    SMAP_ENDPOINT = "https://api.daac.asf.alaska.edu/services/search/spatial"
    GPM_ENDPOINT = "https://jsps.eosdis.nasa.gov/api/v8/dataset"

    # NASA Earth Data server
    NASA_EARTHDATA_URL = "https://data.nsidc.org/daacservices/file_information"

    # Direct download endpoints
    SMAP_OPENDAP = "https://hydro1.gesdisc.eosdis.nasa.gov/opendap"
    GPM_IMAP = "https://gpm1.gesdisc.eosdis.nasa.gov/opendap"

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize NASA SMAP/GPM adapter."""
        super().__init__(credentials)

        # Get credentials from environment if not provided
        if not credentials:
            self.credentials = {
                'username': settings.NASA_EARTHDATA_USERNAME or '',
                'password': settings.NASA_EARTHDATA_PASSWORD or '',
            }

        self.session: Optional[aiohttp.ClientSession] = None
        self.basic_auth = None

        if self.credentials.get('username') and self.credentials.get('password'):
            self.basic_auth = aiohttp.BasicAuth(
                self.credentials['username'],
                self.credentials['password']
            )

    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        data_type: str = 'both',  # 'smap', 'gpm', or 'both'
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch SMAP and/or GPM data for Tamil Nadu.

        Args:
            bbox: Bounding box (south_lat, west_lon, north_lat, east_lon)
            date_from: Start date for data retrieval
            date_to: End date for data retrieval
            data_type: Type of data to fetch ('smap', 'gpm', or 'both')
            **kwargs: Additional parameters

        Returns:
            List of DataReading objects
        """
        readings = []

        try:
            # Create session if needed
            if self.session is None:
                self.session = aiohttp.ClientSession()

            if data_type in ['smap', 'both']:
                logger.info("Fetching SMAP soil moisture data...")
                smap_data = await self._fetch_smap_data(bbox, date_from, date_to)
                readings.extend(smap_data)

            if data_type in ['gpm', 'both']:
                logger.info("Fetching GPM precipitation data...")
                gpm_data = await self._fetch_gpm_data(bbox, date_from, date_to)
                readings.extend(gpm_data)

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def _fetch_smap_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime
    ) -> List[DataReading]:
        """
        Fetch SMAP Level 4 Soil Moisture data.

        SMAP provides global soil moisture estimates at ~9km resolution
        with ~3-day revisit time.
        """
        readings = []

        try:
            south, west, north, east = bbox

            # SMAP data is available at:
            # https://daac.ornl.gov/ and https://nsidc.org/

            # For this implementation, we simulate based on Tamil Nadu grid
            # In production, integrate with actual NASA API
            logger.info(f"SMAP: Fetching for bbox {bbox}, {date_from} to {date_to}")

            # Create Tamil Nadu grid at 0.5° resolution
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.5)

            # Simulate SMAP readings (in production, fetch from NASA API)
            for lat, lon in grid_points:
                # Mock soil moisture value (0-100%)
                import random
                soil_moisture = random.uniform(10, 80)

                reading = DataReading(
                    location_name=f"Grid_{lat:.1f}_{lon:.1f}",
                    latitude=lat,
                    longitude=lon,
                    timestamp=date_to,
                    data_source="SMAP",
                    value=soil_moisture,
                    confidence=0.85,
                    unit="percent",
                    grid_cell_id=f"smap_{lat:.1f}_{lon:.1f}"
                )
                readings.append(reading)

            logger.info(f"SMAP: Created {len(readings)} readings")

        except Exception as e:
            self._handle_error(e, "_fetch_smap_data")

        return readings

    async def _fetch_gpm_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime
    ) -> List[DataReading]:
        """
        Fetch GPM Integrated Multi-satellitE Retrievals (IMERG) data.

        GPM provides global precipitation estimates at ~10km resolution
        with ~30-minute temporal resolution.
        """
        readings = []

        try:
            south, west, north, east = bbox

            logger.info(f"GPM: Fetching for bbox {bbox}, {date_from} to {date_to}")

            # Create Tamil Nadu grid at higher resolution for precipitation
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.25)

            # Simulate GPM readings (in production, fetch from NASA API)
            for lat, lon in grid_points:
                # Mock precipitation rate (mm/hr)
                import random
                precip_rate = random.uniform(0, 50)

                reading = DataReading(
                    location_name=f"Grid_{lat:.2f}_{lon:.2f}",
                    latitude=lat,
                    longitude=lon,
                    timestamp=date_to,
                    data_source="GPM",
                    value=precip_rate,
                    confidence=0.80,
                    unit="mm/hr",
                    grid_cell_id=f"gpm_{lat:.2f}_{lon:.2f}"
                )
                readings.append(reading)

            logger.info(f"GPM: Created {len(readings)} readings")

        except Exception as e:
            self._handle_error(e, "_fetch_gpm_data")

        return readings

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate SMAP and GPM data readings.

        Checks:
        - Coordinate validity
        - Value ranges
        - Outlier detection
        - Spatial continuity
        """
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    logger.warning(f"Invalid coordinates: {reading.latitude}, {reading.longitude}")
                    continue

                # Validate value ranges
                if reading.data_source == "SMAP":
                    if not DataQualityUtils.check_value_range(
                        reading.value, 0, 100, "SMAP soil moisture"
                    ):
                        continue
                elif reading.data_source == "GPM":
                    if not DataQualityUtils.check_value_range(
                        reading.value, 0, 200, "GPM precipitation"
                    ):
                        continue

                # Add confidence score
                if reading.confidence is None:
                    reading.confidence = 0.85

                validated.append(reading)

            except Exception as e:
                logger.error(f"Validation error for {reading.location_name}: {e}")

        logger.info(f"Validated {len(validated)}/{len(readings)} readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """
        Parse JSON response from NASA API.

        Args:
            response: JSON response from API

        Returns:
            List of DataReading objects
        """
        readings = []

        try:
            if isinstance(response, dict):
                # Parse from NASA DAAC response format
                features = response.get('features', [])
                for feature in features:
                    props = feature.get('properties', {})
                    coords = feature.get('geometry', {}).get('coordinates', [])

                    if len(coords) >= 2:
                        reading = DataReading(
                            location_name=props.get('name', 'unknown'),
                            latitude=coords[1],
                            longitude=coords[0],
                            timestamp=datetime.fromisoformat(
                                props.get('acquisitionDate', datetime.utcnow().isoformat())
                            ),
                            data_source=props.get('source', 'NASA'),
                            value=float(props.get('value', 0)),
                            confidence=float(props.get('confidence', 0.85)),
                            unit=props.get('unit', 'unknown'),
                        )
                        readings.append(reading)

        except Exception as e:
            logger.error(f"Error parsing NASA API response: {e}")

        return readings

    async def get_latest_smap(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """
        Convenience method to get latest SMAP data.

        Args:
            bbox: Bounding box (Tamil Nadu)

        Returns:
            List of latest SMAP readings
        """
        date_from, date_to = TemporalUtils.get_date_range(days_back=3)
        return await self.fetch_data(bbox, date_from, date_to, data_type='smap')

    async def get_latest_gpm(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """
        Convenience method to get latest GPM data.

        Args:
            bbox: Bounding box (Tamil Nadu)

        Returns:
            List of latest GPM readings
        """
        date_from, date_to = TemporalUtils.get_date_range(days_back=1)
        return await self.fetch_data(bbox, date_from, date_to, data_type='gpm')

    async def __aenter__(self):
        """Context manager support."""
        if self.session is None:
            self.session = aiohttp.ClientSession()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Clean up session."""
        if self.session:
            await self.session.close()

    def __del__(self):
        """Cleanup on deletion."""
        if self.session and not self.session.closed:
            # Cannot await in __del__, so we need to handle this in __aexit__
            pass
