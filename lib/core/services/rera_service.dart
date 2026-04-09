import 'package:dio/dio.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';

// ─── RERA Karnataka Service ────────────────────────────────────────────────────
// Routes through Railway backend scraper (/rera endpoint)

class ReraService {
  static final ReraService _instance = ReraService._internal();
  factory ReraService() => _instance;
  ReraService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<List<ReraRecord>> searchByProjectName(String projectName, {String district = ''}) async {
    try {
      final response = await _dio.post(ApiConstants.backendReraEndpoint, data: {
        'project_name': projectName,
        'district': district,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final projects = data['projects'];
        if (projects is List) {
          return projects.map((p) => _parseReraRecord(p as Map<String, dynamic>)).toList();
        }
        // Single result
        if (data['project_name'] != null || data['reg_no'] != null) {
          return [_parseReraRecord(data)];
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<ReraRecord>> searchByPromoterName(String promoterName, {String district = ''}) async {
    try {
      final response = await _dio.post(ApiConstants.backendReraEndpoint, data: {
        'promoter': promoterName,
        'district': district,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final projects = data['projects'];
        if (projects is List) {
          return projects.map((p) => _parseReraRecord(p as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<ReraRecord>> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 1.0,
  }) async {
    // Railway backend doesn't expose GPS-based RERA search; return empty for plots
    return [];
  }

  ReraRecord _parseReraRecord(Map<String, dynamic> data) {
    return ReraRecord(
      registrationNumber: data['reg_no']?.toString() ?? data['reraRegNo']?.toString(),
      projectName: data['project_name']?.toString() ?? data['projectName']?.toString(),
      promoterName: data['promoter']?.toString() ?? data['promoterName']?.toString(),
      isRegistered: data['is_registered'] == true || data['status'] == 'Active',
      projectStatus: data['status']?.toString() ?? data['projectStatus']?.toString(),
      projectType: data['project_type']?.toString(),
      totalUnits: int.tryParse(data['total_units']?.toString() ?? ''),
    );
  }
}

// ─── Encumbrance Certificate (EC) Service ─────────────────────────────────────
// Routes through Railway backend scraper (/ec endpoint — Kaveri portal)

class EncumbranceService {
  static final EncumbranceService _instance = EncumbranceService._internal();
  factory EncumbranceService() => _instance;
  EncumbranceService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<List<EncumbranceEntry>> fetchEncumbranceCertificate({
    required String district,
    required String sroOffice,
    required String surveyNumber,
    required int fromYear,
    required int toYear,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.backendEcEndpoint, data: {
        'district': district,
        'taluk': sroOffice,
        'survey_number': surveyNumber,
        'from_year': fromYear,
        'to_year': toYear,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final entries = data['entries'];
        if (entries is List) {
          return entries.map((e) => _parseEntry(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<bool> hasActiveMortgage({required String district, required String surveyNumber}) async {
    final entries = await fetchEncumbranceCertificate(
      district: district, sroOffice: district, surveyNumber: surveyNumber,
      fromYear: DateTime.now().year - 30, toYear: DateTime.now().year,
    );
    return entries.any((e) => e.isActive && e.type.toLowerCase().contains('mortgage'));
  }

  EncumbranceEntry _parseEntry(Map<String, dynamic> e) {
    final type = e['doc_type']?.toString() ?? e['type']?.toString() ?? 'Unknown';
    final active = ['mortgage', 'hypothecation', 'charge', 'lien'];
    final closed = ['release', 'discharge', 'reconveyance', 'sale'];
    final lower = type.toLowerCase();
    bool isActive = active.any((a) => lower.contains(a)) &&
        !closed.any((c) => lower.contains(c));
    return EncumbranceEntry(
      type: type,
      partyName: e['party_name']?.toString() ?? e['claimant']?.toString() ?? 'Unknown',
      bankName: e['bank_name']?.toString(),
      amount: double.tryParse(e['amount']?.toString() ?? ''),
      isActive: isActive,
      registrationDate: e['date'] != null ? DateTime.tryParse(e['date'].toString()) : null,
    );
  }
}
