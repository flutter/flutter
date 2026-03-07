# Tamil Nadu Real-Time Hazard Monitor - Web Backend

A production-grade web application for real-time disaster early-warning in Tamil Nadu with live satellite API integrations, AI-powered hazard synthesis, and interactive web interface.

## 🎯 Features

### Real-Time Data Integration
- **NASA SMAP**: Live soil moisture from satellites (%)
- **NASA GPM IMERG**: Real-time precipitation (mm/day)
- **ASF HyP3/Sentinel-1**: Ground deformation & subsidence (mm/year)
- **Open-Meteo**: Elevation, temperature, vegetation health (NDVI)
- **Parallel Async Fetching**: All APIs called simultaneously with `asyncio.gather()`

### Hazard Risk Scoring
- **Flood Risk**: Based on precipitation, soil moisture, elevation, slope
- **Landslide Risk**: Based on slope, saturation, ground deformation
- **Drought Risk**: Based on soil moisture deficit, vegetation health, temperature
- **Deterministic Algorithms**: No ML models - transparent, interpretable scoring

### Advanced Features
- **🤖 Gemini AI Synthesis**: Automatic natural language hazard assessments
- **📧 Critical Email Alerts**: Instant notifications when risk reaches 100%
- **📡 Live SSE Streaming**: Real-time hazard updates to frontend
- **🗺️ Interactive Leaflet Map**: Click-based location details
- **🔍 Ctrl+K Search**: Instant location lookup across all Tamil Nadu towns
- **📍 GPS Tracking**: Real-time user location monitoring
- **🛣️ Evacuation Routes**: Identify and navigate to safe zones
- **📊 Multi-Layer Visualization**: Toggle satellite data overlays

## 📋 Project Structure

```
web_backend/
├── main.py              # FastAPI app, routes, SSE, email alerts
├── config.py            # Configuration & environment variables
├── data_fetchers.py     # Async NASA API integrations
├── risk_engine.py       # Hazard scoring algorithms
├── requirements.txt     # Python dependencies
├── .env                 # Credentials (keep secret!)
├── start.sh             # Startup script
└── static/
    └── index.html       # React-free web frontend (vanilla JS + Leaflet)
```

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- NASA Earthdata account (free at https://earthdata.nasa.gov/)
- Google Gemini API key (free at https://makersuite.google.com/app/apikey)
- Gmail account with App Password for alerts

### Setup

1. **Clone and navigate:**
```bash
cd web_backend
```

2. **Configure credentials in `.env`:**
```bash
# NASA Earthdata (you have these already)
NASA_EARTHDATA_USERNAME=ashwanth_25
NASA_EARTHDATA_PASSWORD=Ashwanthkumar2006%

# Google Gemini AI (get free key from https://makersuite.google.com/app/apikey)
GEMINI_API_KEY=your_api_key_here

# Gmail SMTP (use App Password if 2FA enabled)
SMTP_EMAIL=ashwanthashwanth2006@gmail.com
SMTP_PASSWORD=your_16_char_app_password
ALERT_RECIPIENT=ashwanthashwanth2006@gmail.com
```

3. **Run startup script:**
```bash
chmod +x start.sh
./start.sh
```

Or manually:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

4. **Access:**
- **Frontend**: http://localhost:8000/static/index.html
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## 📡 API Endpoints

### Get Satellite Metrics
```
GET /api/metrics?lat=13.0827&lon=80.2707
```
Returns raw satellite data from all sources.

### Get Hazard Assessment
```
GET /api/hazards?lat=13.0827&lon=80.2707
```
Returns hazard risk scores + factors + AI analysis.

### Live Streaming (SSE)
```
GET /api/events
```
Real-time hazard updates via Server-Sent Events. Connect from frontend to receive continuous updates.

### Location Search
```
GET /api/search?q=Chennai
```
Fuzzy search across all Tamil Nadu towns, cities, districts.

### Get All Locations
```
GET /api/locations
```
Returns all searchable locations with coordinates.

## 🤖 AI Hazard Synthesis

When enabled, Gemini API receives raw satellite metrics and generates professional 1-paragraph assessments explaining:
- Why metrics are dangerous together
- Immediate action recommendations
- Disaster response priorities

Example output:
```
"Chennai shows critically dangerous conditions with heavy precipitation (145mm)
combined with 82% soil saturation and low elevation. Immediate flood risk
hazard assessment is critical. Evacuation procedures should be prepared."
```

## 📧 Email Alerts

System automatically sends HTML-formatted emergency emails when:
- **Any district reaches Risk Score = 100%**
- Recipient: ashwanthashwanth2006@gmail.com
- Includes: Location, hazard type, risk score, satellite metrics

## 🗺️ Frontend Interface

### Key Features
- **Dark mode base + pale color accents** (code: #c5d9ff, #a8c5ff)
- **Real-time map** with hazard zones color-coded:
  - 🟢 Green: Low risk (<30%)
  - 🟡 Yellow: Moderate (30-60%)
  - 🟠 Orange: High (60-80%)
  - 🔴 Red: Critical (≥80%)

### Controls
- **Ctrl+K**: Open search overlay
- **Click map**: Get location details
- **📍 Button**: Enable GPS tracking
- **🛣️ Button**: Calculate evacuation routes
- **Layer toggles**: Show/hide satellite data overlays

## 🔐 Security

- **Credentials**: NASA & email passwords stored in `.env` (excluded from git)
- **CORS**:  Configured to allow localhost during development
- **Production**: Restrict CORS origins to trusted domains
- **Credentials Protection**: Never commit `.env` to version control

## 📊 Data Update Intervals

Default: 15-minute updates (configurable via `SSE_UPDATE_INTERVAL`)

| Source | Update Frequency | Latency |
|--------|-----------------|---------|
| SMAP | 3 days | ~3-5 days |
| GPM IMERG | 30 minutes | Near real-time |
| Open-Meteo | 1 hour | Real-time |
| Sentinel-1 | 5-12 days | ~1 week |

## 🧪 Testing

### Test a Location
```bash
curl "http://localhost:8000/api/hazards?lat=13.0827&lon=80.2707"
```

### Test Search
```bash
curl "http://localhost:8000/api/search?q=Chennai"
```

### Test Health
```bash
curl http://localhost:8000/health
```

## 📈 Performance Considerations

- **Parallel fetching**: All 4 data sources fetched simultaneously (~4-8 seconds total)
- **Caching**: Consider Redis caching for frequently accessed locations
- **Rate limiting**: NASA APIs have rate limits - monitor in production
- **Error handling**: Graceful degradation if any API is unavailable

## 🐛 Troubleshooting

### NASA API 401 Error
```
✓ Check NASA_EARTHDATA_USERNAME and PASSWORD in .env
✓ Ensure account is registered at https://earthdata.nasa.gov/
✓ Clear any cached credentials
```

### Gemini AI Not Working
```
✓ Verify GEMINI_API_KEY is set and valid
✓ Check key at https://makersuite.google.com/app/apikey
✓ System will gracefully skip AI analysis if key is invalid
```

### SSL Certificate Error
```
✓ Try disabling SSL verification for development:
  Set PYTHONHTTPSVERIFY=0
✓ In production, ensure certificate chain is valid
```

### Email Not Sending
```
✓ Enable "Less secure app access" for Gmail
✓ Or use 16-character App Password (recommended)
✓ Check SMTP_SERVER and SMTP_PORT settings
✓ Verify SMTP_PASSWORD is correct
```

## 🚀 Production Deployment

### Environment Variables
```bash
DEBUG=false
HOST=0.0.0.0
PORT=8000
CORS_ORIGINS=["https://yourdomain.com"]  # Restrict in production
```

### Server
```bash
# Use Gunicorn with Uvicorn workers
pip install gunicorn
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Database (Optional)
Currently no persistent database - data is fetched live from satellite APIs each request.
For production, consider:
- PostgreSQL for historical data archival
- Redis for caching satellite responses
- TimescaleDB for time-series hazard trends

## 📚 Dependencies

```
fastapi==0.104.1          # Web framework
uvicorn==0.24.0           # ASGI server
pydantic==2.4.2           # Data validation
aiohttp==3.9.0            # Async HTTP client
google-generativeai==0.3.0 # Gemini API
python-dotenv==1.0.0      # Environment variables
requests==2.31.0          # HTTP library
shapely==2.0.1            # Geospatial calculations
```

## 🤝 Contributing

This is a research/educational project for Tamil Nadu disaster management.

## 📄 License

MIT License - Free for educational and research use.

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review API logs in terminal output
3. Verify all credentials are correct

---

**Status**: Production-Ready ✅
**Last Updated**: 2026-03-07
**Built with**: FastAPI + Leaflet.js + Real NASA Data
