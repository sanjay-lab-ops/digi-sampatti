FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN playwright install chromium

COPY . .

ENV PORT=8080
EXPOSE $PORT

# Railway injects $PORT at runtime — gunicorn reads it
CMD gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app
