# DigiSampatti — Demo Script & Verification Document
### For Investor / MP Presentation · April 2026

---

## 1. What is DigiSampatti?

DigiSampatti is India's first **automated property verification app** for Karnataka.

A buyer scans or searches a property → the app checks **7 government portals simultaneously** in under 60 seconds → gives a **Risk Score (0-100)** and a **Legal Report PDF**.

**Without DigiSampatti:** A buyer must manually open 7 different government websites, fill forms on each, wait for each to load, and interpret legal documents — taking 2-4 hours, often requiring a lawyer (₹2,000–₹10,000 fees).

**With DigiSampatti:** 60 seconds. ₹149 report. No lawyer needed for initial screening.

---

## 2. What is "Railway"? (For Non-Technical Audience)

Think of Railway as **DigiSampatti's brain in the cloud**.

When you tap "Search Property" in the app:
1. Your phone sends the survey number to Railway
2. Railway opens a real browser (like Chrome) in a data center
3. That browser visits each government website exactly like a human would
4. It fills in the form, reads the result, and sends it back to your phone
5. All 7 portals checked in parallel — done in ~45 seconds

**Analogy:** Hiring 7 clerks who each sit at a government portal computer all day. You call them with a property number, they check their portal, report back in 1 minute. DigiSampatti replaced those 7 clerks with an automated system that costs ₹0 per check (except for CAPTCHA solving at ₹0.10 each).

**Railway cost:** ~₹500/month for the server. Scales automatically with users.

---

## 3. The 7 Portals — What Each One Checks

| # | Portal | What It Verifies | Status |
|---|--------|-----------------|--------|
| 1 | **Bhoomi RTC** (landrecords.karnataka.gov.in) | Who owns the land, what type, any govt acquisition | ✅ Live |
| 2 | **Kaveri EC** (kaveri.karnataka.gov.in) | Encumbrance Certificate — any loans/mortgages registered against this land | ✅ Live* |
| 3 | **RERA Karnataka** (rera.karnataka.gov.in) | Is the builder/project registered? Any complaints? | ✅ Live |
| 4 | **eCourts India** (ecourts.gov.in) | Any active court cases on this property/owner | ✅ Live |
| 5 | **CERSAI** (cersai.org.in) | Central bank mortgage registry — is this property pledged to any bank? | ✅ Live* |
| 6 | **Guidance Value / IGR** (igr.karnataka.gov.in) | Government-set minimum land value — critical for stamp duty | ✅ Live |
| 7 | **FMB Sketch** (landrecords.karnataka.gov.in) | Official land boundary map and survey sketch | ✅ Live* |

*Live but dependent on government portal uptime (these portals have scheduled maintenance)

---

## 4. How to VERIFY the Data is Accurate — Step by Step

### Live Verification Process (Show this in demo)

**Step 1: Search a property in DigiSampatti**
- Open app → Scan/Search → Enter Survey No. 67, District: Bengaluru Urban
- Wait ~45 seconds for all 7 portals to check

**Step 2: Verify Bhoomi RTC manually**
- Open browser → go to `landrecords.karnataka.gov.in`
- Enter same survey number, same taluk
- **Compare:** The owner name, land type, and area shown in DigiSampatti matches exactly what Bhoomi shows

**Step 3: Verify eCourts manually**
- Open browser → go to `ecourts.gov.in`
- Search same party name / district
- **Compare:** DigiSampatti shows "No cases found" — eCourts confirms the same

**Step 4: Verify Guidance Value**
- Open browser → go to `igr.karnataka.gov.in`
- Select Bengaluru North
- **Compare:** DigiSampatti shows ₹6,000/sqft — IGR portal confirms the same value

**Conclusion:** DigiSampatti data = exact data from government portals. We do not generate or estimate data. We only **automate the reading**.

---

## 5. Fraud Detection — What DigiSampatti Catches

DigiSampatti detects these common Karnataka property frauds:

| Fraud Type | How DigiSampatti Catches It |
|------------|----------------------------|
| **Fake ownership** | RTC owner name mismatch with seller's name |
| **Hidden mortgage** | CERSAI shows bank charge even if seller says "clear title" |
| **Double sale** | EC shows previous sale deed registered to another buyer |
| **Government land fraud** | RTC shows land type as "Government" / "Forest" / "Revenue site" |
| **Unauthorized layout** | RERA not registered, layout not in BDA/BBMP records |
| **Court order on property** | eCourts shows injunction or dispute against the property |
| **Guidance value fraud** | Seller quotes price below guidance value — illegal, bank won't loan |

**The score:** 100 = all clean. Below 60 = do not buy without a lawyer. Below 40 = high fraud risk.

---

## 6. Full User Flow — From Scan to Report

```
[User at Property Site]
        ↓
[Opens DigiSampatti]
        ↓
[Camera Scan OR Manual Search]
   • Camera: AI reads RTC document → auto-fills survey number, owner, district
   • Manual: User types survey number
        ↓
[App sends to Railway backend]
        ↓
[Railway checks 7 portals in parallel — ~45 seconds]
   Portal 1: Bhoomi RTC    ──→ Owner, land type, area
   Portal 2: Kaveri EC     ──→ Any loans/transfers in 30 years
   Portal 3: RERA          ──→ Builder registration status
   Portal 4: eCourts       ──→ Active court cases
   Portal 5: CERSAI        ──→ Bank mortgage registry
   Portal 6: IGR           ──→ Guidance value
   Portal 7: FMB Sketch    ──→ Land boundary map
        ↓
[AI Analysis — Claude AI reads all 7 results]
   → Generates Risk Score (0-100)
   → Lists fraud flags
   → "What to DO" and "What NOT to DO"
   → Bank loan eligibility
        ↓
[User pays ₹149 → Downloads PDF Report]
   → Share with lawyer, bank, or family on WhatsApp
```

---

## 7. Revenue Model

| Product | Price | When |
|---------|-------|------|
| Individual Report | ₹149 | Per search |
| Basic Plan | ₹99/report | Bulk |
| Standard | ₹299/month | 5 reports |
| Premium | ₹699/month | Unlimited |
| NRI Pro | ₹999/month | NRI + expert consultation |

**Payment:** Instamojo (active now) — UPI, card, net banking all accepted.

---

## 8. Current Traction

- App built and deployed: April 2026
- Backend: Railway cloud server (live)
- Device tested: VIVO V2318, Android
- Payment: Instamojo live keys configured
- Play Store: Closed testing (12 testers being added)

---

## 9. Why Now?

- Karnataka has **₹2.3 lakh crore** in annual property transactions
- **35%** of property disputes involve fraud or unclear title
- Current solution: Hire a lawyer (₹2,000–₹10,000, takes 1-2 weeks)
- DigiSampatti: ₹149, 60 seconds, on your phone
- No competitor automates all 7 portals — they either show PDF guides or send agents

---

*DigiSampatti — Verify Before You Buy*
*Contact: [your contact] | digi-sampatti.netlify.app*
