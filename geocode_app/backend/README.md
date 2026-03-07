# Real-Time Hazard Monitoring System - Backend

A comprehensive satellite-based early warning system for monitoring soil moisture, precipitation, ground deformation, and vegetation health to detect and alert on floods, landslides, and droughts in Tamil Nadu, India.

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI app initialization
│   ├── config.py                # Configuration and settings
│   ├── dependencies.py          # FastAPI dependencies
│   ├── models/
│   │   ├── __init__.py
│   │   ├── database.py          # SQLAlchemy ORM models
│   │   └── schemas.py           # Pydantic request/response models (TODO)
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── endpoints/       # API route handlers (TODO)
│   │       ├── models.py        # Pydantic schemas (TODO)
│   │       └── router.py        # Route registration (TODO)
│   ├── services/
│   │   ├── __init__.py
│   │   ├── data_sources/        # Satellite data adapters (TODO)
│   │   ├── processing/          # Data processing pipeline (TODO)
│   │   └── utils/               # Helper functions (TODO)
│   └── utils/
│       ├── __init__.py
│       ├── logging.py           # Logging setup (TODO)
│       └── exceptions.py        # Custom exceptions (TODO)
├── tests/
│   ├── __init__.py
│   ├── test_database.py         # Database tests (TODO)
│   ├── test_api.py              # API tests (TODO)
│   └── test_models.py           # Model tests (TODO)
├── migrations/                  # Alembic database migrations (TODO)
├── data/                        # Data directory (SQLite, cache)
├── logs/                        # Application logs
├── models/                      # ML model files
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables
├── .env.example                 # Example environment file
├── docker-compose.yml           # Docker setup (TODO)
├── celery_tasks.py              # Celery task definitions (TODO)
└── README.md                    # This file
```

## Setup Instructions

### Prerequisites

- Python 3.9+
- Redis (for caching and Celery task queue)
- PostgreSQL or SQLite (database)

### Installation

1. **Clone and navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment**
   ```bash
   # Windows
   venv\Scripts\activate

   # Linux/Mac
   source venv/bin/activate
   ```

4. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and configuration
   ```

6. **Initialize database**
   ```bash
   python -c "from app.models.database import init_db; init_db()"
   ```

7. **Run development server**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

   The API will be available at: `http://localhost:8000`
   - API Documentation: `http://localhost:8000/docs`
   - Alternative Docs: `http://localhost:8000/redoc`

## Configuration

### Environment Variables

Critical environment variables in `.env`:

```
# API Settings
DEBUG=True
LOG_LEVEL=INFO

# Database
DATABASE_URL=sqlite:///./data/hazard_system.db

# Redis (required for Celery)
REDIS_URL=redis://localhost:6379

# Email Alerts
SENDGRID_API_KEY=your_key_here
ALERT_EMAIL_TO=ashwanthashwanth2006@gmail.com

# Satellite Data Credentials
NASA_EARTHDATA_USERNAME=your_username
NASA_EARTHDATA_PASSWORD=your_password
JAXA_FTP_USER=your_user
JAXA_FTP_PASSWORD=your_pass
ESA_COPERNICUS_USER=your_user
ESA_COPERNICUS_PASSWORD=your_pass
```

## Database Schema

The system uses SQLAlchemy ORM with the following main tables:

### locations
- Stores cities, towns, villages in Tamil Nadu
- ~1,364+ locations with geographic coordinates
- Indexed for fast search queries

### soil_moisture_readings
- Satellite readings from SMAP, AMSR2 with timestamps
- Includes confidence scores and anomaly detection
- Indexed for time-series queries

### hazard_assessments
- Risk scores for flood, landslide, drought per location
- Stores contributing factors and forecasts
- Tracks alert email sends

### environmental_readings
- Precipitation (GPM), temperature, NDVI, InSAR, cyclone data
- Multi-source environmental data linked to locations

### alerts
- Log of all triggered alerts
- Tracks email sends and user acknowledgments

### ml_model_metadata
- Version tracking for ML models
- Performance metrics and training info

## API Endpoints (Phase 3)

The following endpoints will be implemented:

### Soil Moisture
```
GET /api/v1/soil-moisture/{location}
```

### Hazard Assessment
```
GET /api/v1/hazards/{location}
```

### Search
```
POST /api/v1/search
```

### Maps Data
```
GET /api/v1/maps/{layer}
```

### Safe Routes
```
GET /api/v1/safe-routes
```

## Running Tests

```bash
# Run all tests
pytest

# With coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_database.py -v
```

## Architecture

### Technology Stack

- **Framework**: FastAPI (async, automatic OpenAPI docs)
- **Database**: SQLite (local), PostgreSQL (production)
- **Task Queue**: Celery + Redis (data polling)
- **Geospatial**: rasterio, geopandas, shapely
- **ML**: scikit-learn, XGBoost, TensorFlow
- **Email**: SendGrid
- **Async HTTP**: aiohttp
- **Monitoring**: Sentry (optional)

### Data Flow

1. **Ingest** → Celery polls satellite APIs every 3-12 hours
2. **Process** → Temporal aggregation, spatial interpolation
3. **Analyze** → ML models compute risk scores
4. **Alert** → Email if risk ≥ 100%
5. **Serve** → REST APIs provide data to Flutter app
6. **Display** → App shows real-time hazard maps

## Development Workflow

### Phase 1: Foundation ✅ (Complete)
- ✅ Backend project structure
- ✅ FastAPI initialization
- ✅ SQLite database schema
- ✅ Configuration management
- ✅ Logging setup

### Phase 2: Data Integration (Next)
- TODO: Satellite data adapter interfaces
- TODO: NASA SMAP/GPM adapters
- TODO: JAXA AMSR2 adapter
- TODO: IMD Cyclone adapter
- TODO: Sentinel NDVI adapter
- TODO: InSAR deformation adapter
- TODO: MODIS thermal adapter

### Phase 3: API Endpoints
- TODO: Soil moisture endpoint
- TODO: Hazard assessment endpoint
- TODO: Location search endpoint
- TODO: Maps data endpoint
- TODO: Safe routes endpoint

### Phase 4-9: Additional Phases
- TODO: ML model training
- TODO: Email alerts
- TODO: Celery scheduler
- TODO: Flutter app development
- TODO: Real-time polling
- TODO: Testing and deployment

## Debugging

### Check Database

```python
from app.models.database import SessionLocal, Location
db = SessionLocal()
locations = db.query(Location).limit(5).all()
for loc in locations:
    print(f"{loc.name} ({loc.type}) - {loc.latitude}°N, {loc.longitude}°E")
```

### Check API Logs

```bash
tail -f logs/app.log
```

### Verify Database Schema

```python
from app.models.database import Base, engine
from sqlalchemy import inspect
inspector = inspect(engine)
print(inspector.get_table_names())
```

## Common Issues

### Issue: `ModuleNotFoundError: No module named 'app'`
**Solution**: Ensure you're in the backend directory and run:
```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Issue: Database locked error (SQLite)
**Solution**: Close other connections and ensure single writer:
```bash
rm data/hazard_system.db
python -c "from app.models.database import init_db; init_db()"
```

### Issue: Redis connection error
**Solution**: Start Redis server:
```bash
# Windows
wsl redis-server

# Linux/Mac
redis-server
```

## Production Deployment

For production:

1. Set `DEBUG=False` in `.env`
2. Configure secure `DATABASE_URL` (PostgreSQL recommended)
3. Add `SENTRY_DSN` for error tracking
4. Use gunicorn instead of uvicorn:
   ```bash
   gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000
   ```
5. Set up Celery workers for background tasks
6. Configure SSL/TLS with nginx reverse proxy

## Documentation

- **FastAPI**: https://fastapi.tiangolo.com/
- **SQLAlchemy**: https://docs.sqlalchemy.org/
- **Celery**: https://docs.celeryproject.org/
- **SendGrid**: https://docs.sendgrid.com/

## Contributing

When adding new features:

1. Add database models to `app/models/database.py`
2. Create API endpoints in `app/api/v1/endpoints/`
3. Add services in `app/services/`
4. Write tests in `tests/`
5. Update this README

## License

MIT License - See LICENSE file

## Support

For issues or questions, check:
- API docs at http://localhost:8000/docs
- Logs in `logs/app.log`
- Database schema in `app/models/database.py`
