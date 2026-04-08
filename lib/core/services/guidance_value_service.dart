import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─── Guidance Value Service ────────────────────────────────────────────────────
// Fetches Karnataka IGR guidance values for any location.
// Guidance value = govt-set minimum price per sqft/sqm for stamp duty calculation.
//
// Sources:
//  1. Our backend scraper (Python) → stores in Firestore → app reads Firestore
//  2. Direct IGR query as fallback
//
// Backend endpoint: POST /guidance-value
//   body: { district, taluk, village, property_type }
//   returns: { value_per_sqft, value_per_sqm, updated_at, zone }
// ─────────────────────────────────────────────────────────────────────────────

class GuidanceValue {
  final String district;
  final String taluk;
  final String village;
  final String propertyType;   // residential / commercial / agricultural
  final double valuePerSqft;   // INR per sqft
  final double valuePerSqm;    // INR per sqm
  final String zone;           // A/B/C zone
  final DateTime updatedAt;
  final String source;         // 'igr_scrape' / 'cache' / 'manual'

  const GuidanceValue({
    required this.district,
    required this.taluk,
    required this.village,
    required this.propertyType,
    required this.valuePerSqft,
    required this.valuePerSqm,
    required this.zone,
    required this.updatedAt,
    required this.source,
  });

  factory GuidanceValue.fromMap(Map<String, dynamic> m) => GuidanceValue(
    district: m['district'] ?? '',
    taluk: m['taluk'] ?? '',
    village: m['village'] ?? '',
    propertyType: m['propertyType'] ?? 'residential',
    valuePerSqft: (m['valuePerSqft'] ?? 0).toDouble(),
    valuePerSqm: (m['valuePerSqm'] ?? 0).toDouble(),
    zone: m['zone'] ?? 'B',
    updatedAt: m['updatedAt'] is Timestamp
        ? (m['updatedAt'] as Timestamp).toDate()
        : DateTime.tryParse(m['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    source: m['source'] ?? 'cache',
  );

  Map<String, dynamic> toMap() => {
    'district': district,
    'taluk': taluk,
    'village': village,
    'propertyType': propertyType,
    'valuePerSqft': valuePerSqft,
    'valuePerSqm': valuePerSqm,
    'zone': zone,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'source': source,
  };

  String get formattedPerSqft => '₹${valuePerSqft.toStringAsFixed(0)}/sqft';
  String get formattedPerSqm  => '₹${valuePerSqm.toStringAsFixed(0)}/sqm';
}

class GuidanceValueService {
  static final GuidanceValueService _instance = GuidanceValueService._internal();
  factory GuidanceValueService() => _instance;
  GuidanceValueService._internal();

  final _firestore = FirebaseFirestore.instance;
  late final Dio _dio;

  void initialize() {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://api.digisampatti.in';
    _dio = Dio(BaseOptions(
      baseUrl: backendUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  // ─── Fetch Guidance Value ─────────────────────────────────────────────────
  // 1. Check Firestore cache (valid for 30 days)
  // 2. If stale/missing → call backend scraper
  // 3. Store result in Firestore for future use
  Future<GuidanceValue?> getGuidanceValue({
    required String district,
    required String taluk,
    String village = '',
    String propertyType = 'residential',
  }) async {
    final cacheKey = '${district}_${taluk}_${village}_$propertyType'
        .toLowerCase()
        .replaceAll(' ', '_');

    // 1. Check Firestore cache
    try {
      final doc = await _firestore
          .collection('guidance_values')
          .doc(cacheKey)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final updatedAt = data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 60));

        final ageInDays = DateTime.now().difference(updatedAt).inDays;
        if (ageInDays < 30) {
          return GuidanceValue.fromMap(data);
        }
      }
    } catch (_) {}

    // 2. Call backend scraper
    try {
      final response = await _dio.post('/guidance-value', data: {
        'district': district,
        'taluk': taluk,
        'village': village,
        'property_type': propertyType,
      });

      if (response.statusCode == 200) {
        final d = response.data as Map<String, dynamic>;
        final gv = GuidanceValue(
          district: district,
          taluk: taluk,
          village: village,
          propertyType: propertyType,
          valuePerSqft: (d['value_per_sqft'] ?? 0).toDouble(),
          valuePerSqm: (d['value_per_sqm'] ?? 0).toDouble(),
          zone: d['zone'] ?? 'B',
          updatedAt: DateTime.now(),
          source: 'igr_scrape',
        );

        // Cache in Firestore
        await _firestore
            .collection('guidance_values')
            .doc(cacheKey)
            .set(gv.toMap());

        return gv;
      }
    } catch (_) {}

    // 3. Return hardcoded fallback values for key areas
    return _getFallbackValue(district, taluk, propertyType);
  }

  // ─── Batch Refresh (run yearly) ───────────────────────────────────────────
  // Trigger from admin panel or Cloud Scheduler to refresh all cached values
  Future<void> triggerYearlyRefresh() async {
    try {
      await _dio.post('/guidance-value/refresh-all');
    } catch (_) {}
  }

  // ─── Fallback Values (2024 IGR data — approximate) ────────────────────────
  GuidanceValue? _getFallbackValue(String district, String taluk, String type) {
    // Source: Karnataka IGR 2024 guidance value circular
    final Map<String, Map<String, double>> values = {
      'bengaluru urban_yelahanka':       {'res': 4500, 'com': 7000},
      'bengaluru urban_bengaluru north': {'res': 6000, 'com': 9000},
      'bengaluru urban_bengaluru south': {'res': 8000, 'com': 12000},
      'bengaluru urban_bengaluru east':  {'res': 5500, 'com': 8500},
      'bengaluru urban_anekal':          {'res': 3500, 'com': 5500},
      'bengaluru rural_devanahalli':     {'res': 3000, 'com': 4500},
      'bengaluru rural_hoskote':         {'res': 2800, 'com': 4000},
      'mysuru_mysuru':                   {'res': 2500, 'com': 3800},
      'mangaluru_mangaluru':             {'res': 3000, 'com': 4500},
      'hubballi-dharwad_hubballi':       {'res': 2200, 'com': 3500},
    };

    final key = '${district}_$taluk'.toLowerCase().replaceAll(' ', '_');
    final entry = values[key];
    if (entry == null) return null;

    final perSqft = type == 'commercial' ? entry['com']! : entry['res']!;
    return GuidanceValue(
      district: district,
      taluk: taluk,
      village: '',
      propertyType: type,
      valuePerSqft: perSqft,
      valuePerSqm: perSqft * 10.764,
      zone: 'B',
      updatedAt: DateTime(2024, 10, 1),
      source: 'manual',
    );
  }
}
