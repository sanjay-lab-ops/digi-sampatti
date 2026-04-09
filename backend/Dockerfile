FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-install Chromium during build (base image already has all system deps)
RUN playwright install chromium

COPY . .

ENV PORT=8080
# Cover both possible locations for main.py depending on Railway's build context
ENV PYTHONPATH=/app:/app/backend

EXPOSE $PORT

RUN echo "--- /app contents ---" && ls /app && echo "--- /app/backend (if exists) ---" && ls /app/backend 2>/dev/null || true

CMD gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app
