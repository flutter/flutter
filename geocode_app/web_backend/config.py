"""
Environment configuration and settings management.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Settings:
    """Application settings"""

    # FastAPI Configuration
    API_TITLE = "Tamil Nadu Real-Time Hazard Monitor"
    API_DESCRIPTION = "Real-time disaster early-warning system with live satellite data"
    API_VERSION = "1.0.0"
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"

    # Server Configuration
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))

    # NASA Earthdata Credentials
    NASA_USERNAME = os.getenv("NASA_EARTHDATA_USERNAME", "")
    NASA_PASSWORD = os.getenv("NASA_EARTHDATA_PASSWORD", "")

    # Google Gemini API
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

    # Email Configuration (SMTP)
    SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
    SMTP_EMAIL = os.getenv("SMTP_EMAIL", "ashwanthashwanth2006@gmail.com")
    SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
    ALERT_RECIPIENT = os.getenv("ALERT_RECIPIENT", "ashwanthashwanth2006@gmail.com")

    # API Configuration
    CORS_ORIGINS = ["*"]  # Restrict in production

    # Data Update Intervals (seconds)
    SSE_UPDATE_INTERVAL = int(os.getenv("SSE_UPDATE_INTERVAL", 900))  # 15 minutes
    API_TIMEOUT = int(os.getenv("API_TIMEOUT", 30))  # 30 seconds

    # Tamil Nadu Bounds (for validation)
    TN_LAT_MIN = 8.0
    TN_LAT_MAX = 13.5
    TN_LON_MIN = 76.0
    TN_LON_MAX = 80.5

    # Risk Thresholds
    CRITICAL_RISK_THRESHOLD = 100  # Alert when risk reaches 100


settings = Settings()
