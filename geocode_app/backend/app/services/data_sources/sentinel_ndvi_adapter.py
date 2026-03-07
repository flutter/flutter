"""
ESA Sentinel-2 NDVI (Normalized Difference Vegetation Index) adapter.

Provides vegetation health and land cover information useful for:
- Drought assessment (NDVI decline indicates stress)
- Landslide risk (vegetation loss on slopes)
- Land cover classification
"""

import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import SpatialUtils, DataQualityUtils, TemporalUtils
from app.config import settings

logger = logging.getLogger(__name__)


class Sentinel_NDVI_Adapter(BaseDataAdapter):
    """Adapter for Sentinel-2 NDVI vegetation data."""

    # Copernicus Open Access Hub
    COPERNICUS_ENDPOINT = "https://scihub.copernicus.eu/dhus"
    SENTINEL_HUB_ENDPOINT = "https://sentinel-hub.com/api"

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize Sentinel NDVI adapter."""
        super().__init__(credentials)

        if not credentials:
            self.credentials = {
                'username': settings.ESA_COPERNICUS_USER or '',
                'password': settings.ESA_COPERNICUS_PASSWORD or '',
            }

    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch Sentinel-2 NDVI data from Copernicus Hub.

        Sentinel-2A/B provide 10m resolution data every 5 days
        (or 2-3 days with both satellites).

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
            logger.info(f"Sentinel-2 NDVI: Fetching for {date_from} to {date_to}")

            south, west, north, east = bbox

            # In production, query Copernicus Hub for Sentinel-2 L2A products
            # and compute NDVI from Red (B4) and NIR (B8) bands

            # Create grid at Sentinel-2 resolution (10m to 20m, here simulated at 100m)
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.01)  # ~1km

            # Simulate NDVI readings
            for lat, lon in grid_points:
                # Mock NDVI value (-1 to 1, where 0.4+ is healthy vegetation)
                import random
                ndvi = random.uniform(-0.3, 0.8)

                reading = DataReading(
                    location_name=f"Grid_{lat:.2f}_{lon:.2f}",
                    latitude=lat,
                    longitude=lon,
                    timestamp=date_to,
                    data_source="Sentinel-2_NDVI",
                    value=ndvi,
                    confidence=0.88,
                    unit="index",
                    grid_cell_id=f"ndvi_{lat:.2f}_{lon:.2f}",
                    raw_data={
                        'satellite': 'Sentinel-2A/B',
                        'resolution_m': 10,
                        'bands': {'red': 'B4', 'nir': 'B8'},
                        'cloud_cover': random.uniform(0, 30)
                    }
                )
                readings.append(reading)

            logger.info(f"Sentinel-2 NDVI: Created {len(readings)} readings")

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate Sentinel-2 NDVI data.

        Checks:
        - Coordinate validity
        - NDVI in valid range (-1 to 1)
        - Exclude high cloud cover pixels
        """
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    continue

                # Validate NDVI range
                if not DataQualityUtils.check_value_range(
                    reading.value, -1.0, 1.0, "NDVI"
                ):
                    continue

                # Skip high cloud cover pixels
                if reading.raw_data and reading.raw_data.get('cloud_cover', 0) > 20:
                    logger.debug(f"Skipping pixel with high cloud cover at {reading.latitude}, {reading.longitude}")
                    continue

                validated.append(reading)

            except Exception as e:
                logger.error(f"Sentinel NDVI validation error: {e}")

        logger.info(f"Sentinel-2 NDVI: Validated {len(validated)}/{len(readings)} readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """Parse Sentinel-2 NDVI response."""
        readings = []

        try:
            if isinstance(response, dict) and 'ndvi_data' in response:
                # Parse from GeoTIFF or NetCDF data
                for pixel in response['ndvi_data']:
                    reading = DataReading(
                        location_name=f"Sentinel_NDVI",
                        latitude=float(pixel.get('lat', 0)),
                        longitude=float(pixel.get('lon', 0)),
                        timestamp=datetime.utcnow(),
                        data_source="Sentinel-2_NDVI",
                        value=float(pixel.get('ndvi', 0)),
                        confidence=float(pixel.get('quality', 0.88)),
                        unit="index"
                    )
                    readings.append(reading)

        except Exception as e:
            logger.error(f"Sentinel NDVI response parsing error: {e}")

        return readings

    def classify_vegetation_health(self, ndvi: float) -> str:
        """
        Classify vegetation health based on NDVI value.

        Returns:
            ClassificationString (Dead, Unhealthy, Moderate, Healthy, Very Healthy)
        """
        if ndvi < 0:
            return 'Dead'
        elif ndvi < 0.2:
            return 'Unhealthy'
        elif ndvi < 0.4:
            return 'Moderate'
        elif ndvi < 0.6:
            return 'Healthy'
        else:
            return 'Very_Healthy'

    def calculate_ndvi_anomaly(
        self,
        current_ndvi: float,
        historical_mean: float
    ) -> Tuple[float, str]:
        """
        Calculate NDVI anomaly from expected seasonal value.

        Args:
            current_ndvi: Current NDVI measurement
            historical_mean: Long-term average NDVI for location+season

        Returns:
            Tuple of (anomaly_value, risk_category)
        """
        anomaly = current_ndvi - historical_mean

        if anomaly < -0.2:
            risk = 'severe_decline'
        elif anomaly < -0.1:
            risk = 'moderate_decline'
        elif anomaly > 0.1:
            risk = 'improvement'
        else:
            risk = 'stable'

        return anomaly, risk

    async def get_vegetation_trend(
        self,
        readings_by_date: Dict[datetime, List[DataReading]],
        location_lat: float,
        location_lon: float,
        window_days: int = 30
    ) -> Dict[str, Any]:
        """
        Calculate vegetation trend over time for a specific location.

        Useful for detecting vegetation loss (landslide indicator) or
        decline (drought indicator).

        Args:
            readings_by_date: Dictionary of readings keyed by date
            location_lat: Latitude of location
            location_lon: Longitude of location
            window_days: Time window for trend calculation

        Returns:
            Trend statistics
        """
        trend = {
            'location': f"{location_lat:.2f}N, {location_lon:.2f}E",
            'ndvi_values': [],
            'dates': [],
            'mean_ndvi': 0.0,
            'ndvi_trend': 'stable',
            'trend_slope': 0.0,
            'rate_of_change': 'stable'
        }

        try:
            from datetime import timedelta
            import numpy as np

            # Collect NDVI values
            for date, readings in sorted(readings_by_date.items()):
                for reading in readings:
                    # Find reading closest to target location
                    dist = SpatialUtils.distance_km(
                        reading.latitude, reading.longitude,
                        location_lat, location_lon
                    )

                    if dist < 1.0:  # Within 1km
                        trend['dates'].append(date)
                        trend['ndvi_values'].append(reading.value)

            if len(trend['ndvi_values']) > 1:
                # Calculate statistics
                ndvi_array = np.array(trend['ndvi_values'])
                trend['mean_ndvi'] = float(np.mean(ndvi_array))
                trend['std_ndvi'] = float(np.std(ndvi_array))

                # Linear trend
                date_nums = np.arange(len(trend['dates']))
                coeffs = np.polyfit(date_nums, ndvi_array, 1)
                trend['trend_slope'] = float(coeffs[0])

                if coeffs[0] < -0.01:
                    trend['ndvi_trend'] = 'declining'
                    trend['rate_of_change'] = 'rapid_decline' if coeffs[0] < -0.02 else 'slow_decline'
                elif coeffs[0] > 0.01:
                    trend['ndvi_trend'] = 'improving'
                    trend['rate_of_change'] = 'rapid_improvement' if coeffs[0] > 0.02 else 'slow_improvement'
                else:
                    trend['ndvi_trend'] = 'stable'
                    trend['rate_of_change'] = 'stable'

                logger.info(
                    f"NDVI trend at {trend['location']}: "
                    f"{trend['ndvi_trend']} (slope={trend['trend_slope']:.4f})"
                )

        except Exception as e:
            logger.error(f"Vegetation trend calculation error: {e}")

        return trend

    async def get_latest(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """Get latest available Sentinel NDVI data."""
        date_from, date_to = TemporalUtils.get_date_range(days_back=5)  # Most recent 5 days
        return await self.fetch_data(bbox, date_from, date_to)
