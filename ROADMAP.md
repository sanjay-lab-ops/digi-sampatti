# DigiSampatti — Complete Project Roadmap

## What This App Does
Karnataka property legal due diligence in minutes:
1. Take photo of property → GPS auto-captured
2. Enter survey number, district, taluk
3. App fetches Bhoomi RTC records, encumbrances, RERA status
4. Claude AI analyzes all data → Risk Score 0-100
5. PDF report generated → "Safe to Buy / Caution / Don't Buy"

---

## Files Built (Complete List)

```
c:/DigiSampattiApp/
├── pubspec.yaml                          ← All Flutter dependencies
├── .env                                  ← API keys (fill before running)
├── lib/
│   ├── main.dart                         ← App entry point
│   ├── app.dart                          ← Theme + GoRouter navigation
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart           ← All colors (green brand, risk colors)
│   │   │   ├── app_strings.dart          ← All text + Karnataka districts list
│   │   │   └── api_constants.dart        ← All API URLs (Bhoomi, RERA, Claude)
│   │   ├── models/
│   │   │   ├── property_scan_model.dart  ← GPS location + scan data
│   │   │   ├── land_record_model.dart    ← Bhoomi RTC, Owner, Mutation, EC, RERA
│   │   │   └── legal_report_model.dart   ← Risk score, flags, full report
│   │   ├── services/
│   │   │   ├── gps_service.dart          ← GPS capture + reverse geocoding
│   │   │   ├── camera_service.dart       ← Camera init + photo capture
│   │   │   ├── bhoomi_service.dart       ← Bhoomi RTC + Govt checks (BDA/BBMP/Raja Kaluve/Lake)
│   │   │   ├── rera_service.dart         ← RERA Karnataka + Encumbrance (EC)
│   │   │   ├── ai_analysis_service.dart  ← Claude AI risk analysis
│   │   │   └── report_generator_service.dart ← PDF report generation
│   │   └── providers/
│   │       └── property_provider.dart    ← Riverpod state management
│   ├── features/
│   │   ├── splash/splash_screen.dart     ← Animated splash
│   │   ├── auth/auth_screen.dart         ← Firebase Phone OTP login
│   │   ├── home/home_screen.dart         ← Dashboard + recent reports
│   │   ├── scan/
│   │   │   ├── camera_scan_screen.dart   ← Live camera + GPS overlay
│   │   │   └── manual_search_screen.dart ← Survey no. + district form
│   │   ├── records/land_records_screen.dart ← Bhoomi RTC display
│   │   ├── analysis/ai_analysis_screen.dart ← Claude AI analysis + risk score
│   │   ├── report/legal_report_screen.dart  ← Full report + PDF download
│   │   └── map/map_view_screen.dart      ← Google Maps satellite view
│   └── widgets/common_widgets.dart       ← Reusable UI components
├── android/app/src/main/AndroidManifest.xml ← Permissions (camera, GPS, storage)
└── ios/Runner/Info.plist                 ← iOS permissions (Apple requirement)
```

---

## What Each Screen Does

| Screen | Purpose |
|--------|---------|
| Splash | App logo + auto-login check |
| Auth | Phone OTP via Firebase |
| Home | Dashboard, recent reports, start scan |
| Camera Scan | Take photo with GPS overlay, auto-capture coordinates |
| Manual Search | Enter survey no., district, taluk, hobli, village |
| Land Records | Display Bhoomi RTC data: owner, khata, area, encumbrances, mutations |
| AI Analysis | Claude AI risk score + flags + recommendation |
| Legal Report | Full printable report + PDF download + share |
| Map View | Google Maps satellite view of property location |

---

## Legal Checks Performed

| Check | Source | What It Detects |
|-------|--------|----------------|
| RTC Records | Bhoomi karnataka.gov.in | Owner, land type, area |
| Khata Type | Bhoomi / BBMP | A Khata (legal) vs B Khata (semi-legal) |
| Revenue Site | BDA/BBMP/CMC check | Unauthorized layouts |
| Encumbrances (EC) | IGRS Karnataka | Active mortgages, loans, claims |
| Mutations | Bhoomi portal | Ownership transfer history |
| BDA Acquisition | BDA notifications | Compulsory acquisition notices |
| Road Widening | BBMP/NH/State Highways | Land in proposed road area |
| Raja Kaluve Buffer | BBMP GIS | Storm drain 50m no-build zone |
| Lake Bed / FTL | Karnataka Lake Dev. Auth. | Lake boundary 30m buffer |
| Forest Land | Forest Survey of India | Forest land restrictions |
| HT Line Buffer | BESCOM | High tension line 11m zone |
| Heritage Zone | ASI | Archaeological site restrictions |
| RERA Status | rera.karnataka.gov.in | Builder registration, project status |
| AI Risk Score | Claude AI | Overall legal risk 0-100 |

---

## Does It Need a Server?

**For MVP (Phase 1): NO SERVER NEEDED**

Everything runs on-device:
- Camera + GPS: Phone hardware
- Bhoomi API: Direct HTTP from phone to bhoomi.karnataka.gov.in
- RERA API: Direct HTTP from phone to rera.karnataka.gov.in
- Claude AI: Direct API call from phone to api.anthropic.com
- PDF Report: Generated on-device
- Payment: Razorpay handles servers
- Auth: Firebase handles servers

**You WILL need a server when:**
- Caching Bhoomi data (to reduce repeat API calls)
- Analytics dashboard (track how many reports generated)
- Subscription management backend
- Bank API white-label product
- Advanced features like court case search

---

## Step-by-Step: From Code to Play Store (3 Months)

### WEEK 1-2: Setup
```
1. Install Flutter SDK: flutter.dev/docs/get-started/install/windows
2. Install Android Studio: developer.android.com/studio
3. Install VS Code with Flutter extension
4. Run: flutter doctor (fix any issues)
5. Create Firebase project: console.firebase.google.com
6. Run: flutterfire configure (in project folder)
7. Get Google Maps API key: console.cloud.google.com
8. Get Anthropic API key: console.anthropic.com
9. Fill in .env file with all keys
10. Run: flutter pub get
```

### WEEK 3-4: First Run
```
1. Connect Android phone (enable USB debugging)
2. Run: flutter run
3. Test camera + GPS capture
4. Test manual search with a known survey number
5. Check Bhoomi data comes back
6. Fix any crashes or errors
```

### WEEK 5-6: Bhoomi API Fine-tuning
```
1. Go to bhoomi.karnataka.gov.in manually
2. Open browser developer tools (F12) → Network tab
3. Do a survey search → observe the actual HTTP request
4. Update bhoomi_service.dart endpoints to match exactly
5. Test with 10 different survey numbers
6. Handle edge cases (no record found, portal down)
```

### WEEK 7-8: AI + Reports
```
1. Test Claude AI analysis with real Bhoomi data
2. Review AI responses for accuracy
3. Tune system prompt in ai_analysis_service.dart
4. Generate test PDFs, check formatting
5. Test PDF share on WhatsApp
```

### WEEK 9-10: Payments
```
1. Create Razorpay account: dashboard.razorpay.com
2. Get key ID and secret
3. Add to .env file
4. Test payment flow (₹1 test payment)
5. Implement ₹99/report payment gate before PDF download
```

### WEEK 11-12: Polish + Launch
```
1. Create app icon (1024x1024 PNG)
   - Use: appicon.co
2. Create screenshots (6 screenshots for Play Store)
3. Create Google Play Developer account (₹1,750 one-time fee)
4. Create App Store Connect account ($99/year for iOS)
5. Build release APK: flutter build apk --release
6. Build iOS: flutter build ipa (need Mac or use Codemagic.io)
7. Submit to Play Store (review: 1-7 days)
8. Submit to App Store (review: 1-3 days)
```

---

## API Keys You Need (Fill in .env)

| Key | Where to Get | Cost |
|-----|-------------|------|
| ANTHROPIC_API_KEY | console.anthropic.com | Pay per use (~₹0.50/analysis) |
| GOOGLE_MAPS_API_KEY | console.cloud.google.com | $200 free/month, then pay |
| RAZORPAY_KEY_ID | dashboard.razorpay.com | Free, 2% per transaction |
| Firebase | console.firebase.google.com | Free (Spark plan) |

---

## Revenue Model

| Stream | Price | Target |
|--------|-------|--------|
| Per Report | ₹99-499 | Individual buyers |
| Monthly Subscription | ₹999/month | Agents, advocates |
| API License to Banks | ₹5,000-50,000/month | Banks doing home loans |
| White Label App | ₹2-10L setup fee | NBFCs, PropTech companies |

---

## Government Compliance (Legal Protection for Your App)

1. **DPDP Act 2023** — India's data privacy law
   - Add Privacy Policy page in app
   - Ask user consent before GPS capture
   - Don't store user data without consent

2. **Disclaimer** — Already in app (app_strings.dart)
   - "For informational purposes only, not legal advice"
   - This protects you from liability

3. **IT Act Section 43A** — Data security
   - Don't store Aadhar/PAN numbers
   - Use Firebase security rules

4. **Bhoomi Data Usage**
   - Data is publicly available government data
   - Safe to use for informational app
   - Do NOT resell raw Bhoomi data as-is

---

## Future Expansion (After Karnataka Stabilizes)

- **More States**: Add Telangana (Dharani), Maharashtra (MahaBhulekh), AP (Meebhoomi)
- **Court Case Check**: Integrate eCourts India API
- **Property Tax**: BBMP/GHMC property tax payment status
- **Building Plan**: BBMP building plan approval status
- **Soil Report**: BBMP/BDA zoning maps
- **NRI Features**: Remote verification for NRIs
- **Lawyer Connect**: Connect users with verified property lawyers
- **AI Document Scan**: Upload sale deed/EC → AI extracts key info

---

## Hours Estimate (If Hiring Developer)

| Task | Hours |
|------|-------|
| Setup + Firebase + API keys | 8 hours |
| Bhoomi API fine-tuning | 16 hours |
| UI polish + animations | 12 hours |
| Payment integration testing | 8 hours |
| Bug fixes + edge cases | 20 hours |
| App Store submission | 8 hours |
| **Total** | **~72 hours = ~2 weeks for a Flutter developer** |

**Solo (you + me):** 3 months studying + implementing step by step

---

## Questions to Ask Me on Monday

1. "Explain the Bhoomi service in detail"
2. "How does the AI analysis prompt work?"
3. "Walk me through the payment flow"
4. "How do I get the Google Maps API key?"
5. "What is Riverpod and how does the provider work?"
6. "How do I test on my Android phone?"

---

## Strategic Vision — Single Player in India

**Goal:** Become the CIBIL of property verification in India.

- CIBIL makes ₹800 Cr/year owning credit scores
- DigiSampatti will own property legal verification
- 60 million property transactions/year in India — 0 digital verification today
- First mover = platform monopoly

**Path:**
- Phase 1 (Month 1-6): Karnataka launch, 1,000 users, no govt meetings needed
- Phase 2 (Month 6-12): Department MoUs (SSLR, RERA, BBMP, eCourts) — officer level
- Phase 3 (Year 2): Minister level meetings (Revenue, Housing, IT ministers Karnataka)
- Phase 4 (Year 3): National — NITI Aayog, Ministry of Housing, RBI Regulatory Sandbox
- Phase 5 (Year 5): CIBIL of property — IPO or acquisition

---

## Company Structure — One Company, Two Products

Register ONE Private Limited company owning both:

**DigiSampatti** — Property legal verification
- Users: Property buyers, NRIs, banks
- Revenue: ₹149/report + lawyer referral + home loan commission

**ARTH_ID / FinSelf** — Financial identity platform
- Users: Traders, self-employed, farmers
- Revenue: Banks pay per verified borrower

**No conflict** — different problems, different users.
**Synergy** — DigiSampatti verifies property + ARTH_ID verifies income = perfect home loan package.
Combined referral to bank earns more commission than either alone.

---

## Minister Meeting Plan

**Phase 2 (Month 6-12) — Officer Level:**
- Commissioner, SSLR (Bhoomi MoU)
- Secretary, RERA Karnataka
- BBMP Commissioner
- NIC Karnataka (eCourts API)

**Phase 3 (Year 2) — Minister Level:**
- Revenue Minister Karnataka
- Housing Minister Karnataka
- IT/BT Minister Karnataka
- Union Housing Minister (national expansion)

**Phase 4 (Year 3) — National:**
- NITI Aayog
- RBI Regulatory Sandbox
- Ministry of Housing & Urban Affairs
- CII / FICCI PropTech conferences

---

## App Name

**DigiSampatti** (renamed from PropertyLegal)
- Tagline: "Know Your Property. Own Your Decision."
- Digi = like DigiLocker, DigiYatra (government trust)
- Sampatti = property in all 22 Indian languages
- Domain: DigiSampatti.in


---

## MONDAY MARCH 23 — START HERE

### Saturday/Sunday BEFORE Monday (Weekend Prep):
1. Install Flutter SDK → flutter.dev/docs/get-started/install/windows
   Extract to C:\flutter → Add C:\flutter\bin to Windows PATH → Restart laptop

2. Install Android Studio → developer.android.com/studio
   Open after install → finish setup wizard → install Android SDK

3. Create these free accounts:
   - Firebase: console.firebase.google.com
   - Google Cloud: console.cloud.google.com
   - Anthropic: console.anthropic.com
   - Razorpay: dashboard.razorpay.com

### Monday:
1. Open Command Prompt → run: flutter doctor → screenshot → send to Claude
2. cd C:\PropertyLegalApp → run: flutter pub get
3. Connect Android phone via USB → enable USB debugging
4. Run: flutter run → tell Claude any errors

### Week 1 Goal: App running on your phone
### Week 2 Goal: Bhoomi API working, PDF generating, payment working
### Week 3 Goal: Lawyer tie-ups, NBFC DSA application
### Week 4 Goal: Play Store submission

