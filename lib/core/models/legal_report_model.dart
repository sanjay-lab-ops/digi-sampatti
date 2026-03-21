import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';

// ─── Risk Level ───────────────────────────────────────────────────────────────
enum RiskLevel { low, medium, high }

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low: return 'LOW RISK';
      case RiskLevel.medium: return 'MODERATE RISK';
      case RiskLevel.high: return 'HIGH RISK';
    }
  }

  String get recommendation {
    switch (this) {
      case RiskLevel.low: return 'Safe to Buy';
      case RiskLevel.medium: return 'Buy with Caution';
      case RiskLevel.high: return 'Do NOT Buy';
    }
  }
}

// ─── Legal Flag ───────────────────────────────────────────────────────────────
enum FlagStatus { clear, warning, danger, unknown }

class LegalFlag {
  final String category;       // e.g. "Revenue Records", "Khata", "Encumbrance"
  final String title;
  final String details;
  final FlagStatus status;
  final String? actionRequired;

  const LegalFlag({
    required this.category,
    required this.title,
    required this.details,
    required this.status,
    this.actionRequired,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'title': title,
    'details': details,
    'status': status.name,
    'actionRequired': actionRequired,
  };

  factory LegalFlag.fromJson(Map<String, dynamic> json) => LegalFlag(
    category: json['category'],
    title: json['title'],
    details: json['details'],
    status: FlagStatus.values.byName(json['status']),
    actionRequired: json['actionRequired'],
  );
}

// ─── Risk Assessment ──────────────────────────────────────────────────────────
class RiskAssessment {
  final int score;             // 0 - 100 (100 = safest)
  final RiskLevel level;
  final bool isSafeToBuy;
  final bool isBankLoanEligible;
  final String recommendation;
  final String summary;
  final List<LegalFlag> flags;
  final List<String> positives;
  final List<String> concerns;
  final List<String> actionItems;  // What buyer should do before buying

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.isSafeToBuy,
    required this.isBankLoanEligible,
    required this.recommendation,
    required this.summary,
    required this.flags,
    required this.positives,
    required this.concerns,
    required this.actionItems,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'level': level.name,
    'isSafeToBuy': isSafeToBuy,
    'isBankLoanEligible': isBankLoanEligible,
    'recommendation': recommendation,
    'summary': summary,
    'flags': flags.map((f) => f.toJson()).toList(),
    'positives': positives,
    'concerns': concerns,
    'actionItems': actionItems,
  };

  factory RiskAssessment.fromJson(Map<String, dynamic> json) => RiskAssessment(
    score: json['score'],
    level: RiskLevel.values.byName(json['level']),
    isSafeToBuy: json['isSafeToBuy'],
    isBankLoanEligible: json['isBankLoanEligible'],
    recommendation: json['recommendation'],
    summary: json['summary'],
    flags: (json['flags'] as List? ?? [])
        .map((f) => LegalFlag.fromJson(f))
        .toList(),
    positives: List<String>.from(json['positives'] ?? []),
    concerns: List<String>.from(json['concerns'] ?? []),
    actionItems: List<String>.from(json['actionItems'] ?? []),
  );
}

// ─── Full Legal Report ────────────────────────────────────────────────────────
class LegalReport {
  final String reportId;
  final PropertyScan scan;
  final LandRecord? landRecord;
  final ReraRecord? reraRecord;
  final RiskAssessment riskAssessment;
  final String aiAnalysisSummary;
  final String? aiRawResponse;
  final DateTime generatedAt;
  final bool isPaid;
  final String? paymentId;

  const LegalReport({
    required this.reportId,
    required this.scan,
    this.landRecord,
    this.reraRecord,
    required this.riskAssessment,
    required this.aiAnalysisSummary,
    this.aiRawResponse,
    required this.generatedAt,
    required this.isPaid,
    this.paymentId,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'scan': scan.toJson(),
    'landRecord': landRecord?.toJson(),
    'reraRecord': reraRecord?.toJson(),
    'riskAssessment': riskAssessment.toJson(),
    'aiAnalysisSummary': aiAnalysisSummary,
    'aiRawResponse': aiRawResponse,
    'generatedAt': generatedAt.toIso8601String(),
    'isPaid': isPaid,
    'paymentId': paymentId,
  };

  factory LegalReport.fromJson(Map<String, dynamic> json) => LegalReport(
    reportId: json['reportId'],
    scan: PropertyScan.fromJson(json['scan']),
    landRecord: json['landRecord'] != null
        ? LandRecord.fromJson(json['landRecord'])
        : null,
    reraRecord: json['reraRecord'] != null
        ? ReraRecord.fromJson(json['reraRecord'])
        : null,
    riskAssessment: RiskAssessment.fromJson(json['riskAssessment']),
    aiAnalysisSummary: json['aiAnalysisSummary'],
    aiRawResponse: json['aiRawResponse'],
    generatedAt: DateTime.parse(json['generatedAt']),
    isPaid: json['isPaid'] ?? false,
    paymentId: json['paymentId'],
  );
}
