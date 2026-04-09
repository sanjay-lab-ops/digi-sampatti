FROM python:3.11-slim

WORKDIR /app

# Build context = repo root, so prefix paths with backend/
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

ENV PORT=8080
EXPOSE $PORT

# Install Chromium at container START — bypasses Cloud Build network restrictions
CMD bash -c "playwright install chromium --with-deps && gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app"
