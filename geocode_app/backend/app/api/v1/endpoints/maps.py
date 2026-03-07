"""
Maps API endpoints.
Provides GeoJSON heatmap data for visualization layers.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional, Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
import json

from app.models.database import (
    get_db, Location, SoilMoistureReading, EnvironmentalReading, HazardAssessment
)
from app.api.v1.models import MapLayerResponse, MapCell

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/maps", tags=["Maps"])


@router.get("/{layer}", response_model=MapLayerResponse)
async def get_map_layer(
    layer: Literal['soil_moisture', 'ndvi', 'thermal', 'hazards', 'insar', 'precipitation'],
    bbox: str = Query(..., description="south,west,north,east"),
    days_back: int = Query(default=1, ge=1, le=30),
    db: Session = Depends(get_db)
):
    """
    Get map layer data as grid cells for visualization.

    Supports multiple layers:
    - **soil_moisture**: Soil moisture (%))
    - **ndvi**: Vegetation health (index -1 to 1)
    - **thermal**: Land Surface Temperature (°C)
    - **hazards**: Risk scores (0-100)
    - **insar**: Ground deformation (cm/year)
    - **precipitation**: Rainfall rate (mm/hr)

    Returns GeoJSON-compatible cell data for heatmap rendering.
    """
    try:
        # Parse bbox
        south, west, north, east = map(float, bbox.split(','))

        if not (south < north and west < east):
            raise HTTPException(status_code=400, detail="Invalid bbox")

        logger.info(f"Fetching {layer} map data for bbox: {south},{west},{north},{east}")

        date_from = datetime.utcnow() - timedelta(days=days_back)
        cells = []
        min_value = float('inf')
        max_value = float('-inf')

        if layer == 'soil_moisture':
            readings = db.query(SoilMoistureReading).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                SoilMoistureReading.timestamp >= date_from
            ).all()

            # Get latest for each location
            latest_by_loc = {}
            for reading in sorted(readings, key=lambda r: r.timestamp, reverse=True):
                key = f"{reading.latitude:.1f}_{reading.longitude:.1f}"
                if key not in latest_by_loc:
                    latest_by_loc[key] = reading
                    cells.append(MapCell(
                        latitude=reading.latitude,
                        longitude=reading.longitude,
                        value=reading.moisture_percent,
                        confidence=reading.confidence or 0.85,
                        timestamp=reading.timestamp
                    ))
                    min_value = min(min_value, reading.moisture_percent)
                    max_value = max(max_value, reading.moisture_percent)

            unit = "percent"

        elif layer == 'ndvi':
            env_readings = db.query(EnvironmentalReading).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                EnvironmentalReading.ndvi_value.isnot(None),
                EnvironmentalReading.timestamp >= date_from
            ).all()

            latest_by_loc = {}
            for reading in sorted(env_readings, key=lambda r: r.timestamp, reverse=True):
                key = f"{reading.latitude:.2f}_{reading.longitude:.2f}"
                if key not in latest_by_loc:
                    latest_by_loc[key] = reading
                    cells.append(MapCell(
                        latitude=reading.latitude,
                        longitude=reading.longitude,
                        value=reading.ndvi_value,
                        confidence=0.88,
                        timestamp=reading.timestamp
                    ))
                    min_value = min(min_value, reading.ndvi_value)
                    max_value = max(max_value, reading.ndvi_value)

            unit = "index (-1 to 1)"

        elif layer == 'thermal':
            env_readings = db.query(EnvironmentalReading).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                EnvironmentalReading.surface_temp_c.isnot(None),
                EnvironmentalReading.timestamp >= date_from
            ).all()

            latest_by_loc = {}
            for reading in sorted(env_readings, key=lambda r: r.timestamp, reverse=True):
                key = f"{reading.latitude:.2f}_{reading.longitude:.2f}"
                if key not in latest_by_loc:
                    latest_by_loc[key] = reading
                    cells.append(MapCell(
                        latitude=reading.latitude,
                        longitude=reading.longitude,
                        value=reading.surface_temp_c,
                        confidence=0.85,
                        timestamp=reading.timestamp
                    ))
                    min_value = min(min_value, reading.surface_temp_c)
                    max_value = max(max_value, reading.surface_temp_c)

            unit = "celsius"

        elif layer == 'hazards':
            hazards = db.query(HazardAssessment).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                HazardAssessment.assessment_time >= date_from
            ).all()

            # Aggregate max risk per location
            max_by_loc = {}
            for hazard in hazards:
                key = f"{hazard.location.latitude:.1f}_{hazard.location.longitude:.1f}"
                if key not in max_by_loc or hazard.risk_score > max_by_loc[key]['score']:
                    max_by_loc[key] = {
                        'score': hazard.risk_score,
                        'reading': hazard
                    }

            for loc_key, data in max_by_loc.items():
                hazard = data['reading']
                cells.append(MapCell(
                    latitude=hazard.location.latitude,
                    longitude=hazard.location.longitude,
                    value=data['score'],
                    confidence=0.80,
                    timestamp=hazard.assessment_time
                ))
                min_value = min(min_value, data['score'])
                max_value = max(max_value, data['score'])

            unit = "risk score (0-100)"

        elif layer == 'insar':
            env_readings = db.query(EnvironmentalReading).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                EnvironmentalReading.insar_displacement_cm.isnot(None),
                EnvironmentalReading.timestamp >= date_from
            ).all()

            latest_by_loc = {}
            for reading in sorted(env_readings, key=lambda r: r.timestamp, reverse=True):
                key = f"{reading.latitude:.2f}_{reading.longitude:.2f}"
                if key not in latest_by_loc:
                    latest_by_loc[key] = reading
                    cells.append(MapCell(
                        latitude=reading.latitude,
                        longitude=reading.longitude,
                        value=reading.insar_displacement_cm,
                        confidence=0.75,
                        timestamp=reading.timestamp
                    ))
                    min_value = min(min_value, reading.insar_displacement_cm)
                    max_value = max(max_value, reading.insar_displacement_cm)

            unit = "cm/year"

        elif layer == 'precipitation':
            env_readings = db.query(EnvironmentalReading).join(Location).filter(
                Location.latitude.between(south, north),
                Location.longitude.between(west, east),
                EnvironmentalReading.precipitation_rate_mm_hr.isnot(None),
                EnvironmentalReading.timestamp >= date_from
            ).all()

            latest_by_loc = {}
            for reading in sorted(env_readings, key=lambda r: r.timestamp, reverse=True):
                key = f"{reading.latitude:.2f}_{reading.longitude:.2f}"
                if key not in latest_by_loc:
                    latest_by_loc[key] = reading
                    cells.append(MapCell(
                        latitude=reading.latitude,
                        longitude=reading.longitude,
                        value=reading.precipitation_rate_mm_hr,
                        confidence=0.80,
                        timestamp=reading.timestamp
                    ))
                    min_value = min(min_value, reading.precipitation_rate_mm_hr)
                    max_value = max(max_value, reading.precipitation_rate_mm_hr)

            unit = "mm/hr"

        # Handle empty data
        if not cells:
            min_value = 0
            max_value = 100

        logger.info(f"{layer}: {len(cells)} cells, range [{min_value:.2f}, {max_value:.2f}]")

        response = MapLayerResponse(
            layer_name=layer,
            unit=unit,
            min_value=min_value if min_value != float('inf') else 0,
            max_value=max_value if max_value != float('-inf') else 100,
            cells=cells,
            coverage_percent=(len(cells) / max(1, len(cells))) * 100,
            last_update=datetime.utcnow()
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching map layer: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error fetching map layer")


@router.get("/geojson/{layer}")
async def get_map_layer_geojson(
    layer: Literal['soil_moisture', 'ndvi', 'thermal', 'hazards', 'insar', 'precipitation'],
    bbox: str = Query(...),
    db: Session = Depends(get_db)
):
    """
    Get map layer data as GeoJSON FeatureCollection for direct map rendering.

    Compatible with Leaflet, Mapbox, and other GIS libraries.
    """
    try:
        # Get layer data
        map_response = await get_map_layer(layer, bbox, db=db)

        # Convert to GeoJSON
        features = []
        for cell in map_response.cells:
            feature = {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [cell.longitude, cell.latitude]
                },
                "properties": {
                    "value": cell.value,
                    "confidence": cell.confidence,
                    "timestamp": cell.timestamp.isoformat(),
                    "layer": layer
                }
            }
            features.append(feature)

        geojson = {
            "type": "FeatureCollection",
            "name": layer,
            "features": features,
            "properties": {
                "min_value": map_response.min_value,
                "max_value": map_response.max_value,
                "unit": map_response.unit,
                "last_update": map_response.last_update.isoformat()
            }
        }

        return geojson

    except Exception as e:
        logger.error(f"Error generating GeoJSON: {e}")
        raise HTTPException(status_code=500, detail="Error generating GeoJSON")
