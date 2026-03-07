"""
API router - registers all endpoint modules with FastAPI.
"""

from fastapi import APIRouter
from app.api.v1.endpoints import soil_moisture, hazards, search, maps, safe_routes

# Create main router for v1 API
api_router = APIRouter(prefix="/api/v1", tags=["v1"])

# Include all endpoint routers
api_router.include_router(soil_moisture.router)
api_router.include_router(hazards.router)
api_router.include_router(search.router)
api_router.include_router(maps.router)
api_router.include_router(safe_routes.router)

__all__ = ['api_router']
