"""
Soil Moisture API endpoints.
GET current and historical soil moisture readings by location.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.models.database import (
    get_db, Location, SoilMoistureReading, EnvironmentalReading
)
from app.api.v1.models import SoilMoistureResponse, SoilMoistureReadingResponse
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/soil-moisture", tags=["Soil Moisture"])


@router.get("/{location_name}", response_model=SoilMoistureResponse)
async def get_soil_moisture(
    location_name: str,
    days_back: int = Query(default=7, ge=1, le=30, description="Number of days of history"),
    db: Session = Depends(get_db)
):
    """
    Get current and historical soil moisture for a location.

    Parameters:
    - **location_name**: Name of location to query (e.g., "Madurai")
    - **days_back**: Number of days of historical data (1-30, default 7)

    Returns:
    - Current soil moisture
    - Normal/expected value
    - Anomaly score
    - Data sources used
    - Confidence score
    - 7-day historical trend
    - 24h and 7-day forecasts if available
    """
    try:
        # Find location by name (fuzzy search)
        location = db.query(Location).filter(
            Location.name.ilike(f"%{location_name}%")
        ).first()

        if not location:
            raise HTTPException(
                status_code=404,
                detail=f"Location '{location_name}' not found in Tamil Nadu"
            )

        logger.info(f"Retrieving soil moisture for {location.name} (ID: {location.id})")

        # Get date range
        date_to = datetime.utcnow()
        date_from = date_to - timedelta(days=days_back)

        # Query soil moisture readings
        readings = db.query(SoilMoistureReading).filter(
            SoilMoistureReading.location_id == location.id,
            SoilMoistureReading.timestamp.between(date_from, date_to)
        ).order_by(SoilMoistureReading.timestamp.desc()).all()

        if not readings:
            logger.warning(f"No soil moisture data found for {location.name}")
            raise HTTPException(
                status_code=404,
                detail=f"No soil moisture data available for {location.name}"
            )

        # Get latest reading
        latest_reading = readings[0]

        # Calculate statistics
        all_values = [r.moisture_percent for r in readings]
        current_moisture = latest_reading.moisture_percent
        normal_moisture = latest_reading.normal_value or sum(all_values) / len(all_values)
        anomaly = latest_reading.anomaly or (current_moisture - normal_moisture)

        # Get data sources
        data_sources = list(set(r.data_source for r in readings))

        # Calculate confidence (higher for more sources)
        confidence = min(0.99, 0.7 + len(data_sources) * 0.15)

        # Build historical data
        historical_7days = [
            {
                "timestamp": r.timestamp.isoformat(),
                "moisture": r.moisture_percent,
                "source": r.data_source,
                "confidence": r.confidence
            }
            for r in reversed(readings[:7])  # Last 7 readings
        ]

        # Try to get forecast from most recent readings
        recent_env = db.query(EnvironmentalReading).filter(
            EnvironmentalReading.location_id == location.id,
            EnvironmentalReading.timestamp > datetime.utcnow() - timedelta(hours=6)
        ).order_by(EnvironmentalReading.timestamp.desc()).first()

        forecast_24h = None
        forecast_7d = None
        if recent_env and recent_env.precipitation_rate_mm_hr:
            # Simple forecast: high rainfall should decrease soil moisture
            expected_change = -recent_env.precipitation_rate_mm_hr * 0.1  # Simple model
            forecast_24h = max(0, min(100, current_moisture + expected_change))
            forecast_7d = max(0, min(100, current_moisture + expected_change * 7))

        # Build response
        response = SoilMoistureResponse(
            location=location.name,
            latitude=location.latitude,
            longitude=location.longitude,
            current_moisture=current_moisture,
            normal_moisture=normal_moisture,
            anomaly=anomaly,
            data_sources=data_sources,
            confidence=confidence,
            last_update=latest_reading.timestamp,
            next_update=latest_reading.timestamp + timedelta(hours=12),
            forecast_24h=forecast_24h,
            forecast_7d=forecast_7d,
            historical_7days=historical_7days
        )

        logger.info(f"Soil moisture retrieved: {current_moisture:.1f}% for {location.name}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving soil moisture: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error retrieving soil moisture")


@router.get("/history/{location_name}", response_model=List[SoilMoistureReadingResponse])
async def get_soil_moisture_history(
    location_name: str,
    days_back: int = Query(default=30, ge=1, le=365),
    limit: int = Query(default=100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """
    Get detailed historical soil moisture readings.

    Returns list of individual readings with timestamps, sources, and confidence scores.
    """
    try:
        location = db.query(Location).filter(
            Location.name.ilike(f"%{location_name}%")
        ).first()

        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

        date_from = datetime.utcnow() - timedelta(days=days_back)

        readings = db.query(SoilMoistureReading).filter(
            SoilMoistureReading.location_id == location.id,
            SoilMoistureReading.timestamp >= date_from
        ).order_by(SoilMoistureReading.timestamp.desc()).limit(limit).all()

        return [
            SoilMoistureReadingResponse(
                location_name=location.name,
                latitude=r.latitude,
                longitude=r.longitude,
                moisture_percent=r.moisture_percent,
                data_source=r.data_source,
                confidence=r.confidence,
                timestamp=r.timestamp,
                anomaly=r.anomaly,
                normal_value=r.normal_value
            )
            for r in readings
        ]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving soil moisture history: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving history")


@router.get("/grid/", response_model=List[SoilMoistureReadingResponse])
async def get_soil_moisture_grid(
    bbox: str = Query(..., description="Bounding box as south,west,north,east"),
    db: Session = Depends(get_db)
):
    """
    Get latest soil moisture for all grid cells in bounding box.

    Useful for creating heatmaps.

    Example: bbox=8.0,76.7,13.3,80.4 (Tamil Nadu)
    """
    try:
        # Parse bbox
        try:
            south, west, north, east = map(float, bbox.split(','))
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Invalid bbox format. Use: south,west,north,east"
            )

        # Validate bbox
        if not (south < north and west < east):
            raise HTTPException(status_code=400, detail="Invalid bbox: south must be < north, west must be < east")

        logger.info(f"Fetching soil moisture grid for bbox: {south},{west},{north},{east}")

        # Get latest readings for all locations in bbox
        date_from = datetime.utcnow() - timedelta(days=3)

        readings = db.query(SoilMoistureReading).join(Location).filter(
            Location.latitude.between(south, north),
            Location.longitude.between(west, east),
            SoilMoistureReading.timestamp >= date_from
        ).all()

        # Sort by timestamp and get latest for each location
        latest_by_location = {}
        for reading in sorted(readings, key=lambda r: r.timestamp, reverse=True):
            key = f"{reading.latitude:.1f}_{reading.longitude:.1f}"
            if key not in latest_by_location:
                latest_by_location[key] = reading

        result = [
            SoilMoistureReadingResponse(
                location_name=f"Grid_{r.latitude:.1f}_{r.longitude:.1f}",
                latitude=r.latitude,
                longitude=r.longitude,
                moisture_percent=r.moisture_percent,
                data_source=r.data_source,
                confidence=r.confidence,
                timestamp=r.timestamp,
                anomaly=r.anomaly,
                normal_value=r.normal_value
            )
            for r in latest_by_location.values()
        ]

        logger.info(f"Grid query returned {len(result)} cells")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving soil moisture grid: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving grid data")
