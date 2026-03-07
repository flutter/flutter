from sqlalchemy import create_engine, Column, String, Float, Integer, DateTime, Boolean, Text, JSON, ForeignKey, Index, UniqueConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import uuid

from app.config import settings

# Database configuration
engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {},
    echo=False,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# ============== LOCATION MODELS ==============

class Location(Base):
    """Stores cities, towns, and villages in Tamil Nadu"""
    __tablename__ = "locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # city, town, village, district
    district = Column(String(100), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    population = Column(Integer, nullable=True)
    geom_tile = Column(String(50), nullable=True, index=True)  # H3 geohash for spatial indexing
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    soil_moisture_readings = relationship("SoilMoistureReading", back_populates="location")
    hazard_assessments = relationship("HazardAssessment", back_populates="location")
    environmental_readings = relationship("EnvironmentalReading", back_populates="location")
    alerts = relationship("Alert", back_populates="location")

    __table_args__ = (
        Index('idx_location_name', 'name'),
        Index('idx_location_geom_tile', 'geom_tile'),
        UniqueConstraint('name', 'district', name='uq_location_name_district'),
    )


# ============== SOIL MOISTURE MODELS ==============

class SoilMoistureReading(Base):
    """Satellite soil moisture measurements"""
    __tablename__ = "soil_moisture_readings"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    location_id = Column(String(36), ForeignKey("locations.id"), nullable=False, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    moisture_percent = Column(Float, nullable=False)  # 0-100%
    data_source = Column(String(50), nullable=False)  # SMAP, AMSR2, etc.
    confidence = Column(Float, nullable=True)  # 0-1 confidence score
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    grid_cell_id = Column(String(50), nullable=True)  # Spatial reference
    normal_value = Column(Float, nullable=True)  # Climatological reference
    anomaly = Column(Float, nullable=True)  # Difference from normal
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    location = relationship("Location", back_populates="soil_moisture_readings")

    __table_args__ = (
        Index('idx_soil_timestamp', 'timestamp'),
        Index('idx_soil_location', 'location_id'),
        UniqueConstraint('location_id', 'timestamp', 'data_source', name='uq_soil_reading'),
    )


# ============== HAZARD ASSESSMENT MODELS ==============

class HazardAssessment(Base):
    """Risk scores and assessments for each location"""
    __tablename__ = "hazard_assessments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    location_id = Column(String(36), ForeignKey("locations.id"), nullable=False, index=True)
    assessment_time = Column(DateTime, nullable=False, index=True)
    hazard_type = Column(String(50), nullable=False)  # flood, landslide, drought
    risk_score = Column(Float, nullable=False)  # 0-100
    risk_level = Column(String(20), nullable=False)  # LOW, MODERATE, HIGH, CRITICAL

    # Flood specific factors
    flood_precipitation = Column(Float, nullable=True)
    flood_soil_moisture = Column(Float, nullable=True)
    flood_cyclone_proximity = Column(Float, nullable=True)
    flood_terrain_slope = Column(Float, nullable=True)

    # Landslide specific factors
    landslide_slope = Column(Float, nullable=True)
    landslide_insar_deformation = Column(Float, nullable=True)
    landslide_ndvi_loss = Column(Float, nullable=True)
    landslide_rainfall = Column(Float, nullable=True)

    # Drought specific factors
    drought_soil_moisture = Column(Float, nullable=True)
    drought_ndvi = Column(Float, nullable=True)
    drought_precipitation_deficit = Column(Float, nullable=True)

    # Forecasts
    forecast_24h = Column(Float, nullable=True)  # 24h ahead prediction
    forecast_7d = Column(Float, nullable=True)   # 7 day ahead prediction
    data_sources = Column(JSON, nullable=True)   # Array of data sources used

    # Alert tracking
    alert_triggered = Column(Boolean, default=False)
    alert_email_sent = Column(Boolean, default=False)
    email_sent_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    location = relationship("Location", back_populates="hazard_assessments")

    __table_args__ = (
        Index('idx_hazard_timestamp', 'assessment_time'),
        Index('idx_hazard_location', 'location_id'),
        Index('idx_hazard_risk_score', 'risk_score'),
        UniqueConstraint('location_id', 'assessment_time', 'hazard_type', name='uq_hazard_assessment'),
    )


# ============== ENVIRONMENTAL DATA MODELS ==============

class EnvironmentalReading(Base):
    """Precipitation, temperature, NDVI, InSAR, cyclone data"""
    __tablename__ = "environmental_readings"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    location_id = Column(String(36), ForeignKey("locations.id"), nullable=False, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)

    # Precipitation (GPM)
    precipitation_mm = Column(Float, nullable=True)
    precipitation_rate_mm_hr = Column(Float, nullable=True)

    # Temperature (Thermal/MODIS)
    surface_temp_c = Column(Float, nullable=True)

    # Vegetation (NDVI)
    ndvi_value = Column(Float, nullable=True)  # -1 to 1

    # Ground Deformation (InSAR)
    insar_displacement_cm = Column(Float, nullable=True)
    insar_line_of_sight = Column(String(20), nullable=True)  # Ascending or Descending

    # Cyclone Data (IMD)
    cyclone_proximity_km = Column(Float, nullable=True)
    cyclone_category = Column(String(10), nullable=True)  # I, II, III, IV, V
    cyclone_track_confidence = Column(Float, nullable=True)
    cyclone_name = Column(String(100), nullable=True)

    # Source tracking
    data_source = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    location = relationship("Location", back_populates="environmental_readings")

    __table_args__ = (
        Index('idx_env_timestamp', 'timestamp'),
        Index('idx_env_location', 'location_id'),
        UniqueConstraint('location_id', 'timestamp', 'data_source', name='uq_env_reading'),
    )


# ============== ALERT MODELS ==============

class Alert(Base):
    """Alert history and tracking"""
    __tablename__ = "alerts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    location_id = Column(String(36), ForeignKey("locations.id"), nullable=False, index=True)
    hazard_type = Column(String(50), nullable=False)
    risk_score = Column(Float, nullable=False)
    alert_timestamp = Column(DateTime, nullable=False, index=True)
    email_sent_to = Column(String(255), nullable=True)
    alert_level = Column(String(20), nullable=True)  # LOW, MODERATE, HIGH, CRITICAL
    message = Column(Text, nullable=True)
    acknowledged = Column(Boolean, default=False)
    acknowledged_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    location = relationship("Location", back_populates="alerts")

    __table_args__ = (
        Index('idx_alert_timestamp', 'alert_timestamp'),
    )


# ============== ML MODEL METADATA ==============

class MLModelMetadata(Base):
    """Track ML model versions and performance"""
    __tablename__ = "ml_model_metadata"

    model_id = Column(String(100), primary_key=True)
    model_type = Column(String(50), nullable=False)  # flood_predictor, landslide_detector, etc.
    model_version = Column(String(20), nullable=False)
    training_date = Column(DateTime, nullable=False)
    accuracy = Column(Float, nullable=True)
    precision = Column(Float, nullable=True)
    recall = Column(Float, nullable=True)
    f1_score = Column(Float, nullable=True)
    training_samples = Column(Integer, nullable=True)
    parameters = Column(JSON, nullable=True)
    status = Column(String(20), default='active')  # active, deprecated, training
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ============== USER PREFERENCES ==============

class UserPreferences(Base):
    """App user settings and preferences"""
    __tablename__ = "user_preferences"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    alert_frequency = Column(String(50), default='realtime')  # realtime, 6h, 12h, daily
    email_address = Column(String(255), nullable=True)
    enabled_hazards = Column(JSON, nullable=True)  # List of monitoring hazards
    favorite_locations = Column(JSON, nullable=True)  # List of saved locations
    map_default_layer = Column(String(50), default='osm')  # OpenStreetMap
    theme_preference = Column(String(20), default='light')  # light or dark
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ============== SYNC LOG ==============

class SyncLog(Base):
    """Track Flutter app sync operations"""
    __tablename__ = "sync_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sync_timestamp = Column(DateTime, nullable=False)
    data_type = Column(String(50), nullable=False)  # soil_moisture, hazards, etc.
    location_id = Column(String(36), nullable=True)
    records_synced = Column(Integer, nullable=True)
    error_message = Column(Text, nullable=True)
    status = Column(String(20), default='success')  # success, failed, partial
    created_at = Column(DateTime, default=datetime.utcnow)


# Create all tables
def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)


# Dependency for FastAPI
def get_db():
    """Get database session for FastAPI dependency injection"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
