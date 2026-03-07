"""
Pydantic models for API request/response validation and serialization.
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any, Literal
from datetime import datetime


# ============== COMMON MODELS ==============

class LocationBase(BaseModel):
    """Base location model"""
    name: str
    type: Literal['city', 'town', 'village', 'district', 'grid_cell']
    district: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    population: Optional[int] = None


class LocationResponse(LocationBase):
    """Location response model"""
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


# ============== SOIL MOISTURE MODELS ==============

class SoilMoistureReadingResponse(BaseModel):
    """Individual soil moisture reading"""
    location_name: str
    latitude: float
    longitude: float
    moisture_percent: float = Field(..., ge=0, le=100)
    data_source: str
    confidence: Optional[float] = None
    timestamp: datetime
    anomaly: Optional[float] = None
    normal_value: Optional[float] = None

    class Config:
        from_attributes = True


class SoilMoistureResponse(BaseModel):
    """Comprehensive soil moisture response for a location"""
    location: str
    latitude: float
    longitude: float
    current_moisture: float
    normal_moisture: Optional[float] = None
    anomaly: Optional[float] = None
    data_sources: List[str]
    confidence: float
    last_update: datetime
    next_update: datetime
    forecast_24h: Optional[float] = None
    forecast_7d: Optional[float] = None
    historical_7days: List[Dict[str, Any]] = Field(default_factory=list)


# ============== HAZARD MODELS ==============

class HazardFactor(BaseModel):
    """Individual hazard contributing factor"""
    precipitation: Optional[float] = None
    soil_moisture: Optional[float] = None
    slope: Optional[float] = None
    cyclone_proximity: Optional[float] = None
    insar_deformation: Optional[float] = None
    ndvi_loss: Optional[float] = None
    rainfall: Optional[float] = None


class HazardDetailResponse(BaseModel):
    """Details for a specific hazard type"""
    risk_score: float = Field(..., ge=0, le=100)
    risk_level: Literal['LOW', 'MODERATE', 'HIGH', 'CRITICAL']
    factors: HazardFactor
    forecast_24h: Optional[float] = None
    forecast_7d: Optional[float] = None
    alert_triggered: bool = False
    confidence: float


class HazardAssessmentResponse(BaseModel):
    """Complete hazard assessment for a location"""
    location: str
    latitude: float
    longitude: float
    timestamp: datetime
    hazards: Dict[Literal['flood', 'landslide', 'drought'], HazardDetailResponse]
    alert_status: Literal['NO_ALERT', 'WARNING', 'CRITICAL']
    critical_hazard: Optional[str] = None
    email_notified: bool = False
    recommendations: List[str] = Field(default_factory=list)


# ============== SEARCH MODELS ==============

class SearchRequest(BaseModel):
    """Location search request"""
    query: str = Field(..., min_length=1, max_length=100)
    type: Optional[List[Literal['city', 'town', 'village', 'district']]] = None
    limit: int = Field(default=10, ge=1, le=100)

    @validator('query')
    def query_must_be_alphanumeric(cls, v):
        if not any(c.isalnum() for c in v):
            raise ValueError('Query must contain at least one alphanumeric character')
        return v


class SearchResult(BaseModel):
    """Single search result"""
    name: str
    type: str
    district: str
    latitude: float
    longitude: float
    population: Optional[int] = None
    match_score: float = Field(..., ge=0, le=1)


class SearchResponse(BaseModel):
    """Search response"""
    query: str
    results: List[SearchResult]
    total: int


# ============== MAPS MODELS ==============

class MapLayerRequest(BaseModel):
    """Request for map layer data"""
    layer: Literal['soil_moisture', 'ndvi', 'thermal', 'hazards', 'insar', 'precipitation']
    bbox: List[float] = Field(..., min_items=4, max_items=4)  # [south, west, north, east]
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None


class MapCell(BaseModel):
    """Single cell in map grid"""
    latitude: float
    longitude: float
    value: float
    confidence: float
    timestamp: datetime


class MapLayerResponse(BaseModel):
    """GeoJSON-like map layer response"""
    layer_name: str
    unit: str
    min_value: float
    max_value: float
    cells: List[MapCell]
    coverage_percent: float
    last_update: datetime


# ============== TRENDS MODELS ==============

class TrendPoint(BaseModel):
    """Point in trend data"""
    timestamp: datetime
    value: float
    confidence: Optional[float] = None


class TrendResponse(BaseModel):
    """Historical trend analysis"""
    location: str
    latitude: float
    longitude: float
    hazard_type: str
    trend_data: List[TrendPoint]
    mean_value: float
    std_dev: float
    trend_direction: Literal['increasing', 'decreasing', 'stable']
    anomalies: List[Dict[str, Any]] = Field(default_factory=list)
    forecast: Optional[List[TrendPoint]] = None


# ============== SAFE ROUTES MODELS ==============

class Waypoint(BaseModel):
    """Navigation waypoint"""
    latitude: float
    longitude: float
    order: int


class AvoidedZone(BaseModel):
    """Hazard zone to avoid"""
    hazard_type: str
    risk_level: str
    bbox: List[float]  # [south, west, north, east]


class RouteOption(BaseModel):
    """Single route option"""
    id: str
    type: Literal['safest', 'fastest', 'balanced']
    distance_km: float
    duration_minutes: int
    hazard_score: float
    waypoints: List[Waypoint]
    avoided_zones: List[AvoidedZone]


class SafeRoutesRequest(BaseModel):
    """Request for safe route calculation"""
    start_lat: float = Field(..., ge=-90, le=90)
    start_lon: float = Field(..., ge=-180, le=180)
    end_lat: float = Field(..., ge=-90, le=90)
    end_lon: float = Field(..., ge=-180, le=180)
    hazard_types: List[Literal['flood', 'landslide', 'drought']] = Field(default=['flood', 'landslide'])
    max_hazard_score: float = Field(default=50, ge=0, le=100)


class SafeRoutesResponse(BaseModel):
    """Safe routes response"""
    start_location: str
    end_location: str
    routes: List[RouteOption]
    generated_at: datetime


# ============== ALERT MODELS ==============

class AlertResponse(BaseModel):
    """Single alert notification"""
    id: str
    location: str
    latitude: float
    longitude: float
    hazard_type: str
    risk_score: float
    alert_level: str
    timestamp: datetime
    message: str
    email_sent: bool
    acknowledged: bool


class AlertsResponse(BaseModel):
    """List of recent alerts"""
    total_alerts: int
    critical_alerts: int
    recent_alerts: List[AlertResponse]


# ============== ERROR MODELS ==============

class ErrorResponse(BaseModel):
    """Error response model"""
    error: str
    detail: str
    code: int
    timestamp: datetime


# ============== HEALTH CHECK MODELS ==============

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    version: str
    debug: bool
    timestamp: datetime
    database: str
    cache: str


class AdapterStatusResponse(BaseModel):
    """Satellite adapter health status"""
    adapter_name: str
    status: Literal['online', 'offline', 'degraded']
    last_fetch: Optional[datetime] = None
    failures: int
    success_rate: float


class SystemStatusResponse(BaseModel):
    """Overall system status"""
    status: Literal['healthy', 'degraded', 'unhealthy']
    timestamp: datetime
    adapters: List[AdapterStatusResponse]
    database_size_mb: float
    cache_status: str
    active_alerts: int
