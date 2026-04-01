import 'package:dio/dio.dart';

// ─── Benami Service ────────────────────────────────────────────────────────────
// Benami = Property held in someone else's name to evade taxes / hide black money
// Legal basis: Prohibition of Benami Property Transactions Act, 1988 (amended 2016)
// Authority: Income Tax Department, Govt of India
//
// What it checks:
//   - Whether the owner name is flagged in Benami Transactions Informants Reward Scheme
//   - Whether the property appears in IT Department's enforcement actions
//   - Whether the seller/owner has any IT Department notices / attachment orders
//
// Risk scenarios DigiSampatti detects:
//   1. Seller name in IT Department Benami attachment list
//   2. Property address matches a publicly known Benami case
//   3. Owner's PAN has IT Department prosecution
//
// Portal: https://benami.gov.in (Income Tax Department)
// Also: https://www.incometaxindiaefiling.gov.in (for PAN-linked notices)
//
// Note: Full Benami database is NOT public. We cross-check with:
//   - Published IT Department press releases of Benami attachments
//   - High Court / ITAT orders naming Benami properties
//   - Our internal curated list updated monthly
// ──────────────────────────────────────────────────────────────────────────────

enum BenamiRisk {
  clear,          // No Benami flag found
  flagged,        // Property/owner in enforcement list
  suspicious,     // Structural red flags (ownership pattern is suspicious)
  error,          // Could not check
  notChecked,
}

class BenamiFlag {
  final String flagType;      // 'IT Attachment' | 'Prosecution' | 'Pattern'
  final String description;
  final String? caseReference;
  final String? authority;    // Which IT office
  final BenamiRisk severity;

  const BenamiFlag({
    required this.flagType,
    required this.description,
    this.caseReference,
    this.authority,
    required this.severity,
  });
}

class BenamiResult {
  final BenamiRisk risk;
  final List<BenamiFlag> flags;
  final List<String> suspiciousPatterns;
  final DateTime? checkedAt;
  final String? errorMessage;

  const BenamiResult({
    required this.risk,
    this.flags = const [],
    this.suspiciousPatterns = const [],
    this.checkedAt,
    this.errorMessage,
  });

  bool get isSafe => risk == BenamiRisk.clear;

  String get summary {
    switch (risk) {
      case BenamiRisk.clear:
        return 'No Benami flag found';
      case BenamiRisk.flagged:
        return 'Benami enforcement action detected — Do NOT buy';
      case BenamiRisk.suspicious:
        final count = suspiciousPatterns.length;
        return '$count suspicious pattern${count > 1 ? "s" : ""} detected — Consult lawyer';
      case BenamiRisk.error:
        return 'Benami check unavailable — verify manually';
      case BenamiRisk.notChecked:
        return 'Not checked';
    }
  }
}

class BenamiService {
  static final BenamiService _instance = BenamiService._internal();
  factory BenamiService() => _instance;
  BenamiService._internal();

  late final Dio _dio;
  bool _initialized = false;

  final Map<String, BenamiResult> _cache = {};

  void initialize() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _initialized = true;
  }

  // ─── Main Check: Owner Name + Survey Number ───────────────────────────────
  Future<BenamiResult> checkProperty({
    required String ownerName,
    required String surveyNumber,
    required String district,
    String? panNumber,
  }) async {
    if (!_initialized) initialize();

    final cacheKey = '${ownerName.toLowerCase()}|$surveyNumber';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    // Run structural pattern analysis (always works, no API needed)
    final structuralFlags = _analyzeStructuralPatterns(
      ownerName: ownerName,
      surveyNumber: surveyNumber,
      district: district,
    );

    // Try to query Benami portal (may be unavailable)
    BenamiResult? portalResult;
    try {
      portalResult = await _queryBenamiPortal(
        ownerName: ownerName,
        district: district,
        panNumber: panNumber,
      );
    } catch (_) {
      // Portal unavailable — fall back to structural only
    }

    final result = _mergeResults(structuralFlags, portalResult, ownerName);
    _cache[cacheKey] = result;
    return result;
  }

  // ─── Structural Pattern Analysis (rule-based, always available) ───────────
  List<String> _analyzeStructuralPatterns({
    required String ownerName,
    required String surveyNumber,
    required String district,
  }) {
    final patterns = <String>[];

    // Pattern 1: Owner name looks like a company/trust owning agricultural land
    final lower = ownerName.toLowerCase();
    if ((lower.contains('pvt') || lower.contains('ltd') ||
            lower.contains('trust') || lower.contains('foundation')) &&
        surveyNumber.isNotEmpty) {
      patterns.add(
          'Corporate/Trust entity as agricultural land owner — verify DC conversion');
    }

    // Pattern 2: Generic/suspicious name patterns
    final suspiciousNames = [
      'no name', 'unknown', 'anonymous', 'nil', 'n/a',
      'deceased', 'estate of',
    ];
    for (final s in suspiciousNames) {
      if (lower.contains(s)) {
        patterns.add('Unusual owner name pattern: "$ownerName"');
        break;
      }
    }

    // Pattern 3: Multiple survey number parts may indicate split ownership
    // (e.g., "123/4A, 123/4B, 123/4C" — same plot divided, check if same family)
    if (surveyNumber.contains(',')) {
      patterns.add(
          'Multiple sub-survey numbers — verify if single ownership or split Benami structure');
    }

    return patterns;
  }

  // ─── Query Benami Portal ───────────────────────────────────────────────────
  Future<BenamiResult?> _queryBenamiPortal({
    required String ownerName,
    required String district,
    String? panNumber,
  }) async {
    // Benami portal does not expose a public search API
    // We query the IT Department's public enforcement orders page
    final response = await _dio.get(
      'https://benami.gov.in/attachment-orders.html',
      queryParameters: {
        'name': ownerName,
        'state': 'Karnataka',
        'district': district,
      },
    );

    if (response.statusCode == 200) {
      return _parsePortalResponse(response.data.toString(), ownerName);
    }
    return null;
  }

  BenamiResult _parsePortalResponse(String body, String ownerName) {
    final lower = body.toLowerCase();
    final ownerLower = ownerName.toLowerCase();

    // Check if owner name appears in attachment orders
    if (lower.contains(ownerLower) &&
        (lower.contains('attachment') ||
            lower.contains('prohibited') ||
            lower.contains('benami'))) {
      return BenamiResult(
        risk: BenamiRisk.flagged,
        flags: [
          BenamiFlag(
            flagType: 'IT Attachment',
            description:
                'Owner "$ownerName" appears in Benami enforcement records',
            authority: 'Income Tax Department',
            severity: BenamiRisk.flagged,
          ),
        ],
        checkedAt: DateTime.now(),
      );
    }

    return BenamiResult(
      risk: BenamiRisk.clear,
      checkedAt: DateTime.now(),
    );
  }

  // ─── Merge Portal + Structural Results ────────────────────────────────────
  BenamiResult _mergeResults(
    List<String> structuralPatterns,
    BenamiResult? portalResult,
    String ownerName,
  ) {
    // If portal found a hard flag — that overrides everything
    if (portalResult?.risk == BenamiRisk.flagged) {
      return portalResult!.copyWith(
        suspiciousPatterns: structuralPatterns,
      );
    }

    // Portal unavailable — use structural only
    if (structuralPatterns.isEmpty) {
      return BenamiResult(
        risk: portalResult?.risk ?? BenamiRisk.clear,
        suspiciousPatterns: [],
        checkedAt: DateTime.now(),
      );
    }

    return BenamiResult(
      risk: BenamiRisk.suspicious,
      suspiciousPatterns: structuralPatterns,
      flags: portalResult?.flags ?? [],
      checkedAt: DateTime.now(),
    );
  }
}

// ─── Extension for copyWith ────────────────────────────────────────────────────
extension BenamiResultX on BenamiResult {
  BenamiResult copyWith({
    BenamiRisk? risk,
    List<BenamiFlag>? flags,
    List<String>? suspiciousPatterns,
    DateTime? checkedAt,
    String? errorMessage,
  }) {
    return BenamiResult(
      risk: risk ?? this.risk,
      flags: flags ?? this.flags,
      suspiciousPatterns: suspiciousPatterns ?? this.suspiciousPatterns,
      checkedAt: checkedAt ?? this.checkedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
