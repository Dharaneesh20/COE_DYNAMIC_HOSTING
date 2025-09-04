#!/bin/bash
# Production startup script for AWS deployment

# Initialize database if it doesn't exist
python -c "from app import init_db; init_db()"

# Start the application with Gunicorn for production
exec gunicorn --bind 0.0.0.0:5000 \
              --workers 2 \
              --threads 2 \
              --worker-class gthread \
              --worker-connections 1000 \
              --max-requests 1000 \
              --max-requests-jitter 100 \
              --timeout 60 \
              --keep-alive 2 \
              --log-level info \
              --access-logfile - \
              --error-logfile - \
              app:app
