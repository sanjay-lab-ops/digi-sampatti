import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─── GPS → Property Lookup Service ───────────────────────────────────────────
// Calls backend /gps_lookup which:
//   1. Reverse-geocodes lat/lng via Nominatim → district, taluk, village
//   2. Queries Dishank WMS layer → survey number at that coordinate
//
// Use case: User stands at a site/building, takes photo → GPS auto-identifies
// the survey number so the app can run all 7 portal checks without typing.

class GpsLookupResult {
  final double latitude;
  final double longitude;
  final String? district;
  final String? taluk;
  final String? village;
  final String? surveyNumber;
  final String? source; // 'dishank_wms' | 'nominatim'

  const GpsLookupResult({
    required this.latitude,
    required this.longitude,
    this.district,
    this.taluk,
    this.village,
    this.surveyNumber,
    this.source,
  });

  bool get hasFullData =>
      district != null && taluk != null && village != null && surveyNumber != null;

  bool get hasPartialData =>
      district != null || taluk != null || village != null;

  factory GpsLookupResult.fromJson(Map<String, dynamic> j) => GpsLookupResult(
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        district: _clean(j['district']),
        taluk: _clean(j['taluk']),
        village: _clean(j['village']),
        surveyNumber: _clean(j['survey_number']),
        source: j['source'],
      );

  static String? _clean(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class GpsLookupService {
  static final GpsLookupService _i = GpsLookupService._();
  factory GpsLookupService() => _i;
  GpsLookupService._();

  String get _backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';

  Future<GpsLookupResult?> lookup(double lat, double lng) async {
    try {
      final url = Uri.parse('$_backendUrl/gps_lookup');
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'latitude': lat, 'longitude': lng}),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('error')) return null;
        return GpsLookupResult.fromJson(data);
      }
    } catch (_) {
      // Network error or timeout — caller handles gracefully
    }
    return null;
  }
}
