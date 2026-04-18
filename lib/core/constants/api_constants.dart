class ApiConstants {
  ApiConstants._();

  // ─── Claude AI ─────────────────────────────────────────────────────────────
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  static const String claudeModel = 'claude-sonnet-4-6';
  static const int claudeMaxTokens = 4096;

  // ─── Arth ID Backend ──────────────────────────────────────────────────────
  static const String backendBaseUrl = 'https://digi-sampatti-production.up.railway.app';

  // ─── Karnataka Government Portals (WebView only) ──────────────────────────
  static const String bhoomiBaseUrl = 'https://bhoomi.karnataka.gov.in';
  static const String reraBaseUrl = 'https://rera.karnataka.gov.in';
  static const String bbmpBaseUrl = 'https://bbmp.gov.in';
  static const String igrsBaseUrl = 'https://igr.karnataka.gov.in';

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
