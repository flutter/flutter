"""
Hazard Monitoring & Alert System - FastAPI Backend
Main application entry point with all API endpoints.
"""

from fastapi import FastAPI, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
from datetime import datetime

# Add parent to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from data_sources.nasa_smap import fetch_smap_data, get_moisture_at_location
from data_sources.jaxa_amsr2 import fetch_amsr2_data
from data_sources.gpm_precipitation import fetch_gpm_data
from data_sources.nisar_insar import fetch_insar_data
from data_sources.ndvi_vegetation import fetch_ndvi_data
from data_sources.dem_slope import fetch_dem_data
from data_sources.surface_runoff import fetch_runoff_data
from processing.hazard_analyzer import get_hazard_grid, get_location_assessment
from processing.threshold_engine import evaluate_point
from india_data.locations import search_locations, get_all_locations, get_location_by_name

app = FastAPI(
    title="Hazard Monitoring & Alert System",
    description="Real-time soil moisture monitoring and hazard alerting for India using satellite data",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files
static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


# ═══════════════════════════════════════════════════
# HEALTH & INFO
# ═══════════════════════════════════════════════════

@app.get("/api/health")
async def health_check():
    return {
        "status": "ok",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "Hazard Monitor v1.0",
        "data_sources": [
            "NASA_SMAP", "JAXA_AMSR2", "NASA_GPM",
            "NISAR_InSAR", "MODIS_NDVI", "SRTM_DEM", "NASA_GLDAS"
        ]
    }


@app.get("/api/info")
async def system_info():
    return {
        "name": "Hazard Monitoring & Alert System",
        "version": "1.0.0",
        "coverage": "India (6°N-37°N, 68°E-98°E)",
        "data_sources": {
            "soil_moisture": {
                "SMAP": {"band": "L-band 1.41GHz", "resolution_km": 36, "revisit": "2-3 days"},
                "AMSR2": {"bands": ["C-band 6.9GHz", "X-band 10.65GHz", "Ku-band 36.5GHz"], "resolution_km": "12-35"}
            },
            "precipitation": {
                "GPM_IMERG": {"resolution_km": 10, "temporal": "30 min"}
            },
            "ground_deformation": {
                "NISAR": {"bands": ["L-band 1.257GHz", "S-band 3.226GHz"], "resolution_m": "3-10"}
            },
            "vegetation": {
                "MODIS_NDVI": {"resolution_m": 250, "temporal": "16-day composite"}
            },
            "terrain": {
                "SRTM_DEM": {"resolution_m": 30}
            },
            "hydrology": {
                "GLDAS": {"resolution_deg": 0.25, "temporal": "3-hourly"}
            }
        },
        "thresholds": {
            "drought": "soil moisture < 18%",
            "flood": "soil moisture > 38% + high precipitation",
            "landslide": "slope > 25° + moisture > 35% + ground deformation"
        }
    }


# ═══════════════════════════════════════════════════
# DATA SOURCE ENDPOINTS
# ═══════════════════════════════════════════════════

@app.get("/api/soil-moisture")
async def get_soil_moisture(date: str = None):
    """Get SMAP soil moisture data."""
    return await fetch_smap_data(date=date)


@app.get("/api/amsr2")
async def get_amsr2(date: str = None):
    """Get JAXA AMSR2 data."""
    return await fetch_amsr2_data(date=date)


@app.get("/api/precipitation")
async def get_precipitation(date: str = None):
    """Get GPM precipitation data."""
    return await fetch_gpm_data(date=date)


@app.get("/api/insar")
async def get_insar(date: str = None):
    """Get NISAR/InSAR ground deformation data."""
    return await fetch_insar_data(date=date)


@app.get("/api/ndvi")
async def get_ndvi(date: str = None):
    """Get NDVI vegetation index data."""
    return await fetch_ndvi_data(date=date)


@app.get("/api/terrain")
async def get_terrain():
    """Get DEM/slope terrain data."""
    return await fetch_dem_data()


@app.get("/api/runoff")
async def get_runoff(date: str = None):
    """Get surface runoff data."""
    return await fetch_runoff_data(date=date)


# ═══════════════════════════════════════════════════
# HAZARD ASSESSMENT
# ═══════════════════════════════════════════════════

@app.get("/api/hazard-assessment")
async def hazard_assessment():
    """Get comprehensive hazard assessment grid for India."""
    return await get_hazard_grid(step=1.0)  # 1° grid for performance


@app.get("/api/hazard-assessment/detail")
async def hazard_assessment_detail():
    """Get detailed hazard assessment (finer grid)."""
    return await get_hazard_grid(step=0.5)


@app.get("/api/location-assessment")
async def location_assessment(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """Get detailed hazard assessment for a specific location."""
    return get_location_assessment(lat, lon)


# ═══════════════════════════════════════════════════
# SEARCH & LOCATIONS
# ═══════════════════════════════════════════════════

@app.get("/api/search")
async def search(q: str = Query(..., min_length=1, description="Search query")):
    """Search Indian cities, towns, and villages."""
    results = search_locations(q)
    # Add soil moisture data to each result
    enriched = []
    for loc in results:
        moisture = get_moisture_at_location(loc["lat"], loc["lon"])
        enriched.append({**loc, "moisture_data": moisture})
    return {"query": q, "results": enriched, "count": len(enriched)}


@app.get("/api/locations")
async def list_locations(
    type: str = Query(None, description="Filter by type: metro, city, town, village")
):
    """List all Indian locations."""
    locations = get_all_locations()
    if type:
        locations = [l for l in locations if l["type"] == type]
    return {"locations": locations, "count": len(locations)}


@app.get("/api/location/{name}")
async def get_location(name: str):
    """Get details and hazard assessment for a specific location."""
    location = get_location_by_name(name)
    if not location:
        return JSONResponse(status_code=404, content={"error": f"Location '{name}' not found"})

    assessment = get_location_assessment(location["lat"], location["lon"])
    return {**location, "assessment": assessment}


# ═══════════════════════════════════════════════════
# ALERTS
# ═══════════════════════════════════════════════════

@app.get("/api/alerts")
async def get_active_alerts():
    """Get currently active hazard alerts across India."""
    import numpy as np
    from data_sources.nasa_smap import _terrain_moisture_model
    from data_sources.dem_slope import _elevation_model
    from data_sources.gpm_precipitation import _precipitation_model
    from data_sources.ndvi_vegetation import _ndvi_model
    from data_sources.nisar_insar import _ground_deformation_model
    from data_sources.surface_runoff import _surface_runoff_model

    now = datetime.utcnow()
    np.random.seed(int(now.timestamp()) % 100000)

    alerts = []
    # Check key monitoring points
    monitoring_points = [
        ("Joshimath", 30.555, 79.565),
        ("Kedarnath", 30.735, 79.067),
        ("Wayanad", 11.685, 76.132),
        ("Idukki", 9.853, 76.972),
        ("Cherrapunji", 25.270, 91.731),
        ("Mumbai", 19.076, 72.878),
        ("Chennai", 13.083, 80.271),
        ("Kolkata", 22.573, 88.364),
        ("Barmer", 25.753, 71.397),
        ("Jaisalmer", 26.916, 70.908),
        ("Chamoli", 30.403, 79.324),
        ("Uttarkashi", 30.727, 78.435),
        ("Dehradun", 30.317, 78.032),
        ("Guwahati", 26.145, 91.736),
        ("Patna", 25.609, 85.138),
        ("Varanasi", 25.318, 82.974),
        ("Srinagar", 34.084, 74.797),
    ]

    for name, lat, lon in monitoring_points:
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

        if assessment["risk_score"] >= 40:
            for alert in assessment["alerts"]:
                if alert["score"] >= 40:
                    alerts.append({
                        "location": name,
                        "lat": lat,
                        "lon": lon,
                        "type": alert["type"],
                        "severity": alert["severity"],
                        "message": alert["message"],
                        "score": alert["score"],
                        "timestamp": now.isoformat()
                    })

    alerts.sort(key=lambda x: -x["score"])
    return {
        "total_alerts": len(alerts),
        "critical": sum(1 for a in alerts if a["severity"] == "CRITICAL"),
        "severe": sum(1 for a in alerts if a["severity"] == "SEVERE"),
        "moderate": sum(1 for a in alerts if a["severity"] == "MODERATE"),
        "alerts": alerts,
        "timestamp": now.isoformat()
    }


# ═══════════════════════════════════════════════════
# SERVE FRONTEND
# ═══════════════════════════════════════════════════

@app.get("/", response_class=HTMLResponse)
async def serve_frontend():
    """Serve the main frontend page."""
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse(content="<h1>Hazard Monitor - Frontend not found</h1>")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
