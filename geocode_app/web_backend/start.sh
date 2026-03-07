#!/bin/bash

# Tamil Nadu Real-Time Hazard Monitor - Web Backend Startup Script
# This script sets up and runs the FastAPI web backend

set -e

echo "=================================="
echo "Tamil Nadu Hazard Monitor - Setup"
echo "=================================="

# Check Python version
python_version=$(python3 --version 2>&1)
echo "✓ Using $python_version"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt
echo "✓ Dependencies installed"

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found!"
    echo "📋 Please configure the following in .env:"
    echo "   - NASA_EARTHDATA_USERNAME"
    echo "   - NASA_EARTHDATA_PASSWORD"
    echo "   - GEMINI_API_KEY"
    echo "   - SMTP credentials"
else
    echo "✓ .env file configured"
fi

echo ""
echo "=================================="
echo "🚀 Starting FastAPI Server"
echo "=================================="
echo "📡 API: http://localhost:8000"
echo "📊 Docs: http://localhost:8000/docs"
echo "🌐 Frontend: http://localhost:8000/static/index.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
