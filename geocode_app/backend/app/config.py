import os
from functools import lru_cache
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application settings and configuration"""

    # API Configuration
    API_TITLE: str = "Real-Time Hazard Monitoring System"
    API_VERSION: str = "1.0.0"
    API_DESCRIPTION: str = "Satellite-based hazard monitoring for Tamil Nadu"
    DEBUG: bool = Field(default=False, env="DEBUG")

    # Database Configuration
    DATABASE_URL: str = Field(default="sqlite:///./hazard_system.db", env="DATABASE_URL")
    SQLITE_DB_PATH: str = Field(default="./data/hazard_system.db", env="SQLITE_DB_PATH")

    # Redis Configuration
    REDIS_URL: str = Field(default="redis://localhost:6379", env="REDIS_URL")
    CACHE_EXPIRE_SECONDS: int = 14400  # 4 hours

    # Email Configuration
    SENDGRID_API_KEY: Optional[str] = Field(default=None, env="SENDGRID_API_KEY")
    EMAIL_FROM: str = Field(default="alerts@hazard-monitor.com", env="EMAIL_FROM")
    ALERT_EMAIL_TO: str = Field(default="ashwanthashwanth2006@gmail.com", env="ALERT_EMAIL_TO")

    # Data Source Credentials
    NASA_EARTHDATA_USERNAME: Optional[str] = Field(default=None, env="NASA_EARTHDATA_USERNAME")
    NASA_EARTHDATA_PASSWORD: Optional[str] = Field(default=None, env="NASA_EARTHDATA_PASSWORD")
    JAXA_FTP_USER: Optional[str] = Field(default=None, env="JAXA_FTP_USER")
    JAXA_FTP_PASSWORD: Optional[str] = Field(default=None, env="JAXA_FTP_PASSWORD")
    ESA_COPERNICUS_USER: Optional[str] = Field(default=None, env="ESA_COPERNICUS_USER")
    ESA_COPERNICUS_PASSWORD: Optional[str] = Field(default=None, env="ESA_COPERNICUS_PASSWORD")
    IMD_FTP_USER: Optional[str] = Field(default=None, env="IMD_FTP_USER")
    IMD_FTP_PASSWORD: Optional[str] = Field(default=None, env="IMD_FTP_PASSWORD")

    # Geographic Configuration
    TAMIL_NADU_BBOX: tuple = (8.0, 76.7, 13.3, 80.4)  # (south_lat, west_lon, north_lat, east_lon)
    MIN_LATITUDE: float = 8.0
    MAX_LATITUDE: float = 13.3
    MIN_LONGITUDE: float = 76.7
    MAX_LONGITUDE: float = 80.4

    # Risk Thresholds
    FLOOD_CRITICAL_THRESHOLD: int = 100  # Risk score >= 100% triggers alert
    LANDSLIDE_CRITICAL_THRESHOLD: int = 100
    DROUGHT_CRITICAL_THRESHOLD: int = 100

    # ML Model Configuration
    ML_MODELS_PATH: str = Field(default="./models", env="ML_MODELS_PATH")
    FLOOD_MODEL_PATH: str = "flood_predictor_v2.1.joblib"
    LANDSLIDE_MODEL_PATH: str = "landslide_detector_v1.0.joblib"
    DROUGHT_MODEL_PATH: str = "drought_classifier_v1.0.h5"

    # Celery Configuration
    CELERY_BROKER_URL: str = Field(default="redis://localhost:6379/0", env="CELERY_BROKER_URL")
    CELERY_RESULT_BACKEND: str = Field(default="redis://localhost:6379/0", env="CELERY_RESULT_BACKEND")
    CELERY_TIMEZONE: str = "UTC"

    # Polling Intervals (seconds)
    GPM_POLL_INTERVAL: int = 1800  # 30 minutes
    CYCLONE_POLL_INTERVAL: int = 21600  # 6 hours
    AMSR2_POLL_INTERVAL: int = 86400  # 1 day
    HAZARD_COMPUTE_INTERVAL: int = 14400  # 4 hours
    ALERT_PROCESS_INTERVAL: int = 900  # 15 minutes
    SMAP_POLL_INTERVAL: int = 259200  # 3 days
    NDVI_POLL_INTERVAL: int = 432000  # 5 days
    INSAR_POLL_INTERVAL: int = 604800  # 7 days

    # Logging
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")
    LOG_FILE: str = Field(default="./logs/app.log", env="LOG_FILE")

    # Sentry Configuration (Error Tracking)
    SENTRY_DSN: Optional[str] = Field(default=None, env="SENTRY_DSN")

    # Data Retention
    DATA_RETENTION_DAYS: int = 30  # Keep 30 days of local cache
    ARCHIVE_DATA: bool = True

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Global settings instance
settings = get_settings()
