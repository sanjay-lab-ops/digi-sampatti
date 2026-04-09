import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';

// ─── GPS Survey Detection Result ──────────────────────────────────────────────
class SurveyDetectionResult {
  final String? surveyNumber;
  final String? district;
  final String? taluk;
  final String? hobli;
  final String? village;
  final double confidence;  // 0.0 to 1.0
  final String source;      // 'dishank' / 'backend' / 'geocode'

  const SurveyDetectionResult({
    this.surveyNumber,
    this.district,
    this.taluk,
    this.hobli,
    this.village,
    this.confidence = 0.0,
    this.source = 'geocode',
  });

  bool get hasSurveyNumber => surveyNumber != null && surveyNumber!.isNotEmpty;
}

class GpsService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  late final Dio _dio;
  late final Dio _backendDio;

  void initialize() {
    // Dishank / Bhoomi spatial API
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    ));

    // Our backend scraper
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://api.digisampatti.in';
    _backendDio = Dio(BaseOptions(
      baseUrl: backendUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ));
  }

  // ─── Request Permission ────────────────────────────────────────────────────
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ─── Get Current Location ──────────────────────────────────────────────────
  Future<GpsLocation?> getCurrentLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      String? address;
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {}

      return GpsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: DateTime.now(),
        address: address,
      );
    } catch (e) {
      return null;
    }
  }

  // ─── GPS → Survey Number (Dishank-style) ──────────────────────────────────
  // Replicates what the Karnataka Dishank app does:
  //   1. Try our backend scraper (which hits Bhoomi spatial DB)
  //   2. Try Dishank portal API directly
  //   3. Fallback: reverse geocode → extract district/taluk/village
  //
  // Returns null surveyNumber if not found but always returns location context.
  Future<SurveyDetectionResult> getSurveyFromLocation({
    required double latitude,
    required double longitude,
  }) async {
    // ── Step 1: Try our backend scraper ─────────────────────────────────────
    try {
      final response = await _backendDio.post('/survey-from-gps', data: {
        'lat': latitude,
        'lon': longitude,
      });
      if (response.statusCode == 200) {
        final d = response.data as Map<String, dynamic>;
        if (d['survey_number'] != null) {
          return SurveyDetectionResult(
            surveyNumber: d['survey_number'],
            district:     d['district'],
            taluk:        d['taluk'],
            hobli:        d['hobli'],
            village:      d['village'],
            confidence:   (d['confidence'] ?? 0.8).toDouble(),
            source:       'backend',
          );
        }
      }
    } catch (_) {}

    // ── Step 2: Try Dishank Karnataka portal ────────────────────────────────
    // Dishank uses Bhoomi's spatial database to map GPS → survey number.
    // URL: https://dishank.karnataka.gov.in/rtcRequest/getSurveyDetailsByGPS
    try {
      final response = await _dio.get(
        'https://dishank.karnataka.gov.in/rtcRequest/getSurveyDetailsByGPS',
        queryParameters: {
          'latitude':  latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
        },
      );
      if (response.statusCode == 200) {
        final d = response.data;
        final data = d is Map ? d : {};
        final surveyNo = data['surveyNo']?.toString() ??
                         data['survey_number']?.toString() ??
                         data['surveyNumber']?.toString();
        if (surveyNo != null && surveyNo.isNotEmpty) {
          return SurveyDetectionResult(
            surveyNumber: surveyNo,
            district: data['district']?.toString(),
            taluk:    data['taluk']?.toString(),
            hobli:    data['hobli']?.toString(),
            village:  data['village']?.toString() ?? data['hobli']?.toString(),
            confidence: 0.95,
            source: 'dishank',
          );
        }
      }
    } catch (_) {}

    // ── Step 3: Reverse geocode fallback ────────────────────────────────────
    // No survey number, but we extract district/taluk/village from address.
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final district = _normalizeDistrict(place.administrativeArea ?? '');
        final village  = place.subLocality ?? place.locality ?? '';
        return SurveyDetectionResult(
          surveyNumber: null,
          district: district.isNotEmpty ? district : place.administrativeArea,
          taluk:    place.locality,
          village:  village,
          confidence: 0.5,
          source: 'geocode',
        );
      }
    } catch (_) {}

    return const SurveyDetectionResult(source: 'geocode');
  }

  // ─── Auto-detect and fill search form ─────────────────────────────────────
  Future<SurveyDetectionResult> detectAndFill() async {
    final location = await getCurrentLocation();
    if (location == null) return const SurveyDetectionResult();
    return getSurveyFromLocation(
      latitude:  location.latitude,
      longitude: location.longitude,
    );
  }

  // ─── Normalize district name ───────────────────────────────────────────────
  String _normalizeDistrict(String raw) {
    final map = {
      'bangalore':        'Bengaluru Urban',
      'bengaluru':        'Bengaluru Urban',
      'bangalore urban':  'Bengaluru Urban',
      'bangalore rural':  'Bengaluru Rural',
      'mysore':           'Mysuru',
      'mangalore':        'Mangaluru',
      'hubli':            'Hubballi-Dharwad',
      'dharwad':          'Hubballi-Dharwad',
      'belgaum':          'Belagavi',
      'gulbarga':         'Kalaburagi',
      'bijapur':          'Vijayapura',
      'bellary':          'Ballari',
      'shimoga':          'Shivamogga',
      'tumkur':           'Tumakuru',
      'davanagere':       'Davanagere',
      'hassan':           'Hassan',
      'chickmagalur':     'Chikkamagaluru',
    };
    final lower = raw.toLowerCase();
    for (final entry in map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return raw;
  }

  // ─── Stream Location Updates ───────────────────────────────────────────────
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // ─── Calculate Distance (meters) ──────────────────────────────────────────
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ─── Format Coordinates for Display ───────────────────────────────────────
  String formatCoordinates(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}° $latDir, ${lon.abs().toStringAsFixed(6)}° $lonDir';
  }

  // ─── Get Google Maps URL ───────────────────────────────────────────────────
  String getGoogleMapsUrl(double lat, double lon) {
    return 'https://maps.google.com/?q=$lat,$lon';
  }
}
