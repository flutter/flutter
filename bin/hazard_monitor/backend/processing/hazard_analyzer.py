"""
Hazard Analyzer
Combines all data sources into a unified hazard risk assessment.
Produces grid-level and location-level hazard scores.
"""

import numpy as np
from datetime import datetime
from typing import Dict, Any, List, Optional
from data_sources.nasa_smap import _terrain_moisture_model, get_moisture_at_location
from data_sources.dem_slope import _elevation_model
from data_sources.gpm_precipitation import _precipitation_model
from data_sources.ndvi_vegetation import _ndvi_model
from data_sources.nisar_insar import _ground_deformation_model
from data_sources.surface_runoff import _surface_runoff_model
from processing.threshold_engine import evaluate_point

INDIA_BBOX = {
    "min_lat": 6.0, "max_lat": 37.0,
    "min_lon": 68.0, "max_lon": 98.0
}


async def get_hazard_grid(
    bbox: Optional[Dict] = None,
    step: float = 0.5
) -> Dict[str, Any]:
    """
    Generate comprehensive hazard assessment grid for India.
    Combines all data sources into unified risk scoring.
    """
    if bbox is None:
        bbox = INDIA_BBOX

    now = datetime.utcnow()
    np.random.seed(int(now.timestamp()) % 100000)

    grid_data = []
    alerts_summary = {"CRITICAL": 0, "HIGH": 0, "MODERATE": 0, "LOW": 0, "SAFE": 0}
    hazard_counts = {"DROUGHT": 0, "FLOOD": 0, "LANDSLIDE": 0}

    lat = bbox["min_lat"]
    while lat <= bbox["max_lat"]:
        lon = bbox["min_lon"]
        while lon <= bbox["max_lon"]:
            # Gather all data
            moisture = _terrain_moisture_model(lat, lon, now)
            terrain = _elevation_model(lat, lon)
            precip = _precipitation_model(lat, lon, now)
            veg = _ndvi_model(lat, lon, now)
            deform = _ground_deformation_model(lat, lon, now)
            runoff = _surface_runoff_model(lat, lon, now)

            # Evaluate thresholds
            assessment = evaluate_point(
                soil_moisture=moisture,
                slope=terrain["slope_deg"],
                precipitation=precip["daily_accumulation_mm"],
                ndvi=veg["ndvi"],
                displacement=deform["displacement_mm"],
                runoff=runoff["surface_runoff_mm"]
            )

            alerts_summary[assessment["overall_risk"]] += 1
            for alert in assessment["alerts"]:
                if alert["type"] in hazard_counts:
                    hazard_counts[alert["type"]] += 1

            grid_data.append({
                "lat": round(lat, 4),
                "lon": round(lon, 4),
                "soil_moisture": round(moisture, 2),
                "elevation": round(terrain["elevation_m"], 1),
                "slope": round(terrain["slope_deg"], 2),
                "precipitation": round(precip["daily_accumulation_mm"], 1),
                "ndvi": round(veg["ndvi"], 3),
                "displacement": round(deform["displacement_mm"], 2),
                "runoff": round(runoff["surface_runoff_mm"], 2),
                "risk_score": assessment["risk_score"],
                "risk_level": assessment["overall_risk"],
                "alerts": [a["type"] for a in assessment["alerts"]],
                "flood_risk": runoff["flood_risk"],
                "landslide_susceptibility": terrain["landslide_susceptibility"],
                "vegetation_health": veg["vegetation_health"]
            })

            lon += step
        lat += step

    total = len(grid_data)

    return {
        "timestamp": now.isoformat(),
        "grid_points": total,
        "resolution_deg": step,
        "bbox": bbox,
        "summary": {
            "risk_distribution": alerts_summary,
            "hazard_types": hazard_counts,
            "critical_pct": round(alerts_summary["CRITICAL"] / total * 100, 1),
            "high_risk_pct": round((alerts_summary["CRITICAL"] + alerts_summary["HIGH"]) / total * 100, 1)
        },
        "grid_data": grid_data
    }


def get_location_assessment(lat: float, lon: float) -> Dict[str, Any]:
    """Get comprehensive hazard assessment for a specific location."""
    now = datetime.utcnow()

    moisture = _terrain_moisture_model(lat, lon, now)
    terrain = _elevation_model(lat, lon)
    precip = _precipitation_model(lat, lon, now)
    veg = _ndvi_model(lat, lon, now)
    deform = _ground_deformation_model(lat, lon, now)
    runoff = _surface_runoff_model(lat, lon, now)

    assessment = evaluate_point(
        soil_moisture=moisture,
        slope=terrain["slope_deg"],
        precipitation=precip["daily_accumulation_mm"],
        ndvi=veg["ndvi"],
        displacement=deform["displacement_mm"],
        runoff=runoff["surface_runoff_mm"]
    )

    return {
        "location": {"lat": lat, "lon": lon},
        "timestamp": now.isoformat(),
        "soil_moisture": {
            "value_pct": round(moisture, 2),
            "depth_cm": 5,
            "source": "SMAP+AMSR2 fusion"
        },
        "terrain": terrain,
        "precipitation": precip,
        "vegetation": veg,
        "ground_deformation": deform,
        "hydrology": runoff,
        "hazard_assessment": assessment
    }
