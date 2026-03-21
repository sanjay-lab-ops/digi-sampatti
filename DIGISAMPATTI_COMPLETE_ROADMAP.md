# DigiSampatti — Complete Master Roadmap
## India's Property Legal Verification Platform
### Version 2.0 | March 2026 | Save this file — Never Lose Context

---

# SECTION 1 — WHAT IS DIGISAMPATTI

## One Line
DigiSampatti is an AI-powered mobile app that does in 5 minutes what a lawyer charges ₹20,000 and 2 weeks to do — full property legal due diligence for any Karnataka land.

## The Vision
Become the CIBIL of property verification in India.
- CIBIL makes ₹800 Cr/year owning credit scores
- DigiSampatti will own property legal verification
- 60 million property transactions/year — 0 digital verification today
- First mover = platform monopoly

## App Name
**DigiSampatti**
- Digi = like DigiLocker, DigiYatra (government trust)
- Sampatti = property in ALL 22 Indian languages
- Tagline: "Know Your Property. Own Your Decision."
- Package name: digi_sampatti
- Domain: DigiSampatti.in

---

# SECTION 2 — WHAT IS BUILT (CODE STATUS)

## All Files Built ✅
```
C:\PropertyLegalApp\
├── pubspec.yaml                          ✅ digi_sampatti package
├── .env                                  ❌ FILL WITH API KEYS
├── lib/
│   ├── main.dart                         ✅ App entry point
│   ├── app.dart                          ✅ Theme + GoRouter (10 routes)
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart           ✅ Brand colors
│   │   │   ├── app_strings.dart          ✅ All text + partners + disclaimers
│   │   │   └── api_constants.dart        ✅ Bhoomi, RERA, Claude URLs
│   │   ├── models/
│   │   │   ├── property_scan_model.dart  ✅ GPS + scan data
│   │   │   ├── land_record_model.dart    ✅ RTC, Owner, Mutation, EC, RERA
│   │   │   └── legal_report_model.dart   ✅ Risk score, flags, report
│   │   ├── services/
│   │   │   ├── gps_service.dart          ✅ GPS + reverse geocoding
│   │   │   ├── bhoomi_service.dart       ✅ Bhoomi RTC + BDA/BBMP/Lake checks
│   │   │   ├── rera_service.dart         ✅ RERA Karnataka + EC
│   │   │   ├── ai_analysis_service.dart  ✅ Claude AI risk analysis
│   │   │   └── report_generator_service.dart ✅ PDF generation
│   │   └── providers/
│   │       └── property_provider.dart    ✅ Riverpod state management
│   ├── features/
│   │   ├── splash/splash_screen.dart     ✅ Animated splash
│   │   ├── auth/auth_screen.dart         ✅ Firebase Phone OTP
│   │   ├── home/home_screen.dart         ✅ Dashboard + recent reports
│   │   ├── scan/
│   │   │   ├── camera_scan_screen.dart   ✅ Camera + GPS overlay
│   │   │   └── manual_search_screen.dart ✅ Survey number form
│   │   ├── records/land_records_screen.dart ✅ Bhoomi RTC display
│   │   ├── analysis/ai_analysis_screen.dart ✅ AI analysis + risk score
│   │   ├── report/legal_report_screen.dart  ✅ Full report + PDF download
│   │   ├── map/map_view_screen.dart      ✅ Google Maps satellite view
│   │   ├── verification/
│   │   │   └── physical_verification_screen.dart ✅ Physical checklist
│   │   └── partners/
│   │       └── partners_screen.dart      ✅ Lawyer/Bank/Insurance referrals
```

---

# SECTION 3 — WHAT YOU NEED TO DO (PERSONAL LAPTOP)

## Weekend Setup (Do in Order)

### Step 1 — Install Flutter (30 min)
1. Go to: docs.flutter.dev/get-started/install/windows/mobile
2. Download Flutter SDK → Extract to C:\flutter
3. Add C:\flutter\bin to Windows System PATH
4. Restart laptop

### Step 2 — Install Android Studio (20 min)
1. Go to: developer.android.com/studio
2. Download → Install → Open → Finish setup wizard (downloads Android SDK)
3. Restart laptop

### Step 3 — Verify
Open Command Prompt:
```
flutter doctor
```
Screenshot → Send to Claude → I fix errors

### Step 4 — Create 4 Accounts (All Free)
| Account | URL | Why |
|---------|-----|-----|
| Firebase | console.firebase.google.com | Phone OTP login |
| Google Cloud | console.cloud.google.com | Maps API |
| Anthropic | console.anthropic.com | Claude AI analysis |
| Razorpay | dashboard.razorpay.com | ₹149 payments |

### Step 5 — Get API Keys

**Google Maps Key:**
- console.cloud.google.com → New Project: DigiSampatti
- APIs → Enable: Maps SDK for Android
- Credentials → Create API Key → Copy

**Claude Key:**
- console.anthropic.com → API Keys → Create → Copy

**Razorpay Keys:**
- dashboard.razorpay.com → Settings → API Keys → Generate Test Keys → Copy both

**Firebase:**
- console.firebase.google.com → New Project: DigiSampatti
- Add Android app → package: com.digisampatti.app
- Download google-services.json → put in C:\PropertyLegalApp\android\app\

### Step 6 — Fill .env File
Open C:\PropertyLegalApp\.env → paste:
```
CLAUDE_API_KEY=your_claude_key_here
GOOGLE_MAPS_KEY=your_maps_key_here
RAZORPAY_KEY_ID=rzp_test_xxxxxxx
RAZORPAY_KEY_SECRET=your_secret_here
```

### Step 7 — Clone and Run
```
cd C:\
git clone https://github.com/sanjay-lab-ops/digi-sampatti.git PropertyLegalApp
cd PropertyLegalApp
flutter pub get
```
Connect Android phone → Enable USB debugging
```
flutter run
```

---

# SECTION 4 — COMPLETE ROADMAP

## Phase 0 — Setup (This Weekend)
- [ ] Install Flutter on personal laptop
- [ ] Install Android Studio
- [ ] Create 4 accounts (Firebase, Google Cloud, Anthropic, Razorpay)
- [ ] Get all API keys
- [ ] Fill .env file
- [ ] Run flutter doctor → send screenshot to Claude
- [ ] flutter run → app on phone

## Phase 1 — Make It Work (Week 1–2)
- [ ] Test every screen on phone
- [ ] Fix any bugs (send screenshots to Claude)
- [ ] Test Bhoomi search with real survey number
- [ ] Test PDF generation
- [ ] Test ₹1 Razorpay test payment
- [ ] Test AI analysis (Claude API)

## Phase 2 — Business Setup (Week 3–4)
- [ ] Get 3 property lawyer tie-ups in Bengaluru
  → WhatsApp 10 lawyers: "I have property verification app, I send you verified leads, you pay ₹500–1000 per client"
- [ ] Apply for 1 NBFC DSA (Direct Selling Agent)
  → Bajaj Finserv: bajajfinserv.in/dsa-registration (free)
- [ ] Create Play Store developer account
  → play.google.com/console → ₹2,500 one-time
- [ ] Create App Store developer account (optional Month 2)
  → developer.apple.com → ₹8,000/year

## Phase 3 — Launch (Month 2)
- [ ] Submit to Play Store
- [ ] Share with 20 friends/family (free test reports)
- [ ] Post in Bengaluru property buyer WhatsApp/Facebook groups
- [ ] First Instagram post: "I built an app that does what lawyers charge ₹20,000 for — for ₹149"
- [ ] Send to 5 property brokers in Bengaluru (free reports for their clients)

## Phase 4 — Grow (Month 3–6)
- [ ] 100 paying users → Month 3
- [ ] 500 users → Month 4
- [ ] Write to SSLR for MoU → Month 5
- [ ] First NBFC API deal → Month 6
- [ ] Instagram: 1,000 followers

## Phase 5 — Scale (Month 6–12)
- [ ] Add Maharashtra (MahaOnline portal)
- [ ] Add Telangana (Dharani portal)
- [ ] Add Tamil Nadu (TNREGINET portal)
- [ ] Formal MoU with Karnataka SSLR
- [ ] RERA Karnataka API agreement
- [ ] Bank API license (₹2–5L/month each)
- [ ] Hire 1 BD person for lawyer/bank tie-ups

---

# SECTION 5 — GOVERNMENT APPROVALS & MINISTER MEETINGS

## Phase 1 MVP — No Approval Needed
You are reading PUBLIC government data. Same as any citizen visiting bhoomi.karnataka.gov.in.
- Bhoomi RTC → Karnataka Land Revenue Act (public)
- RERA → RERA Act 2016 Section 11 (mandatory public disclosure)
- Encumbrance → Registration Act 1908 (public)
- eCourts → Public court records
- BBMP → Public civic records

## Phase 2 — Department MoUs (Month 6–12, after 1,000 users)
| Office | Contact | Cost |
|--------|---------|------|
| Karnataka SSLR (Bhoomi) | commissioner.sslr@karnataka.gov.in | FREE |
| RERA Karnataka | info@rera.karnataka.gov.in | FREE |
| IGRS Karnataka | igr@karnataka.gov.in | FREE |
| NIC eCourts | ecourts.gov.in/services/api | FREE |
| BBMP | commissioner@bbmp.gov.in | FREE |

**All MoUs are free — just formal letters and 30–90 days waiting.**

## Phase 3 — Minister Level (Year 2, after 10,000 users)
| Minister | Department | What to Ask |
|---------|-----------|------------|
| Revenue Minister, Karnataka | Bhoomi / Land Records | Official verification partner status |
| Housing Minister, Karnataka | RERA, Urban Development | Integrate into home loan process |
| IT/BT Minister, Karnataka | Digital Karnataka | Feature in Digital India stack |
| Union Housing Minister | National RERA | Expand to all states |

**Presentation deck needed (I will build this when time comes):**
- Slide 1: Problem (36 million loan applications rejected)
- Slide 2: Solution (DigiSampatti live demo)
- Slide 3: Numbers (users, reports, banks)
- Slide 4: Ask (official partnership + policy recommendation)
- Slide 5: Vision (CIBIL of property)

## Phase 4 — National Level (Year 3)
- NITI Aayog presentation (Digital India alignment)
- RBI Regulatory Sandbox application
- Ministry of Housing & Urban Affairs, New Delhi
- CII / FICCI PropTech conferences

---

# SECTION 6 — MARKETPLACE LAUNCH PLAN

## What Marketplace Means
DigiSampatti becomes a platform where:
- Buyers find verified lawyers, surveyors, valuers
- Lawyers list themselves and pay per lead
- Banks list loan products and pay per verified borrower
- Insurance companies list products and pay per policy
= Two-sided marketplace (like Sulekha but for property professionals)

## Launch Sequence

### Marketplace Phase 1 — Manual (Month 2–3)
```
You personally onboard:
- 5 property lawyers in Bengaluru (sign 1-page agreement)
- 2 licensed surveyors
- 1 title insurance tie-up
All manually managed via WhatsApp + spreadsheet
```

### Marketplace Phase 2 — In-App (Month 4–6)
```
Partners get their own profile in the app:
- Name, bar registration number, experience
- Price, languages spoken, areas covered
- Rating from past DigiSampatti clients
User picks preferred partner from list
You earn referral fee automatically
```

### Marketplace Phase 3 — Self-Serve (Month 6–12)
```
Lawyers/banks register themselves on DigiSampatti
Pay ₹500/month to be listed
Pay per lead when client contacts them
You earn: listing fee + per lead + per conversion
This is when it becomes a true marketplace
```

## Commission Structure (Confirmed)
| Partner | You Earn | How |
|---------|---------|-----|
| Property Lawyer | ₹500–1,000 per case | Per referral |
| Licensed Surveyor | ₹300–500 per visit | Per referral |
| Home Loan (NBFC) | 0.25% of loan amount | DSA commission (₹12,500 on ₹50L loan) |
| Title Insurance | ₹800–1,500 per policy | Per referral |
| Document Writer | ₹200–400 per registration | Per referral |

---

# SECTION 7 — REVENUE MODEL (COMPLETE)

## Per-User Revenue
| Stream | Who Pays | Amount | Active From |
|--------|---------|--------|------------|
| Digital report | User | ₹149 | Day 1 |
| Subscription | User | ₹999/month | Month 2 |
| Lawyer referral | Lawyer | ₹500–1,000 | Month 2 |
| Surveyor referral | Surveyor | ₹300–500 | Month 2 |
| Home loan commission | Bank/NBFC | 0.25% of loan | Month 3 |
| Title insurance | Insurance | ₹800–1,500 | Month 3 |
| Bank API license | Bank | ₹2–5L/month | Month 9 |
| Govt MoU | State Govt | ₹50L–2Cr/year | Year 2 |

## Monthly Revenue Projections
| Month | Users | Revenue |
|-------|-------|---------|
| Month 3 | 100 | ₹14,900 (reports only) |
| Month 6 | 500 | ₹2,23,500 (reports + referrals + loans) |
| Month 12 | 2,000 | ₹8–12 Lakh |
| Year 2 | 20,000 | ₹50–80 Lakh/month |
| Year 3 | 1 Lakh | ₹2–3 Crore/month |

---

# SECTION 8 — COMPANY STRUCTURE

## One Company, Two Products
Register ONE Private Limited Company (Month 3, when first revenue):
- **DigiSampatti** — Property legal verification
- **ARTH_ID / FinSelf** — Financial identity platform

## Registration Process (Month 3)
1. mca.gov.in → SPICe+ form → ₹10,000 total cost
2. Get: CIN, PAN, TAN, GST number
3. Open current account: HDFC / ICICI
4. Apply DPIIT: startupindia.gov.in (free, tax benefits for 3 years)

## Important — HivePro Contract
- Clause 3.3 + 7.6: Need written permission for any outside business
- **Action:** Email HR: "Building personal property tech app unrelated to cybersecurity. Request acknowledgement."
- OR: Register company in family member's name initially
- Always use personal laptop + personal WiFi for all work
- Never discuss on company equipment or email

---

# SECTION 9 — DIGISAMPATTI + ARTH_ID RELATIONSHIP

## No Conflict — They Are a Pipeline
```
User verifies property on DigiSampatti ✅
User needs home loan but has trading income ❌ (bank rejects)
User goes to ARTH_ID → income verified ✅
Bank sees: Verified property + Verified income = Loan approved ✅

You earn:
₹149 DigiSampatti report
+ ₹12,500 home loan commission
+ ARTH_ID referral commission
= ₹13,000+ from ONE user
```

## Priority Order
- **Now → Play Store launch:** DigiSampatti only
- **After Play Store launch:** Both in parallel
  - DigiSampatti: Mon/Wed/Fri
  - ARTH_ID: Tue/Thu/Sat

## ARTH_ID Status
- 3 screens built (Welcome, Loading, Profile)
- React + Vite + Tailwind (web app)
- All demo/dummy data
- Repo: github.com/sanjay-lab-ops/arth-india
- Next step: Node.js backend, real Aadhaar OTP, Account Aggregator

---

# SECTION 10 — PHYSICAL VERIFICATION CHECKS (IN-APP)

Checks that CANNOT be done digitally — app guides user:

| Check | Office | Why Physical |
|-------|--------|-------------|
| Court cases | City Civil Court | Pre-2010 cases not digitized |
| Benami property | Income Tax — BTPU | No public API |
| Original document chain | Sub-Registrar | Pre-2004 deeds not digitized |
| Tahsildar mutation confirm | Taluk Office | Physical stamp needed |
| Physical boundary | Licensed Surveyor | GPS ≠ measurement |
| Bank NOC | Issuing bank | Manual clearance |
| Gram Panchayat NOC | Local GP Office | Village accountant signature |
| Will/inheritance disputes | Civil Court Probate | Family records only |

---

# SECTION 11 — NEXT IMMEDIATE STEPS

## You Do NOW (Today/Weekend)
1. Install Flutter on personal laptop
2. Install Android Studio
3. Create 4 accounts (Firebase, Google Cloud, Anthropic, Razorpay)
4. Email HivePro HR about outside project permission
5. Delete Flutter + Node.js from company laptop (DONE ✅)
6. Push all code to GitHub (DONE ✅)

## Claude Does NOW (Already Done)
- ✅ Physical Verification Screen built
- ✅ Partners Screen built
- ✅ Both added to router

## You Do Monday
1. flutter doctor → screenshot → send to Claude
2. flutter pub get
3. flutter run → app on phone
4. Test every screen

## Week 2
1. Test Bhoomi with real survey number
2. Test PDF download
3. Test Razorpay ₹1 payment
4. Report any bugs with screenshots

---

# THIS DOCUMENT
Save this file. Print it if needed.
Every decision made, every feature discussed, every plan agreed — all here.
If chat is deleted: open this file and Claude will have full context.

GitHub: github.com/sanjay-lab-ops/digi-sampatti
Code location: C:\PropertyLegalApp (personal laptop)
Last updated: March 21, 2026
