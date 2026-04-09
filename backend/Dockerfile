FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE $PORT

# Install Chromium at container START (not build time) — bypasses Railway build network restrictions
CMD bash -c "playwright install chromium --with-deps && gunicorn --bind 0.0.0.0:$PORT --workers 1 --timeout 120 main:app"
