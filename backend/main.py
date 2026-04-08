"""
DigiSampatti Backend Scraper
============================
Automates ALL Karnataka government property portals:

  1. Dishank / Bhoomi  → GPS → Survey Number, RTC
  2. Kaveri Online      → Encumbrance Certificate (EC)
  3. RERA Karnataka     → Project / promoter check
  4. eCourts            → Court case search
  5. BBMP               → Khata / property tax
  6. CERSAI             → Mortgage / lien check
  7. IGR Karnataka      → Guidance value, stamp duty
  8. FMB (Sketch)       → Land sketch / boundary map

Technique: Playwright headless browser + anticaptcha.com for CAPTCHAs
Deploy:    Google Cloud Run  (asia-south1, ~₹0/month free tier)
Cost:      ~₹0.10 per CAPTCHA solve (anticaptcha.com)
"""

from __future__ import annotations

import os
import re
import time
import asyncio
import logging
from pathlib import Path
from typing import Optional

import httpx
from flask import Flask, request, jsonify
from playwright.async_api import async_playwright, Page, Browser

# ─── Load .env from parent directory (digi-sampatti/.env) ─────────────────────
def _load_env():
    # Try parent dir (digi-sampatti/.env) then current dir
    for env_path in [
        Path(__file__).resolve().parent.parent / ".env",
        Path(__file__).resolve().parent / ".env",
    ]:
        if env_path.exists():
            for line in env_path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, _, v = line.partition("=")
                    k, v = k.strip(), v.strip()
                    # Always override — env var might be "" from a previous blank load
                    if v:
                        os.environ[k] = v
            break

_load_env()

# ─── Optional Firebase (skip if no creds) ─────────────────────────────────────
try:
    import firebase_admin
    from firebase_admin import credentials, firestore as fs
    cred_path = os.environ.get("FIREBASE_CREDS", "serviceAccount.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = fs.client()
    else:
        db = None
except Exception:
    db = None

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("digisampatti")

app = Flask(__name__)
PORT = int(os.environ.get("PORT", 8080))

def _anticaptcha_key() -> str:
    """Read key at call time so debugger reloader picks up .env correctly."""
    k = os.environ.get("ANTICAPTCHA_KEY", "")
    if not k:
        _load_env()
        k = os.environ.get("ANTICAPTCHA_KEY", "")
    return k

BROWSER_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    "Accept": "application/json, text/html, */*",
    "Accept-Language": "en-IN,en;q=0.9,kn;q=0.8",
}


# ══════════════════════════════════════════════════════════════════════════════
# CAPTCHA SOLVER
# ══════════════════════════════════════════════════════════════════════════════

async def solve_recaptcha(site_key: str, page_url: str) -> Optional[str]:
    key = _anticaptcha_key()
    if not key:
        return None
    async with httpx.AsyncClient(timeout=130) as c:
        r = await c.post("https://api.anti-captcha.com/createTask", json={
            "clientKey": key,
            "task": {"type": "RecaptchaV2TaskProxyless",
                     "websiteURL": page_url, "websiteKey": site_key},
        })
        d = r.json()
        if d.get("errorId", 1) != 0:
            return None
        task_id = d["taskId"]
        for _ in range(24):
            await asyncio.sleep(5)
            res = await c.post("https://api.anti-captcha.com/getTaskResult",
                               json={"clientKey": key, "taskId": task_id})
            rd = res.json()
            if rd.get("status") == "ready":
                return rd["solution"]["gRecaptchaResponse"]
    return None


async def inject_captcha_token(page: Page, token: str):
    """Inject solved reCAPTCHA token into page."""
    await page.evaluate(f"""
        document.getElementById('g-recaptcha-response') &&
        (document.getElementById('g-recaptcha-response').innerHTML = '{token}');
        typeof ___grecaptcha_cfg !== 'undefined' &&
        Object.entries(___grecaptcha_cfg.clients).forEach(([k,v]) => {{
            const cb = v[''] && v['']['callback'];
            if (typeof cb === 'function') cb('{token}');
        }});
    """)


# ══════════════════════════════════════════════════════════════════════════════
# CACHE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def cache_get(collection: str, key: str, ttl_days: int = 7) -> Optional[dict]:
    if not db:
        return None
    try:
        doc = db.collection(collection).document(key).get()
        if doc.exists:
            d = doc.to_dict()
            if time.time() - d.get("_ts", 0) < 86400 * ttl_days:
                return d
    except Exception:
        pass
    return None


def cache_set(collection: str, key: str, data: dict):
    if db:
        try:
            data["_ts"] = time.time()
            db.collection(collection).document(key).set(data)
        except Exception:
            pass


# ══════════════════════════════════════════════════════════════════════════════
# 1. DISHANK / BHOOMI — GPS → Survey Number
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/survey-from-gps", methods=["POST"])
def survey_from_gps():
    d = request.get_json()
    lat, lon = d.get("lat"), d.get("lon")
    if not lat or not lon:
        return jsonify({"error": "lat/lon required"}), 400

    key = f"gps_{round(lat,4)}_{round(lon,4)}"
    cached = cache_get("gps_survey_cache", key, ttl_days=30)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_dishank_gps(lat, lon))
    if result:
        cache_set("gps_survey_cache", key, result)
    return jsonify(result or {"survey_number": None})


async def _dishank_gps(lat: float, lon: float) -> dict:
    endpoints = [
        f"https://dishank.karnataka.gov.in/rtcRequest/getSurveyDetailsByGPS?latitude={lat}&longitude={lon}",
        f"https://bhoomi.karnataka.gov.in/bhoomi/GISMap/getSurveyByLatLon.do?lat={lat}&lon={lon}",
    ]
    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=15, follow_redirects=True) as c:
        for url in endpoints:
            try:
                r = await c.get(url)
                if r.status_code == 200:
                    data = r.json()
                    sno = data.get("surveyNo") or data.get("survey_number") or data.get("sno")
                    if sno:
                        return {
                            "survey_number": str(sno),
                            "district": data.get("district") or data.get("districtName"),
                            "taluk":    data.get("taluk")    or data.get("talukName"),
                            "hobli":    data.get("hobli")    or data.get("hobliName"),
                            "village":  data.get("village")  or data.get("villageName"),
                            "confidence": 0.95,
                            "source": "dishank",
                        }
            except Exception as e:
                logger.warning(f"Dishank GPS {url}: {e}")
    return {}


# ══════════════════════════════════════════════════════════════════════════════
# 2. BHOOMI — RTC (Record of Rights, Tenancy & Crops)
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/rtc", methods=["POST"])
def fetch_rtc():
    d = request.get_json()
    district  = d.get("district", "")
    taluk     = d.get("taluk", "")
    hobli     = d.get("hobli", "")
    village   = d.get("village", "")
    survey_no = d.get("survey_number", "")
    if not district or not survey_no:
        return jsonify({"error": "district and survey_number required"}), 400

    key = f"rtc_{district}_{taluk}_{village}_{survey_no}".lower().replace(" ", "_")
    cached = cache_get("rtc_cache", key, ttl_days=7)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_bhoomi_rtc(district, taluk, hobli, village, survey_no))
    if result:
        cache_set("rtc_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "Bhoomi portal unavailable"}), 503


async def _scrape_bhoomi_rtc(district, taluk, hobli, village, survey_no) -> Optional[dict]:
    # Real URL: bhoomi.karnataka.gov.in redirects → landrecords.karnataka.gov.in/Service2
    # Uses ASP.NET cascading dropdowns, no CAPTCHA
    async with async_playwright() as p:
        browser: Browser = await p.chromium.launch(headless=True)
        page: Page = await browser.new_page(extra_http_headers=BROWSER_HEADERS)
        try:
            await page.goto("https://landrecords.karnataka.gov.in/Service2",
                            wait_until="networkidle", timeout=30000)

            # Normalize district name to match dropdown (all-caps Karnataka names)
            dist_map = {
                "bangalore urban": "BENGALURU",
                "bengaluru urban": "BENGALURU",
                "bangalore south": "BENGALURU SOUTH",
                "bengaluru south": "BENGALURU SOUTH",
                "bangalore rural": "BANGALORE RURAL",
                "bengaluru rural": "BANGALORE RURAL",
                "mysuru": "MYSORE", "mysore": "MYSORE",
                "belagavi": "BELAGAVI", "belgaum": "BELAGAVI",
                "hubballi-dharwad": "DHARWAD", "dharwad": "DHARWAD",
                "mangaluru": "DAKSHINA KANNADA", "dakshina kannada": "DAKSHINA KANNADA",
                "shivamogga": "SHIVAMOGGA", "tumakuru": "TUMAKURU",
                "kalaburagi": "KALABURAGI", "raichur": "RAICHUR",
                "ballari": "BALLARI", "vijayapura": "VIJAYAPURA",
                "chikkaballapur": "CHIKKABALLAPUR", "kolar": "KOLAR",
                "ramanagara": "RAMANAGARA", "mandya": "MANDYA",
                "hassan": "HASSAN", "kodagu": "KODAGU",
                "udupi": "UDUPI", "uttara kannada": "UTTAR KANNADA",
                "chitradurga": "CHITRADURGA", "davanagere": "DAVANAGERE",
                "gadag": "GADAG", "haveri": "HAVERI",
                "bidar": "BIDAR", "koppal": "KOPPAL",
                "chikkamagaluru": "CHIKKAMAGALURU", "bagalkote": "BAGALKOTE",
                "yadgir": "YADAGIR", "vijayanagara": "VIJAYANAGARA",
            }
            dist_label = dist_map.get(district.lower(), district.upper())

            # Select district — options are in initial HTML, no AJAX needed
            await page.select_option('#ctl00_MainContent_ddlCDistrict', label=dist_label)
            await page.wait_for_timeout(2000)

            # Taluk name normalization (dropdown uses UPPERCASE with hyphens)
            taluk_map = {
                "bangalore north": "BANGALORE-NORTH",
                "bangalore south": "BANGALORE-SOUTH",
                "bangalore east":  "BANGALORE-EAST",
                "anekal": "ANEKAL",
                "yalahanka": "YALAHANKA",
                "yelahanka": "YALAHANKA",
                "devanahalli": "DEVANAHALLI",
                "hoskote": "HOSKOTE",
                "doddaballapur": "DODDABALLAPUR",
                "nelamangala": "NELAMANGALA",
                "mysuru": "MYSURU", "mysore": "MYSORE",
                "hunsur": "HUNSUR", "periyapatna": "PERIYAPATNA",
                "mangaluru": "MANGALURU", "mangalore": "MANGALURU",
                "belagavi": "BELAGAVI", "belgaum": "BELAGAVI",
                "hubli": "HUBLI", "dharwad": "DHARWAD",
                "tumakuru": "TUMAKURU", "shivamogga": "SHIVAMOGGA",
                "hassan": "HASSAN", "mandya": "MANDYA",
            }
            taluk_label = taluk_map.get(taluk.lower(), taluk.upper()) if taluk else ""

            async def wait_and_select(sel_id, label, fallback_label=None, timeout=12000):
                """Wait for ASP.NET AJAX to populate dropdown, then select.
                Tries exact match first, then partial/prefix match."""
                try:
                    await page.wait_for_function(
                        f"document.querySelector('#{sel_id}') && "
                        f"document.querySelector('#{sel_id}').options.length > 1",
                        timeout=timeout
                    )
                    # Get all available option texts
                    opts = await page.evaluate(
                        f"Array.from(document.querySelector('#{sel_id}').options).map(o=>o.text)"
                    )
                    logger.info(f"RTC {sel_id} options: {opts}")

                    # Find best match: exact, then starts-with, then contains
                    ul = label.upper()
                    best = None
                    for o in opts:
                        if o.upper() == ul:
                            best = o; break
                    if not best:
                        for o in opts:
                            if o.upper().startswith(ul):
                                best = o; break
                    if not best and fallback_label:
                        fl = fallback_label.upper()
                        for o in opts:
                            if o.upper().startswith(fl):
                                best = o; break
                    if not best:
                        for o in opts:
                            if ul in o.upper():
                                best = o; break

                    if best:
                        await page.select_option(f"#{sel_id}", label=best)
                        logger.info(f"RTC {sel_id} selected: {best}")
                        return True
                    else:
                        logger.warning(f"RTC {sel_id}: no match for '{label}' in {opts}")
                        return False
                except Exception as e:
                    logger.warning(f"RTC select {sel_id} ({label}): {e}")
                    return False

            if taluk_label:
                ok = await wait_and_select('ctl00_MainContent_ddlCTaluk', taluk_label)
                if ok:
                    logger.info(f"RTC taluk selected: {taluk_label}")
                    await page.wait_for_timeout(2000)

            if hobli:
                ok = await wait_and_select(
                    'ctl00_MainContent_ddlCHobli', hobli.upper(), hobli, timeout=10000)
                if ok:
                    await page.wait_for_timeout(2000)

            if village:
                ok = await wait_and_select(
                    'ctl00_MainContent_ddlCVillage', village.upper(), village, timeout=10000)
                if ok:
                    await page.wait_for_timeout(1000)

            # Survey number: set via JS and dispatch input event so ASP.NET sees the change
            await page.evaluate(f'''
                var el = document.getElementById("ctl00_MainContent_txtSurvey");
                if (el) {{
                    el.readOnly = false;
                    el.value = "{survey_no}";
                    el.dispatchEvent(new Event("change", {{bubbles: true}}));
                    el.dispatchEvent(new Event("input", {{bubbles: true}}));
                }}
            ''')
            await page.wait_for_timeout(500)

            # Step 1: Click "Go" to validate survey number entry
            go_btn = await page.query_selector('#ctl00_MainContent_btnCGo')
            if go_btn:
                await go_btn.click()
                await page.wait_for_timeout(2000)

            # Step 2: Click "Fetch details" (enabled after Go)
            try:
                await page.wait_for_selector('#ctl00_MainContent_btnCFetchDetails:not([disabled])', timeout=6000)
                fetch_btn = await page.query_selector('#ctl00_MainContent_btnCFetchDetails')
                if fetch_btn:
                    await fetch_btn.click()
                    await page.wait_for_load_state("networkidle", timeout=20000)
            except Exception:
                pass

            html = await page.content()
            logger.info(f"Bhoomi RTC page length: {len(html)}")
            # Log a snippet to see what data the page returned
            snippet = re.sub(r'<[^>]+>', ' ', html)
            snippet = re.sub(r'\s+', ' ', snippet).strip()
            logger.info(f"Bhoomi RTC text snippet: {snippet[2000:3000]}")
            return _parse_rtc(html, district, taluk, hobli, village, survey_no)
        except Exception as e:
            logger.error(f"Bhoomi RTC: {e}")
            return None
        finally:
            await browser.close()


def _parse_rtc(html, district, taluk, hobli, village, survey_no) -> dict:
    # Strip tags to get clean text for label:value extraction
    text = re.sub(r'<[^>]+>', ' ', html)
    text = re.sub(r'\s+', ' ', text)

    def after(label):
        """Find value after a label text in the page text."""
        patterns = [
            rf'{re.escape(label)}\s*:\s*([^\n:]{2,100}?)(?:\s{{2,}}|\s*:)',
            rf'{re.escape(label)}\s+([A-Z][^\s:]+(?:\s+[A-Z][^\s:]+){{0,5}})',
        ]
        for p in patterns:
            m = re.search(p, text, re.IGNORECASE)
            if m:
                v = m.group(1).strip().rstrip(':,')
                if v and v.lower() not in ('select', 'n/a', ''):
                    return v
        return ""

    def find_html(pattern):
        m = re.search(pattern, html, re.IGNORECASE | re.DOTALL)
        return m.group(1).strip() if m else ""

    # Try HTML-based extraction first (table cells)
    owner    = find_html(r'(?:Name of Owner|Owner Name|ಮಾಲೀಕ)[^<]*</(?:td|th)>\s*<(?:td|th)[^>]*>([^<]{3,100})')
    extent   = find_html(r'(?:Total Extent|Extent|ವಿಸ್ತಾರ)[^<]*</(?:td|th)>\s*<(?:td|th)[^>]*>([0-9][^<]{0,40})')
    land_use = find_html(r'(?:Land Use|Nature of Land|ಜಮೀನು)[^<]*</(?:td|th)>\s*<(?:td|th)[^>]*>([^<]{2,60})')
    kharab   = find_html(r'(?:kharab|Karab)[^<]*</(?:td|th)>\s*<(?:td|th)[^>]*>([^<]{2,50})')
    liab     = find_html(r'(?:Liabilit|Encumbrance|Loan)[^<]*</(?:td|th)>\s*<(?:td|th)[^>]*>([^<]{2,100})')

    # Fallback to text-based extraction
    if not owner:
        owner = after("Name of Owner") or after("Owner")
    if not extent:
        extent = after("Total Extent") or after("Extent")

    return {
        "survey_number": survey_no,
        "district": district, "taluk": taluk, "hobli": hobli, "village": village,
        "owner_name":  owner,
        "extent":      extent,
        "land_type":   land_use,
        "kharab":      kharab,
        "liabilities": liab,
        "source": "bhoomi_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 3. KAVERI ONLINE — Encumbrance Certificate (EC)
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/ec", methods=["POST"])
def fetch_ec():
    d = request.get_json()
    district  = d.get("district", "")
    taluk     = d.get("taluk", "")
    village   = d.get("village", "")
    survey_no = d.get("survey_number", "")
    from_year = d.get("from_year", "2000")
    to_year   = d.get("to_year", "2025")

    key = f"ec_{district}_{taluk}_{village}_{survey_no}_{from_year}_{to_year}".lower().replace(" ", "_")
    cached = cache_get("ec_cache", key, ttl_days=3)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_kaveri_ec(district, taluk, village, survey_no, from_year, to_year))
    if result:
        cache_set("ec_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "Kaveri portal unavailable"}), 503


async def _scrape_kaveri_ec(district, taluk, village, survey_no, from_year, to_year) -> Optional[dict]:
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(extra_http_headers=BROWSER_HEADERS)
        try:
            # Kaveri 2.0 EC search — kaveri.karnataka.gov.in/ec-search-citizen
            await page.goto("https://kaveri.karnataka.gov.in/ec-search-citizen",
                            wait_until="domcontentloaded", timeout=25000)
            await page.wait_for_timeout(3000)

            # Angular mat-select for district
            try:
                await page.click('[formcontrolname="district"], mat-select:first-of-type', timeout=6000)
                await page.wait_for_timeout(600)
                await page.click(f'mat-option:has-text("{district}")', timeout=4000)
                await page.wait_for_timeout(1500)
            except Exception as e1:
                logger.warning(f"EC district: {e1}")

            if taluk:
                try:
                    await page.click('[formcontrolname="taluk"]', timeout=4000)
                    await page.wait_for_timeout(600)
                    await page.click(f'mat-option:has-text("{taluk}")', timeout=4000)
                    await page.wait_for_timeout(1500)
                except Exception:
                    pass

            if village:
                try:
                    await page.click('[formcontrolname="village"]', timeout=4000)
                    await page.wait_for_timeout(600)
                    await page.click(f'mat-option:has-text("{village}")', timeout=4000)
                    await page.wait_for_timeout(1000)
                except Exception:
                    pass

            # Survey number
            for sel in ['input[formcontrolname="surveyNo"]', 'input[formcontrolname="survey_number"]',
                        'input[placeholder*="survey"]', 'input[name="surveyNo"]']:
                inp = await page.query_selector(sel)
                if inp:
                    await inp.fill(survey_no)
                    break

            # Date range (year inputs)
            for sel in ['input[formcontrolname="fromYear"]', 'input[placeholder*="from"]']:
                inp = await page.query_selector(sel)
                if inp:
                    await inp.fill(from_year)
                    break
            for sel in ['input[formcontrolname="toYear"]', 'input[placeholder*="to"]']:
                inp = await page.query_selector(sel)
                if inp:
                    await inp.fill(to_year)
                    break

            # Submit
            btn = await page.query_selector(
                'button[type="submit"], button:has-text("Search"), button:has-text("Get EC")')
            if btn:
                await btn.click()
                await page.wait_for_timeout(4000)

            html = await page.content()
            return _parse_ec(html, district, taluk, village, survey_no)
        except Exception as e:
            logger.error(f"Kaveri EC: {e}")
            return None
        finally:
            await browser.close()


def _parse_ec(html, district, taluk, village, survey_no) -> dict:
    transactions = re.findall(
        r'<tr[^>]*>.*?<td[^>]*>([^<]{1,200})</td>.*?</tr>', html, re.DOTALL | re.IGNORECASE
    )
    clean = [t.strip() for t in transactions if len(t.strip()) > 5][:20]
    clean_html = "No transactions found" if not clean else "; ".join(clean[:10])

    encumbrance_free = "no encumbrance" in html.lower() or "nil encumbrance" in html.lower()

    return {
        "survey_number": survey_no,
        "district": district, "taluk": taluk, "village": village,
        "encumbrance_free": encumbrance_free,
        "transactions_summary": clean_html,
        "transaction_count": len(clean),
        "source": "kaveri_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 4. RERA KARNATAKA — Project & Promoter Check
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/rera", methods=["POST"])
def fetch_rera():
    d = request.get_json()
    project_name = d.get("project_name", "")
    promoter     = d.get("promoter_name", "")
    district     = d.get("district", "")

    key = f"rera_{project_name}_{promoter}_{district}".lower().replace(" ", "_")
    cached = cache_get("rera_cache", key, ttl_days=7)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_rera(project_name, promoter, district))
    if result:
        cache_set("rera_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "RERA portal unavailable"}), 503


async def _scrape_rera(project_name, promoter, district) -> Optional[dict]:
    # RERA Karnataka has a public search API — no CAPTCHA
    search_term = project_name or promoter
    if not search_term:
        return {"error": "project_name or promoter_name required"}

    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=20, follow_redirects=True) as c:
        try:
            # Try RERA public search endpoint
            r = await c.get(
                "https://rera.karnataka.gov.in/viewAllProjects",
                params={"searchText": search_term, "districtId": ""},
            )
            html = r.text
            return _parse_rera(html, search_term, district)
        except Exception as e:
            logger.error(f"RERA: {e}")
            return None


def _parse_rera(html, search_term, district) -> dict:
    reg_numbers = re.findall(r'PRM/KA/RERA/\d+/\d+/\w+', html)
    statuses = re.findall(r'(?:Registered|Revoked|Lapsed|Expired)', html, re.IGNORECASE)
    promoter_names = re.findall(r'<td[^>]*>\s*([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)\s*</td>', html)

    return {
        "search_term": search_term,
        "district": district,
        "registration_numbers": list(set(reg_numbers[:5])),
        "statuses": list(set(statuses[:3])),
        "is_registered": len(reg_numbers) > 0,
        "promoters_found": list(set(promoter_names[:3])),
        "source": "rera_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 5. eCOURTS — Court Case Search
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/ecourts", methods=["POST"])
def fetch_ecourts():
    d = request.get_json()
    party_name = d.get("party_name", "")
    survey_no  = d.get("survey_number", "")
    district   = d.get("district", "")

    key = f"court_{party_name}_{survey_no}_{district}".lower().replace(" ", "_")
    cached = cache_get("court_cache", key, ttl_days=1)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_ecourts(party_name, survey_no, district))
    if result:
        cache_set("court_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "eCourts unavailable"}), 503


async def _scrape_ecourts(party_name, survey_no, district) -> Optional[dict]:
    # eCourts India has a public party-name search — no CAPTCHA for basic search
    search = party_name or survey_no
    if not search:
        return {"error": "party_name or survey_number required"}

    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=20, follow_redirects=True) as c:
        try:
            r = await c.post(
                "https://ecourts.gov.in/ecourts_home/index.php",
                data={"party_name": search, "state_code": "KA", "dist_code": ""},
            )
            return _parse_ecourts(r.text, search)
        except Exception as e:
            logger.error(f"eCourts: {e}")
            return None


def _parse_ecourts(html, search) -> dict:
    case_numbers = re.findall(r'\b(?:O\.S\.|R\.S\.|W\.P\.|CRL\.|C\.C\.)\s*\d+/\d{4}', html)
    pending = "pending" in html.lower() or "disposed" not in html.lower()

    return {
        "search_term": search,
        "cases_found": len(case_numbers),
        "case_numbers": list(set(case_numbers[:10])),
        "has_pending_cases": pending and len(case_numbers) > 0,
        "source": "ecourts_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 6. BBMP — Khata & Property Tax
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/bbmp", methods=["POST"])
def fetch_bbmp():
    d = request.get_json()
    khata_no   = d.get("khata_number", "")
    owner_name = d.get("owner_name", "")
    ward       = d.get("ward", "")

    if not khata_no and not owner_name:
        return jsonify({"error": "khata_number or owner_name required"}), 400

    key = f"bbmp_{khata_no}_{owner_name}".lower().replace(" ", "_")
    cached = cache_get("bbmp_cache", key, ttl_days=7)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_bbmp(khata_no, owner_name, ward))
    if result:
        cache_set("bbmp_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "BBMP portal unavailable"}), 503


async def _scrape_bbmp(khata_no, owner_name, ward) -> Optional[dict]:
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(extra_http_headers=BROWSER_HEADERS)
        try:
            await page.goto("https://bbmptax.karnataka.gov.in/", wait_until="networkidle", timeout=30000)

            # Fill search
            if khata_no:
                inp = await page.query_selector('input[name="applicationNo"], input[name="khataNo"]')
                if inp:
                    await inp.fill(khata_no)
            elif owner_name:
                inp = await page.query_selector('input[name="ownerName"], input[name="owner_name"]')
                if inp:
                    await inp.fill(owner_name)

            sk_el = await page.query_selector('[data-sitekey]')
            if sk_el:
                sk = await sk_el.get_attribute("data-sitekey")
                token = await solve_recaptcha(sk, page.url)
                if token:
                    await inject_captcha_token(page, token)

            btn = await page.query_selector('input[type="submit"], button[type="submit"]')
            if btn:
                await btn.click()
                await page.wait_for_load_state("networkidle", timeout=15000)

            html = await page.content()
            return _parse_bbmp(html, khata_no, owner_name)
        except Exception as e:
            logger.error(f"BBMP: {e}")
            return None
        finally:
            await browser.close()


def _parse_bbmp(html, khata_no, owner_name) -> dict:
    def find(p):
        m = re.search(p, html, re.IGNORECASE | re.DOTALL)
        return m.group(1).strip() if m else ""

    return {
        "khata_number": khata_no,
        "owner_name":   find(r'(?:owner|applicant)[^<]*<[^>]+>([^<]{3,100})</td>') or owner_name,
        "pid_number":   find(r'(?:PID|pid)[^<]*<[^>]+>([A-Z0-9\-]{5,30})</td>'),
        "tax_due":      find(r'(?:tax due|arrears)[^<]*<[^>]+>([₹0-9,\.]+)</td>'),
        "khata_type":   find(r'(?:khata type|type)[^<]*<[^>]+>([A-Z][^<]{1,30})</td>'),
        "ward":         find(r'(?:ward)[^<]*<[^>]+>([^<]{2,50})</td>'),
        "source": "bbmp_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 7. CERSAI — Mortgage / Lien / Charge Check
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/cersai", methods=["POST"])
def fetch_cersai():
    d = request.get_json()
    state      = d.get("state", "Karnataka")
    district   = d.get("district", "")
    survey_no  = d.get("survey_number", "")

    key = f"cersai_{district}_{survey_no}".lower().replace(" ", "_")
    cached = cache_get("cersai_cache", key, ttl_days=3)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_cersai(state, district, survey_no))
    if result:
        cache_set("cersai_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "CERSAI unavailable"}), 503


async def _scrape_cersai(state, district, survey_no) -> Optional[dict]:
    """CERSAI 2.0 — Vue.js SPA at cersai.org.in/CERSAI/asstsrch.prg
    Intercept the internal search API call for reliable data extraction."""
    captured: list = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(extra_http_headers=BROWSER_HEADERS)
        page = await context.new_page()

        async def capture_response(response):
            url = response.url.lower()
            if any(k in url for k in ["search", "asset", "security", "charge", "prg"]):
                try:
                    ct = response.headers.get("content-type", "")
                    if "json" in ct or "text" in ct:
                        body = await response.text()
                        if any(k in body.lower() for k in ["charge", "mortgage", "lien", "bank", "assets"]):
                            captured.append(body)
                            logger.info(f"CERSAI intercepted: {url}")
                except Exception:
                    pass

        page.on("response", capture_response)

        try:
            await page.goto("https://cersai.org.in/CERSAI/asstsrch.prg",
                            wait_until="domcontentloaded", timeout=20000)
            await page.wait_for_timeout(2000)

            # Fill property/survey number in search
            for sel in ['input[id="plotNo"]', 'input[name="plotNo"]',
                        'input[placeholder*="survey"]', 'input[placeholder*="Plot"]',
                        'input[placeholder*="property"]']:
                inp = await page.query_selector(sel)
                if inp:
                    await inp.fill(survey_no)
                    break

            # Select state (Karnataka)
            try:
                state_inp = await page.query_selector(
                    'input[placeholder*="state"], .multiselect__input, [id*="state"]')
                if state_inp:
                    await state_inp.fill("Karnataka")
                    await page.wait_for_timeout(500)
                    await page.click('.multiselect__option:has-text("Karnataka"), li:has-text("Karnataka")',
                                     timeout=3000)
            except Exception:
                pass

            # Click Search — CERSAI uses Vue.js, button may take time to render
            try:
                await page.wait_for_selector(
                    'button[type="submit"], button:has-text("Search"), input[type="submit"]',
                    timeout=8000)
                btn = await page.query_selector(
                    'button[type="submit"], button:has-text("Search"), input[type="submit"]')
                if btn:
                    await btn.click()
                    await page.wait_for_timeout(4000)
            except Exception as e:
                logger.warning(f"CERSAI search click: {e} — parsing whatever is on page")

            html = await page.content()
            result = _parse_cersai(html, district, survey_no)

            # Override with intercepted API data if richer
            if captured:
                body = " ".join(captured)
                charges = re.findall(r'(?:charge|mortgage|lien|security interest)', body, re.IGNORECASE)
                banks = re.findall(r'(?:HDFC|SBI|ICICI|Axis|Kotak|Canara|Union|Bank\s+of\s+\w+)',
                                   body, re.IGNORECASE)
                if charges or banks:
                    result["charges_found"] = len(charges)
                    result["lenders"] = list(set([b.title() for b in banks[:5]]))
                    result["is_mortgaged"] = len(charges) > 0

            return result
        except Exception as e:
            logger.error(f"CERSAI: {e}")
            return None
        finally:
            await browser.close()


def _parse_cersai(html, district, survey_no) -> dict:
    # Only scan inside result tables/rows — avoid nav/header false positives
    table_sections = re.findall(r'<(?:table|tbody|tr)[^>]*>(.*?)</(?:table|tbody|tr)>',
                                html, re.IGNORECASE | re.DOTALL)
    result_text = " ".join(table_sections)

    # Real charges appear with SI number, amount, or institution name in results
    charges = re.findall(
        r'(?:security interest|SI No|Charge ID|mortgage|lien|hypothecation)',
        result_text, re.IGNORECASE)
    banks = re.findall(
        r'(?:HDFC|SBI|ICICI|Axis|Kotak|Canara|Union|Punjab|Bank\s+of\s+\w+|Financial\s+Institution)',
        result_text, re.IGNORECASE)

    # "No records found" or empty result = clean
    no_records = bool(re.search(r'no\s+record|not\s+found|0\s+record', html, re.IGNORECASE))

    return {
        "district": district,
        "survey_number": survey_no,
        "charges_found": len(charges),
        "lenders": list(set([b.title() for b in banks[:5]])),
        "is_mortgaged": len(charges) > 0 and not no_records,
        "no_records_found": no_records,
        "source": "cersai_scrape",
    }


# ══════════════════════════════════════════════════════════════════════════════
# 8. IGR KARNATAKA — Guidance Value
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/guidance-value", methods=["POST"])
def guidance_value():
    d         = request.get_json()
    district  = d.get("district", "")
    taluk     = d.get("taluk", "")
    village   = d.get("village", "")
    prop_type = d.get("property_type", "residential")

    key = f"gv_{district}_{taluk}_{village}_{prop_type}".lower().replace(" ", "_")
    cached = cache_get("guidance_values", key, ttl_days=30)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_igr(district, taluk, village, prop_type))
    if result:
        cache_set("guidance_values", key, result)
        return jsonify(result)
    return jsonify(_fallback_guidance(district, taluk, village, prop_type))


async def _scrape_igr(district, taluk, village, prop_type) -> Optional[dict]:
    """
    Scrape real guidance value from Kaveri Online.
    Strategy: intercept the internal API call the Angular SPA makes when user
    fills in the form — much faster than waiting for UI rendering.
    """
    captured: list = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(extra_http_headers=BROWSER_HEADERS)
        page = await context.new_page()

        # Intercept responses that look like guidance value API calls
        async def handle_response(response):
            url = response.url.lower()
            if any(k in url for k in ["guidance", "guidancevalue", "gv/", "marketvalue", "rate"]):
                try:
                    ct = response.headers.get("content-type", "")
                    if "json" in ct:
                        body = await response.json()
                        captured.append(body)
                        logger.info(f"IGR API intercepted: {url}")
                except Exception:
                    pass

        page.on("response", handle_response)

        try:
            await page.goto("https://kaveri.karnataka.gov.in/guidance-value",
                            wait_until="domcontentloaded", timeout=20000)
            await page.wait_for_timeout(3000)

            # Try clicking district mat-select and selecting option
            try:
                await page.click('[formcontrolname="district"], mat-select:first-of-type', timeout=5000)
                await page.wait_for_timeout(800)
                await page.click(f'mat-option:has-text("{district}")', timeout=4000)
                await page.wait_for_timeout(1500)
            except Exception as e:
                logger.warning(f"IGR district: {e}")

            if taluk:
                try:
                    await page.click('[formcontrolname="taluk"]', timeout=4000)
                    await page.wait_for_timeout(800)
                    await page.click(f'mat-option:has-text("{taluk}")', timeout=4000)
                    await page.wait_for_timeout(1500)
                except Exception:
                    pass

            if village:
                try:
                    await page.click('[formcontrolname="village"]', timeout=4000)
                    await page.wait_for_timeout(800)
                    await page.click(f'mat-option:has-text("{village}")', timeout=4000)
                    await page.wait_for_timeout(1500)
                except Exception:
                    pass

            if prop_type == "commercial":
                try:
                    await page.click('mat-radio-button:has-text("Commercial")', timeout=3000)
                    await page.wait_for_timeout(500)
                except Exception:
                    pass

            try:
                btn = await page.query_selector(
                    'button[type="submit"], button:has-text("Search"), button:has-text("Get"), button:has-text("View")')
                if btn:
                    await btn.click()
                    await page.wait_for_timeout(4000)
            except Exception:
                pass

            # Check if we intercepted an API response
            if captured:
                raw = captured[-1]
                logger.info(f"IGR intercepted data: {str(raw)[:300]}")
                # Parse from common structures
                per_sqft = None
                zone = "N/A"
                if isinstance(raw, list) and raw:
                    row = raw[0]
                    for k in ["guidanceValue", "GuidanceValue", "ratePerSqft", "rate", "value"]:
                        if k in row:
                            per_sqft = float(str(row[k]).replace(",", ""))
                            break
                    zone = row.get("zone", row.get("Zone", "N/A"))
                elif isinstance(raw, dict):
                    for k in ["guidanceValue", "GuidanceValue", "ratePerSqft", "rate", "value"]:
                        if k in raw:
                            per_sqft = float(str(raw[k]).replace(",", ""))
                            break
                    zone = raw.get("zone", raw.get("Zone", "N/A"))

                if per_sqft:
                    return {
                        "district": district, "taluk": taluk, "village": village,
                        "property_type": prop_type,
                        "value_per_sqft": per_sqft,
                        "value_per_sqm": round(per_sqft * 10.764, 2),
                        "zone": zone, "source": "kaveri_live",
                    }

            # Fallback: parse HTML
            html = await page.content()
            prices = re.findall(r'([\d,]{4,})\s*/?\s*(?:Sq\.?Ft|sqft|sq\.ft)', html, re.IGNORECASE)
            if not prices:
                prices = re.findall(r'(?:₹|Rs\.?)\s*([\d,]+)', html)
            if prices:
                per_sqft = float(prices[0].replace(",", ""))
                zone_m = re.search(r'Zone[:\s]+([A-F])', html, re.IGNORECASE)
                return {
                    "district": district, "taluk": taluk, "village": village,
                    "property_type": prop_type,
                    "value_per_sqft": per_sqft,
                    "value_per_sqm": round(per_sqft * 10.764, 2),
                    "zone": zone_m.group(1) if zone_m else "N/A",
                    "source": "kaveri_html",
                }
        except Exception as e:
            logger.error(f"IGR scrape error: {e}")
        finally:
            await browser.close()
    return None


def _fallback_guidance(district, taluk, village="", prop_type="residential") -> dict:
    vals = {
        ("bengaluru urban", "yelahanka"):       {"res": 4500, "com": 7000},
        ("bengaluru urban", "bengaluru north"): {"res": 6000, "com": 9000},
        ("bengaluru urban", "bengaluru south"): {"res": 8000, "com": 12000},
        ("bengaluru urban", "bengaluru east"):  {"res": 5500, "com": 8500},
        ("bengaluru urban", "anekal"):          {"res": 3500, "com": 5500},
        ("bengaluru rural", "devanahalli"):     {"res": 3000, "com": 4500},
        ("bengaluru rural", "hoskote"):         {"res": 2800, "com": 4000},
        ("mysuru", "mysuru"):                   {"res": 2500, "com": 3800},
        ("mangaluru", "mangaluru"):             {"res": 3000, "com": 4500},
        ("hubballi-dharwad", "hubballi"):       {"res": 2200, "com": 3500},
        ("belagavi", "belagavi"):               {"res": 2000, "com": 3200},
        ("tumakuru", "tumakuru"):               {"res": 1600, "com": 2500},
    }
    entry = vals.get((district.lower(), taluk.lower()), {"res": 1200, "com": 1800})
    per_sqft = entry["com"] if prop_type == "commercial" else entry["res"]
    return {
        "district": district, "taluk": taluk, "village": village,
        "property_type": prop_type,
        "value_per_sqft": per_sqft,
        "value_per_sqm": round(per_sqft * 10.764, 2),
        "zone": "B", "source": "igr_gazette_2024",
    }


@app.route("/guidance-value/refresh-all", methods=["POST"])
def refresh_all():
    locs = [
        ("Bengaluru Urban", "Yelahanka"), ("Bengaluru Urban", "Bengaluru North"),
        ("Bengaluru Urban", "Bengaluru South"), ("Bengaluru Urban", "Bengaluru East"),
        ("Bengaluru Urban", "Anekal"), ("Bengaluru Rural", "Devanahalli"),
        ("Bengaluru Rural", "Hoskote"), ("Mysuru", "Mysuru"),
        ("Mangaluru", "Mangaluru"), ("Hubballi-Dharwad", "Hubballi"),
        ("Belagavi", "Belagavi"), ("Tumakuru", "Tumakuru"),
    ]
    n = 0
    for dist, taluk in locs:
        for pt in ["residential", "commercial"]:
            r = asyncio.run(_scrape_igr(dist, taluk, "", pt))
            if r:
                key = f"gv_{dist}_{taluk}__{pt}".lower().replace(" ", "_")
                cache_set("guidance_values", key, r)
                n += 1
    return jsonify({"refreshed": n})


# ══════════════════════════════════════════════════════════════════════════════
# 9. FMB SKETCH — Land Boundary Map
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/fmb", methods=["POST"])
def fetch_fmb():
    d = request.get_json()
    district  = d.get("district", "")
    taluk     = d.get("taluk", "")
    village   = d.get("village", "")
    survey_no = d.get("survey_number", "")

    key = f"fmb_{district}_{taluk}_{village}_{survey_no}".lower().replace(" ", "_")
    cached = cache_get("fmb_cache", key, ttl_days=30)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_fmb(district, taluk, village, survey_no))
    if result:
        cache_set("fmb_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "FMB sketch unavailable"}), 503


async def _scrape_fmb(district, taluk, village, survey_no) -> Optional[dict]:
    # FMB Sketch: landrecords.karnataka.gov.in/service2/forM16A.aspx
    # Selectors: drpdist, drptaluk, drphobli, drpvillage, txtSurvey, Button1
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(extra_http_headers=BROWSER_HEADERS)
        try:
            await page.goto("https://landrecords.karnataka.gov.in/service2/forM16A.aspx",
                            wait_until="networkidle", timeout=30000)

            # FMB district labels (different casing from RTC page)
            dist_map = {
                "bangalore urban": "BENGALURU URBAN", "bengaluru urban": "BENGALURU URBAN",
                "bangalore south": "BENGALURU SOUTH", "bengaluru south": "BENGALURU SOUTH",
                "bangalore rural": "BENGALURU Rural", "bengaluru rural": "BENGALURU Rural",
                "mysuru": "MYSURU", "mysore": "MYSURU",
                "belagavi": "BELAGAVI", "belgaum": "BELAGAVI",
                "mangaluru": "Dakshina Kannada", "dakshina kannada": "Dakshina Kannada",
                "hubballi-dharwad": "DHARWAD", "dharwad": "DHARWAD",
                "shivamogga": "SHIVAMOGGA", "tumakuru": "TUMAKURU",
                "kalaburagi": "KALABURAGI", "raichur": "RAICHUR",
                "chikkaballapur": "Chikkaballapur", "kolar": "KOLAR",
                "ramanagara": "RAMANAGARA",
            }
            # FMB has mixed casing — try exact map first, then partial match
            dist_label = dist_map.get(district.lower(), district.upper())

            await page.wait_for_function(
                "document.querySelector('#ctl00_MainContent_drpdist') && "
                "document.querySelector('#ctl00_MainContent_drpdist').options.length > 1",
                timeout=10000
            )
            # Partial match for FMB district (mixed casing)
            fmb_opts = await page.evaluate(
                "Array.from(document.querySelector('#ctl00_MainContent_drpdist').options).map(o=>o.text)")
            dl = dist_label.lower()
            best_dist = next((o for o in fmb_opts if o.lower() == dl), None) or \
                        next((o for o in fmb_opts if dl in o.lower() or o.lower() in dl), None) or \
                        dist_label
            await page.select_option('#ctl00_MainContent_drpdist', label=best_dist)
            logger.info(f"FMB district selected: {best_dist}")
            await page.wait_for_timeout(2000)

            if taluk:
                try:
                    await page.wait_for_function(
                        "document.querySelector('#ctl00_MainContent_drptaluk') && "
                        "document.querySelector('#ctl00_MainContent_drptaluk').options.length > 1",
                        timeout=8000)
                    taluk_opts = await page.evaluate(
                        "Array.from(document.querySelector('#ctl00_MainContent_drptaluk').options).map(o=>o.text)")
                    tl = taluk.lower()
                    # Match by contains (handles BENGALURU-NORTH, BANGALORE-NORTH, etc.)
                    keywords = [w for w in tl.replace("bangalore", "").replace("bengaluru", "").strip().split() if w]
                    best_taluk = next(
                        (o for o in taluk_opts
                         if 'select' not in o.lower() and (
                             all(kw in o.lower() for kw in keywords) if keywords else tl in o.lower()
                         )), None) or \
                        next((o for o in taluk_opts if tl in o.lower() and 'select' not in o.lower()), None)
                    if best_taluk:
                        await page.select_option('#ctl00_MainContent_drptaluk', label=best_taluk)
                        logger.info(f"FMB taluk selected: {best_taluk}")
                        await page.wait_for_timeout(2000)
                    else:
                        logger.warning(f"FMB taluk '{taluk}' not in {taluk_opts}")
                except Exception as e:
                    logger.warning(f"FMB taluk: {e}")

            # FMB: try hobli then village — both optional, survey number is key
            try:
                await page.wait_for_function(
                    "document.querySelector('#ctl00_MainContent_drphobli').options.length > 1",
                    timeout=8000)
                hobli_opts = await page.evaluate(
                    "Array.from(document.querySelector('#ctl00_MainContent_drphobli').options).map(o=>o.text)")
                # Match village name in hobli options (e.g., Yelahanka hobli for Yelahanka village)
                vl = village.upper() if village else ""
                best_hobli = None
                if vl:
                    best_hobli = next((o for o in hobli_opts
                                       if vl in o.upper() and 'select' not in o.lower()), None)
                if not best_hobli:
                    best_hobli = next((o for o in hobli_opts if 'select' not in o.lower()), None)
                if best_hobli:
                    await page.select_option('#ctl00_MainContent_drphobli', label=best_hobli)
                    logger.info(f"FMB hobli selected: {best_hobli}")
                    await page.wait_for_timeout(2500)
            except Exception as e:
                logger.warning(f"FMB hobli: {e}")

            if village:
                try:
                    await page.wait_for_function(
                        "document.querySelector('#ctl00_MainContent_DDLVillageListData').options.length > 1",
                        timeout=10000)
                    opts = await page.evaluate(
                        "Array.from(document.querySelector('#ctl00_MainContent_DDLVillageListData').options).map(o=>o.text)")
                    vl = village.upper()
                    best = next((o for o in opts if o.upper() == vl), None) or \
                           next((o for o in opts if o.upper().startswith(vl)), None) or \
                           next((o for o in opts if vl in o.upper()), None)
                    if best:
                        await page.select_option('#ctl00_MainContent_DDLVillageListData', label=best)
                        await page.wait_for_timeout(1500)
                        logger.info(f"FMB village selected: {best}")
                except Exception as e:
                    logger.warning(f"FMB village (optional): {e}")

            # Survey number via JS
            await page.evaluate(f'''
                var el = document.getElementById("ctl00_MainContent_txtSurvey");
                if (el) {{ el.readOnly = false; el.value = "{survey_no}"; }}
            ''')
            await page.wait_for_timeout(300)

            inp = await page.query_selector('input[name="surveyNo"], input[name="sno"]')
            if inp:
                await inp.fill(survey_no)

            # Click View button (Button1)
            btn = await page.query_selector('#ctl00_MainContent_Button1, input[type="submit"]')
            if btn:
                await btn.click()
                await page.wait_for_load_state("networkidle", timeout=20000)

            # Look for sketch image
            img = await page.query_selector(
                'img[src*="sketch"], img[src*="fmb"], img[src*="map"], img[src*="M16"]')
            img_url = await img.get_attribute("src") if img else None
            if img_url and img_url.startswith("/"):
                img_url = "https://landrecords.karnataka.gov.in" + img_url

            html = await page.content()
            area_match = re.search(
                r'(?:area|extent|ವಿಸ್ತಾರ)[^<]*<[^>]+>([0-9\.\-]+\s*(?:acres|guntas|sqft)[^<]*)</td>',
                html, re.IGNORECASE)
            return {
                "survey_number": survey_no,
                "district": district, "taluk": taluk, "village": village,
                "sketch_url": img_url,
                "area": area_match.group(1).strip() if area_match else "",
                "source": "fmb_scrape",
            }
        except Exception as e:
            logger.error(f"FMB: {e}")
            return None
        finally:
            await browser.close()


# ══════════════════════════════════════════════════════════════════════════════
# COMBINED — Full Property Check (all portals in parallel)
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/full-check", methods=["POST"])
def full_check():
    """
    Run ALL portal checks in parallel for a given property.
    Returns combined result: RTC + EC + RERA + eCourts + CERSAI + Guidance Value + FMB
    """
    d = request.get_json()
    district     = d.get("district", "")
    taluk        = d.get("taluk", "")
    hobli        = d.get("hobli", "")
    village      = d.get("village", "")
    survey_no    = d.get("survey_number", "")
    owner_name   = d.get("owner_name", "")
    project_name = d.get("project_name", "")

    if not district or not survey_no:
        return jsonify({"error": "district and survey_number required"}), 400

    key = f"full_{district}_{taluk}_{village}_{survey_no}".lower().replace(" ", "_")
    cached = cache_get("full_check_cache", key, ttl_days=3)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_run_full_check(
        district, taluk, hobli, village, survey_no, owner_name, project_name
    ))
    cache_set("full_check_cache", key, result)
    return jsonify(result)


async def _run_full_check(district, taluk, hobli, village, survey_no, owner_name, project_name):
    """Run all portal scrapes concurrently."""
    tasks = await asyncio.gather(
        _scrape_bhoomi_rtc(district, taluk, hobli, village, survey_no),
        _scrape_kaveri_ec(district, taluk, village, survey_no, "2000", "2025"),
        _scrape_ecourts(owner_name, survey_no, district),
        _scrape_cersai("Karnataka", district, survey_no),
        _scrape_igr(district, taluk, village, "residential"),
        _scrape_fmb(district, taluk, village, survey_no),
        return_exceptions=True,
    )

    rtc, ec, courts, cersai, gv, fmb = tasks

    # Risk scoring
    risk_flags = []
    if isinstance(cersai, dict) and cersai.get("is_mortgaged"):
        risk_flags.append("Property has active mortgage/lien (CERSAI)")
    if isinstance(courts, dict) and courts.get("has_pending_cases"):
        risk_flags.append(f"Pending court cases found: {courts.get('case_numbers', [])}")
    if isinstance(ec, dict) and not ec.get("encumbrance_free"):
        risk_flags.append("Encumbrance found in EC")

    risk_level = "HIGH" if len(risk_flags) >= 2 else "CAUTION" if risk_flags else "SAFE"

    return {
        "survey_number": survey_no,
        "district": district, "taluk": taluk, "village": village,
        "rtc":     rtc    if isinstance(rtc,    dict) else None,
        "ec":      ec     if isinstance(ec,     dict) else None,
        "courts":  courts if isinstance(courts, dict) else None,
        "cersai":  cersai if isinstance(cersai, dict) else None,
        "guidance_value": gv if isinstance(gv, dict) else _fallback_guidance(district, taluk, village, "residential"),
        "fmb":     fmb    if isinstance(fmb,   dict) else None,
        "risk_level":  risk_level,
        "risk_flags":  risk_flags,
        "checked_at":  time.time(),
    }


# ══════════════════════════════════════════════════════════════════════════════
# BHOOMI DROPDOWN APIs — Hobli & Village lists
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/hoblis", methods=["POST"])
def get_hoblis():
    """Fetch hobli list from Bhoomi for given district + taluk."""
    d = request.get_json()
    district = d.get("district", "")
    taluk    = d.get("taluk", "")
    result = asyncio.run(_fetch_bhoomi_hoblis(district, taluk))
    return jsonify({"hoblis": result})


@app.route("/villages", methods=["POST"])
def get_villages():
    """Fetch village list from Bhoomi for given district + taluk + hobli."""
    d = request.get_json()
    district = d.get("district", "")
    taluk    = d.get("taluk", "")
    hobli    = d.get("hobli", "")
    result = asyncio.run(_fetch_bhoomi_villages(district, taluk, hobli))
    return jsonify({"villages": result})


async def _fetch_bhoomi_hoblis(district: str, taluk: str) -> list:
    """Scrape Bhoomi dropdown for hoblis under given district+taluk."""
    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=12, follow_redirects=True) as c:
        try:
            # Bhoomi uses AJAX endpoints to populate dropdowns
            r = await c.post(
                "https://bhoomi.karnataka.gov.in/bhoomi/getHobliList.do",
                data={"district": district, "taluk": taluk},
            )
            if r.status_code == 200:
                try:
                    data = r.json()
                    hoblis = [h.get("hobliName") or h.get("name") or str(h)
                              for h in (data if isinstance(data, list) else data.get("hoblis", []))]
                    return [h for h in hoblis if h]
                except Exception:
                    # Parse HTML select options
                    options = re.findall(r'<option[^>]*value="([^"]+)"[^>]*>([^<]+)</option>', r.text)
                    return [v.strip() for _, v in options if v.strip() and v.strip() != "Select"]
        except Exception as e:
            logger.warning(f"Bhoomi hobli fetch: {e}")
    return []


async def _fetch_bhoomi_villages(district: str, taluk: str, hobli: str) -> list:
    """Scrape Bhoomi dropdown for villages under given district+taluk+hobli."""
    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=12, follow_redirects=True) as c:
        try:
            r = await c.post(
                "https://bhoomi.karnataka.gov.in/bhoomi/getVillageList.do",
                data={"district": district, "taluk": taluk, "hobli": hobli},
            )
            if r.status_code == 200:
                try:
                    data = r.json()
                    villages = [v.get("villageName") or v.get("name") or str(v)
                                for v in (data if isinstance(data, list) else data.get("villages", []))]
                    return [v for v in villages if v]
                except Exception:
                    options = re.findall(r'<option[^>]*value="([^"]+)"[^>]*>([^<]+)</option>', r.text)
                    return [v.strip() for _, v in options if v.strip() and v.strip() != "Select"]
        except Exception as e:
            logger.warning(f"Bhoomi village fetch: {e}")
    return []


# ══════════════════════════════════════════════════════════════════════════════
# NADAKACHERI — Caste / Income / Residence Certificate Check
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/nadakacheri", methods=["POST"])
def fetch_nadakacheri():
    """
    Nadakacheri Karnataka — Check certificate status (caste, income, residence).
    Used to verify seller's identity documents.
    URL: nadakacheri.karnataka.gov.in
    """
    d = request.get_json()
    ack_no = d.get("acknowledgement_number", "")
    if not ack_no:
        return jsonify({"error": "acknowledgement_number required"}), 400

    key = f"nkc_{ack_no}"
    cached = cache_get("nadakacheri_cache", key, ttl_days=3)
    if cached:
        return jsonify(cached)

    result = asyncio.run(_scrape_nadakacheri(ack_no))
    if result:
        cache_set("nadakacheri_cache", key, result)
        return jsonify(result)
    return jsonify({"error": "Nadakacheri portal unavailable"}), 503


async def _scrape_nadakacheri(ack_no: str) -> Optional[dict]:
    async with httpx.AsyncClient(headers=BROWSER_HEADERS, timeout=15, follow_redirects=True) as c:
        try:
            r = await c.post(
                "https://nadakacheri.karnataka.gov.in/static/applicationStatusReport.html",
                data={"ackNo": ack_no},
            )
            html = r.text
            status = re.search(r'(?:status|certificate)[^<]*<[^>]+>([^<]{3,50})</td>', html, re.IGNORECASE)
            name   = re.search(r'(?:applicant|name)[^<]*<[^>]+>([A-Za-z\s]{3,60})</td>', html, re.IGNORECASE)
            cert   = re.search(r'(?:certificate type|type)[^<]*<[^>]+>([^<]{3,80})</td>', html, re.IGNORECASE)
            return {
                "acknowledgement_number": ack_no,
                "applicant_name": name.group(1).strip() if name else "",
                "certificate_type": cert.group(1).strip() if cert else "",
                "status": status.group(1).strip() if status else "Unknown",
                "source": "nadakacheri_scrape",
            }
        except Exception as e:
            logger.error(f"Nadakacheri: {e}")
            return None


# ══════════════════════════════════════════════════════════════════════════════
# HEALTH CHECK
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/health")
def health():
    import os as _os
    key = _anticaptcha_key()
    return jsonify({
        "status": "ok",
        "service": "digisampatti-backend",
        "portals": ["bhoomi", "kaveri", "rera", "ecourts", "bbmp", "cersai", "igr", "fmb", "nadakacheri"],
        "dropdowns": ["hoblis", "villages"],
        "captcha_solver": "configured" if key else "not configured (RTC/EC/FMB/CERSAI need this)",
        "captcha_key_preview": key[:8] + "..." if key else "EMPTY",
        "firestore": "connected" if db else "not connected",
        "cwd": _os.getcwd(),
        "env_file_found": str(Path(__file__).resolve().parent / ".env"),
        "env_file_exists": (Path(__file__).resolve().parent / ".env").exists(),
    })


# ══════════════════════════════════════════════════════════════════════════════
# GPS → PROPERTY LOOKUP  (Photo/Site scan → Survey Number via Dishank + OSM)
# ══════════════════════════════════════════════════════════════════════════════
#
# When a user stands at a property and takes a photo, the app sends GPS coords.
# We:
#   1. Reverse-geocode with Nominatim to get district/taluk/village
#   2. Scrape Dishank GIS portal to find survey number at those coords
#   3. Return survey_number, village, taluk, district → app auto-fills search
#
# Dishank (dishank.karnataka.gov.in) is a GIS portal with WMS tiles.
# The survey layer is: WMS geoserver/dishank/wms?SERVICE=WMS&REQUEST=GetFeatureInfo
# We query the feature at the given coordinates to get the survey/parcel number.

@app.route("/gps_lookup", methods=["POST"])
def gps_lookup():
    data = request.get_json(force=True) or {}
    lat = data.get("latitude")
    lng = data.get("longitude")

    if not lat or not lng:
        return jsonify({"error": "latitude and longitude required"}), 400

    try:
        result = asyncio.run(_gps_to_property(float(lat), float(lng)))
        return jsonify(result)
    except Exception as e:
        logger.error(f"GPS lookup error: {e}")
        return jsonify({"error": str(e)}), 500


async def _gps_to_property(lat: float, lng: float) -> dict:
    """
    Step 1: Reverse geocode (Nominatim, no API key needed)
    Step 2: Dishank WMS GetFeatureInfo to get survey parcel
    """
    result = {
        "latitude": lat,
        "longitude": lng,
        "district": None,
        "taluk": None,
        "village": None,
        "survey_number": None,
        "source": None,
    }

    # ── Step 1: Reverse geocode with Nominatim ─────────────────────────────
    try:
        nom_url = (
            f"https://nominatim.openstreetmap.org/reverse"
            f"?format=json&lat={lat}&lon={lng}&zoom=15&addressdetails=1"
        )
        async with httpx.AsyncClient(timeout=10,
                headers={"User-Agent": "DigiSampatti/1.0 property-verification"}) as client:
            r = await client.get(nom_url)
            nom = r.json()

        addr = nom.get("address", {})
        # Nominatim Karnataka tags
        result["district"] = (
            addr.get("county") or addr.get("state_district") or addr.get("district") or ""
        ).replace(" District", "").strip()
        result["taluk"] = (addr.get("city") or addr.get("town") or addr.get("village") or "").strip()
        result["village"] = (addr.get("suburb") or addr.get("hamlet") or addr.get("neighbourhood") or "").strip()
        result["source"] = "nominatim"
    except Exception as e:
        logger.warning(f"Nominatim reverse geocode failed: {e}")

    # ── Step 2: Dishank WMS GetFeatureInfo ─────────────────────────────────
    # Dishank uses EPSG:4326. We build a tiny bounding box around the point.
    # The WMS server returns XML with the cadastral parcel (survey number).
    try:
        delta = 0.0001  # ~11 metres
        bbox = f"{lng-delta},{lat-delta},{lng+delta},{lat+delta}"
        width, height = 101, 101
        x, y = 50, 50  # pixel at centre of 101×101 image

        dishank_url = (
            "https://dishank.karnataka.gov.in/geoserver/dishank/wms"
            "?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetFeatureInfo"
            "&LAYERS=dishank:survey_boundaries"
            "&QUERY_LAYERS=dishank:survey_boundaries"
            "&INFO_FORMAT=application/json"
            f"&BBOX={bbox}&WIDTH={width}&HEIGHT={height}"
            f"&X={x}&Y={y}&SRS=EPSG:4326&FEATURE_COUNT=5"
        )
        async with httpx.AsyncClient(timeout=15,
                headers={"User-Agent": "Mozilla/5.0", "Referer": "https://dishank.karnataka.gov.in/"}) as client:
            r = await client.get(dishank_url)

        if r.status_code == 200:
            try:
                features = r.json().get("features", [])
                if features:
                    props = features[0].get("properties", {})
                    # Dishank property names (vary by layer version)
                    survey_no = (
                        props.get("survey_no") or props.get("surveyno") or
                        props.get("SURVEY_NO") or props.get("sy_no") or
                        props.get("parcel_no") or ""
                    )
                    if survey_no:
                        result["survey_number"] = str(survey_no).strip()
                    if not result["village"]:
                        result["village"] = props.get("village_name") or props.get("VILLAGE_NAME") or ""
                    if not result["taluk"]:
                        result["taluk"] = props.get("taluk_name") or props.get("TALUK_NAME") or ""
                    if not result["district"]:
                        result["district"] = props.get("dist_name") or props.get("DIST_NAME") or ""
                    result["source"] = "dishank_wms"
            except Exception:
                pass  # JSON parse failure — fall through with nominatim data

    except Exception as e:
        logger.warning(f"Dishank WMS lookup failed (may need VPN/network to reach dishank): {e}")
        # Graceful: still return nominatim address data

    return result


if __name__ == "__main__":
    # debug=False → single process, no reloader, no conflicts with other PIDs
    app.run(host="0.0.0.0", port=PORT, debug=False)
