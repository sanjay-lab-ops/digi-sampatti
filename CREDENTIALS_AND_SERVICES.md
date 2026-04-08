# DigiSampatti — All Credentials & Services

**Last updated:** 2026-04-08  
**App name:** DigiSampatti (ಡಿಜಿ ಸಂಪತ್ತಿ)  
**Company:** Startup India | IN-0326-9427JD | Patent Provisional Filed

---

## 1. Firebase (Auth + Firestore)

| Item | Value |
|------|-------|
| Project name | digi-sampatti |
| Console | https://console.firebase.google.com/project/digi-sampatti |
| Auth method | Phone OTP (Firebase Authentication) |
| Database | Firestore (Cloud Firestore) |
| Service account | `digi-sampatti/backend/serviceAccount.json` |

**Firestore Collections:**
- `users/{uid}` — user profiles
- `callback_requests` — expert/partner callback submissions
- `users/{uid}/callback_requests` — per-user callbacks
- `rtc_cache` — Bhoomi RTC results (7-day TTL)
- `ec_cache` — Kaveri EC results (3-day TTL)
- `guidance_values` — IGR guidance value cache (30-day TTL)

---

## 2. Google Services

| Service | Key / Value |
|---------|-------------|
| Maps API Key | `AIzaSyCPRJU4zqwTxWbtfnHId2X1GGbuOixwHAs` |
| Maps usage | GPS reverse geocoding, Dishank fallback |
| Anthropic API | `` |
| Anthropic usage | AI Legal Score, property analysis (Claude claude-sonnet-4-6) |

---

## 3. CAPTCHA Solving — anti-captcha.com

| Item | Value |
|------|-------|
| Service | https://anti-captcha.com |
| API Key | `c3e22ee4f9c2b9d5ae8807031a25f39f` |
| Balance (2026-04-08) | $9.90 |
| Cost per solve | ~$0.10 per reCAPTCHA |
| Used for | Bhoomi RTC, Kaveri EC, CERSAI, FMB (when CAPTCHA appears) |

---

## 4. Payment — Razorpay

| Item | Value |
|------|-------|
| Mode | Test (not live yet) |
| Key ID | `rzp_test_STzj4B5S21m18M` |
| Key Secret | `kq2yBFKUj0gl0uu39UsD11Jz` |
| Report price | ₹149 per report |
| Subscription | ₹999/month |
| Dashboard | https://dashboard.razorpay.com |

**To go live:** Replace test keys with live keys from Razorpay dashboard.

---

## 5. Backend Server

### Current Setup (Development/Testing)
| Item | Value |
|------|-------|
| Tech | Python Flask + Playwright (headless Chrome) |
| Location | `C:\Users\Dell\digi-sampatti\backend\main.py` |
| Start command | `cd C:\Users\Dell\digi-sampatti\backend && python main.py` |
| Local URL | `http://127.0.0.1:8080` |
| LAN URL | `http://192.168.29.151:8080` |
| Python version | 3.11 |

### Public Tunnel (for testers — temporary)
| Item | Value |
|------|-------|
| Service | localhost.run (free, no signup) |
| Current URL | `https://9a5fae161aa490.lhr.life` |
| Start command | `ssh -R 80:localhost:8080 nokey@localhost.run` |
| Limitation | URL changes every restart, requires PC to stay on |

**Note:** localhost.run URL changes each time you restart it. After restarting:
1. Get new URL from terminal output
2. Update `C:\Users\Dell\digi-sampatti\.env` → `BACKEND_URL=https://NEW_URL.lhr.life`
3. Rebuild APK: `flutter build apk --release --dart-define-from-file=.env`
4. Install: `adb install -r android\app\build\outputs\apk\release\app-release.apk`

### Production Deployment (planned)
| Option | Cost | Notes |
|--------|------|-------|
| Google Cloud Run | ~$5–15/month at 100 scans/day | Best option — scales to zero |
| Railway.app | $5/month flat | Easier setup |
| ngrok (paid) | $10/month | Fixed subdomain |

**To deploy on Google Cloud Run:**
```bash
# From backend directory
gcloud run deploy digisampatti-backend \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --timeout 120 \
  --set-env-vars ANTICAPTCHA_KEY=c3e22ee4f9c2b9d5ae8807031a25f39f
```

---

## 6. Government Portals Scraped

| Portal | URL | Auth Needed | CAPTCHA |
|--------|-----|-------------|---------|
| Bhoomi RTC | landrecords.karnataka.gov.in/Service2 | No | Sometimes |
| Kaveri EC | kaveri.karnataka.gov.in/ec-search-citizen | No | No |
| RERA Karnataka | rera.karnataka.gov.in | No | No |
| eCourts | ecourts.gov.in | No | No |
| CERSAI | cersai.org.in/CERSAI/asstsrch.prg | No | No |
| IGR / Guidance Value | kaveri.karnataka.gov.in/guidance-value | No | No |
| FMB Sketch | landrecords.karnataka.gov.in/service2/forM16A.aspx | No | No |
| Dishank (GPS) | dishank.karnataka.gov.in | No | No |

---

## 7. Flutter App Config

**File:** `C:\Users\Dell\digi-sampatti\.env`

```
ANTHROPIC_API_KEY=
GOOGLE_MAPS_API_KEY=AIzaSyCPRJU4zqwTxWbtfnHId2X1GGbuOixwHAs
RAZORPAY_KEY_ID=rzp_test_STzj4B5S21m18M
RAZORPAY_KEY_SECRET=kq2yBFKUj0gl0uu39UsD11Jz
BACKEND_URL=https://9a5fae161aa490.lhr.life
ANTICAPTCHA_KEY=c3e22ee4f9c2b9d5ae8807031a25f39f
APP_NAME=DigiSampatti
APP_ENV=development
REPORT_PRICE_INR=149
SUBSCRIPTION_PRICE_INR=999
```

**APK location:** `android\app\build\outputs\apk\release\app-release.apk`

**Build command:**
```
flutter build apk --release --dart-define-from-file=.env
```

**Install command:**
```
adb install -r android\app\build\outputs\apk\release\app-release.apk
```

---

## 8. Key Contacts & Registrations

| Item | Value |
|------|-------|
| Startup India | IN-0326-9427JD |
| Patent | Provisional Filed |
| DPDP Act 2023 | Compliant (no PII stored without consent) |

---

## 9. How to Hand Over to a New Developer

1. Share this file
2. Share Firebase service account JSON: `backend/serviceAccount.json`
3. Share Google Cloud project access (if deployed)
4. GitHub repo (if set up) — all code at `C:\Users\Dell\digi-sampatti\`
5. anti-captcha.com account credentials (top up when balance < $2)
6. Razorpay account — switch to live keys before launch

---

## 10. Daily Operations Checklist (for testing phase)

- [ ] Start backend: `python main.py` in `digi-sampatti\backend\`
- [ ] Start tunnel: `ssh -R 80:localhost:8080 nokey@localhost.run`
- [ ] Update `.env` with new tunnel URL (if URL changed)
- [ ] Rebuild APK if URL changed
- [ ] Check anti-captcha balance: https://anti-captcha.com/dashboard
- [ ] Check Firebase usage: https://console.firebase.google.com
