import logging
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

from app.config import settings
from app.models.database import init_db, engine, Base

# Create necessary directories first
os.makedirs("./data", exist_ok=True)
os.makedirs("./logs", exist_ok=True)
os.makedirs("./models", exist_ok=True)

# Configure Logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(settings.LOG_FILE) if settings.LOG_FILE else logging.NullHandler()
    ]
)

logger = logging.getLogger(__name__)

# Configure Sentry for error tracking (if DSN provided)
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[
            FastApiIntegration(),
            SqlalchemyIntegration(),
        ],
        traces_sample_rate=0.1,
        environment="production" if not settings.DEBUG else "development"
    )
    logger.info("Sentry initialized for error tracking")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for app startup and shutdown"""
    # Startup
    logger.info("=== Application Startup ===")

    # Initialize database tables
    try:
        init_db()
        logger.info("Database tables initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise

    # Create necessary directories
    os.makedirs("./data", exist_ok=True)
    os.makedirs("./logs", exist_ok=True)
    os.makedirs("./models", exist_ok=True)

    logger.info("Application startup complete")
    yield

    # Shutdown
    logger.info("=== Application Shutdown ===")
    logger.info("Closing database connections")


# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    description=settings.API_DESCRIPTION,
    version=settings.API_VERSION,
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for now (restrict in production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("CORS middleware configured")


# ============== HEALTH CHECK ENDPOINT ==============

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": settings.API_VERSION,
        "debug": settings.DEBUG,
    }


# ============== ROOT ENDPOINT ==============

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "application": settings.API_TITLE,
        "version": settings.API_VERSION,
        "description": settings.API_DESCRIPTION,
        "documentation": "/docs",
        "endpoints": {
            "health": "/health",
            "soil_moisture": "/api/v1/soil-moisture/{location}",
            "hazards": "/api/v1/hazards/{location}",
            "search": "/api/v1/search",
        }
    }


# ============== API ROUTERS ==============

# Import and include API routers
from app.api.v1.router import api_router
app.include_router(api_router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
