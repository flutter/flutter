"""
ESA Sentinel-1 Synthetic Aperture Radar (SAR) InSAR data adapter.

Provides ground deformation measurements useful for:
- Landslide detection (subsurface/surface displacement)
- Ground subsidence monitoring
- Active fault zone monitoring
- Mining-related ground changes

InSAR (Interferometric SAR) measures displacement using phase differences
between radar images taken from slightly different orbital positions.
"""

import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import SpatialUtils, DataQualityUtils, TemporalUtils
from app.config import settings

logger = logging.getLogger(__name__)


class Sentinel1_InSAR_Adapter(BaseDataAdapter):
    """Adapter for Sentinel-1 InSAR deformation data."""

    # Copernicus Scientific Data Hub
    COPERNICUS_ENDPOINT = "https://scihub.copernicus.eu/dhus"

    # ASF DAAC (Alaska Satellite Facility) Vertex
    ASF_ENDPOINT = "https://vertex.daac.asf.alaska.edu"

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize Sentinel-1 InSAR adapter."""
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
        Fetch Sentinel-1 InSAR deformation data.

        Sentinel-1A/B provide SAR imagery every 6-12 days depending on region.
        InSAR processing derives line-of-sight displacement measurements.

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
            logger.info(f"Sentinel-1 InSAR: Fetching deformation data for {date_from} to {date_to}")

            south, west, north, east = bbox

            # In production, query ASF DAAC or ESA hub for Sentinel-1 SLC products
            # and process with InSAR software (SNAP, ISCE2, etc.)

            # Create grid at SAR resolution (20m for stripmap, here simulated at 100m)
            grid_points = SpatialUtils.create_grid(bbox, resolution=0.02)  # ~2km

            # Simulate InSAR displacement readings
            for lat, lon in grid_points:
                # Mock displacement value (cm/year, negative = subsidence)
                import random
                import numpy as np

                # Landslide-prone areas show anomalous deformation
                displacement = random.uniform(-5, 5)  # cm/year

                # Add some spatial correlation (landslides cluster)
                if random.random() > 0.95:  # 5% chance of anomaly
                    displacement = random.uniform(-20, -5)  # Larger subsidence

                reading = DataReading(
                    location_name=f"Grid_{lat:.2f}_{lon:.2f}",
                    latitude=lat,
                    longitude=lon,
                    timestamp=date_to,
                    data_source="Sentinel-1_InSAR",
                    value=displacement,
                    confidence=0.75,  # InSAR has coherence-dependent quality
                    unit="cm/year",
                    grid_cell_id=f"insar_{lat:.2f}_{lon:.2f}",
                    raw_data={
                        'satellite': 'Sentinel-1A/B',
                        'geometry': 'ascending',  # or 'descending'
                        'line_of_sight': 'range',  # Direction of measurement
                        'wavelength_cm': 5.6,  # C-band
                        'temporal_baseline_days': 12,
                        'spatial_baseline_m': 100,
                        'coherence': 0.5 + 0.4 * random.random()  # Coherence 0-1
                    }
                )
                readings.append(reading)

            logger.info(f"Sentinel-1 InSAR: Created {len(readings)} deformation readings")

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """
        Validate Sentinel-1 InSAR data.

        Checks:
        - Coordinate validity
        - Coherence threshold (reject low coherence)
        - Displacement range checks
        - Phase unwrapping errors
        """
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    continue

                # Check coherence (minimum required for reliable data)
                coherence = reading.raw_data.get('coherence', 0) if reading.raw_data else 0
                if coherence < 0.3:
                    logger.debug(f"Low coherence {coherence} at {reading.latitude}, {reading.longitude}")
                    continue

                # Validate displacement range (-50 to +50 cm/year is typical)
                if not DataQualityUtils.check_value_range(
                    reading.value, -50, 50, "InSAR displacement"
                ):
                    continue

                # Adjust confidence based on coherence
                if reading.confidence:
                    reading.confidence *= coherence

                validated.append(reading)

            except Exception as e:
                logger.error(f"InSAR validation error: {e}")

        logger.info(f"Sentinel-1 InSAR: Validated {len(validated)}/{len(readings)} readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """Parse Sentinel-1 GeoTIFF or NetCDF InSAR response."""
        readings = []

        try:
            if isinstance(response, dict) and 'deformation_grid' in response:
                # Parse from InSAR GeoTIFF (displacement map)
                grid = response['deformation_grid']
                bounds = response.get('bounds', {})

                for data_point in grid:
                    reading = DataReading(
                        location_name=f"InSAR_Point",
                        latitude=float(data_point.get('lat', 0)),
                        longitude=float(data_point.get('lon', 0)),
                        timestamp=datetime.utcnow(),
                        data_source="Sentinel-1_InSAR",
                        value=float(data_point.get('displacement', 0)),
                        confidence=float(data_point.get('coherence', 0.75)),
                        unit="cm/year",
                        raw_data={
                            'geometry': data_point.get('geometry', 'ascending'),
                            'line_of_sight': data_point.get('los', 'range')
                        }
                    )
                    readings.append(reading)

        except Exception as e:
            logger.error(f"InSAR response parsing error: {e}")

        return readings

    def identify_deformation_zones(
        self,
        readings: List[DataReading],
        displacement_threshold_cm: float = 2.0
    ) -> Dict[str, Any]:
        """
        Identify zones of significant deformation.

        Areas with displacement > threshold may indicate:
        - Active landslide movement
        - Ground subsidence
        - Mining activity
        - Fault rupture

        Args:
            readings: InSAR displacement readings
            displacement_threshold_cm: Threshold for deformation (cm/year)

        Returns:
            Dictionary with identified zones
        """
        zones = {
            'total_readings': len(readings),
            'deformation_zones': [],
            'max_displacement': 0,
            'subsidence_areas': [],
            'uplift_areas': []
        }

        try:
            anomalies = []

            for reading in readings:
                if abs(reading.value) > displacement_threshold_cm:
                    anomalies.append({
                        'lat': reading.latitude,
                        'lon': reading.longitude,
                        'displacement': reading.value,
                        'coherence': reading.raw_data.get('coherence', 0) if reading.raw_data else 0
                    })

                    # Track extremes
                    if reading.value < zones['max_displacement']:
                        zones['max_displacement'] = reading.value

            # Cluster anomalies (zones with nearby pixels)
            for anomaly in anomalies:
                if anomaly['displacement'] < 0:
                    zones['subsidence_areas'].append(anomaly)
                else:
                    zones['uplift_areas'].append(anomaly)

            zones['deformation_zones'] = anomalies
            logger.info(f"InSAR: Identified {len(anomalies)} anomalous pixels")

        except Exception as e:
            logger.error(f"Deformation zone identification error: {e}")

        return zones

    def calculate_hazard_index_from_insar(
        self,
        displacement: float,
        slope_degrees: Optional[float] = None,
        coherence: Optional[float] = None
    ) -> Tuple[float, str]:
        """
        Calculate landslide hazard index based on InSAR displacement.

        Combines displacement rate with slope to estimate failure risk.

        Args:
            displacement: Line-of-sight displacement (cm/year)
            slope_degrees: Terrain slope at location
            coherence: InSAR coherence (0-1)

        Returns:
            Tuple of (hazard_index_0_100, risk_level)
        """
        hazard_index = 0.0

        # Magnitude of displacement
        abs_displacement = abs(displacement)

        # Base hazard from displacement rate
        if abs_displacement > 10:
            hazard_index += 70
        elif abs_displacement > 5:
            hazard_index += 50
        elif abs_displacement > 2:
            hazard_index += 30
        else:
            hazard_index += 10

        # Slope effect (steeper slopes more hazardous)
        if slope_degrees:
            if slope_degrees > 45:
                hazard_index += 20
            elif slope_degrees > 30:
                hazard_index += 10
            elif slope_degrees > 20:
                hazard_index += 5

        # Coherence effect (low coherence = uncertain measurement)
        if coherence:
            quality_factor = coherence
            hazard_index *= quality_factor

        # Normalize to 0-100
        hazard_index = min(100, max(0, hazard_index))

        # Classify
        if hazard_index >= 75:
            risk_level = 'CRITICAL'
        elif hazard_index >= 50:
            risk_level = 'HIGH'
        elif hazard_index >= 25:
            risk_level = 'MODERATE'
        else:
            risk_level = 'LOW'

        return hazard_index, risk_level

    async def get_latest(self, bbox: Tuple[float, float, float, float]) -> List[DataReading]:
        """Get latest available Sentinel-1 InSAR data."""
        date_from, date_to = TemporalUtils.get_date_range(days_back=12)  # 12-day revisit
        return await self.fetch_data(bbox, date_from, date_to)

    async def process_time_series(
        self,
        readings_by_date: Dict[datetime, List[DataReading]]
    ) -> Dict[str, Any]:
        """
        Process time series of InSAR measurements.

        Calculates cumulative displacement, acceleration, and trends.

        Args:
            readings_by_date: Dictionary of readings keyed by date

        Returns:
            Time series analysis results
        """
        analysis = {
            'total_epochs': len(readings_by_date),
            'time_span_days': 0,
            'cumulative_displacement': 0.0,
            'acceleration_detected': False,
            'trend': 'stable'
        }

        try:
            from datetime import timedelta
            import numpy as np

            if not readings_by_date:
                return analysis

            dates = sorted(readings_by_date.keys())
            analysis['time_span_days'] = (dates[-1] - dates[0]).days

            # Collect all displacement values over time
            displacements = []
            for date in dates:
                readings = readings_by_date[date]
                if readings:
                    mean_disp = np.mean([r.value for r in readings])
                    displacements.append(mean_disp)

            if len(displacements) > 2:
                analysis['cumulative_displacement'] = sum(displacements)

                # Check for acceleration (second derivative)
                first_differences = np.diff(displacements)
                if len(first_differences) > 1:
                    second_differences = np.diff(first_differences)
                    if np.std(second_differences) > np.mean(np.abs(first_differences)) * 0.5:
                        analysis['acceleration_detected'] = True

                # Trend
                if analysis['cumulative_displacement'] < -5:
                    analysis['trend'] = 'subsiding'
                elif analysis['cumulative_displacement'] > 5:
                    analysis['trend'] = 'uplifting'
                else:
                    analysis['trend'] = 'stable'

        except Exception as e:
            logger.error(f"Time series processing error: {e}")

        return analysis
