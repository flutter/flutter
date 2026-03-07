#!/bin/bash
# Quick diagnostic script for web_backend

echo "======================================"
echo "Tamil Nadu Hazard Monitor - Diagnostic"
echo "======================================"
echo ""

# Check Python
echo "✓ Checking Python..."
python --version
echo ""

# Check virtual environment
echo "✓ Creating virtual environment..."
if [ ! -d "venv" ]; then
    python -m venv venv
else
    echo "  (venv already exists)"
fi
echo ""

# Activate venv
echo "✓ Installing dependencies..."
if [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate  # Windows Git Bash
elif [ -f "venv/bin/activate" ]; then
    source venv/bin/activate       # Linux/Mac
fi
pip install -q -r requirements.txt 2>&1 | grep -i error || echo "  (dependencies OK)"
echo ""

# Test imports
echo "✓ Testing Python imports..."
python -c "
import fastapi; print('  ✓ FastAPI')
import uvicorn; print('  ✓ Uvicorn')
import pydantic; print('  ✓ Pydantic')
import aiohttp; print('  ✓ aiohttp')
import dotenv; print('  ✓ python-dotenv')
print('')
" || echo "  ERROR: Import failed"

# Check files
echo "✓ Checking project files..."
[ -f "main.py" ] && echo "  ✓ main.py"
[ -f "config.py" ] && echo "  ✓ config.py"
[ -f "data_fetchers.py" ] && echo "  ✓ data_fetchers.py"
[ -f "risk_engine.py" ] && echo "  ✓ risk_engine.py"
[ -f ".env" ] && echo "  ✓ .env"
[ -f "static/index.html" ] && echo "  ✓ static/index.html"
echo ""

# Try to import main
echo "✓ Testing main.py..."
python -c "from main import app; print('  ✓ main.py imports successfully')" 2>&1 | head -5
echo ""

echo "======================================"
echo "Ready to start! Run:"
echo "  uvicorn main:app --reload"
echo "======================================"
