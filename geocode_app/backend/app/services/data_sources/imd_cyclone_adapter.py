"""
India Meteorological Department (IMD) Cyclone tracking data adapter.

Provides real-time cyclone/typhoon tracking, prediction, and intensity data
for early warning of flood/storm surge hazards.
"""

import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading
from app.services.data_sources.utils import SpatialUtils, TemporalUtils
from app.config import settings

logger = logging.getLogger(__name__)


class IMD_Cyclone_Adapter(BaseDataAdapter):
    """Adapter for IMD cyclone tracking data."""

    # IMD Data Transfer Station
    IMD_ENDPOINT = "ftp://ftp.imd.gov.in/mausam/nhc/"
    IMD_WEB = "https://mausam.imd.gov.in/mausam_api_v2/"

    # Cyclone categories (Indian classification)
    CYCLONE_CATEGORIES = {
        'I': {'wind_speed_kmh': (62, 88), 'surge_m': (0.4, 0.9)},
        'II': {'wind_speed_kmh': (89, 117), 'surge_m': (1.0, 1.5)},
        'III': {'wind_speed_kmh': (118, 147), 'surge_m': (1.6, 2.0)},
        'IV': {'wind_speed_kmh': (148, 177), 'surge_m': (2.1, 3.0)},
        'V': {'wind_speed_kmh': (178, 999), 'surge_m': (3.0, 999)},
    }

    def __init__(self, credentials: Optional[Dict[str, str]] = None):
        """Initialize IMD Cyclone adapter."""
        super().__init__(credentials)

        if not credentials:
            self.credentials = {
                'ftp_user': settings.IMD_FTP_USER or '',
                'ftp_password': settings.IMD_FTP_PASSWORD or '',
            }

        self.active_cyclones = []

    async def fetch_data(
        self,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime,
        **kwargs
    ) -> List[DataReading]:
        """
        Fetch IMD cyclone data for the region.

        Returns proximity and track data for any active cyclones.

        Args:
            bbox: Bounding box (south_lat, west_lon, north_lat, east_lon)
            date_from: Start date
            date_to: End date (typically current time for tracking)
            **kwargs: Additional parameters

        Returns:
            List of DataReading objects (cyclone proximity data)
        """
        readings = []

        try:
            logger.info("IMD: Fetching cyclone tracking data...")

            # In production, fetch from IMD APIs/FTP
            # https://mausam.imd.gov.in/ has cyclone bulletins

            # For demo, check for active cyclones
            readings = await self._fetch_active_cyclones(bbox, date_to)

            logger.info(f"IMD: Found {len(readings)} cyclone-related readings")

        except Exception as e:
            self._handle_error(e, "fetch_data")

        return readings

    async def _fetch_active_cyclones(
        self,
        bbox: Tuple[float, float, float, float],
        current_time: datetime
    ) -> List[DataReading]:
        """Fetch active cyclone tracks and compute proximity data."""
        readings = []

        try:
            # Simulated active cyclone data
            # In production, this comes from IMD bulletins
            cyclones = [
                {
                    'name': 'Cyclone-Demo',
                    'current_lat': 11.5,
                    'current_lon': 79.0,
                    'category': 'III',
                    'wind_speed': 130,
                    'heading': 320,  # Direction in degrees
                    'speed_kmh': 15,  # Movement speed
                    'track_points': [
                        (10.5, 78.5),
                        (11.0, 78.8),
                        (11.5, 79.0),
                    ],
                    'forecast': [
                        (11.8, 79.2, '24h'),
                        (12.0, 79.5, '48h'),
                    ]
                }
            ]

            south, west, north, east = bbox

            for cyclone in cyclones:
                # Check if cyclone track intersects with bbox
                for track_lat, track_lon in cyclone['track_points']:
                    if south <= track_lat <= north and west <= track_lon <= east:

                        # Create reading for cyclone center location
                        reading = DataReading(
                            location_name=f"Cyclone_{cyclone['name']}_{current_time.strftime('%Y%m%d')}",
                            latitude=cyclone['current_lat'],
                            longitude=cyclone['current_lon'],
                            timestamp=current_time,
                            data_source="IMD_Cyclone",
                            value=cyclone['wind_speed'],  # Wind speed as main value
                            confidence=0.90,
                            unit="km/h",
                            grid_cell_id=f"cyclone_{cyclone['name']}",
                            raw_data={
                                'cyclone_name': cyclone['name'],
                                'category': cyclone['category'],
                                'heading': cyclone['heading'],
                                'movement_speed': cyclone['speed_kmh'],
                                'track': cyclone['track_points'],
                                'forecast': cyclone['forecast']
                            }
                        )
                        readings.append(reading)

                # Compute proximity data for each location in bbox
                # (distance to cyclone center)
                grid_points = SpatialUtils.create_grid(bbox, resolution=1.0)

                for lat, lon in grid_points:
                    distance_km = SpatialUtils.distance_km(
                        lat, lon,
                        cyclone['current_lat'], cyclone['current_lon']
                    )

                    # Only include if within 500km (significant impact zone)
                    if distance_km < 500:
                        reading = DataReading(
                            location_name=f"Grid_{lat:.1f}_{lon:.1f}_CycloneProx",
                            latitude=lat,
                            longitude=lon,
                            timestamp=current_time,
                            data_source="IMD_CycloneProximity",
                            value=distance_km,
                            confidence=0.95,
                            unit="km",
                            grid_cell_id=f"cyc_prox_{lat:.1f}_{lon:.1f}",
                            raw_data={
                                'cyclone_name': cyclone['name'],
                                'cyclone_category': cyclone['category'],
                                'wind_speed_at_cyclone': cyclone['wind_speed'],
                                'estimated_wind_at_location': self._estimate_wind_speed(
                                    cyclone['wind_speed'],
                                    distance_km
                                )
                            }
                        )
                        readings.append(reading)

        except Exception as e:
            logger.error(f"IMD cyclone fetch error: {e}")

        return readings

    @staticmethod
    def _estimate_wind_speed(cyclone_wind: float, distance_km: float) -> float:
        """
        Estimate wind speed at a location based on distance from cyclone center.

        Uses simplified exponential decay model.

        Args:
            cyclone_wind: Wind speed at cyclone center (km/h)
            distance_km: Distance from cyclone center

        Returns:
            Estimated wind speed at location (km/h)
        """
        import math
        # Wind decreases with distance from center
        # Using exponential decay with decay distance of ~200km
        decay_distance = 200.0
        estimated_wind = cyclone_wind * math.exp(-distance_km / decay_distance)
        return max(0, estimated_wind)

    async def validate_data(self, readings: List[DataReading]) -> List[DataReading]:
        """Validate cyclone data."""
        validated = []

        for reading in readings:
            try:
                # Validate coordinates
                if not SpatialUtils.validate_coordinates(reading.latitude, reading.longitude):
                    continue

                # Validate cyclone-specific values
                if reading.data_source == "IMD_Cyclone":
                    # Wind speed should be > 40 km/h for cyclone
                    if reading.value < 40:
                        continue
                elif reading.data_source == "IMD_CycloneProximity":
                    # Distance should be positive
                    if reading.value < 0:
                        continue

                validated.append(reading)

            except Exception as e:
                logger.error(f"IMD validation error: {e}")

        logger.info(f"IMD: Validated {len(validated)}/{len(readings)} cyclone readings")
        return validated

    async def parse_response(self, response: Any) -> List[DataReading]:
        """Parse IMD API response for cyclone data."""
        readings = []

        try:
            if isinstance(response, dict) and 'cyclones' in response:
                for cyclone in response['cyclones']:
                    reading = DataReading(
                        location_name=cyclone.get('name', 'Unknown'),
                        latitude=float(cyclone.get('latitude', 0)),
                        longitude=float(cyclone.get('longitude', 0)),
                        timestamp=datetime.fromisoformat(
                            cyclone.get('timestamp', datetime.utcnow().isoformat())
                        ),
                        data_source="IMD_Cyclone",
                        value=float(cyclone.get('wind_speed', 0)),
                        confidence=0.90,
                        unit="km/h",
                        raw_data={
                            'category': cyclone.get('category'),
                            'track': cyclone.get('track', []),
                            'forecast': cyclone.get('forecast', [])
                        }
                    )
                    readings.append(reading)

        except Exception as e:
            logger.error(f"IMD response parsing error: {e}")

        return readings

    async def get_cyclone_statistics(
        self,
        bbox: Tuple[float, float, float, float],
        readings: List[DataReading]
    ) -> Dict[str, Any]:
        """
        Compute cyclone statistics for warning generation.

        Args:
            bbox: Area of interest
            readings: Cyclone proximity readings

        Returns:
            Statistics for alert generation
        """
        stats = {
            'active_cyclones': 0,
            'max_wind_speed': 0,
            'closest_distance_km': float('inf'),
            'affected_area_percent': 0.0,
            'flood_surge_risk': 'LOW'
        }

        try:
            cyclone_readings = [r for r in readings if 'Cyclone' in r.data_source]

            if not cyclone_readings:
                return stats

            stats['active_cyclones'] = len(set(r.raw_data.get('cyclone_name') for r in cyclone_readings))

            proximity_readings = [r for r in readings if 'Proximity' in r.data_source]

            if proximity_readings:
                distances = [r.value for r in proximity_readings]
                stats['closest_distance_km'] = min(distances)
                stats['affected_area_percent'] = (len(proximity_readings) / max(1, len(readings))) * 100

                # Estimate flood surge risk
                if stats['closest_distance_km'] < 100:
                    stats['flood_surge_risk'] = 'CRITICAL'
                elif stats['closest_distance_km'] < 200:
                    stats['flood_surge_risk'] = 'HIGH'
                elif stats['closest_distance_km'] < 400:
                    stats['flood_surge_risk'] = 'MODERATE'

        except Exception as e:
            logger.error(f"Cyclone statistics error: {e}")

        return stats
