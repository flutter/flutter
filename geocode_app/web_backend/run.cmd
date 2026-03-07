@echo off
REM Tamil Nadu Hazard Monitor - Windows Startup Script
REM This script sets up Python venv and starts the FastAPI server

setlocal enabledelayedexpansion

cls
echo ========================================
echo Tamil Nadu Hazard Monitor - Starting
echo ========================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    echo Please install Python 3.10+ from python.org
    pause
    exit /b 1
)

echo [OK] Python found
echo.

REM Create virtual environment if it doesn't exist
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
    echo [OK] Virtual environment created
) else (
    echo [OK] Virtual environment exists
)
echo.

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat
echo [OK] Activated
echo.

REM Install requirements
echo Installing dependencies...
pip install -q -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

echo ========================================
echo Starting FastAPI Server
echo ========================================
echo.
echo WEB INTERFACE: http://localhost:8000/static/index.html
echo API DOCS:      http://localhost:8000/docs
echo HEALTH CHECK:  http://localhost:8000/health
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

REM If uvicorn fails
if errorlevel 1 (
    echo.
    echo ERROR: Failed to start server
    echo Make sure port 8000 is not in use
    pause
)
