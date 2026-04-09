import 'package:dio/dio.dart';

// ─── CERSAI Service ────────────────────────────────────────────────────────────
// CERSAI = Central Registry of Securitisation Asset Reconstruction and
//          Security Interest of India
//
// What it checks:
//   - Whether the property has any existing mortgage/lien registered with a bank
//   - Loans against the property that may not appear in the EC
//   - SARFAESI Act proceedings (bank trying to seize the property)
//
// Legal basis: RBI mandated all banks to register charges on cersai.org.in
// Public search is free at: https://cersai.org.in/CERSAI/home.htm
//
// API strategy:
//   - CERSAI does NOT have an official public API
//   - We use the public web search (same as any browser)
//   - Read-only access to public records — no scraping, just querying public data
//   - Search by: Property State + District + PIN Code + Survey/Plot Number
// ──────────────────────────────────────────────────────────────────────────────

enum CersaiStatus {
  clean,            // No charge registered
  charged,          // Active mortgage/lien found
  discharged,       // Past mortgage, now released
  sarfaesiAction,   // Bank proceeding to seize under SARFAESI
  error,            // Could not fetch
  notSearched,      // Search not yet performed
}

class CersaiCharge {
  final String bankName;
  final String chargeType;      // Mortgage / Hypothecation / Pledge
  final String chargeDate;
  final String chargeAmount;
  final CersaiStatus status;    // Active / Discharged
  final String? sarfaesiNotice; // Notice date if SARFAESI action

  const CersaiCharge({
    required this.bankName,
    required this.chargeType,
    required this.chargeDate,
    required this.chargeAmount,
    required this.status,
    this.sarfaesiNotice,
  });
}

class CersaiResult {
  final CersaiStatus status;
  final List<CersaiCharge> charges;
  final String? searchReference;
  final DateTime? checkedAt;
  final String? errorMessage;

  const CersaiResult({
    required this.status,
    this.charges = const [],
    this.searchReference,
    this.checkedAt,
    this.errorMessage,
  });

  // If ANY active charge exists → property has outstanding bank loan
  bool get hasActiveLien =>
      charges.any((c) => c.status == CersaiStatus.charged);

  // If SARFAESI action → bank is seizing property — DO NOT BUY
  bool get hasSarfaesiAction =>
      charges.any((c) => c.status == CersaiStatus.sarfaesiAction);

  String get summary {
    if (status == CersaiStatus.clean) return 'No mortgage registered — Clear';
    if (hasSarfaesiAction) return 'SARFAESI action active — Bank seizing property';
    if (hasActiveLien) {
      final banks = charges
          .where((c) => c.status == CersaiStatus.charged)
          .map((c) => c.bankName)
          .join(', ');
      return 'Active mortgage registered — $banks';
    }
    if (status == CersaiStatus.discharged) return 'Past mortgage discharged — Clear';
    if (status == CersaiStatus.error) return 'Could not verify — check manually';
    return 'Not checked';
  }
}

class CersaiService {
  static final CersaiService _instance = CersaiService._internal();
  factory CersaiService() => _instance;
  CersaiService._internal();

  late final Dio _dio;
  bool _initialized = false;
  final Map<String, CersaiResult> _cache = {};

  void initialize() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: 'https://digi-sampatti-production.up.railway.app',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
    _initialized = true;
  }

  Future<CersaiResult> searchBySurveyNumber({
    required String surveyNumber,
    required String district,
    String state = 'Karnataka',
    String? pinCode,
  }) async {
    if (!_initialized) initialize();
    final cacheKey = '$surveyNumber|$district';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final response = await _dio.post('/cersai', data: {
        'state': state,
        'district': district,
        'survey_no': surveyNumber,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final result = _parseBackendResponse(data);
        _cache[cacheKey] = result;
        return result;
      }
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      final result = CersaiResult(
        status: CersaiStatus.error,
        errorMessage: isTimeout
            ? 'CERSAI check timed out. Verify manually at cersai.org.in'
            : 'CERSAI unavailable: ${e.message}',
        checkedAt: DateTime.now(),
      );
      _cache[cacheKey] = result;
      return result;
    }
    return const CersaiResult(status: CersaiStatus.error);
  }

  CersaiResult _parseBackendResponse(Map<String, dynamic> data) {
    final statusStr = data['status']?.toString().toLowerCase() ?? '';
    if (statusStr == 'clean' || data['charges'] == null || (data['charges'] as List?)?.isEmpty == true) {
      return CersaiResult(
        status: CersaiStatus.clean,
        checkedAt: DateTime.now(),
        searchReference: data['ref']?.toString(),
      );
    }
    if (statusStr == 'sarfaesi') {
      return CersaiResult(
        status: CersaiStatus.sarfaesiAction,
        charges: _parseCharges(data['charges'] as List),
        checkedAt: DateTime.now(),
      );
    }
    final isActive = statusStr == 'charged';
    return CersaiResult(
      status: isActive ? CersaiStatus.charged : CersaiStatus.discharged,
      charges: _parseCharges((data['charges'] as List?) ?? []),
      checkedAt: DateTime.now(),
    );
  }

  List<CersaiCharge> _parseCharges(List rawList) {
    return rawList.map((c) {
      final m = c as Map<String, dynamic>;
      final s = m['status']?.toString().toLowerCase() ?? '';
      return CersaiCharge(
        bankName: m['bank']?.toString() ?? 'Unknown Bank',
        chargeType: m['charge_type']?.toString() ?? 'Mortgage',
        chargeDate: m['date']?.toString() ?? 'Unknown',
        chargeAmount: m['amount']?.toString() ?? 'Unknown',
        status: s == 'sarfaesi'
            ? CersaiStatus.sarfaesiAction
            : s == 'discharged'
                ? CersaiStatus.discharged
                : CersaiStatus.charged,
      );
    }).toList();
  }
}
