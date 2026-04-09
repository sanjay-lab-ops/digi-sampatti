# Use official Playwright image — Chromium + all system deps pre-installed
# No apt-get failures, no font package issues.
FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

WORKDIR /app

# Build context = repo root, so prefix paths with backend/
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

ENV PORT=8080
EXPOSE $PORT

CMD gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app
