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

  // Upload-first model: RERA data comes from user-uploaded RERA certificate.
  // Claude Vision OCR extracts reg number, project name, promoter, status.
  // These search methods are retained for future in-app portal search feature.
  Future<List<ReraRecord>> searchByProjectName(String projectName, {String district = ''}) async {
    // No backend scrape — user uploads RERA certificate via document guide
    return [];
  }

  Future<List<ReraRecord>> searchByPromoterName(String promoterName, {String district = ''}) async {
    // No backend scrape — user uploads RERA certificate via document guide
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

  // Upload-first model: EC data comes from user-uploaded EC document.
  // Claude Vision OCR reads EC → OcrToFindingsMapper extracts encumbrance entries.
  Future<List<EncumbranceEntry>> fetchEncumbranceCertificate({
    required String district,
    required String sroOffice,
    required String surveyNumber,
    required int fromYear,
    required int toYear,
  }) async {
    // No backend scrape — user uploads EC from Kaveri portal via document guide
    return [];
  }

  Future<bool> hasActiveMortgage({required String district, required String surveyNumber}) async {
    // Determined from uploaded EC document, not from backend scrape
    return false;
  }

  EncumbranceEntry _parseEntry(Map<String, dynamic> e) {
    final type = e['doc_type']?.toString() ?? e['type']?.toString() ?? 'Unknown';
    final active = ['mortgage', 'hypothecation', 'charge', 'lien'];
    final closed = ['release', 'discharge', 'reconveyance', 'sale'];
    final lower = type.toLowerCase();
    bool isActive = active.any((a) => lower.contains(a)) &&
        !closed.any((c) => lower.contains(c));
    return EncumbranceEntry(
      ecNumber: e['ec_number']?.toString() ?? e['doc_no']?.toString() ?? '',
      type: type,
      partyName: e['party_name']?.toString() ?? e['claimant']?.toString() ?? 'Unknown',
      bankName: e['bank_name']?.toString(),
      amount: double.tryParse(e['amount']?.toString() ?? ''),
      isActive: isActive,
      date: e['date'] != null ? DateTime.tryParse(e['date'].toString()) : null,
    );
  }
}
