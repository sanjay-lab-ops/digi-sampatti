# DigiSampatti — All Credentials & Services

**Last updated:** 2026-04-08  
**App name:** DigiSampatti (ಡಿಜಿ ಸಂಪತ್ತಿ)  
**Company:** Startup India | IN-0326-9427JD | Patent Provisional Filed

> **IMPORTANT:** Real API keys are in `.env` file (not committed to git).
> This document uses placeholders. Never commit real keys to GitHub.

---

## 1. Firebase (Auth + Firestore)

| Item | Value |
|------|-------|
| Project name | digi-sampatti |
| Console | https://console.firebase.google.com/project/digi-sampatti |
| Auth method | Phone OTP (Firebase Authentication) |
| Database | Firestore (Cloud Firestore) |
| Service account | `digi-sampatti/backend/serviceAccount.json` (not in git) |

**Firestore Collections:**
- `users/{uid}` — user profiles
- `callback_requests` — expert/partner callback submissions
- `professionals/{uid}` — verified professional partner profiles
- `professional_leads/{id}` — buyer → professional connection requests
- `rtc_cache` — Bhoomi RTC results (7-day TTL)
- `ec_cache` — Kaveri EC results (3-day TTL)
- `guidance_values` — IGR guidance value cache (30-day TTL)

---

## 2. Google Services

| Service | Key / Value |
|---------|-------------|
| Maps API Key | stored in `.env` as `GOOGLE_MAPS_API_KEY` |
| Maps usage | GPS reverse geocoding, Dishank fallback |
| Anthropic API | stored in `.env` as `ANTHROPIC_API_KEY` |
| Anthropic usage | AI Legal Score, property analysis (Claude Sonnet) |

---

## 3. CAPTCHA Solving — anti-captcha.com

| Item | Value |
|------|-------|
| Service | https://anti-captcha.com |
| API Key | stored in `.env` as `ANTICAPTCHA_KEY` |
| Balance (2026-04-08) | $9.90 |
| Cost per solve | ~$0.10 per reCAPTCHA |
| Used for | Bhoomi RTC, Kaveri EC, CERSAI, FMB (when CAPTCHA appears) |

---

## 4. Payment — Razorpay

| Item | Value |
|------|-------|
| Mode | Test (not live yet) |
| Key ID | stored in `.env` as `RAZORPAY_KEY_ID` |
| Key Secret | stored in `.env` as `RAZORPAY_KEY_SECRET` |
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
| Python version | 3.11 |

### Public Tunnel (for testers — temporary)
| Item | Value |
|------|-------|
| Service | localhost.run (free, no signup) |
| Start command | `ssh -R 80:localhost:8080 nokey@localhost.run` |
| Limitation | URL changes every restart, requires PC to stay on |

**After restarting tunnel:**
1. Get new URL from terminal output
2. Update `.env` → `BACKEND_URL=https://NEW_URL.lhr.life`
3. Rebuild APK: `flutter build apk --release --dart-define-from-file=.env`
4. Reinstall on testers' phones

### Production Deployment (Railway — permanent)
| Option | Cost | Notes |
|--------|------|-------|
| Railway.app | ~$5/month | Easiest — Git push, always on |
| Google Cloud Run | ~$0-15/month | Scales to zero, cheapest at scale |

**Railway setup:**
1. Go to railway.app → New Project → Deploy from GitHub
2. Select repo `sanjay-lab-ops/digi-sampatti` → Root directory: `backend`
3. Add env vars: `ANTICAPTCHA_KEY`, `PORT=8080`
4. Get URL → update `.env` BACKEND_URL → rebuild APK

---

## 6. Government Portals Scraped

| Portal | URL | CAPTCHA |
|--------|-----|---------|
| Bhoomi RTC | landrecords.karnataka.gov.in/Service2 | Sometimes |
| Kaveri EC | kaveri.karnataka.gov.in/ec-search-citizen | No |
| RERA Karnataka | rera.karnataka.gov.in | No |
| eCourts | ecourts.gov.in | No |
| CERSAI | cersai.org.in/CERSAI/asstsrch.prg | No |
| IGR / Guidance Value | kaveri.karnataka.gov.in/guidance-value | No |
| FMB Sketch | landrecords.karnataka.gov.in/service2/forM16A.aspx | No |
| Dishank (GPS lookup) | dishank.karnataka.gov.in | No |

---

## 7. Flutter App .env Template

Copy this to `.env` (never commit to git) and fill real values:

```
ANTHROPIC_API_KEY=sk-ant-...your-key-here...
GOOGLE_MAPS_API_KEY=AIza...your-key-here...
RAZORPAY_KEY_ID=rzp_test_...
RAZORPAY_KEY_SECRET=...
BACKEND_URL=https://your-railway-url.up.railway.app
ANTICAPTCHA_KEY=...your-key-here...
APP_NAME=DigiSampatti
APP_ENV=development
REPORT_PRICE_INR=149
SUBSCRIPTION_PRICE_INR=999
```

---

## 8. How to Build APK (Complete Reference)

### Debug APK — for testing on your own phone
```bash
cd C:\Users\Dell\digi-sampatti
flutter build apk --debug
# Output: android\app\build\outputs\flutter-apk\app-debug.apk
# Size: ~80MB | Slower but shows errors
```

### Release APK — for sending to testers
```bash
cd C:\Users\Dell\digi-sampatti
flutter build apk --release --dart-define-from-file=.env
# Output: android\app\build\outputs\flutter-apk\app-release.apk
# Size: ~30MB | Fast, no debug info
```

### Install on phone wirelessly (ADB WiFi)
```bash
# Step 1: Connect (phone must be on same WiFi, wireless debugging ON)
adb connect 192.168.29.76:PORT

# Step 2: Install
adb install -r android\app\build\outputs\flutter-apk\app-debug.apk

# Check connected devices first:
adb devices
```

### Send to testers (no ADB needed)
```
Share the APK file via WhatsApp or Google Drive.
Tester must allow "Install from unknown sources" in Android settings.
APK location: android\app\build\outputs\flutter-apk\app-release.apk
```

### When to rebuild APK
| Change | Rebuild needed? |
|--------|----------------|
| Backend code changed | No — backend deploys separately |
| BACKEND_URL changed in .env | Yes — app needs new URL baked in |
| Flutter/Dart code changed | Yes |
| Firebase config changed | Yes |
| Just restarting backend | No |

### Full deploy sequence after any code change
```bash
# 1. Make code changes
# 2. Build
flutter build apk --release --dart-define-from-file=.env
# 3. Install on your phone
adb install -r android\app\build\outputs\flutter-apk\app-release.apk
# 4. Share with testers
# Send: android\app\build\outputs\flutter-apk\app-release.apk via WhatsApp
```

**APK location (quick reference):**
- Debug: `android\app\build\outputs\flutter-apk\app-debug.apk`
- Release: `android\app\build\outputs\flutter-apk\app-release.apk`

---

## 8. Key Contacts & Registrations

| Item | Value |
|------|-------|
| Startup India | IN-0326-9427JD |
| Patent | Provisional Filed |
| DPDP Act 2023 | Compliant (no PII stored without consent) |
| GitHub | https://github.com/sanjay-lab-ops/digi-sampatti |

---

## 9. Daily Operations Checklist (testing phase — before Railway deploy)

- [ ] Start backend: `python main.py` in `digi-sampatti\backend\`
- [ ] Start tunnel: `ssh -R 80:localhost:8080 nokey@localhost.run`
- [ ] Update `.env` with new tunnel URL (if URL changed)
- [ ] Rebuild APK if URL changed
- [ ] Check anti-captcha balance: https://anti-captcha.com/dashboard
- [ ] Check Firebase usage: https://console.firebase.google.com

## 10. After Railway Deploy (no more daily checklist needed)

- Backend runs 24/7 — PC can be off
- APK sent once to testers — works anytime
- Only rebuild APK when app code changes
