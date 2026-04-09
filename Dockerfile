FROM python:3.11-slim

WORKDIR /app

# Install Chromium system deps — only packages that exist in Debian bookworm slim.
# ttf-unifont / ttf-ubuntu-font-family do NOT exist here; skip them.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libnss3 libnspr4 \
      libatk1.0-0 libatk-bridge2.0-0 \
      libcups2 libdrm2 libdbus-1-3 libexpat1 \
      libxcb1 libxkbcommon0 \
      libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 \
      libgbm1 libpango-1.0-0 libcairo2 libasound2 \
      fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Chromium at BUILD time — deps already above, no --with-deps needed
RUN playwright install chromium

COPY backend/ .

ENV PORT=8080
EXPOSE $PORT

# No browser install at runtime — just start gunicorn
CMD gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app
