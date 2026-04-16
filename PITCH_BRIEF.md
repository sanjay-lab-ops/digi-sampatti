# DigiSampatti — Official Pitch Brief
**Property Intelligence Platform · Made in India · All-India Coverage**

---

## The Problem We Solve

India has **₹300 lakh crore** locked in real estate. Yet every year:
- **70,000+ property fraud cases** are registered (NCRB 2023)
- Buyers pay crores on properties with hidden mortgages, court cases, agricultural land restrictions
- A document check that should take hours takes **3–6 months** of running between offices
- **NRIs lose ₹8,000+ Cr** annually to property fraud from abroad
- Even legal professionals miss encumbrances because portals are state-specific

**Current process:** Buyer → Lawyer → Sub-Registrar Office → Revenue Dept → EC search → Court check → RERA check — each step requires a physical visit, costs ₹10,000–₹50,000, and takes weeks.

---

## What DigiSampatti Does

**One app. Upload any property document. Get a verified legal report in minutes.**

### Core Pipeline
```
Buyer uploads RTC / Sale Deed / EC / Agreement
          ↓
Claude AI reads document (OCR + extraction)
          ↓
Checks 8 government portals simultaneously:
  • Bhoomi (RTC / land records)
  • Kaveri (Encumbrance Certificate)
  • eCourts (court cases & injunctions)
  • BBMP e-Aasthi (Khata verification)
  • CERSAI (mortgage registry)
  • RERA (builder & project check)
  • IGR (Guidance Value)
  • BDA / BMRDA (layout approval)
          ↓
30+ rule engine: agricultural land, injunction,
  DC conversion, Raja Kaluve buffer, lake bed FTL,
  mutation status, encumbrance-free status
          ↓
AI Legal Verdict: DO BUY / CAUTION / DO NOT BUY
Risk Score 0–100 · Law citations · Next steps
```

**Time: 3–7 minutes. Cost: ₹499/report.**

---

## Features Built (Live in App)

| Feature | Description |
|---|---|
| Document OCR | Reads RTC, EC, sale deed, agreements in any language |
| Risk Score | 0–100 AI score with DO BUY / CAUTION / DO NOT BUY |
| All India Coverage | Karnataka, Tamil Nadu, Maharashtra, AP, Telangana, Kerala, UP, Delhi, Gujarat, and 18 more states + UTs |
| Guidance Value | Lookup for all 30 Karnataka districts + 15 other states. Browse by District → Taluk → Area |
| Property Marketplace | Amazon-style listings by locality — buyer browses, contacts seller, initiates escrow |
| Digital Escrow | Advance held safely (NBFC/RazorpayX) — released only after docs verified. 0.5% fee |
| Seller KYC | PAN format check, name match, trust score |
| ARTH ID | Home loan eligibility — know buying power before choosing property |
| Financial Tools | Property tax (all states), EMI, stamp duty (14 states), total cost, loan eligibility — all inline |
| SRO Locator | Find Sub-Registrar Office with GPS |
| Field Inspection | Book on-ground GPS visit — agent visits, photographs, 48hr report |
| e-Sign | Aadhaar-based digital signing of agreement |
| Document Locker | Encrypted cloud storage for all property papers |
| Post-Purchase Tracker | Mutation alerts, tax reminders, annual check, fraud alerts |
| NRI Module | FEMA compliance, TDS 22.88%, repatriation, DTAA, PoA for 15 countries |
| Court Case Check | eCourts integration — search by owner name + district |
| Lawyer Connect | Empanelled lawyers per district, Lok Adalat guidance |
| Title Insurance | HDFC Ergo referral — 8–12% commission to DigiSampatti |
| Screenshot Protection | FLAG_SECURE on all report screens — data cannot be copied or screenshotted |
| Broker Zone | Dedicated professional portal for agents |

---

## Business Model

| Revenue Stream | Price | Notes |
|---|---|---|
| Per Report | ₹499 / report | Individual buyers, one-time check |
| Monthly Unlimited | ₹1,999 / month | Frequent buyers, investors |
| Agent Subscription | ₹4,999 / month | Brokers — 50 reports/month |
| Field Inspection | ₹2,499 / visit | GPS photos, 48hr report |
| Escrow Fee | 0.5% of advance | Split 50/50 buyer & seller |
| Title Insurance | 8–12% commission | HDFC Ergo referral |
| Lawyer Referral | ₹2,000 / connect | Bar Council empanelled lawyers |
| Developer API | ₹50,000 / month | Banks, NBFCs, builders |

**Target:** 10,000 reports/month by Month 12 = ₹49.9 L/month GMV

---

## Escrow Structure (for ₹2 Cr Property Example)

| Component | Amount | Notes |
|---|---|---|
| Token (non-negotiable minimum) | ₹2,00,000 | 1% of deal, min ₹1L. Paid immediately. Reserves property. |
| Advance (standard 10%, negotiable) | ₹20,00,000 | Held in DS escrow. Released only after document verification. |
| Balance at registration | ₹1,78,00,000 | Paid at SRO on deed registration day. |
| DigiSampatti Escrow Fee | ₹1,00,000 | 0.5% of advance — split equally buyer & seller |
| **Total buyer pays upfront** | **₹22,00,000** | Token + Advance + Fee |

**If deal falls through due to bad documents:** Advance returned in 7 business days.
**If buyer backs out without reason:** Token is forfeited to seller.

---

## What DigiSampatti Does NOT Do

- Does **not scrape** government portals illegally
- Does **not store** raw Aadhaar / PAN numbers
- Is **automating** portal access, not bypassing it
- Anticaptcha / portal automation is used only for legitimate user-initiated lookups
- All document analysis is run through Claude AI with explicit user consent

---

## Why Now — Regulatory Tailwind

- **RERA 2016**: Mandatory builder registration — data now available
- **Digitisation drive**: Bhoomi, Kaveri, CERSAI all have public APIs
- **UPI + RazorpayX**: Digital escrow is now technically feasible
- **NeSL + CERSAI**: Central mortgage registry — all mortgages traceable
- **Digital India Mission**: Govt wants private sector to build on top of land records

---

## Team & Technology

- Flutter Android app (iOS version ready Q3 2025)
- Python/Flask backend — Claude Sonnet 4.6 AI (Anthropic)
- Firebase Auth, Firestore (scalable to 1M users)
- AES-256 encryption for all stored documents
- SOC 2 Type II compliance roadmap (Q4 2025)

---

## Ask from Officials / Partners

**For Sub-Registrar Offices / Revenue Dept:**
- API access to guidance value updates (we display, not scrape)
- WhatsApp alert integration for mutation completion

**For Banks / NBFCs:**
- Property pre-verification API before loan disbursement
- Integration fee: ₹50,000/month per bank

**For RERA Authority:**
- White-label property check widget for official RERA website
- Reduces fraud complaints reaching RERA office

**For HDFC Ergo / Other Insurers:**
- Title insurance co-referral — we identify clean titles, you insure
- Revenue share: 8–12% of premium

---

## Contact

**App:** DigiSampatti (available on Play Store — search "DigiSampatti")
**GitHub:** github.com/sanjay-lab-ops/digi-sampatti
**Email:** jrjeethu018@gmail.com

*"Not just checking documents — verifying futures."*
