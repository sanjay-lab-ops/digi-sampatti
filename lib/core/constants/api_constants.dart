class ApiConstants {
  ApiConstants._();

  // ─── Claude AI ─────────────────────────────────────────────────────────────
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  static const String claudeModel = 'claude-sonnet-4-6';
  static const int claudeMaxTokens = 4096;

  // ─── DigiSampatti Railway Backend ─────────────────────────────────────────
  // Playwright scraper backend deployed on Railway
  // Handles: RTC, EC, RERA, eCourts, BBMP, CERSAI, IGR, FMB, GPS→Survey
  static const String backendBaseUrl = 'https://digi-sampatti-production.up.railway.app';
  static const String backendRtcEndpoint = '/rtc';
  static const String backendEcEndpoint = '/ec';
  static const String backendReraEndpoint = '/rera';
  static const String backendEcourtsEndpoint = '/ecourts';
  static const String backendBbmpEndpoint = '/bbmp';
  static const String backendCersaiEndpoint = '/cersai';
  static const String backendGuidanceEndpoint = '/guidance-value';
  static const String backendFmbEndpoint = '/fmb';
  static const String backendSurveyFromGpsEndpoint = '/survey-from-gps';

  // ─── Karnataka Bhoomi Portal (direct — fallback only) ─────────────────────
  static const String bhoomiBaseUrl = 'https://bhoomi.karnataka.gov.in';
  static const String bhoomiRtcEndpoint = '/bhoomi/RTCPrint.do';
  static const String bhoomiMutationEndpoint = '/bhoomi/MutationPrint.do';
  static const String bhoomiPartyEndpoint = '/bhoomi/PartyCertificate.do';
  static const String bhoomiOwnerEndpoint = '/bhoomi/OwnershipReport.do';
  static const String bhoomiSketchEndpoint = '/bhoomi/SketchCertificate.do';

  // ─── RERA Karnataka ────────────────────────────────────────────────────────
  static const String reraBaseUrl = 'https://rera.karnataka.gov.in';
  static const String reraProjectSearch = '/viewAllProjects';
  static const String reraPromotorSearch = '/viewAllPromoters';
  static const String reraComplaintSearch = '/viewAllComplaints';

  // ─── BBMP (Bruhat Bengaluru Mahanagara Palike) ─────────────────────────────
  static const String bbmpBaseUrl = 'https://bbmp.gov.in';
  static const String bbmpKhataEndpoint = '/khata/search';

  // ─── IGRS (Stamps & Registration) ─────────────────────────────────────────
  // For Encumbrance Certificate (EC)
  static const String igrsBaseUrl = 'https://igr.karnataka.gov.in';
  static const String igrsEcEndpoint = '/ec/search';

  // ─── Google Maps ───────────────────────────────────────────────────────────
  static const String googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';
  static const String geocodeEndpoint = '/geocode/json';
  static const String reverseGeocodeEndpoint = '/geocode/json';

  // ─── Timeouts ──────────────────────────────────────────────────────────────
  // Gov portals fail fast (they don't have public APIs — we use demo data)
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 8);
  // Claude AI gets more time
  static const Duration aiTimeout = Duration(seconds: 45);

  // ─── Headers ───────────────────────────────────────────────────────────────
  static const Map<String, String> bhoomiHeaders = {
    'User-Agent': 'Mozilla/5.0 (Android; Mobile)',
    'Accept': 'application/json, text/html',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static Map<String, String> claudeHeaders(String apiKey) => {
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };
}
