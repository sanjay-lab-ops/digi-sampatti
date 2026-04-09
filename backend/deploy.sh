#!/bin/bash
# Deploy DigiSampatti backend to Google Cloud Run
# Run this once from your terminal (needs gcloud CLI installed)

PROJECT_ID="digisampatti"
SERVICE_NAME="digisampatti-backend"
REGION="asia-south1"   # Mumbai — closest to Karnataka

echo "Building and deploying to Cloud Run..."

gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --project $PROJECT_ID \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 120 \
  --set-env-vars "ANTICAPTCHA_KEY=$ANTICAPTCHA_KEY" \
  --set-env-vars "FIREBASE_CREDS=/app/serviceAccount.json"

echo ""
echo "After deploy, copy the Cloud Run URL and add to .env:"
echo "BACKEND_URL=https://digisampatti-backend-xxxx-el.a.run.app"