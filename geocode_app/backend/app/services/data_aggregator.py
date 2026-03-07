"""
Data Aggregator Service - Orchestrates data fetching from all satellite sources.

Coordinates with all satellite adapters to:
- Fetch data in parallel from multiple sources
- Validate and normalize data
- Store in database
- Handle failures with fallbacks
- Log and track data ingestion
"""

import logging
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
from sqlalchemy.orm import Session

from app.services.data_sources import (
    NASASensorAdapter,
    JAXA_AMSR2_Adapter,
    IMD_Cyclone_Adapter,
    Sentinel_NDVI_Adapter,
    Sentinel1_InSAR_Adapter,
    MODIS_Thermal_Adapter,
    DataReading
)
from app.models.database import (
    SoilMoistureReading, EnvironmentalReading, Location
)
from app.config import settings

logger = logging.getLogger(__name__)


class DataAggregatorService:
    """
    Central service for aggregating satellite data from all sources.

    Coordinates:
    - Parallel data fetching with circuit breaker for failures
    - Data validation and quality checks
    - Temporal aggregation (averaging over time windows)
    - Storage in local database
    - Fallback mechanisms
    """

    def __init__(self, db: Optional[Session] = None):
        """Initialize aggregator with optional database session."""
        self.db = db
        self.tamil_nadu_bbox = settings.TAMIL_NADU_BBOX

        # Initialize all adapters
        self.adapters = {
            'smap_gpm': NASASensorAdapter(),
            'amsr2': JAXA_AMSR2_Adapter(),
            'cyclone': IMD_Cyclone_Adapter(),
            'ndvi': Sentinel_NDVI_Adapter(),
            'insar': Sentinel1_InSAR_Adapter(),
            'thermal': MODIS_Thermal_Adapter(),
        }

        # Track adapter health for circuit breaker
        self.adapter_failures = {name: 0 for name in self.adapters}
        self.circuit_break_threshold = 3
        self.circuit_broken = {name: False for name in self.adapters}

        logger.info("DataAggregatorService initialized with 6 satellite adapters")

    async def fetch_all_data(
        self,
        bbox: Optional[Tuple[float, float, float, float]] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        include_adapters: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, List[DataReading]]:
        """
        Fetch data from all active satellite sources in parallel.

        Args:
            bbox: Bounding box (defaults to Tamil Nadu)
            date_from: Start date
            date_to: End date
            include_adapters: List of adapter names to use (all if None)
            **kwargs: Additional parameters

        Returns:
            Dictionary keyed by adapter name with lists of DataReading objects
        """
        if bbox is None:
            bbox = self.tamil_nadu_bbox
        if date_from is None:
            date_from = datetime.utcnow() - timedelta(days=3)
        if date_to is None:
            date_to = datetime.utcnow()

        if include_adapters is None:
            include_adapters = list(self.adapters.keys())

        logger.info(
            f"Starting parallel data fetch from {len(include_adapters)} adapters: "
            f"{include_adapters}, bbox={bbox}, {date_from} to {date_to}"
        )

        # Create tasks for parallel execution
        tasks = []
        for adapter_name in include_adapters:
            if adapter_name in self.adapters and not self.circuit_broken[adapter_name]:
                task = asyncio.create_task(
                    self._fetch_from_adapter(adapter_name, bbox, date_from, date_to)
                )
                tasks.append(task)

        # Execute all tasks concurrently
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Parse results
        aggregated_data = {}
        for adapter_name, result in zip(include_adapters, results):
            if isinstance(result, Exception):
                logger.error(f"{adapter_name} fetch error: {result}")
                self.adapter_failures[adapter_name] += 1
                if self.adapter_failures[adapter_name] >= self.circuit_break_threshold:
                    self.circuit_broken[adapter_name] = True
                    logger.warning(f"Circuit breaker activated for {adapter_name}")
                aggregated_data[adapter_name] = []
            else:
                aggregated_data[adapter_name] = result
                self.adapter_failures[adapter_name] = 0  # Reset on success

        # Log summary
        total_readings = sum(len(readings) for readings in aggregated_data.values())
        logger.info(f"Data fetch complete: {total_readings} total readings aggregated")

        return aggregated_data

    async def _fetch_from_adapter(
        self,
        adapter_name: str,
        bbox: Tuple[float, float, float, float],
        date_from: datetime,
        date_to: datetime
    ) -> List[DataReading]:
        """Fetch data from single adapter with error handling."""
        try:
            adapter = self.adapters[adapter_name]
            logger.debug(f"{adapter_name}: Starting fetch...")

            data = await adapter.get_data(bbox, date_from, date_to)

            logger.info(f"{adapter_name}: Fetched {len(data)} readings")
            return data

        except Exception as e:
            logger.error(f"{adapter_name} fetch failed: {e}", exc_info=True)
            raise

    async def aggregate_soil_moisture(
        self,
        readings_by_source: Dict[str, List[DataReading]]
    ) -> Dict[str, Any]:
        """
        Aggregate soil moisture from SMAP and AMSR2 sources.

        Creates ensemble estimate by combining both sources.

        Args:
            readings_by_source: Dictionary with 'smap_gpm' and 'amsr2' keys

        Returns:
            Aggregated soil moisture readings with confidence scores
        """
        aggregated = {}

        try:
            smap_readings = readings_by_source.get('smap_gpm', [])
            amsr2_readings = readings_by_source.get('amsr2', [])

            logger.info(f"Aggregating soil moisture: {len(smap_readings)} SMAP + {len(amsr2_readings)} AMSR2")

            # Build spatial index for matching
            smap_index = {
                f"{round(r.latitude, 1)}_{round(r.longitude, 1)}": r
                for r in smap_readings
            }

            for amsr2_reading in amsr2_readings:
                key = f"{round(amsr2_reading.latitude, 1)}_{round(amsr2_reading.longitude, 1)}"

                if key in smap_index:
                    smap_reading = smap_index[key]

                    # Ensemble average
                    avg_moisture = (smap_reading.value + amsr2_reading.value) / 2
                    avg_confidence = (smap_reading.confidence or 0 + amsr2_reading.confidence or 0) / 2

                    aggregated[key] = {
                        'latitude': smap_reading.latitude,
                        'longitude': smap_reading.longitude,
                        'soil_moisture': avg_moisture,
                        'confidence': avg_confidence,
                        'sources': ['SMAP', 'AMSR2'],
                        'timestamp': max(smap_reading.timestamp, amsr2_reading.timestamp)
                    }

            logger.info(f"Soil moisture aggregation complete: {len(aggregated)} ensemble points")

        except Exception as e:
            logger.error(f"Soil moisture aggregation error: {e}")

        return aggregated

    async def store_readings_to_db(
        self,
        db: Session,
        readings: List[DataReading]
    ) -> int:
        """
        Store data readings to SQLite database.

        Args:
            db: Database session
            readings: List of DataReading objects to store

        Returns:
            Number of readings successfully stored
        """
        stored_count = 0

        try:
            for reading in readings:
                try:
                    if reading.data_source.startswith('SMAP') or reading.data_source == 'AMSR2':
                        # Store as soil moisture reading
                        db_reading = SoilMoistureReading(
                            location_id=await self._get_or_create_location(
                                db, reading.latitude, reading.longitude
                            ),
                            timestamp=reading.timestamp,
                            moisture_percent=reading.value,
                            data_source=reading.data_source,
                            confidence=reading.confidence,
                            latitude=reading.latitude,
                            longitude=reading.longitude,
                            grid_cell_id=reading.grid_cell_id,
                        )
                        db.add(db_reading)

                    else:
                        # Store as environmental reading (precipitation, NDVI, InSAR, etc.)
                        env_data = {
                            'location_id': await self._get_or_create_location(
                                db, reading.latitude, reading.longitude
                            ),
                            'timestamp': reading.timestamp,
                            'data_source': reading.data_source,
                            'latitude': reading.latitude,
                            'longitude': reading.longitude,
                        }

                        # Map value to appropriate column based on data source
                        if 'GPM' in reading.data_source:
                            env_data['precipitation_rate_mm_hr'] = reading.value
                        elif 'NDVI' in reading.data_source:
                            env_data['ndvi_value'] = reading.value
                        elif 'InSAR' in reading.data_source:
                            env_data['insar_displacement_cm'] = reading.value
                        elif 'LST' in reading.data_source or 'Thermal' in reading.data_source:
                            env_data['surface_temp_c'] = reading.value
                        elif 'Cyclone' in reading.data_source or 'Proximity' in reading.data_source:
                            env_data['cyclone_proximity_km'] = reading.value

                        db_reading = EnvironmentalReading(**env_data)
                        db.add(db_reading)

                    stored_count += 1

                except Exception as e:
                    logger.warning(f"Error storing reading for {reading.latitude}, {reading.longitude}: {e}")

            # Commit all changes
            db.commit()
            logger.info(f"Stored {stored_count}/{len(readings)} readings to database")

        except Exception as e:
            logger.error(f"Database commit error: {e}")
            db.rollback()

        return stored_count

    async def _get_or_create_location(
        self,
        db: Session,
        latitude: float,
        longitude: float
    ) -> str:
        """
        Get or create location record for coordinates.

        Args:
            db: Database session
            latitude: Latitude
            longitude: Longitude

        Returns:
            Location ID
        """
        try:
            # Try to find nearby location in database
            existing = db.query(Location).filter(
                Location.latitude.between(latitude - 0.1, latitude + 0.1),
                Location.longitude.between(longitude - 0.1, longitude + 0.1)
            ).first()

            if existing:
                return existing.id

            # Create new grid location
            new_location = Location(
                name=f"Grid_{latitude:.2f}_{longitude:.2f}",
                type='grid_cell',
                district='Tamil Nadu',
                latitude=latitude,
                longitude=longitude,
                population=0
            )
            db.add(new_location)
            db.commit()

            return new_location.id

        except Exception as e:
            logger.error(f"Location creation error: {e}")
            return None

    def get_aggregator_status(self) -> Dict[str, Any]:
        """Get health status of all adapters."""
        return {
            'timestamp': datetime.utcnow().isoformat(),
            'adapters': {
                name: {
                    'failures': self.adapter_failures[name],
                    'circuit_broken': self.circuit_broken[name],
                    'status': 'offline' if self.circuit_broken[name] else 'online'
                }
                for name in self.adapters
            },
            'circuit_break_threshold': self.circuit_break_threshold
        }

    def reset_circuit_breaker(self, adapter_name: Optional[str] = None) -> None:
        """Reset circuit breaker for adapter(s)."""
        if adapter_name:
            self.circuit_broken[adapter_name] = False
            self.adapter_failures[adapter_name] = 0
            logger.info(f"Circuit breaker reset for {adapter_name}")
        else:
            for name in self.adapters:
                self.circuit_broken[name] = False
                self.adapter_failures[name] = 0
            logger.info("All circuit breakers reset")


# Singleton instance
_aggregator_instance: Optional[DataAggregatorService] = None


def get_aggregator(db: Optional[Session] = None) -> DataAggregatorService:
    """Get or create aggregator singleton."""
    global _aggregator_instance
    if _aggregator_instance is None:
        _aggregator_instance = DataAggregatorService(db)
    return _aggregator_instance
