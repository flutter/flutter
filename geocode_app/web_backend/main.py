"""
FastAPI application for Tamil Nadu Real-Time Hazard Monitor
Production-grade backend with live satellite APIs, risk scoring, and AI synthesis
"""
import logging
import asyncio
import json
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import AsyncGenerator, Optional, Dict, Any
from datetime import datetime

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles

import google.generativeai as genai

from config import settings
from data_fetchers import DataFetchers, TAMIL_NADU_LOCATIONS
from risk_engine import RiskEngine

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configure Gemini AI
if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "your_gemini_api_key_here":
    genai.configure(api_key=settings.GEMINI_API_KEY)
    MODEL = genai.GenerativeModel('gemini-1.5-flash')
else:
    MODEL = None
    logger.warning("Gemini API key not configured - AI synthesis disabled")

# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    description=settings.API_DESCRIPTION,
    version=settings.API_VERSION
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("CORS middleware configured")


# ============== EMAIL ALERT SERVICE ==============

async def send_critical_alert_email(location: str, hazard_type: str, risk_score: float):
    """
    Send critical alert email when risk reaches 100%.
    Runs asynchronously to avoid blocking the request.
    """
    if not settings.SMTP_PASSWORD or settings.SMTP_PASSWORD == "your_app_password_here":
        logger.warning(f"Email not sent - SMTP credentials not configured")
        return

    try:
        # Check if email credentials are configured
        if not all([settings.SMTP_EMAIL, settings.SMTP_PASSWORD, settings.ALERT_RECIPIENT]):
            logger.warning("Email credentials incomplete")
            return

        subject = f"🚨 CRITICAL HAZARD ALERT - {hazard_type.upper()} - {location}"

        body = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .alert {{ background-color: #ff4444; color: white; padding: 20px; border-radius: 5px; }}
                .details {{ margin-top: 20px; }}
                .metric {{ margin: 10px 0; }}
            </style>
        </head>
        <body>
            <div class="alert">
                <h2>🚨 CRITICAL HAZARD ALERT</h2>
            </div>
            <div class="details">
                <p><strong>Location:</strong> {location}</p>
                <p><strong>Hazard Type:</strong> {hazard_type.upper()}</p>
                <p><strong>Risk Score:</strong> {risk_score:.1f}%</p>
                <p><strong>Alert Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S IST')}</p>
                <p><strong>Action:</strong> Please initiate immediate disaster response procedures.</p>
            </div>
        </body>
        </html>
        """

        # Create email
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = settings.SMTP_EMAIL
        msg["To"] = settings.ALERT_RECIPIENT

        msg.attach(MIMEText(body, "html"))

        # Send email
        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_EMAIL, settings.ALERT_RECIPIENT, msg.as_string())

        logger.info(f"Alert email sent for {hazard_type} at {location}")
    except Exception as e:
        logger.error(f"Failed to send email alert: {e}")


async def synthesize_hazard_analysis(location: str, metrics: Dict[str, Any], hazards: Dict[str, Any]) -> Optional[str]:
    """
    Use Gemini AI to generate a natural language hazard assessment.
    Returns a 1-paragraph professional analysis.
    """
    if not MODEL:
        logger.warning("Gemini not configured - skipping AI synthesis")
        return None

    try:
        # Format metrics for AI
        metrics_text = f"""
        Soil Moisture: {metrics.get('soil_moisture', 0):.1f}%
        Precipitation (24h): {metrics.get('precipitation_24h', 0):.1f}mm
        Elevation: {metrics.get('elevation', 0):.0f}m
        Slope: {metrics.get('slope', 0):.1f}°
        Temperature: {metrics.get('temperature', 0):.1f}°C
        NDVI (Vegetation Health): {metrics.get('ndvi', 0.5):.2f}
        Ground Deformation: {metrics.get('insar_deformation', 0):.1f}mm/year
        """

        hazards_text = f"""
        Flood Risk: {hazards['flood']['score']:.1f}% ({hazards['flood']['level']})
        Landslide Risk: {hazards['landslide']['score']:.1f}% ({hazards['landslide']['level']})
        Drought Risk: {hazards['drought']['score']:.1f}% ({hazards['drought']['level']})
        """

        prompt = f"""You are a disaster response coordinator analyzing real satellite data for {location}, Tamil Nadu.

Real-time satellite metrics:
{metrics_text}

Calculated hazard risks:
{hazards_text}

Generate a concise, professional 1-paragraph assessment explaining the current hazard situation based on these metrics.
Focus on why these metrics are dangerous together and what immediate actions might be needed.
Keep the tone professional but urgent."""

        response = await asyncio.to_thread(lambda: MODEL.generate_content(prompt))
        return response.text if response else None
    except Exception as e:
        logger.error(f"Gemini synthesis error: {e}")
        return None


# ============== HEALTH CHECK ==============

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": settings.API_VERSION,
        "timestamp": datetime.now().isoformat(),
    }


# ============== ROOT ENDPOINT ==============

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "application": settings.API_TITLE,
        "version": settings.API_VERSION,
        "documentation": "/docs",
        "endpoints": {
            "health": "/health",
            "hazards": "/api/hazards?lat=13.0827&lon=80.2707",
            "satellite_metrics": "/api/metrics?lat=13.0827&lon=80.2707",
            "locations": "/api/locations",
            "search": "/api/search?q=Chennai",
            "live_events": "/api/events",
        }
    }


# ============== SATELLITE DATA ENDPOINT ==============

@app.get("/api/metrics")
async def get_satellite_metrics(
    lat: float = Query(..., ge=8.0, le=13.5, description="Latitude within Tamil Nadu"),
    lon: float = Query(..., ge=76.0, le=80.5, description="Longitude within Tamil Nadu")
):
    """
    Fetch real satellite metrics from NASA APIs
    """
    try:
        logger.info(f"Fetching metrics for ({lat}, {lon})")
        metrics = await DataFetchers.fetch_all_metrics(lat, lon)
        return {
            "status": "success",
            "location": {"latitude": lat, "longitude": lon},
            "timestamp": datetime.now().isoformat(),
            "metrics": metrics
        }
    except Exception as e:
        logger.error(f"Metrics fetch error: {e}")
        return {
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }


# ============== HAZARD ASSESSMENT ENDPOINT ==============

@app.get("/api/hazards")
async def get_hazard_assessment(
    lat: float = Query(..., ge=8.0, le=13.5, description="Latitude within Tamil Nadu"),
    lon: float = Query(..., ge=76.0, le=80.5, description="Longitude within Tamil Nadu")
):
    """
    Calculate hazard risks (flood, landslide, drought) for a location.
    Returns risk scores, levels, and AI-generated natural language assessment.
    """
    try:
        # Fetch satellite metrics
        metrics = await DataFetchers.fetch_all_metrics(lat, lon)

        # Calculate hazard risks
        hazards = RiskEngine.calculate_all_hazards(metrics)

        # Synthesize AI analysis
        location_name = "Unknown"
        for loc in TAMIL_NADU_LOCATIONS:
            if abs(loc["lat"] - lat) < 0.05 and abs(loc["lon"] - lon) < 0.05:
                location_name = loc["name"]
                break

        ai_analysis = await synthesize_hazard_analysis(location_name, metrics, hazards)

        # Check for critical alerts
        max_risk = max(h["score"] for h in hazards.values())
        if max_risk >= settings.CRITICAL_RISK_THRESHOLD:
            # Identify the critical hazard
            critical_hazard = max(hazards.keys(), key=lambda k: hazards[k]["score"])
            await send_critical_alert_email(location_name, critical_hazard, hazards[critical_hazard]["score"])

        return {
            "status": "success",
            "location": {"latitude": lat, "longitude": lon, "name": location_name},
            "timestamp": datetime.now().isoformat(),
            "metrics": metrics,
            "hazards": hazards,
            "ai_analysis": ai_analysis,
            "critical_alert": max_risk >= settings.CRITICAL_RISK_THRESHOLD
        }
    except Exception as e:
        logger.error(f"Hazard assessment error: {e}")
        return {
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }


# ============== LOCATION SEARCH ==============

@app.get("/api/locations")
async def get_locations():
    """Get all Tamil Nadu locations"""
    return {
        "status": "success",
        "count": len(TAMIL_NADU_LOCATIONS),
        "locations": TAMIL_NADU_LOCATIONS
    }


@app.get("/api/search")
async def search_locations(q: str = Query(..., min_length=1, description="Search query")):
    """
    Search Tamil Nadu locations by name (similar to Ctrl+K search).
    Returns matching locations with coordinates.
    """
    query_lower = q.lower()
    matches = [
        loc for loc in TAMIL_NADU_LOCATIONS
        if query_lower in loc["name"].lower() or query_lower in loc["district"].lower()
    ]

    return {
        "status": "success",
        "query": q,
        "results": matches,
        "count": len(matches)
    }


# ============== LIVE SSE STREAMING ENDPOINT ==============

async def event_generator(
    lat: Optional[float] = None,
    lon: Optional[float] = None
) -> AsyncGenerator[str, None]:
    """
    Generate server-sent events with live hazard data.
    Continuously fetches and streams updates every SSE_UPDATE_INTERVAL seconds.
    """
    # If location is specified, focus on that location
    if lat and lon:
        locations = [{"name": "Custom Location", "lat": lat, "lon": lon}]
    else:
        # Stream all major Tamil Nadu locations
        locations = TAMIL_NADU_LOCATIONS[:5]  # Top 5 for demo

    iteration = 0
    while True:
        try:
            iteration += 1
            logger.info(f"SSE iteration {iteration}: Fetching hazard data")

            data = {
                "iteration": iteration,
                "timestamp": datetime.now().isoformat(),
                "locations": []
            }

            # Fetch hazard data for each location
            for loc in locations:
                try:
                    metrics = await DataFetchers.fetch_all_metrics(loc["lat"], loc["lon"])
                    hazards = RiskEngine.calculate_all_hazards(metrics)

                    data["locations"].append({
                        "name": loc["name"],
                        "latitude": loc["lat"],
                        "longitude": loc["lon"],
                        "metrics": metrics,
                        "hazards": hazards
                    })
                except Exception as e:
                    logger.error(f"Error fetching data for {loc['name']}: {e}")

            # Yield SSE formatted data
            yield f"data: {json.dumps(data)}\n\n"

            # Wait before next update
            await asyncio.sleep(settings.SSE_UPDATE_INTERVAL)
        except asyncio.CancelledError:
            logger.info("SSE stream cancelled")
            break
        except Exception as e:
            logger.error(f"SSE generator error: {e}")
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
            await asyncio.sleep(settings.SSE_UPDATE_INTERVAL)


@app.get("/api/events")
async def live_events(
    lat: Optional[float] = Query(None, description="Optional latitude for focused monitoring"),
    lon: Optional[float] = Query(None, description="Optional longitude for focused monitoring")
):
    """
    Live Server-Sent Events endpoint for real-time hazard streaming.
    Connect from frontend and receive hazard updates every 15 minutes (configurable).
    """
    return StreamingResponse(
        event_generator(lat, lon),
        media_type="text/event-stream"
    )


# ============== STATIC FILES ==============

# Serve static frontend files (HTML, CSS, JS)
try:
    if os.path.exists("static"):
        app.mount("/static", StaticFiles(directory="static"), name="static")
        logger.info("Static files mounted from ./static")
except:
    logger.warning("Static directory not found - frontend serving disabled")


# ============== STARTUP/SHUTDOWN ==============

@app.on_event("startup")
async def startup_event():
    """Startup event"""
    logger.info("=== Application Startup ===")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"Server: {settings.HOST}:{settings.PORT}")
    logger.info(f"Gemini AI: {'Enabled' if MODEL else 'Disabled'}")
    logger.info(f"Email Alerts: Configured for {settings.ALERT_RECIPIENT}")


@app.on_event("shutdown")
async def shutdown_event():
    """Shutdown event"""
    logger.info("=== Application Shutdown ===")


if __name__ == "__main__":
    import uvicorn
    import os
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )

