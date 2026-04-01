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

  // Cache to avoid repeat calls for same property in same session
  final Map<String, CersaiResult> _cache = {};

  void initialize() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: 'https://cersai.org.in',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        'Accept': 'application/json, text/html',
      },
    ));
    _initialized = true;
  }

  // ─── Search by Survey Number + District ───────────────────────────────────
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
      // CERSAI public search endpoint
      // Parameters: state_id, district_id, property_type, survey_no
      final response = await _dio.get(
        '/CERSAI/searchProperty.htm',
        queryParameters: {
          'state': state,
          'district': district,
          'surveyNo': surveyNumber,
          if (pinCode != null) 'pinCode': pinCode,
        },
      );

      if (response.statusCode == 200) {
        final result = _parseResponse(response.data.toString(), surveyNumber);
        _cache[cacheKey] = result;
        return result;
      }
    } on DioException catch (e) {
      // CERSAI portal is often slow/down — treat as error, not as clean
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      final result = CersaiResult(
        status: CersaiStatus.error,
        errorMessage: isTimeout
            ? 'CERSAI portal timed out. Verify manually at cersai.org.in'
            : 'CERSAI unavailable: ${e.message}',
        checkedAt: DateTime.now(),
      );
      _cache[cacheKey] = result;
      return result;
    }

    return const CersaiResult(status: CersaiStatus.error);
  }

  // ─── Parse HTML/JSON Response ─────────────────────────────────────────────
  CersaiResult _parseResponse(String responseBody, String surveyNumber) {
    final lower = responseBody.toLowerCase();

    // CERSAI returns structured data indicating charges
    // Patterns to detect from their response pages:
    if (lower.contains('no record found') ||
        lower.contains('no charge registered') ||
        lower.contains('0 records')) {
      return CersaiResult(
        status: CersaiStatus.clean,
        checkedAt: DateTime.now(),
        searchReference: 'CERSAI-${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (lower.contains('sarfaesi') || lower.contains('possession notice')) {
      return CersaiResult(
        status: CersaiStatus.sarfaesiAction,
        charges: [
          CersaiCharge(
            bankName: _extractBankName(responseBody),
            chargeType: 'SARFAESI Proceeding',
            chargeDate: _extractDate(responseBody),
            chargeAmount: _extractAmount(responseBody),
            status: CersaiStatus.sarfaesiAction,
            sarfaesiNotice: _extractDate(responseBody),
          ),
        ],
        checkedAt: DateTime.now(),
      );
    }

    if (lower.contains('mortgage') ||
        lower.contains('hypothecation') ||
        lower.contains('charge created')) {
      // Check if it's discharged
      final isActive = !lower.contains('discharged') &&
          !lower.contains('charge satisfied') &&
          !lower.contains('released');

      return CersaiResult(
        status: isActive ? CersaiStatus.charged : CersaiStatus.discharged,
        charges: [
          CersaiCharge(
            bankName: _extractBankName(responseBody),
            chargeType: lower.contains('hypothecation')
                ? 'Hypothecation'
                : 'Mortgage',
            chargeDate: _extractDate(responseBody),
            chargeAmount: _extractAmount(responseBody),
            status: isActive ? CersaiStatus.charged : CersaiStatus.discharged,
          ),
        ],
        checkedAt: DateTime.now(),
      );
    }

    // Unknown response — treat as error, not clean
    return CersaiResult(
      status: CersaiStatus.error,
      errorMessage: 'Unexpected response from CERSAI. Verify manually.',
      checkedAt: DateTime.now(),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _extractBankName(String body) {
    final banks = [
      'SBI', 'HDFC', 'ICICI', 'Axis', 'Canara', 'Union', 'PNB',
      'Bank of Baroda', 'Kotak', 'Yes Bank', 'IndusInd', 'Federal',
    ];
    for (final b in banks) {
      if (body.contains(b)) return b;
    }
    return 'Bank (name not extracted)';
  }

  String _extractDate(String body) {
    final dateRegex = RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}');
    final match = dateRegex.firstMatch(body);
    return match?.group(0) ?? 'Date not available';
  }

  String _extractAmount(String body) {
    final amtRegex = RegExp(r'₹[\d,]+|Rs\.?\s*[\d,]+|INR\s*[\d,]+');
    final match = amtRegex.firstMatch(body);
    return match?.group(0) ?? 'Amount not available';
  }
}
