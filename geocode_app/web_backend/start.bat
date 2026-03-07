@echo off
REM Tamil Nadu Real-Time Hazard Monitor - Web Backend Startup Script (Windows)

echo ==================================
echo Tamil Nadu Hazard Monitor - Setup
echo ==================================

REM Check Python version
for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo. ✓ Using %PYTHON_VERSION%

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo. 📦 Creating virtual environment...
    python -m venv venv
    echo. ✓ Virtual environment created
)

REM Activate virtual environment
echo. 🔌 Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo. 📥 Installing dependencies...
pip install -r requirements.txt
echo. ✓ Dependencies installed

REM Check for .env file
if not exist ".env" (
    echo. ⚠️  .env file not found!
    echo. 📋 Please configure the following in .env:
    echo.    - NASA_EARTHDATA_USERNAME
    echo.    - NASA_EARTHDATA_PASSWORD
    echo.    - GEMINI_API_KEY
    echo.    - SMTP credentials
) else (
    echo. ✓ .env file configured
)

echo.
echo ==================================
echo 🚀 Starting FastAPI Server
echo ==================================
echo. 📡 API: http://localhost:8000
echo. 📊 Docs: http://localhost:8000/docs
echo. 🌐 Frontend: http://localhost:8000/static/index.html
echo.
echo. Press Ctrl+C to stop the server
echo.

REM Start the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
