# DigiSampatti — Business Model, Revenue & Cost Flow
**ಡಿಜಿ ಸಂಪತ್ತಿ | Complete Financial Architecture**

---

## 1. WHO PAYS WHAT — Revenue Streams

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        REVENUE STREAMS                                      │
│                                                                             │
│  BUYER (Property purchaser)                                                 │
│  ├── ₹99      → Single property report (PDF with 7-portal AI score)        │
│  ├── ₹499/mo  → Unlimited reports — for brokers, lawyers, NRIs            │
│  └── ₹999/mo  → Pro plan — unlimited + priority support + bulk reports    │
│                                                                             │
│  PROFESSIONAL (Advocate / Broker / Surveyor etc.)                          │
│  ├── FREE     → Register & get listed (we verify their license)            │
│  ├── ₹999/mo  → Featured placement (appear first in search results)        │
│  └── 10-15%   → Commission per successful lead connection                  │
│                                                                             │
│  DEVELOPER / BUILDER                                                       │
│  ├── ₹5,000/mo → List projects in "Verified Projects" section             │
│  └── ₹50/lead  → Pay-per-lead for buyer enquiries                         │
│                                                                             │
│  BANK / NBFC (Home loan partners)                                          │
│  └── ₹300-500  → Cost per application referral (lead generation)          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. COMPLETE TRANSACTION FLOW — End to End

```
BUYER FLOW:
─────────────────────────────────────────────────────────────────────────────

  [1] BUYER downloads app → Logs in with phone OTP (Firebase Auth)
          │
          ▼
  [2] BUYER scans property
      ├── Option A: Camera → OCR reads RTC/deed → auto-fills district/taluk/survey
      ├── Option B: Manual → selects District > Taluk > Village > Survey No
      └── Option C: GPS Site Scan → stands at property → Dishank WMS → survey no
          │
          ▼
  [3] APP sends to BACKEND (Python Flask on Cloud Run)
      ┌──────────────────────────────────────────────────────────────────┐
      │  Backend scrapes SIMULTANEOUSLY (Playwright headless browser):  │
      │                                                                  │
      │  1. Bhoomi RTC     → Owner, land type, extent, B-Kharab?       │
      │  2. Kaveri EC      → 30yr transaction history, mortgages       │
      │  3. RERA           → Project registered? Completion date?      │
      │  4. eCourts        → Active court cases on survey number       │
      │  5. CERSAI         → Bank mortgage / charge registered?        │
      │  6. IGR            → Guidance value ₹/sqft                    │
      │  7. FMB Sketch     → Official boundary sketch image            │
      │                                                                  │
      │  CAPTCHAs → solved via anti-captcha.com API (₹0.10 each)      │
      └──────────────────────────────────────────────────────────────────┘
          │
          ▼
  [4] AI SCORE computed (0-100) from all 7 portal results
      ├── 80-100 → Green "SAFE TO BUY"
      ├── 50-79  → Yellow "VERIFY"
      └── 0-49   → Red "HIGH RISK"
          │
          ▼
  [5] REPORT shown on screen (free preview — blurred after 60 seconds)
          │
          ▼
  [6] PAYMENT GATE — ₹99 via Razorpay (UPI / Card / Net Banking)
          │   Razorpay charges: 2% + ₹3 per transaction
          ▼
  [7] FULL PDF REPORT unlocked → buyer downloads, shares on WhatsApp
          │
          ▼
  [8] "GET EXPERT HELP" screen shown
      ├── Lists VERIFIED professionals for buyer's district
      ├── Buyer taps "Connect" → sends lead to professional (Firestore)
      └── Professional calls buyer within 2 hours

PROFESSIONAL FLOW:
─────────────────────────────────────────────────────────────────────────────

  [1] PROFESSIONAL registers via app
      ├── Selects type (Advocate / Broker / Surveyor etc.)
      ├── Fills license no, districts served, fee, languages, bio
      └── Uploads license photo → Firebase Storage (private, admin-only)
          │
          ▼
  [2] DigiSampatti ADMIN reviews in Firebase console
      ├── Verifies license with Bar Council / RERA / Survey Dept
      ├── Changes status: pending → verified
      └── Professional gets notification
          │
          ▼
  [3] PROFILE goes LIVE → visible to buyers in that district
          │
          ▼
  [4] BUYER sends lead → Professional gets WhatsApp notification
      ├── Lead includes: buyer phone, district, survey number
      └── Professional contacts buyer directly
          │
          ▼
  [5] SERVICE completed → Buyer leaves review → updates professional's rating
```

---

## 3. UNIT ECONOMICS — Revenue Per Transaction

```
┌──────────────────────────────────────────────────────────────────────────┐
│  PER ₹99 REPORT SOLD                                                     │
│                                                                          │
│  Gross Revenue          ₹99.00                                           │
│  Razorpay fee (2%+₹3)  ₹4.98                                            │
│  CAPTCHA cost (0-3)     ₹0.30  (avg 3 portals need CAPTCHA)             │
│  Cloud Run CPU time     ₹0.15  (Playwright session ~45 sec)              │
│  Firebase (read/write)  ₹0.05                                            │
│  ─────────────────────────────────────                                   │
│  NET MARGIN             ₹93.52  (94.5%)                                  │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  PER ₹499/MONTH SUBSCRIPTION                                             │
│                                                                          │
│  Gross Revenue          ₹499.00                                          │
│  Razorpay fee           ₹13.00                                           │
│  CAPTCHA (30 reports)   ₹9.00                                            │
│  Cloud Run              ₹4.50                                            │
│  Firebase               ₹1.50                                            │
│  ─────────────────────────────────────                                   │
│  NET MARGIN             ₹471.00  (94.4%)                                 │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 4. REVENUE PROJECTION — Monthly Targets

```
PHASE 1 — First 6 months (Bengaluru only, 500 users/month)
──────────────────────────────────────────────────────────
  Pay-per-report: 300 users × ₹99             = ₹29,700
  Subscriptions:   20 users × ₹499            = ₹9,980
  Professional featured:  5 × ₹999            = ₹4,995
  ─────────────────────────────────────────────────────
  MONTHLY REVENUE                              = ₹44,675
  MONTHLY COST (servers, CAPTCHA, misc)        = ₹3,500
  MONTHLY PROFIT                               = ₹41,175

PHASE 2 — Year 1 (Karnataka, 5,000 active users/month)
──────────────────────────────────────────────────────
  Pay-per-report: 2,000 × ₹99                 = ₹1,98,000
  Subscriptions:    300 × ₹499                = ₹1,49,700
  Professional featured: 50 × ₹999            = ₹49,950
  Developer listings:    10 × ₹5,000          = ₹50,000
  Bank referrals:       100 × ₹400            = ₹40,000
  ─────────────────────────────────────────────────────
  MONTHLY REVENUE                              = ₹4,87,650
  MONTHLY COST (cloud, CAPTCHA, marketing)     = ₹35,000
  MONTHLY PROFIT                               = ₹4,52,650

PHASE 3 — Year 2 (South India, 50,000 users/month)
───────────────────────────────────────────────────
  Monthly Revenue target                       = ₹35-50 Lakhs
  (Same unit economics, scale via cloud)
```

---

## 5. SERVER INFRASTRUCTURE & COSTS

```
CURRENT SETUP (Development / Testing)
──────────────────────────────────────
  Backend:     Python Flask on local PC + localhost.run tunnel
  Database:    Firebase (free tier — 50K reads/day, 20K writes/day)
  Auth:        Firebase Auth (free)
  Storage:     Firebase Storage (1GB free)
  Total cost:  ₹0/month

PRODUCTION SETUP (Recommended)
────────────────────────────────────────────────────────────────
  Component              Service            Est. Monthly Cost
  ─────────────────────────────────────────────────────────
  Backend API server     Google Cloud Run   ₹0-800  (2M req free)
  Database               Firebase Firestore ₹0-1500 (up to 10M reads)
  Auth                   Firebase Auth      ₹0      (always free)
  File storage           Firebase Storage   ₹0-400  (5GB free)
  CAPTCHA solving        anti-captcha.com   ₹500-2000 (per volume)
  CDN / domain           Cloudflare         ₹0      (free tier)
  APK distribution       Firebase App Dist  ₹0      (free)
  Play Store             Google             ₹2,000  (one-time)
  ─────────────────────────────────────────────────────────
  TOTAL AT 5,000 USERS/MONTH                ₹3,000-5,000/month

WHY CLOUD RUN IS IDEAL FOR THIS APP:
  ✓ Scales to 0 when no requests — no idle cost
  ✓ Playwright (headless Chrome) runs in containers
  ✓ Auto-scales to 100 instances during peak
  ✓ asia-south1 (Mumbai) region — low latency from Karnataka
  ✓ 2 million free requests/month on free tier
```

---

## 6. CAPTCHA COSTS — Breakdown

```
WHICH PORTALS NEED CAPTCHA:
  ✓ Bhoomi RTC   — reCAPTCHA v2 — ₹0.10/solve
  ✓ Kaveri EC    — reCAPTCHA v2 — ₹0.10/solve
  ✓ CERSAI       — reCAPTCHA v2 — ₹0.10/solve
  ✗ RERA         — No CAPTCHA
  ✗ eCourts      — No CAPTCHA
  ✗ IGR          — No CAPTCHA
  ✗ FMB Sketch   — reCAPTCHA (reuses Bhoomi session)

COST PER SEARCH:  ₹0.30 (3 CAPTCHAs × ₹0.10)
COST AT 10,000 SEARCHES/MONTH: ₹3,000

CURRENT BALANCE (anti-captcha.com): $9.90 ≈ ₹823
  → Good for ~8,230 CAPTCHA solves → ~2,700 full reports
```

---

## 7. AI LEGAL SCORE — WHERE IT APPEARS IN THE APP

```
SCREEN 1: LOGIN SCREEN (auth_screen.dart)
  → Green gradient banner: "AI Legal Score — 0-100 property safety score"
  → Tappable → shows dialog explaining what the score means
  → Purpose: MARKETING — shows buyers the value proposition before signup

SCREEN 2: LEGAL REPORT SCREEN (legal_report_screen.dart)
  → Large animated number counting up from 0 to score (e.g. 87/100)
  → Color coded: Green (80+), Yellow (50-79), Red (<50)
  → Shows: "SAFE TO BUY" / "VERIFY" / "HIGH RISK"
  → Shows: "Bank Loan: ELIGIBLE ✓" or "NOT ELIGIBLE ✗"
  → This IS the AI score — it's the HEADLINE of every report

HOW THE SCORE IS CALCULATED (ai_analysis_service.dart):
  ├── EC clear (no mortgage, no attachment)    → +30 points
  ├── RTC ownership matches seller             → +20 points
  ├── RERA registered (if apartment)           → +15 points
  ├── No active court cases (eCourts)          → +20 points
  ├── CERSAI clear (no bank charge)            → +10 points
  └── Guidance value vs sale price reasonable  → +5 points
  ─────────────────────────────────────────────────────────
  TOTAL POSSIBLE                               = 100 points
```

---

## 8. WHAT EACH PORTAL GIVES — DATA FLOW

```
USER INPUT:
  District + Taluk + Hobli + Village + Survey Number
           │
           ▼
  ┌────────────────────────────────────────────────────────────────┐
  │                    BACKEND (main.py)                           │
  │                                                                │
  │  POST /scan_property                                           │
  │  {district, taluk, hobli, village, survey_number}             │
  │                    │                                           │
  │    ┌───────────────┼──────────────────────┐                   │
  │    ▼               ▼                      ▼                   │
  │  RTC Scraper    EC Scraper            CERSAI Scraper          │
  │  (Playwright)   (Playwright)          (Playwright)            │
  │    │               │                      │                   │
  │    ▼               ▼                      ▼                   │
  │  owner_name     transactions[]         charges[]              │
  │  land_type      mortgages[]            registered_banks[]     │
  │  extent         last_sale_date                                │
  │  kharab_status  seller_matches?                               │
  │    │               │                      │                   │
  │    └───────────────┴──────────────────────┘                   │
  │                    │                                           │
  │              Combined JSON response                            │
  └────────────────────────────────────────────────────────────────┘
           │
           ▼
  APP computes AI score → shows report → payment gate → PDF
```

---

## 9. PHOTO SCAN FLOW — What a Building Photo Gets You

```
WHAT HAPPENS WHEN YOU TAP "SCAN SITE" AND TAKE A PHOTO:

  1. Camera opens with GPS overlay showing lat/lng in real time
  2. Tap the "My Location" button (GPS icon in centre)
  3. App sends GPS coordinates to backend: /gps_lookup
  4. Backend queries:
     a) Nominatim (OpenStreetMap) → district, taluk, village name
     b) Dishank WMS GIS layer → cadastral parcel → survey number
  5. If found: "Survey No 123/2A — Yelahanka, Bengaluru Urban"
     → Taps Continue → all 7 portals checked automatically
  6. If NOT found (rural area not yet in Dishank):
     → Shows district/taluk/village from GPS
     → User just needs to type survey number manually

WHY DRONE DATA MATTERS (Karnataka SVAMITVA / NAKSHE):
  - Karnataka government uses drones via NAKSHE/Bhoomi projects
  - Drone surveys update FMB (Field Measurement Book) boundaries
  - Dishank GIS portal (dishank.karnataka.gov.in) shows these
  - Updated every 2-3 years in phases by taluk
  - Urban areas (Bengaluru, Mysuru, Mangaluru): mostly mapped
  - Rural / village areas: still being mapped (2024-2026 target)
  - Our GPS lookup works where Dishank has data
  - Fallback: nominatim gives address, user adds survey number
```

---

## 10. COMPLETE SERVICES FLOW CHART

```
                    ┌──────────────────────────┐
                    │   USER OPENS APP          │
                    └─────────────┬────────────┘
                                  │
                    ┌─────────────▼────────────┐
                    │  LOGIN WITH PHONE OTP     │
                    │  (Firebase Auth)           │
                    └─────────────┬────────────┘
                                  │
              ┌───────────────────▼──────────────────┐
              │         HOME SCREEN                   │
              │  [Scan Property] [My Reports]         │
              │  [Tools] [Guides] [Partners]          │
              └───────────┬──────────────┬───────────┘
                          │              │
              ┌───────────▼───┐    ┌─────▼──────────┐
              │  SCAN SCREEN  │    │ OTHER FEATURES  │
              │ ┌───────────┐ │    │ EMI Calculator  │
              │ │ Document  │ │    │ Stamp Duty Calc │
              │ │ OCR Scan  │ │    │ Buyer Guides    │
              │ └───────────┘ │    │ Transfer Guide  │
              │ ┌───────────┐ │    │ NRI Mode        │
              │ │ GPS Site  │ │    │ Court Tracker   │
              │ │ Scan      │ │    └────────────────┘
              │ └───────────┘ │
              └───────┬───────┘
                      │
              ┌───────▼───────────────┐
              │  MANUAL SEARCH FORM   │
              │  District > Taluk >   │
              │  Hobli > Village >    │
              │  Survey Number        │
              └───────┬───────────────┘
                      │ POST /scan_property
              ┌───────▼───────────────┐
              │   BACKEND SCRAPER     │
              │  7 Portals + CAPTCHA  │
              │  ~45-90 seconds       │
              └───────┬───────────────┘
                      │
              ┌───────▼───────────────┐
              │  REPORT SCREEN        │
              │  AI Score: 87/100     │
              │  SAFE TO BUY ✓       │
              │  Bank Loan: ELIGIBLE  │
              │                       │
              │  [₹99 Download PDF]   │
              └───────┬───────────────┘
                      │ Razorpay
              ┌───────▼───────────────┐
              │  PDF REPORT UNLOCKED  │
              │  Share on WhatsApp    │
              └───────┬───────────────┘
                      │
              ┌───────▼───────────────┐
              │  GET EXPERT HELP      │
              │  Real professionals   │
              │  filtered by district │
              │                       │
              │  [Connect Advocate]   │
              │  [Home Loan]          │
              │  [Surveyor]           │
              └───────────────────────┘
```

---

## 11. PRICING vs COMPETITION

```
  Service              Provider          Cost per Property
  ─────────────────────────────────────────────────────────
  Manual EC search     Sub-Registrar     Free (but 2hr wait)
  Property lawyer      Local advocate    ₹5,000 - ₹50,000
  Property report      MagicBricks       Not available
  Property report      NoBroker          ₹499 (limited portals)
  Full due-diligence   Advocate firm     ₹15,000 - ₹1,00,000
  ─────────────────────────────────────────────────────────
  DigiSampatti         We                ₹99 (all 7 portals, AI)

  WHY WE WIN:
  ✓ 90 seconds vs 2-7 days for manual
  ✓ ₹99 vs ₹15,000+ for full due-diligence
  ✓ 7 government portals in one place
  ✓ AI score — not just raw data
  ✓ Professional marketplace after the report
  ✓ Works from any phone, any location
```

---

## 12. GOVERNMENT DIGITAL SIGNATURE & OFFICIAL SEALS

```
CURRENT STATUS — What's Official vs What We Do:
────────────────────────────────────────────────
  ✓ DATA is official — fetched live from government portals
  ✗ DOCUMENT is not government-signed — it's our formatted report
  
WHAT GOVERNMENT OFFICIALS DO:
  - EC from Kaveri has a "Digitally Signed" certificate when downloaded
    directly from kaveri.karnataka.gov.in (for ₹5 fee)
  - RTC has an e-signature when downloaded from Bhoomi portal
  - These have legal standing in courts and banks

WHAT WE DO:
  - We scrape the SAME data and present it in our report
  - Our report is an ANALYSIS TOOL — not a replacement for official docs
  - For loan applications: buyer should download official EC from Kaveri
  - For court cases: official certified copies needed

FUTURE OPTION (DigiLocker Integration):
  - DigiLocker has Bhoomi RTC as an officially issued document
  - Integration possible after getting SSLR department approval
  - This would give our reports official government backing
```

---

*Document Version: April 2026*
*DigiSampatti — Startup India | Patent Provisional Filed*
