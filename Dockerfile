FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Chromium during build (base image has all system/font deps pre-installed)
RUN playwright install chromium

COPY backend/ .

ENV PORT=8080
EXPOSE $PORT

CMD gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app
