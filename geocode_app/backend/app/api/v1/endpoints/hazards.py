"""
Hazard Assessment API endpoints.
Compute and return flood, landslide, and drought risk scores for locations.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional, Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.models.database import (
    get_db, Location, SoilMoistureReading, EnvironmentalReading,
    HazardAssessment
)
from app.api.v1.models import (
    HazardAssessmentResponse, HazardDetailResponse, HazardFactor
)
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/hazards", tags=["Hazards"])


class HazardScoringEngine:
    """Computes hazard risk scores from satellite data."""

    @staticmethod
    def compute_flood_risk(
        precipitation: float,
        soil_moisture: float,
        slope: Optional[float] = None,
        cyclone_proximity: Optional[float] = None
    ) -> tuple:
        """
        Compute flood risk score (0-100).

        Factors:
        - Precipitation: 40% weight (heavy rain = flood risk)
        - Soil moisture: 30% weight (saturated soil = poor drainage)
        - Slope: 15% weight (flat areas prone to pooling)
        - Cyclone: 15% weight (storm surge + wind-driven rain)
        """
        score = 0.0

        # Precipitation factor (0-50 mm/hr scale to 0-100)
        precip_factor = min(100, (precipitation / 50) * 100)
        score += precip_factor * 0.40

        # Soil moisture factor (>70% = saturated)
        if soil_moisture > 70:
            moisture_factor = ((soil_moisture - 70) / 30) * 100
        else:
            moisture_factor = 0
        score += moisture_factor * 0.30

        # Slope factor (flat <5° is flood-prone)
        if slope:
            if slope < 5:
                slope_factor = 80
            elif slope < 15:
                slope_factor = 40
            else:
                slope_factor = 10
            score += slope_factor * 0.15

        # Cyclone proximity (< 200km = increased risk)
        if cyclone_proximity and cyclone_proximity < 200:
            cyclone_factor = max(0, 100 - (cyclone_proximity / 2))
            score += cyclone_factor * 0.15

        return min(100, score), {
            'precipitation': precip_factor,
            'soil_moisture': moisture_factor,
            'slope': slope if slope else 0,
            'cyclone_proximity': cyclone_proximity or 999
        }

    @staticmethod
    def compute_landslide_risk(
        slope: Optional[float] = None,
        insar_displacement: Optional[float] = None,
        ndvi_loss: Optional[float] = None,
        rainfall: Optional[float] = None
    ) -> tuple:
        """
        Compute landslide risk score (0-100).

        Factors:
        - Slope: 35% (>30° is high risk)
        - InSAR displacement: 25% (active ground deformation)
        - NDVI loss: 20% (vegetation removal = destabilization)
        - Rainfall: 20% (pore pressure buildup)
        """
        score = 0.0

        # Slope factor
        if slope:
            if slope > 45:
                slope_factor = 95
            elif slope > 30:
                slope_factor = 75
            elif slope > 20:
                slope_factor = 50
            else:
                slope_factor = 20
            score += slope_factor * 0.35
        else:
            score += 20 * 0.35  # Default low slope risk

        # InSAR displacement (>5 cm/year = concern)
        if insar_displacement:
            disp_factor = min(100, (abs(insar_displacement) / 10) * 100)
            score += disp_factor * 0.25

        # NDVI loss (declining vegetation = destabilization)
        if ndvi_loss and ndvi_loss < -0.1:
            ndvi_factor = min(100, (abs(ndvi_loss) / 0.5) * 100)
            score += ndvi_factor * 0.20

        # Rainfall (>20 mm in 24h = pore pressure)
        if rainfall and rainfall > 20:
            rain_factor = min(100, (rainfall / 100) * 100)
            score += rain_factor * 0.20

        return min(100, score), {
            'slope': slope or 0,
            'insar_displacement': insar_displacement or 0,
            'ndvi_loss': ndvi_loss or 0,
            'rainfall': rainfall or 0
        }

    @staticmethod
    def compute_drought_risk(
        soil_moisture: float,
        soil_moisture_normal: float,
        ndvi: Optional[float] = None,
        precipitation_deficit: Optional[float] = None
    ) -> tuple:
        """
        Compute drought risk score (0-100).

        Factors:
        - Soil moisture anomaly: 50% (<20% = critical)
        - NDVI anomaly: 30% (vegetation stress)
        - Precipitation deficit: 20% (cumulative lack of rain)
        """
        score = 0.0

        # Soil moisture anomaly
        moisture_anomaly = soil_moisture - soil_moisture_normal
        if moisture_anomaly < -20:  # Very dry
            moisture_factor = 95
        elif moisture_anomaly < -10:
            moisture_factor = 70
        elif moisture_anomaly < 0:
            moisture_factor = 40
        else:
            moisture_factor = 0
        score += moisture_factor * 0.50

        # NDVI stress indicator (low NDVI = stressed crops)
        if ndvi is not None:
            if ndvi < 0.3:
                ndvi_factor = 80
            elif ndvi < 0.5:
                ndvi_factor = 50
            else:
                ndvi_factor = 0
            score += ndvi_factor * 0.30

        # Precipitation deficit
        if precipitation_deficit and precipitation_deficit > 50:  # mm cumulative
            deficit_factor = min(100, (precipitation_deficit / 200) * 100)
            score += deficit_factor * 0.20

        return min(100, score), {
            'soil_moisture': soil_moisture,
            'soil_moisture_normal': soil_moisture_normal,
            'ndvi': ndvi or 0,
            'precipitation_deficit': precipitation_deficit or 0
        }


@router.get("/{location_name}", response_model=HazardAssessmentResponse)
async def get_hazard_assessment(
    location_name: str,
    db: Session = Depends(get_db)
):
    """
    Get comprehensive hazard assessment (flood, landslide, drought) for a location.

    Combines satellite data to compute risk scores and generates recommendations.
    """
    try:
        # Find location
        location = db.query(Location).filter(
            Location.name.ilike(f"%{location_name}%")
        ).first()

        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

        logger.info(f"Computing hazard assessment for {location.name}")

        # Get latest data from each source
        date_from = datetime.utcnow() - timedelta(days=3)

        # Soil moisture
        soil_moisture_reading = db.query(SoilMoistureReading).filter(
            SoilMoistureReading.location_id == location.id,
            SoilMoistureReading.timestamp >= date_from
        ).order_by(SoilMoistureReading.timestamp.desc()).first()

        soil_moisture = soil_moisture_reading.moisture_percent if soil_moisture_reading else 50
        soil_moisture_normal = soil_moisture_reading.normal_value if soil_moisture_reading else 50

        # Environmental data
        env_readings = db.query(EnvironmentalReading).filter(
            EnvironmentalReading.location_id == location.id,
            EnvironmentalReading.timestamp >= date_from
        ).order_by(EnvironmentalReading.timestamp.desc()).all()

        precipitation = None
        ndvi = None
        insar_displacement = None
        cyclone_proximity = None
        surface_temp = None

        for env in env_readings:
            if env.precipitation_rate_mm_hr and not precipitation:
                precipitation = env.precipitation_rate_mm_hr
            if env.ndvi_value and not ndvi:
                ndvi = env.ndvi_value
            if env.insar_displacement_cm and not insar_displacement:
                insar_displacement = env.insar_displacement_cm
            if env.cyclone_proximity_km and not cyclone_proximity:
                cyclone_proximity = env.cyclone_proximity_km

        # Default values if not available
        precipitation = precipitation or 0
        ndvi = ndvi or 0.5
        insar_displacement = insar_displacement or 0
        cyclone_proximity = cyclone_proximity or 999

        # Compute hazard scores
        engine = HazardScoringEngine()

        flood_score, flood_factors = engine.compute_flood_risk(
            precipitation, soil_moisture, cyclone_proximity=cyclone_proximity
        )

        landslide_score, landslide_factors = engine.compute_landslide_risk(
            insar_displacement=insar_displacement, ndvi_loss=None, rainfall=precipitation
        )

        drought_score, drought_factors = engine.compute_drought_risk(
            soil_moisture, soil_moisture_normal, ndvi
        )

        # Determine alert status
        max_score = max(flood_score, landslide_score, drought_score)
        if max_score >= 75:
            alert_status = 'CRITICAL'
        elif max_score >= 50:
            alert_status = 'WARNING'
        else:
            alert_status = 'NO_ALERT'

        # Generate recommendations
        recommendations = []
        if flood_score > 60:
            recommendations.append("High flood risk: Move to higher ground, avoid water crossings")
        if landslide_score > 60:
            recommendations.append("High landslide risk: Stay away from steep slopes and unstable terrain")
        if drought_score > 60:
            recommendations.append("Drought conditions: Emergency water rationing in effect")

        # Risk level mapping
        def get_risk_level(score):
            if score >= 75:
                return 'CRITICAL'
            elif score >= 50:
                return 'HIGH'
            elif score >= 25:
                return 'MODERATE'
            else:
                return 'LOW'

        # Build response
        response = HazardAssessmentResponse(
            location=location.name,
            latitude=location.latitude,
            longitude=location.longitude,
            timestamp=datetime.utcnow(),
            hazards={
                'flood': HazardDetailResponse(
                    risk_score=flood_score,
                    risk_level=get_risk_level(flood_score),
                    factors=HazardFactor(
                        precipitation=flood_factors.get('precipitation'),
                        soil_moisture=flood_factors.get('soil_moisture'),
                        cyclone_proximity=flood_factors.get('cyclone_proximity')
                    ),
                    confidence=0.85,
                    alert_triggered=flood_score >= 75
                ),
                'landslide': HazardDetailResponse(
                    risk_score=landslide_score,
                    risk_level=get_risk_level(landslide_score),
                    factors=HazardFactor(
                        slope=landslide_factors.get('slope'),
                        insar_deformation=landslide_factors.get('insar_displacement'),
                        rainfall=landslide_factors.get('rainfall')
                    ),
                    confidence=0.80,
                    alert_triggered=landslide_score >= 75
                ),
                'drought': HazardDetailResponse(
                    risk_score=drought_score,
                    risk_level=get_risk_level(drought_score),
                    factors=HazardFactor(
                        soil_moisture=drought_factors.get('soil_moisture'),
                        ndvi_loss=drought_factors.get('ndvi')
                    ),
                    confidence=0.75,
                    alert_triggered=drought_score >= 75
                )
            },
            alert_status=alert_status,
            critical_hazard=None if max_score < 75 else (
                'flood' if flood_score == max_score else
                'landslide' if landslide_score == max_score else 'drought'
            ),
            email_notified=False,
            recommendations=recommendations
        )

        logger.info(f"Hazard assessment computed: Flood={flood_score:.1f}, Landslide={landslide_score:.1f}, Drought={drought_score:.1f}")
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error computing hazard assessment: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error computing hazard assessment")


@router.get("/grid/", response_model=List[dict])
async def get_hazard_grid(
    bbox: str = Query(..., description="Bounding box as south,west,north,east"),
    hazard_type: Literal['flood', 'landslide', 'drought', 'all'] = Query('all'),
    db: Session = Depends(get_db)
):
    """Get latest hazard scores for all grid cells in bbox."""
    try:
        # Parse bbox
        south, west, north, east = map(float, bbox.split(','))

        logger.info(f"Fetching hazard grid for {hazard_type}")

        date_from = datetime.utcnow() - timedelta(hours=12)

        query = db.query(HazardAssessment).join(Location).filter(
            Location.latitude.between(south, north),
            Location.longitude.between(west, east),
            HazardAssessment.assessment_time >= date_from
        )

        if hazard_type != 'all':
            query = query.filter(HazardAssessment.hazard_type == hazard_type)

        hazards = query.all()

        result = [
            {
                'location': h.location.name,
                'latitude': h.location.latitude,
                'longitude': h.location.longitude,
                'hazard_type': h.hazard_type,
                'risk_score': h.risk_score,
                'risk_level': h.risk_level,
                'timestamp': h.assessment_time.isoformat()
            }
            for h in hazards
        ]

        return result

    except Exception as e:
        logger.error(f"Error retrieving hazard grid: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving hazard grid")
