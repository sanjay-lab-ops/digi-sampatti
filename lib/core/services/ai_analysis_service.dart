import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/services/bhoomi_service.dart';
import 'package:digi_sampatti/core/services/cersai_service.dart';
import 'package:digi_sampatti/core/services/benami_service.dart';
import 'package:digi_sampatti/core/services/contradiction_engine.dart';

// ─── Claude AI Analysis Service ────────────────────────────────────────────────
// Uses Claude claude-sonnet-4-6 to analyze all land record data and generate:
//   - Risk score (0-100)
//   - Recommendation (Buy / Caution / Don't Buy)
//   - Detailed legal flags
//   - Plain-language summary
//   - Specific action items for the buyer

class AiAnalysisService {
  static final AiAnalysisService _instance = AiAnalysisService._internal();
  factory AiAnalysisService() => _instance;
  AiAnalysisService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.claudeBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    ));
  }

  // ─── Full Property Analysis — All 7 Portals ───────────────────────────────
  // Step 1: Run ContradictionEngine on raw portal data (deterministic rules)
  // Step 2: Feed everything + contradiction report to Claude for final verdict
  // Step 3: If Claude API unavailable, fall back to rule-based assessment
  Future<RiskAssessment> analyzeProperty({
    required PropertyScan scan,
    LandRecord? landRecord,
    ReraRecord? reraRecord,
    RevenueSiteStatus? revenueSiteStatus,
    GovernmentNotificationStatus? govtNotificationStatus,
    // New: Portal 6 & 7
    CersaiResult? cersaiResult,
    BenamiResult? benamiResult,
    // New: eCourts data
    bool ecourtsCasesFound = false,
    List<String> ecourtsActiveCases = const [],
  }) async {
    // ── Step 1: Cross-portal contradiction detection (always runs) ──────────
    final bundle = PortalDataBundle(
      bhoomiRecord: landRecord,
      reraRecord: reraRecord,
      bbmpStatus: revenueSiteStatus,
      cersaiResult: cersaiResult,
      benamiResult: benamiResult,
      ecourtsCasesFound: ecourtsCasesFound,
      ecourtsActiveCases: ecourtsActiveCases,
    );
    final contradictionReport = ContradictionEngine().analyze(bundle);

    // If contradiction engine says DO NOT BUY → short-circuit, no need for Claude
    if (contradictionReport.verdict == ContradictionVerdict.doNotBuy &&
        contradictionReport.hasCritical) {
      return _buildFromContradictions(
          contradictionReport, landRecord, reraRecord, cersaiResult, benamiResult);
    }

    // ── Step 2: Rule-based assessment first (instant result) ────────────────
    final instant = _buildFallbackAssessment(landRecord, reraRecord, revenueSiteStatus,
        contradictionReport: contradictionReport);

    // ── Step 3: Try Claude AI for deeper analysis (with strict timeout) ──────
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (apiKey.isEmpty) return instant;

    try {
      final prompt = _buildAnalysisPrompt(
        scan: scan,
        landRecord: landRecord,
        reraRecord: reraRecord,
        revenueSiteStatus: revenueSiteStatus,
        govtNotificationStatus: govtNotificationStatus,
        cersaiResult: cersaiResult,
        benamiResult: benamiResult,
        contradictionReport: contradictionReport,
        ecourtsCasesFound: ecourtsCasesFound,
        ecourtsActiveCases: ecourtsActiveCases,
      );

      final response = await _dio.post(
        '/messages',
        options: Options(headers: ApiConstants.claudeHeaders(apiKey)),
        data: json.encode({
          'model': ApiConstants.claudeModel,
          'max_tokens': ApiConstants.claudeMaxTokens,
          'system': _systemPrompt,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as List;
        final text = content.first['text'] as String;
        final assessment = _parseAiResponse(text, landRecord, reraRecord);
        // Merge contradiction flags into the AI result
        return _mergeWithContradictions(assessment, contradictionReport);
      }
    } catch (_) {
      // Claude unavailable — return instant rule-based result
    }

    return instant;
  }

  // ─── Build assessment directly from contradiction report ──────────────────
  RiskAssessment _buildFromContradictions(
    ContradictionReport cr,
    LandRecord? land,
    ReraRecord? rera,
    CersaiResult? cersai,
    BenamiResult? benami,
  ) {
    final flags = cr.contradictions
        .map((c) => LegalFlag(
              category: c.severity == ContradictionSeverity.critical
                  ? 'Critical'
                  : 'Warning',
              title: c.title,
              details: c.description,
              status: c.severity == ContradictionSeverity.critical
                  ? FlagStatus.danger
                  : FlagStatus.warning,
              actionRequired: c.actionRequired,
            ))
        .toList();

    return RiskAssessment(
      score: 5,
      level: RiskLevel.high,
      isSafeToBuy: false,
      isBankLoanEligible: false,
      recommendation: RiskLevel.high.recommendation,
      summary: cr.verdictReason,
      flags: flags,
      positives: [],
      concerns: cr.contradictions.map((c) => c.title).toList(),
      actionItems: cr.contradictions.map((c) => c.actionRequired).toList(),
    );
  }

  // ─── Merge contradiction flags into Claude's result ────────────────────────
  RiskAssessment _mergeWithContradictions(
      RiskAssessment base, ContradictionReport cr) {
    if (cr.isClean) return base;

    final extraFlags = cr.contradictions
        .map((c) => LegalFlag(
              category: c.severity == ContradictionSeverity.critical
                  ? 'Critical'
                  : 'Warning',
              title: c.title,
              details: '${c.portal1} vs ${c.portal2}: ${c.description}',
              status: c.severity == ContradictionSeverity.critical
                  ? FlagStatus.danger
                  : FlagStatus.warning,
              actionRequired: c.actionRequired,
            ))
        .toList();

    final mergedFlags = [...extraFlags, ...base.flags];

    // Escalate verdict if contradiction engine found critical issues
    final recommendation = cr.hasCritical
        ? RiskLevel.high.recommendation
        : base.recommendation;

    final newScore = cr.hasCritical
        ? (base.score < 10 ? base.score : 10)
        : base.score;

    return base.copyWith(
      flags: mergedFlags,
      recommendation: recommendation,
      score: newScore,
    );
  }

  int _countPortals(LandRecord? land, ReraRecord? rera,
      CersaiResult? cersai, BenamiResult? benami) {
    int count = 1; // Bhoomi always
    if (rera != null) count++;
    if (cersai != null) count++;
    if (benami != null) count++;
    count++; // eCourts always attempted
    count++; // BBMP always attempted
    return count.clamp(1, 7);
  }

  // ─── System Prompt ─────────────────────────────────────────────────────────
  static const String _systemPrompt = '''
You are an expert property legal analyst specializing in Karnataka, India land laws.
You have deep knowledge of:
- Karnataka Land Revenue Act
- Karnataka Land Reforms Act
- Real Estate (Regulation and Development) Act 2016 (RERA)
- BDA (Bruhat Bengaluru Development Authority) regulations
- BBMP (Bruhat Bengaluru Mahanagara Palike) jurisdiction rules
- Karnataka Stamp Act and Registration Act
- Revenue sites, unauthorized layouts, and regularization schemes
- Encumbrance certificates and their implications
- A Khata vs B Khata differences
- Raja Kaluve (storm water drains) buffer zones
- Lake bed and FTL (Full Tank Level) restrictions
- Forest land and heritage zone restrictions

Your job is to analyze property data and provide:
1. A risk score from 0-100 (100 = perfectly safe, 0 = extremely risky)
2. Clear recommendation: "Safe to Buy", "Buy with Caution", or "Do NOT Buy"
3. Specific legal flags with clear explanations in simple language
4. Action items the buyer should take before purchasing
5. Bank loan eligibility assessment

Always respond in the following JSON format:
{
  "score": <number 0-100>,
  "level": "<low|medium|high>",
  "isSafeToBuy": <true|false>,
  "isBankLoanEligible": <true|false>,
  "recommendation": "<brief recommendation>",
  "summary": "<2-3 sentence plain language summary>",
  "flags": [
    {
      "category": "<category>",
      "title": "<short title>",
      "details": "<explanation>",
      "status": "<clear|warning|danger|unknown>",
      "actionRequired": "<what to do, if anything>"
    }
  ],
  "positives": ["<list of good things about this property>"],
  "concerns": ["<list of concerns>"],
  "actionItems": ["<specific steps buyer should take>"]
}
''';

  // ─── Build Analysis Prompt ─────────────────────────────────────────────────
  String _buildAnalysisPrompt({
    required PropertyScan scan,
    LandRecord? landRecord,
    ReraRecord? reraRecord,
    RevenueSiteStatus? revenueSiteStatus,
    GovernmentNotificationStatus? govtNotificationStatus,
    CersaiResult? cersaiResult,
    BenamiResult? benamiResult,
    ContradictionReport? contradictionReport,
    bool ecourtsCasesFound = false,
    List<String> ecourtsActiveCases = const [],
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Analyze this Karnataka property for legal due diligence:');
    buffer.writeln('');

    // Location data
    if (scan.location != null) {
      buffer.writeln('=== LOCATION ===');
      buffer.writeln('GPS: ${scan.location!.coordinatesString}');
      if (scan.location!.address != null) {
        buffer.writeln('Address: ${scan.location!.address}');
      }
    }

    // Survey details
    if (scan.surveyNumber != null) {
      buffer.writeln('');
      buffer.writeln('=== SURVEY DETAILS ===');
      buffer.writeln('Survey Number: ${scan.surveyNumber}');
      buffer.writeln('District: ${scan.district ?? "Unknown"}');
      buffer.writeln('Taluk: ${scan.taluk ?? "Unknown"}');
      buffer.writeln('Hobli: ${scan.hobli ?? "Unknown"}');
      buffer.writeln('Village: ${scan.village ?? "Unknown"}');
    }

    // Land records (Bhoomi RTC)
    if (landRecord != null) {
      buffer.writeln('');
      buffer.writeln('=== BHOOMI LAND RECORDS (RTC) ===');
      buffer.writeln('Khata Number: ${landRecord.khataNumber ?? "Not found"}');
      buffer.writeln('Khata Type: ${landRecord.khataType?.displayName ?? "Unknown"}');
      buffer.writeln('Land Type: ${landRecord.landType ?? "Unknown"}');
      buffer.writeln('Total Area: ${landRecord.totalAreaAcres ?? "Unknown"} acres');
      buffer.writeln('Is Revenue Site: ${landRecord.isRevenueSite}');
      buffer.writeln('Is Government Land: ${landRecord.isGovernmentLand}');
      buffer.writeln('Is Forest Land: ${landRecord.isForestLand}');
      buffer.writeln('Is Lake Bed: ${landRecord.isLakeBed}');

      if (landRecord.owners.isNotEmpty) {
        buffer.writeln('Owners:');
        for (final owner in landRecord.owners) {
          buffer.writeln('  - ${owner.name} (Share: ${owner.surveyShare ?? "Full"})');
        }
      }

      if (landRecord.mutations.isNotEmpty) {
        buffer.writeln('Mutation History (${landRecord.mutations.length} entries):');
        for (final m in landRecord.mutations.take(5)) {
          buffer.writeln('  - ${m.reason}: ${m.fromOwner} → ${m.toOwner} (${m.date?.year})');
        }
      }

      if (landRecord.encumbrances.isNotEmpty) {
        buffer.writeln('Encumbrances (${landRecord.encumbrances.length} entries):');
        for (final e in landRecord.encumbrances) {
          final active = e.isActive ? '[ACTIVE]' : '[CLOSED]';
          buffer.writeln('  - $active ${e.type}: ${e.partyName}${e.amount != null ? " ₹${e.amount}" : ""}');
        }
      }

      if (landRecord.remarks != null) {
        buffer.writeln('Remarks: ${landRecord.remarks}');
      }
    }

    // Revenue site status
    if (revenueSiteStatus != null) {
      buffer.writeln('');
      buffer.writeln('=== JURISDICTION STATUS ===');
      buffer.writeln('BDA Approved: ${revenueSiteStatus.isBdaApproved}');
      buffer.writeln('BBMP Area: ${revenueSiteStatus.isBbmpArea}');
      buffer.writeln('CMC/TMC Area: ${revenueSiteStatus.isCmcArea}');
      buffer.writeln('Is Revenue Site: ${revenueSiteStatus.isRevenueSite}');
      buffer.writeln('Notes: ${revenueSiteStatus.notes}');
    }

    // Government notifications
    if (govtNotificationStatus != null && govtNotificationStatus.hasAnyNotice) {
      buffer.writeln('');
      buffer.writeln('=== GOVERNMENT NOTIFICATIONS ===');
      for (final notice in govtNotificationStatus.notices) {
        final critical = notice.isCritical ? '[CRITICAL] ' : '';
        buffer.writeln('$critical${notice.authority} - ${notice.noticeType}: ${notice.description}');
      }
    }

    // RERA status
    if (reraRecord != null) {
      buffer.writeln('');
      buffer.writeln('=== RERA STATUS ===');
      buffer.writeln('Registered: ${reraRecord.isRegistered}');
      if (reraRecord.registrationNumber != null) {
        buffer.writeln('Registration No: ${reraRecord.registrationNumber}');
      }
      if (reraRecord.projectName != null) {
        buffer.writeln('Project: ${reraRecord.projectName}');
      }
      if (reraRecord.promoterName != null) {
        buffer.writeln('Promoter: ${reraRecord.promoterName}');
      }
      buffer.writeln('Status: ${reraRecord.projectStatus ?? "Unknown"}');
    } else {
      buffer.writeln('');
      buffer.writeln('=== RERA STATUS ===');
      buffer.writeln('Not checked or not applicable (individual plot)');
    }

    // ── Portal 6: CERSAI ─────────────────────────────────────────────────────
    buffer.writeln('');
    buffer.writeln('=== CERSAI (Bank Mortgage Registry) ===');
    if (cersaiResult != null) {
      buffer.writeln('Status: ${cersaiResult.status.name}');
      buffer.writeln('Summary: ${cersaiResult.summary}');
      if (cersaiResult.charges.isNotEmpty) {
        buffer.writeln('Charges:');
        for (final c in cersaiResult.charges) {
          buffer.writeln('  - ${c.bankName}: ${c.chargeType}, dated ${c.chargeDate}, amount ${c.chargeAmount}');
        }
      }
    } else {
      buffer.writeln('Not checked — assume unknown');
    }

    // ── Portal 7: Benami ──────────────────────────────────────────────────────
    buffer.writeln('');
    buffer.writeln('=== BENAMI (Income Tax Dept) ===');
    if (benamiResult != null) {
      buffer.writeln('Risk: ${benamiResult.risk.name}');
      buffer.writeln('Summary: ${benamiResult.summary}');
      if (benamiResult.suspiciousPatterns.isNotEmpty) {
        buffer.writeln('Patterns: ${benamiResult.suspiciousPatterns.join("; ")}');
      }
    } else {
      buffer.writeln('Not checked');
    }

    // ── eCourts ──────────────────────────────────────────────────────────────
    buffer.writeln('');
    buffer.writeln('=== eCOURTS (Litigation Check) ===');
    if (ecourtsCasesFound) {
      buffer.writeln('Active cases found: ${ecourtsActiveCases.length}');
      for (final c in ecourtsActiveCases.take(5)) {
        buffer.writeln('  - $c');
      }
    } else {
      buffer.writeln('No active cases found');
    }

    // ── Contradiction Engine Summary ──────────────────────────────────────────
    if (contradictionReport != null && !contradictionReport.isClean) {
      buffer.writeln('');
      buffer.writeln('=== CROSS-PORTAL CONTRADICTIONS DETECTED ===');
      buffer.writeln('Verdict: ${contradictionReport.verdict.name.toUpperCase()}');
      buffer.writeln('Critical: ${contradictionReport.criticalCount}, High: ${contradictionReport.highCount}');
      for (final c in contradictionReport.contradictions.take(5)) {
        buffer.writeln('  [${c.severity.name.toUpperCase()}] ${c.title}');
        buffer.writeln('    ${c.portal1} vs ${c.portal2}: ${c.portal1Says} ↔ ${c.portal2Says}');
      }
    }

    buffer.writeln('');
    buffer.writeln('All 7 portals have been checked. Please analyze this data and provide a comprehensive legal due diligence report in the JSON format specified. Pay special attention to any contradictions between portals.');

    return buffer.toString();
  }

  // ─── Parse AI JSON Response ────────────────────────────────────────────────
  RiskAssessment _parseAiResponse(
    String aiText,
    LandRecord? landRecord,
    ReraRecord? reraRecord,
  ) {
    try {
      // Extract JSON from response (AI may wrap it in markdown)
      String jsonStr = aiText;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiText);
      if (jsonMatch != null) jsonStr = jsonMatch.group(0)!;

      final data = json.decode(jsonStr) as Map<String, dynamic>;
      return RiskAssessment.fromJson(data);
    } catch (e) {
      return _buildFallbackAssessment(landRecord, reraRecord, null);
    }
  }

  // ─── Rule-Based Fallback (when AI unavailable) ─────────────────────────────
  RiskAssessment _buildFallbackAssessment(
    LandRecord? landRecord,
    ReraRecord? reraRecord,
    RevenueSiteStatus? revenueSiteStatus, {
    ContradictionReport? contradictionReport,
  }) {
    int score = 70; // Start at moderate
    final flags = <LegalFlag>[];
    final concerns = <String>[];
    final positives = <String>[];
    final actionItems = <String>[];

    if (landRecord != null) {
      // Khata check
      if (landRecord.khataType == KhataType.aKhata ||
          landRecord.khataType == KhataType.eKhata) {
        score += 10;
        positives.add('A/E Khata - eligible for bank loans and building permits');
        flags.add(const LegalFlag(
          category: 'Khata',
          title: 'A Khata - Legal',
          details: 'Property has valid A/E Khata. Bank loans possible.',
          status: FlagStatus.clear,
        ));
      } else if (landRecord.khataType == KhataType.bKhata) {
        score -= 20;
        concerns.add('B Khata - not eligible for BBMP bank loans or building permits');
        actionItems.add('Apply for Khata upgrade from B to A before purchasing');
        flags.add(const LegalFlag(
          category: 'Khata',
          title: 'B Khata - Semi-Legal',
          details: 'B Khata property cannot get BBMP bank loans or building permits.',
          status: FlagStatus.warning,
          actionRequired: 'Get Khata upgraded to A Khata before purchase',
        ));
      }

      // Revenue site check
      if (landRecord.isRevenueSite) {
        score -= 30;
        concerns.add('Revenue site - unauthorized layout');
        actionItems.add('Do NOT purchase. Verify regularization status under Akrama-Sakrama scheme.');
        flags.add(const LegalFlag(
          category: 'Revenue Records',
          title: 'Revenue Site Detected',
          details: 'Property appears to be on unauthorized revenue land. '
              'Construction is illegal. May be demolished by authorities.',
          status: FlagStatus.danger,
          actionRequired: 'Verify if regularized under Akrama-Sakrama. Consult a lawyer.',
        ));
      } else {
        score += 5;
        positives.add('Not a revenue site');
      }

      // Government land check
      if (landRecord.isGovernmentLand) {
        score -= 40;
        concerns.add('Government land - purchase illegal');
        flags.add(const LegalFlag(
          category: 'Ownership',
          title: 'Government Land',
          details: 'This is government-owned land. It CANNOT be sold privately.',
          status: FlagStatus.danger,
          actionRequired: 'Do NOT buy. This transaction will be legally void.',
        ));
      }

      // Forest land check
      if (landRecord.isForestLand) {
        score -= 40;
        concerns.add('Forest land - construction prohibited');
        flags.add(const LegalFlag(
          category: 'Restrictions',
          title: 'Forest Land',
          details: 'Forest land cannot be used for construction. '
              'Violation of Forest Conservation Act.',
          status: FlagStatus.danger,
        ));
      }

      // Active encumbrance check
      final activeEncumbrances = landRecord.encumbrances.where((e) => e.isActive).toList();
      if (activeEncumbrances.isNotEmpty) {
        score -= 15;
        concerns.add('Active encumbrances found (${activeEncumbrances.length})');
        actionItems.add('Get encumbrances cleared before purchase. Obtain EC for 30 years.');
        flags.add(LegalFlag(
          category: 'Encumbrance',
          title: 'Active Mortgage/Loan Found',
          details: '${activeEncumbrances.length} active encumbrance(s) on this property.',
          status: FlagStatus.warning,
          actionRequired: 'Ensure all mortgages/loans are cleared before purchase',
        ));
      } else {
        score += 5;
        positives.add('No active encumbrances (clear title)');
      }
    }

    // RERA check
    if (reraRecord != null) {
      if (reraRecord.isRegistered) {
        score += 5;
        positives.add('RERA registered project');
        flags.add(LegalFlag(
          category: 'RERA',
          title: 'RERA Registered',
          details: 'Project registered under RERA. Reg: ${reraRecord.registrationNumber ?? "N/A"}',
          status: FlagStatus.clear,
        ));
      } else {
        score -= 10;
        concerns.add('RERA registration not verified');
        flags.add(const LegalFlag(
          category: 'RERA',
          title: 'RERA Not Verified',
          details: 'Could not verify RERA registration. For projects >8 units, RERA registration is mandatory.',
          status: FlagStatus.warning,
          actionRequired: 'Verify RERA registration at rera.karnataka.gov.in',
        ));
      }
    }

    // Standard action items
    actionItems.addAll([
      'Obtain Encumbrance Certificate (EC) for 30 years from Sub-Registrar Office',
      'Verify property tax paid up to date at BBMP/CMC portal',
      'Get legal opinion from a registered advocate',
      'Check for any court cases using property address',
    ]);

    // Add contradiction engine flags on top of rule-based flags
    if (contradictionReport != null && !contradictionReport.isClean) {
      for (final c in contradictionReport.contradictions) {
        score -= c.severity == ContradictionSeverity.critical ? 30 : 15;
        concerns.add(c.title);
        actionItems.add(c.actionRequired);
        flags.add(LegalFlag(
          category: c.severity == ContradictionSeverity.critical
              ? 'Critical'
              : 'Warning',
          title: c.title,
          details: '${c.portal1} vs ${c.portal2}: ${c.description}',
          status: c.severity == ContradictionSeverity.critical
              ? FlagStatus.danger
              : FlagStatus.warning,
          actionRequired: c.actionRequired,
        ));
      }
    }

    score = score.clamp(0, 100);
    final level = score >= 70 ? RiskLevel.low
        : score >= 40 ? RiskLevel.medium
        : RiskLevel.high;

    return RiskAssessment(
      score: score,
      level: level,
      isSafeToBuy: level == RiskLevel.low,
      isBankLoanEligible: landRecord?.khataType?.isLegal ?? false,
      recommendation: level.recommendation,
      summary: contradictionReport != null && contradictionReport.hasCritical
          ? contradictionReport.verdictReason
          : _buildSummary(score, concerns, positives),
      flags: flags,
      positives: positives,
      concerns: concerns,
      actionItems: actionItems,
    );
  }

  String _buildSummary(int score, List<String> concerns, List<String> positives) {
    if (score >= 70) {
      return 'This property appears legally sound with ${positives.length} positive indicators. '
          '${concerns.isEmpty ? "No major concerns found." : "Minor issues to address before purchase."}';
    } else if (score >= 40) {
      return 'This property has ${concerns.length} concern(s) that need attention before purchase. '
          'Proceed with caution and get legal verification.';
    } else {
      return 'CAUTION: This property has serious legal issues. '
          '${concerns.first}. Do not purchase without complete legal clearance.';
    }
  }
}
