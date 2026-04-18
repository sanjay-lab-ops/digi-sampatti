# DigiSampatti — Official Pitch Brief
**India's First End-to-End Property Intelligence & Transaction Platform**
*Built for Buyers · Sellers · Lawyers · Banks · NRIs*

---

## The Problem

India has **₹300 lakh crore** locked in real estate. Every year:

- **70,000+ property fraud cases** (NCRB 2023) — buyers lose crores to hidden mortgages, forged deeds, court injunctions
- A document check that takes 3 minutes in DigiSampatti takes **3–6 months** the traditional way
- **NRIs lose ₹8,000 Cr/year** to fraud from abroad — no way to verify remotely
- First-time buyers have zero guidance — they don't know what RTC, EC, Khata, CERSAI even mean
- Sellers with clean documents can't prove it — buyers distrust every listing

**Nobody protects the buyer. Nobody helps the seller prove honesty. Nobody holds money safely between them.**

---

## What DigiSampatti Does

**One app that guides both buyer and seller through the entire property transaction — from first search to final registration.**

### The 7-Stage Journey (Every Transaction)

```
STAGE 1 — CHECK      Upload documents → AI reads → 30+ fraud checks → Risk Score 0–100
STAGE 2 — INSPECT    Book field agent → GPS visit → 48hr on-ground report
STAGE 3 — LEGAL      e-Courts check → lawyer connect → legal opinion
STAGE 4 — FINANCE    ARTH ID loan check → EMI calculator → stamp duty → total cost
STAGE 5 — PROTECT    Title insurance → document locker → time-limited key sharing
STAGE 6 — TRANSACT   e-Sign agreement → digital escrow (advance held safely)
STAGE 7 — OWN        Mutation tracker → tax alerts → post-sale fraud monitoring
```

**Every stage is a screen in the app. The user is never confused about what to do next.**

---

## Core Product — Property Risk Report

```
Buyer photographs any document (RTC / EC / Sale Deed / Agreement)
                    ↓
     Claude AI reads it (OCR + field extraction)
                    ↓
     Checks 8 government portals simultaneously:
       Bhoomi · Kaveri · eCourts · BBMP e-Aasthi
       CERSAI · RERA · IGR · BDA/BMRDA
                    ↓
     30+ rule engine checks:
       Agricultural land restriction · DC conversion status
       Raja Kaluve / lake bed buffer · Injunction / attachment
       Encumbrance (30 years) · Khata type (A/B) · Mutation pending
       RERA registration · Builder credibility · Court cases
                    ↓
     AI Legal Verdict:  ✅ DO BUY  /  ⚠ CAUTION  /  ❌ DO NOT BUY
     Risk Score 0–100 · Law citations · Recommended next steps
```

**Time: 3–7 minutes. Cost: ₹499.**

---

## Buyer Flow (New)

**Zomato-style property discovery — no confusing dropdowns.**

1. **Home screen** — Personalized greeting, Property Tax Estimator, Know Your Documents guide, 5 quick tools
2. **Browse** — Search by locality + keyword (3BHK, BMRDA, near school) → filter by property type
3. **Two-tier access:**
   - **₹99 Basic** — Owner name, location, document score, doc summary (no phone)
   - **₹499 Full** — All 7 portals, AI report, seller contact, PDF, document lock access
4. **Moderated contact** — WhatsApp / video call (phone only after ₹499) — no direct loopholes
5. **Escrow → Sign → Own** — guided through remaining stages

---

## Seller Flow (New)

**Step-by-step listing in 5 screens — no confusion.**

1. **Location** — State → District → Taluk → Village
2. **Property details** — Type (6 options), area, price, description
3. **Document upload** — CIBIL-style Document Score (0–100) based on weighted checklist
   - RTC (20 pts) + EC (20 pts) + Khata (15 pts) + Sale Deed (15 pts) + 6 more docs
   - Guidelines shown for every document (what it is, where to get it, what to check)
4. **GPS + Photos** — Stand at property, capture coordinates + up to 10 photos
5. **Pricing** — ₹99 Basic (30-day listing) or ₹499 Full Service (90-day + Verified Badge + AI report + leads)

**The Document Score works like CIBIL for properties — higher score = more buyer trust = faster sale.**

---

## Document Key System (Unique Feature)

**Time-limited, tamper-proof document sharing — like a hotel key card for your property files.**

- Seller generates an **8-character access key** (e.g. `ABCD EFGH`) from Document Locker
- Sets: who it's for (bank/lawyer/buyer), purpose, validity (24h / 48h / 7d / 30d)
- Key auto-expires — no manual revoke needed
- **Chain-of-custody hash**: SHA-256 of all documents at key issue time
  - When buyer opens key → we re-hash current docs and compare
  - If different → warning: "Documents were modified after this key was issued"
  - In production: hash anchored on blockchain (Ethereum/Polygon) for immutable proof
- Seller can also instantly revoke any key

**Use cases:** Share with SBI for loan sanction, Advocate for legal opinion, buyer for due diligence — each gets a separate key with different expiry.

---

## Digital Escrow (MVP — RBI-Compliant Architecture)

**Advance money held safely. Released only when both parties confirm.**

```
FSM States:
INIT → FUNDED → DOC_VERIFIED → BUYER_APPROVED → RELEASED
                                              ↘ DISPUTE → REFUND
```

| State | Action |
|---|---|
| INIT | Buyer gets ICICI virtual account details. Transfers advance via IMPS/NEFT |
| FUNDED | Seller uploads all documents to locker. Buyer runs AI check |
| DOC_VERIFIED | Buyer reviews report, inspection findings, all uploaded docs |
| BUYER_APPROVED | Both parties sign agreement via Aadhaar e-Sign |
| RELEASED | Advance released to seller. Balance at SRO registration |
| DISPUTE | Funds frozen. DigiSampatti mediates within 5 business days |
| REFUND | Advance returned to buyer after dispute resolution |

**Penalty engine:** Seller defaults (forged docs, no-show) → 100–200% of advance forfeited. Buyer defaults (withdrawal after inspection) → 25–50% forfeited. All agreed at signing per Indian Contract Act.

---

## Features Built (Live in App)

| Feature | Status |
|---|---|
| Document OCR + AI Analysis | ✅ Live |
| Risk Score 0–100 (DO BUY / CAUTION / DO NOT BUY) | ✅ Live |
| 8 government portal checks | ✅ Live |
| Buyer home — personalized, 7-stage guided | ✅ Live |
| Zomato-style property search + keyword filter | ✅ Live |
| ₹99 basic / ₹499 full service buyer tiers | ✅ Live |
| Seller 5-step listing flow | ✅ Live |
| Document Score (CIBIL-like, 0–100) | ✅ Live |
| Document Locker with key system | ✅ Live |
| Time-limited key sharing + tamper detection | ✅ Live |
| Digital Escrow (FSM — 6 states) | ✅ Live |
| Penalty engine (buyer + seller defaults) | ✅ Live |
| e-Sign (Aadhaar-based) | ✅ Live |
| Field Inspection booking | ✅ Live |
| ARTH ID — loan eligibility | ✅ Live |
| Financial tools (EMI, stamp duty, tax, total cost) | ✅ Live |
| Guidance Value (all India) | ✅ Live |
| NRI Module (FEMA, TDS, repatriation) | ✅ Live |
| eCourts — court case check by owner name | ✅ Live |
| SRO Locator | ✅ Live |
| Post-purchase tracker (mutation, tax, fraud alerts) | ✅ Live |
| Broker Zone | ✅ Live |
| Report history + PDF generation | ✅ Live |

---

## Business Model

| Revenue Stream | Price | Target Volume (Month 12) |
|---|---|---|
| Buyer property report | ₹499 / report | 8,000/month = ₹39.9L |
| Buyer basic view | ₹99 / view | 20,000/month = ₹19.8L |
| Seller basic listing | ₹99 / listing | 5,000/month = ₹4.95L |
| Seller full service | ₹499 / listing | 2,000/month = ₹9.98L |
| Field inspection | ₹2,499 / visit | 500/month = ₹12.5L |
| Escrow fee | 0.25% of advance | 200 deals/month = ~₹15L |
| Lawyer referral | ₹2,000 / connect | 300/month = ₹6L |
| Title insurance | 8–12% commission | 100/month = ₹8L |
| Bank/NBFC API | ₹50,000/month | 5 banks = ₹2.5L |

**Month 12 GMV target: ₹1.18 Cr/month**

---

## Competitive Moat

| What others do | What DigiSampatti does |
|---|---|
| 99acres / MagicBricks — list properties, no verification | Verify AND list — buyer knows the property is clean before paying |
| Traditional lawyer — ₹20,000–₹50,000, 4–6 weeks | AI report in 7 minutes for ₹499 |
| No escrow product exists for individual property buyers | FSM escrow with penalty engine and dispute resolution |
| Sellers have no way to prove document quality | Document Score + Verified Badge — like CIBIL for properties |
| NRIs have no remote verification tool | Full NRI module — FEMA, TDS, remote PoA, 15 countries |

---

## Why Now

- RERA 2016 — all builder data is now public
- Bhoomi, Kaveri, CERSAI — digital land records accessible
- UPI + bank virtual accounts — digital escrow finally feasible
- Claude AI (Anthropic) — first AI good enough to read Indian legal documents reliably
- ₹300 lakh crore market with zero trusted verification layer

---

## Tech Stack

- **App:** Flutter (Android live, iOS Q3 2025)
- **AI:** Claude Sonnet 4.6 (Anthropic) — document OCR + legal analysis
- **Backend:** Python/Flask + Firebase Firestore
- **Escrow:** ICICI Bank virtual accounts (RBI-compliant)
- **Payments:** Razorpay / Instamojo / UPI direct
- **Document Keys:** SHA-256 hash chain (Ethereum anchor in production)
- **Security:** AES-256, FLAG_SECURE on report screens, DPDP Act 2023 compliant

---

## Ask

**For Banks / NBFCs:** Property pre-verification API before loan disbursement (₹50,000/month)
**For RERA Authority:** White-label property check widget for official portal
**For Sub-Registrar Offices:** API access to guidance value + mutation completion alerts
**For Insurers (HDFC Ergo):** Title insurance co-referral — 8–12% revenue share
**For Investors:** Seed round — scaling portal automation, ML risk model, iOS launch

---

## Contact

**Email:** jrjeethu018@gmail.com
**App:** DigiSampatti (Android APK available)

*"Not just checking documents — verifying futures."*
