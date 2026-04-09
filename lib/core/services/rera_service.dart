import 'package:dio/dio.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';

// ─── RERA Karnataka Service ────────────────────────────────────────────────────
// Karnataka RERA: rera.karnataka.gov.in
// Under Real Estate (Regulation and Development) Act, 2016
// All residential/commercial projects >500 sqm or >8 units MUST register

class ReraService {
  static final ReraService _instance = ReraService._internal();
  factory ReraService() => _instance;
  ReraService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.reraBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));
  }

  // ─── Search RERA by Project Name ───────────────────────────────────────────
  Future<List<ReraRecord>> searchByProjectName(String projectName) async {
    try {
      final response = await _dio.get(
        ApiConstants.reraProjectSearch,
        queryParameters: {
          'projectName': projectName,
          'state': 'Karnataka',
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['projects'] ?? [];
        return data.map((p) => _parseReraRecord(p)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ─── Search RERA by Registration Number ───────────────────────────────────
  Future<ReraRecord?> searchByRegistrationNumber(String regNumber) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.reraProjectSearch}/$regNumber',
      );

      if (response.statusCode == 200) {
        return _parseReraRecord(response.data);
      }
    } catch (_) {}
    return null;
  }

  // ─── Search by Promoter Name ───────────────────────────────────────────────
  Future<List<ReraRecord>> searchByPromoterName(String promoterName) async {
    try {
      final response = await _dio.get(
        ApiConstants.reraPromotorSearch,
        queryParameters: {'promoterName': promoterName},
      );

      if (response.statusCode == 200) {
        final List data = response.data['promoters'] ?? [];
        return data.map((p) => _parseReraRecord(p)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ─── Check If Location Needs RERA Registration ────────────────────────────
  // Projects near this GPS coordinate
  Future<List<ReraRecord>> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 1.0,
  }) async {
    // RERA portal does not have a public location API. Return empty for individual plots.
    return [];
  }

  // ─── Check Promoter Complaints ────────────────────────────────────────────
  Future<int> getComplaintCount(String promoterName) async {
    try {
      final response = await _dio.get(
        ApiConstants.reraComplaintSearch,
        queryParameters: {'promoterName': promoterName},
      );

      if (response.statusCode == 200) {
        return (response.data['totalComplaints'] ?? 0) as int;
      }
    } catch (_) {}
    return 0;
  }

  // ─── Parse RERA Record ────────────────────────────────────────────────────
  ReraRecord _parseReraRecord(Map<String, dynamic> data) {
    return ReraRecord(
      registrationNumber: data['reraRegNo']?.toString(),
      projectName: data['projectName']?.toString(),
      promoterName: data['promoterName']?.toString(),
      isRegistered: data['isRegistered'] == true || data['status'] == 'Active',
      registrationDate: data['registrationDate'] != null
          ? DateTime.tryParse(data['registrationDate'].toString())
          : null,
      expiryDate: data['expiryDate'] != null
          ? DateTime.tryParse(data['expiryDate'].toString())
          : null,
      projectStatus: data['projectStatus']?.toString(),
      projectType: data['projectType']?.toString(),
      totalUnits: int.tryParse(data['totalUnits']?.toString() ?? ''),
      websiteUrl: data['websiteUrl']?.toString(),
    );
  }
}

// ─── Encumbrance Certificate (EC) Service ─────────────────────────────────────
// IGRS Karnataka: igr.karnataka.gov.in
// EC = history of all registered transactions on a property (mortgages, sales, etc.)

class EncumbranceService {
  static final EncumbranceService _instance = EncumbranceService._internal();
  factory EncumbranceService() => _instance;
  EncumbranceService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.igrsBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));
  }

  // ─── Fetch EC (Encumbrance Certificate) ───────────────────────────────────
  // EC for last 30 years is standard requirement for property purchase
  Future<List<EncumbranceEntry>> fetchEncumbranceCertificate({
    required String district,
    required String sroOffice,   // Sub-Registrar Office
    required String surveyNumber,
    required int fromYear,
    required int toYear,
  }) async {
    // IGRS portal does not have a public API — EC data is included in Bhoomi record
    return [];
  }

  // ─── Check Active Mortgages ────────────────────────────────────────────────
  Future<bool> hasActiveMortgage({
    required String district,
    required String surveyNumber,
  }) async {
    final entries = await fetchEncumbranceCertificate(
      district: district,
      sroOffice: district,
      surveyNumber: surveyNumber,
      fromYear: DateTime.now().year - 30,
      toYear: DateTime.now().year,
    );

    return entries.any((e) =>
        e.isActive && e.type.toLowerCase().contains('mortgage'));
  }

  bool _isActiveEncumbrance(String? documentType) {
    if (documentType == null) return false;
    final active = ['mortgage', 'hypothecation', 'charge', 'lien'];
    final closed = ['release', 'discharge', 'reconveyance', 'sale'];

    final lower = documentType.toLowerCase();
    if (closed.any((c) => lower.contains(c))) return false;
    if (active.any((a) => lower.contains(a))) return true;
    return false;
  }
}
