#!/bin/bash

# Production startup script for AWS Cloud Storage
# This script should be run from the application directory

echo "Starting AWS Cloud Storage Application..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create necessary directories
mkdir -p uploads
mkdir -p instance

# Initialize database if it doesn't exist
if [ ! -f "cloud_storage.db" ]; then
    echo "Initializing database..."
    python -c "from app import init_db; init_db()"
fi

echo "Starting Flask application..."
python app.py
