"""
NASA MODIS (Moderate Resolution Imaging Spectroradiometer) thermal data adapter.

Provides Land Surface Temperature (LST) and thermal anomaly detection useful for:
- Fire/heat anomaly detection
- Urban heat island identification
- Surface moisture inference
- Vegetation stress detection (elevated temperature)
"""

import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import SpatialUtils, DataQualityUtils, TemporalUtils
from app.config import settings

logger = logging.getLogger(__name__)


class MODIS_Thermal_Adapter(BaseDataAdapter):
    """Adapter for NASA MODIS thermal/LST data."""

    # LAADS DAAC (NASA EarthData)
    LAADS_ENDPOINT = "https://ladsweb.modaps.eosdis.nasa.gov/api/v2"

    # Direct data portal
    MODIS_ENDPOINT = "https://lpdaac.usgs.gov/products"

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize MODIS Thermal adapter."""
        super().__init__(credentials)

        if not credentials:
            self.credentials = {
                'username': settings.NASA_EARTHDATA_USERNAME or '',
                'password': settings.NASA_EARTHDATA_PASSWORD or '',
            }

    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch MODIS Land Surface Temperature (LST) data.

        MODIS aboard Terra and Aqua provides global LST every 1-2 days
        at 1km resolution (MOD11A1/MYD11A1 products).

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
            logger.info(f"MODIS LST: Fetching thermal data for {date_from} to {date_to}")

            south, west, north, east = bbox

            # In production, fetch from LAADS DAAC:
            # MOD11A1 - Terra daily LST
            # MYD11A1 - Aqua daily LST
            # MOD11A2 - Terra 8-day composite

            # Create grid at MODIS resolution (1km)
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.01)  # ~1km

            # Simulate MODIS LST readings
            for lat, lon in grid_points:
                # Mock LST temperature (Celsius, typical range 10-45°C)
                import random
                lst = random.uniform(15, 42)

                # Emissivity (varies by land cover, 0.95-0.99 typical)
                emissivity = random.uniform(0.95, 0.99)

                reading = DataReading(
                    location_name=f"Grid_{lat:.2f}_{lon:.2f}",
                    latitude=lat,
                    longitude=lon,
                    timestamp=date_to,
                    data_source="MODIS_LST",
                    value=lst,
                    confidence=0.85,
                    unit="celsius",
                    grid_cell_id=f"modis_lst_{lat:.2f}_{lon:.2f}",
                    raw_data={
                        'product': 'MOD11A1/MYD11A1',
                        'satellite': 'Terra/Aqua',
                        'emissivity': emissivity,
                        'quality_flag': 'good',
                        'day_or_night': 'day'
                    }
                )
                readings.append(reading)

            logger.info(f"MODIS LST: Created {len(readings)} thermal readings")

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate MODIS LST data.

        Checks:
        - Coordinate validity
        - LST range checks
        - Quality flags
        - Exclude water/out-of-range pixels
        """
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    continue

                # Validate LST range (physical bounds: -20°C to 70°C)
                if not DataQualityUtils.check_value_range(
                    reading.value, -20, 70, "MODIS LST"
                ):
                    continue

                # Check quality flag
                if reading.raw_data and reading.raw_data.get('quality_flag') == 'poor':
                    continue

                validated.append(reading)

            except Exception as e:
                logger.error(f"MODIS LST validation error: {e}")

        logger.info(f"MODIS LST: Validated {len(validated)}/{len(readings)} readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """Parse MODIS LST response."""
        readings = []

        try:
            if isinstance(response, dict) and 'lst_data' in response:
                # Parse from HDF4/NetCDF data
                for pixel in response['lst_data']:
                    reading = DataReading(
                        location_name=f"MODIS_LST",
                        latitude=float(pixel.get('lat', 0)),
                        longitude=float(pixel.get('lon', 0)),
                        timestamp=datetime.utcnow(),
                        data_source="MODIS_LST",
                        value=float(pixel.get('lst_kelvin', 273)) - 273.15,  # Convert K to C
                        confidence=float(pixel.get('quality', 0.85)),
                        unit="celsius"
                    )
                    readings.append(reading)

        except Exception as e:
            logger.error(f"MODIS LST response parsing error: {e}")

        return readings

    def detect_thermal_anomalies(
        self,
        readings: List[DataReading],
        std_dev_threshold: float = 2.0
    ) -> Dict[str, Any]:
        """
        Detect thermal anomalies (unusually hot/cold spots).

        Useful for:
        - Fire detection (extreme heat)
        - Urban heat islands
        - Cold spots (water, crops)

        Args:
            readings: MODIS LST readings
            std_dev_threshold: Standard deviations from mean to flag as anomaly

        Returns:
            Anomaly detection results
        """
        anomalies = {
            'total_pixels': len(readings),
            'hot_anomalies': [],
            'cold_anomalies': [],
            'mean_temp': 0.0,
            'std_dev': 0.0,
            'fire_risk_zones': []
        }

        try:
            import numpy as np

            if not readings:
                return anomalies

            # Calculate statistics
            temps = np.array([r.value for r in readings])
            anomalies['mean_temp'] = float(np.mean(temps))
            anomalies['std_dev'] = float(np.std(temps))

            threshold_hot = anomalies['mean_temp'] + (std_dev_threshold * anomalies['std_dev'])
            threshold_cold = anomalies['mean_temp'] - (std_dev_threshold * anomalies['std_dev'])

            # Identify anomalies
            for reading in readings:
                if reading.value > threshold_hot:
                    anomalies['hot_anomalies'].append({
                        'lat': reading.latitude,
                        'lon': reading.longitude,
                        'temp': reading.value,
                        'deviation': reading.value - anomalies['mean_temp']
                    })

                    # Flag as fire risk if very hot (>50°C)
                    if reading.value > 50:
                        anomalies['fire_risk_zones'].append({
                            'lat': reading.latitude,
                            'lon': reading.longitude,
                            'temp': reading.value,
                            'risk': 'high'
                        })

                elif reading.value < threshold_cold:
                    anomalies['cold_anomalies'].append({
                        'lat': reading.latitude,
                        'lon': reading.longitude,
                        'temp': reading.value,
                        'deviation': reading.value - anomalies['mean_temp']
                    })

            logger.info(
                f"MODIS LST: Detected {len(anomalies['hot_anomalies'])} hot and "
                f"{len(anomalies['cold_anomalies'])} cold anomalies"
            )

        except Exception as e:
            logger.error(f"Thermal anomaly detection error: {e}")

        return anomalies

    def estimate_soil_moisture_from_lst(
        self,
        lst: float,
        ndvi: Optional[float] = None
    ) -> Tuple[float, str]:
        """
        Estimate relative soil moisture from LST using Temperature-NDVI space.

        Uses the concept that moist soil is cooler and has higher NDVI.

        Args:
            lst: Land Surface Temperature (Celsius)
            ndvi: Normalized Difference Vegetation Index (optional)

        Returns:
            Tuple of (estimated_soil_moisture_percent, confidence)
        """
        # Temperature Condition Index (TCI)
        # Assumes: min_T (wet) = 15°C, max_T (dry) = 45°C
        min_temp = 15.0
        max_temp = 45.0

        tci = (max_temp - lst) / (max_temp - min_temp)
        tci = max(0, min(1, tci))  # Clamp to 0-1

        moisture_estimate = tci * 100  # Convert to percentage

        confidence = 'low'
        if ndvi is not None:
            # If NDVI is available, increase confidence
            if ndvi > 0.4:  # Vegetated area
                confidence = 'medium'
            elif ndvi > 0.6:
                confidence = 'high'

        return moisture_estimate, confidence

    def calculate_vegetation_stress_index(
        self,
        lst: float,
        ndvi: float,
        reference_lst: Optional[float] = None
    ) -> Tuple[float, str]:
        """
        Calculate vegetation stress based on LST and NDVI.

        High temperature + low NDVI = stressed vegetation.

        Args:
            lst: Land Surface Temperature (Celsius)
            ndvi: NDVI value (-1 to 1)
            reference_lst: Reference/expected LST for location

        Returns:
            Tuple of (stress_index_0_100, stress_level)
        """
        # Normalize LST (assuming 15-45°C range)
        lst_normalized = (lst - 15) / 30  # 0=cold, 1=hot
        lst_normalized = max(0, min(1, lst_normalized))

        # Normalize NDVI (assuming -0.3 to 0.8 range)
        ndvi_normalized = (ndvi + 0.3) / 1.1  # 0=unhealthy, 1=healthy
        ndvi_normalized = max(0, min(1, ndvi_normalized))

        # Stress = high temp + low NDVI
        stress_index = (lst_normalized * 0.6 + (1 - ndvi_normalized) * 0.4) * 100

        if stress_index > 70:
            stress_level = 'severe'
        elif stress_index > 50:
            stress_level = 'moderate'
        elif stress_index > 30:
            stress_level = 'mild'
        else:
            stress_level = 'healthy'

        return stress_index, stress_level

    async def get_latest(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """Get latest available MODIS LST data."""
        date_from, date_to = TemporalUtils.get_date_range(days_back=1)
        return await self.fetch_data(bbox, date_from, date_to)
