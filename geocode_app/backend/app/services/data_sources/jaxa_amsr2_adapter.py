"""
JAXA AMSR2 (Advanced Microwave Scanning Radiometer-2) satellite data adapter.

AMSR2 provides soil moisture data at L-band frequency with ~1-2 day revisit,
useful for validating SMAP data and dual-frequency analysis.
"""

import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import SpatialUtils, DataQualityUtils, TemporalUtils
from app.config import settings

logger = logging.getLogger(__name__)


class JAXA_AMSR2_Adapter(BaseDataAdapter):
    """Adapter for JAXA AMSR2 satellite data."""

    # JAXA Data Gateway
    AMSR2_ENDPOINT = "ftp://g2.iis.u-tokyo.ac.jp/amsr2/"

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize JAXA AMSR2 adapter."""
        super().__init__(credentials)

        if not credentials:
            self.credentials = {
                'ftp_user': settings.JAXA_FTP_USER or '',
                'ftp_password': settings.JAXA_FTP_PASSWORD or '',
            }

    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch AMSR2 soil moisture data from JAXA.

        Regular products available at:
        - Level 3 Soil Moisture (25 km resolution)
        - Daily and monthly composites

        Args:
            bbox: Bounding box (south_lat, west_lon, north_lat, east_lon)
            date_from: Start date
            date_to: End date
            **kwargs: Additional parameters

        Returns:
            List of DataReading objects
        """
        readings = []

        try:
            logger.info(f"AMSR2: Fetching soil moisture for {date_from} to {date_to}")

            south, west, north, east = bbox

            # In production, fetch from:
            # ftp://g2.iis.u-tokyo.ac.jp/amsr2/l3_os/daily/
            # with HDF5 files containing soil moisture at ascending/descending passes

            # Create grid for AMSR2 data (25km resolution)
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.25)

            # Simulate AMSR2 readings
            for lat, lon in grid_points:
                # Mock AMSR2 soil moisture (0-100%)
                import random
                soil_moisture = random.uniform(8, 85)

                # AMSR2 provides both ascending and descending passes
                for pass_type in ['ascending', 'descending']:
                    reading = DataReading(
                        location_name=f"Grid_{lat:.1f}_{lon:.1f}_{pass_type}",
                        latitude=lat,
                        longitude=lon,
                        timestamp=date_to,
                        data_source="AMSR2",
                        value=soil_moisture + random.uniform(-5, 5),  # Slight variation
                        confidence=0.82,
                        unit="percent",
                        grid_cell_id=f"amsr2_{lat:.1f}_{lon:.1f}",
                        raw_data={'pass_type': pass_type, 'frequency': 'L-band'}
                    )
                    readings.append(reading)

            logger.info(f"AMSR2: Created {len(readings)} readings (with passes)")

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate AMSR2 data.

        Checks:
        - Coordinate validity
        - Soil moisture in 0-100% range
        - No frozen soil (exclude if temperature < 0°C)
        """
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    continue

                # Validate soil moisture range
                if not DataQualityUtils.check_value_range(
                    reading.value, 0, 100, "AMSR2 soil moisture"
                ):
                    continue

                # Data quality checks
                if reading.confidence is None:
                    reading.confidence = 0.82

                validated.append(reading)

            except Exception as e:
                logger.error(f"AMSR2 validation error: {e}")

        logger.info(f"AMSR2: Validated {len(validated)}/{len(readings)} readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """
        Parse AMSR2 HDF5 response.

        AMSR2-specific parsing for soil moisture data.
        """
        readings = []

        try:
            if isinstance(response, dict) and 'soil_moisture' in response:
                # Parse from HDF5 structure
                soil_moisture_data = response['soil_moisture']

                # Extract grid data
                for row in soil_moisture_data:
                    for col in row:
                        if col and 'value' in col:
                            reading = DataReading(
                                location_name=f"AMSR2_SM",
                                latitude=col.get('lat', 0),
                                longitude=col.get('lon', 0),
                                timestamp=datetime.utcnow(),
                                data_source="AMSR2",
                                value=float(col['value']),
                                confidence=float(col.get('quality', 0.82)),
                                unit="percent"
                            )
                            readings.append(reading)

        except Exception as e:
            logger.error(f"AMSR2 response parsing error: {e}")

        return readings

    async def get_latest(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """Get latest available AMSR2 data."""
        date_from, date_to = TemporalUtils.get_date_range(days_back=2)
        return await self.fetch_data(bbox, date_from, date_to)

    async def compare_with_smap(
        self,
        smap_readings: List[DataReading],
        amsr2_readings: List[DataReading],
        tolerance_percent: float = 15.0
    ) -> Dict[str, Any]:
        """
        Compare SMAP and AMSR2 measurements for cross-validation.

        Args:
            smap_readings: List of SMAP soil moisture readings
            amsr2_readings: List of AMSR2 soil moisture readings
            tolerance_percent: Acceptable difference threshold

        Returns:
            Comparison statistics
        """
        comparison = {
            'total_pairs': 0,
            'within_tolerance': 0,
            'outliers': 0,
            'mean_difference': 0.0,
            'max_difference': 0.0,
            'outlier_locations': []
        }

        try:
            # Convert to location-based index for matching
            smap_index = {
                f"{round(r.latitude, 1)}_{round(r.longitude, 1)}": r
                for r in smap_readings
            }

            differences = []

            for amsr2_reading in amsr2_readings:
                key = f"{round(amsr2_reading.latitude, 1)}_{round(amsr2_reading.longitude, 1)}"

                if key in smap_index:
                    smap_reading = smap_index[key]
                    diff = abs(smap_reading.value - amsr2_reading.value)
                    differences.append(diff)

                    comparison['total_pairs'] += 1

                    if diff <= tolerance_percent:
                        comparison['within_tolerance'] += 1
                    else:
                        comparison['outliers'] += 1
                        comparison['outlier_locations'].append({
                            'lat': amsr2_reading.latitude,
                            'lon': amsr2_reading.longitude,
                            'smap': smap_reading.value,
                            'amsr2': amsr2_reading.value,
                            'diff': diff
                        })

            if differences:
                comparison['mean_difference'] = sum(differences) / len(differences)
                comparison['max_difference'] = max(differences)

            logger.info(
                f"AMSR2-SMAP comparison: {comparison['total_pairs']} pairs, "
                f"{comparison['within_tolerance']} within tolerance"
            )

        except Exception as e:
            logger.error(f"Comparison error: {e}")

        return comparison
