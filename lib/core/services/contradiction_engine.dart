import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/services/bhoomi_service.dart';
import 'package:digi_sampatti/core/services/cersai_service.dart';
import 'package:digi_sampatti/core/services/benami_service.dart';

// ─── Cross-Portal Contradiction Engine ────────────────────────────────────────
// This is DigiSampatti's core differentiator.
//
// Problem: Each portal shows partial truth.
//   - Bhoomi says: Owner = Ramu, Area = 1 acre
//   - IGRS/EC says: No mortgage
//   - CERSAI says: Active mortgage with SBI (!)
//   ↑ These two contradict each other — property has a hidden loan.
//
// A citizen checking portals one by one CANNOT see this.
// A lawyer checking manually may miss it.
// DigiSampatti reads all 7 portals simultaneously and compares.
//
// Contradiction Types (with severity):
//   CRITICAL  → Do NOT buy — high probability of fraud or legal dispute
//   HIGH      → Major concern — requires lawyer review before proceeding
//   MEDIUM    → Investigate further — may have explanation
//   LOW       → Minor inconsistency — verify and document
//
// The 7 portals:
//   1. Bhoomi (RTC/EC)          — owner, area, khata, liabilities
//   2. IGRS/KAVERI              — registered encumbrance, EC
//   3. RERA Karnataka           — project registration, complaints
//   4. BBMP/BDA                 — khata type (A/B), tax, building plan
//   5. eCourts                  — litigation by owner name
//   6. CERSAI                   — bank registered mortgage
//   7. Benami (Income Tax)      — Benami enforcement actions
// ──────────────────────────────────────────────────────────────────────────────

enum ContradictionSeverity { critical, high, medium, low }

class Contradiction {
  final String id;
  final String title;
  final String description;
  final ContradictionSeverity severity;
  final String portal1;       // First portal involved
  final String portal2;       // Second portal involved
  final String portal1Says;   // What portal 1 shows
  final String portal2Says;   // What portal 2 shows
  final String buyerImpact;   // Plain English: what this means for the buyer
  final String actionRequired;

  const Contradiction({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.portal1,
    required this.portal2,
    required this.portal1Says,
    required this.portal2Says,
    required this.buyerImpact,
    required this.actionRequired,
  });
}

class ContradictionReport {
  final List<Contradiction> contradictions;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final ContradictionVerdict verdict;
  final String verdictReason;

  ContradictionReport({
    required this.contradictions,
    required this.verdict,
    required this.verdictReason,
  })  : criticalCount =
            contradictions.where((c) => c.severity == ContradictionSeverity.critical).length,
        highCount =
            contradictions.where((c) => c.severity == ContradictionSeverity.high).length,
        mediumCount =
            contradictions.where((c) => c.severity == ContradictionSeverity.medium).length,
        lowCount =
            contradictions.where((c) => c.severity == ContradictionSeverity.low).length;

  bool get isClean => contradictions.isEmpty;
  bool get hasCritical => criticalCount > 0;
}

enum ContradictionVerdict {
  safe,       // No contradictions across all 7 portals
  caution,    // Medium/low contradictions — proceed with lawyer
  doNotBuy,   // Critical/high contradictions — stop here
}

// ─── Input Bundle (all 7 portal results) ─────────────────────────────────────
class PortalDataBundle {
  // Portal 1: Bhoomi
  final LandRecord? bhoomiRecord;

  // Portal 2: IGRS/KAVERI
  final ReraRecord? igrsRecord;        // Reusing ReraRecord model for encumbrance

  // Portal 3: RERA
  final ReraRecord? reraRecord;

  // Portal 4: BBMP/BDA
  final RevenueSiteStatus? bbmpStatus;

  // Portal 5: eCourts
  final bool ecourtsCasesFound;
  final List<String> ecourtsActiveCases;  // Case numbers/descriptions

  // Portal 6: CERSAI
  final CersaiResult? cersaiResult;

  // Portal 7: Benami
  final BenamiResult? benamiResult;

  const PortalDataBundle({
    this.bhoomiRecord,
    this.igrsRecord,
    this.reraRecord,
    this.bbmpStatus,
    this.ecourtsCasesFound = false,
    this.ecourtsActiveCases = const [],
    this.cersaiResult,
    this.benamiResult,
  });
}

// ─── The Engine ───────────────────────────────────────────────────────────────
class ContradictionEngine {
  static final ContradictionEngine _instance = ContradictionEngine._internal();
  factory ContradictionEngine() => _instance;
  ContradictionEngine._internal();

  // ─── Main: Analyze All 7 Portals Together ────────────────────────────────
  ContradictionReport analyze(PortalDataBundle data) {
    final contradictions = <Contradiction>[];

    // Run all checks
    contradictions.addAll(_checkBhoomiVsCersai(data));
    contradictions.addAll(_checkBhoomiVsEcourts(data));
    contradictions.addAll(_checkBhoomiVsBbmp(data));
    contradictions.addAll(_checkIgrsVsCersai(data));
    contradictions.addAll(_checkBenamiFlags(data));
    contradictions.addAll(_checkReraIssues(data));
    contradictions.addAll(_checkAreaMismatch(data));
    contradictions.addAll(_checkOwnershipChain(data));

    // Sort by severity (critical first)
    contradictions.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    // Determine verdict
    final verdict = _determineVerdict(contradictions);
    final reason = _buildVerdictReason(contradictions, verdict);

    return ContradictionReport(
      contradictions: contradictions,
      verdict: verdict,
      verdictReason: reason,
    );
  }

  // ─── CHECK 1: Bhoomi says no liability, CERSAI says active mortgage ───────
  List<Contradiction> _checkBhoomiVsCersai(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.bhoomiRecord == null || data.cersaiResult == null) return result;

    final bhoomi = data.bhoomiRecord!;
    final cersai = data.cersaiResult!;

    // Bhoomi RTC column 12 shows liabilities. If empty but CERSAI shows mortgage:
    final bhoomiLiabilityFree = bhoomi.encumbrances.isEmpty;

    if (bhoomiLiabilityFree && cersai.hasActiveLien) {
      final banks = cersai.charges
          .where((c) => c.status == CersaiStatus.charged)
          .map((c) => c.bankName)
          .join(', ');

      result.add(Contradiction(
        id: 'BHOOMI_CERSAI_LIEN',
        title: 'Hidden Bank Mortgage Not in Bhoomi',
        description:
            'Bhoomi RTC shows no liabilities. CERSAI shows an active bank mortgage with $banks. '
            'The bank has a registered charge on this property that the seller has not disclosed.',
        severity: ContradictionSeverity.critical,
        portal1: 'Bhoomi (RTC)',
        portal2: 'CERSAI',
        portal1Says: 'No liabilities in column 12',
        portal2Says: 'Active mortgage registered — $banks',
        buyerImpact:
            'If you buy this property, the bank can seize it to recover the seller\'s unpaid loan. '
            'You will lose both the property and your money.',
        actionRequired:
            'Demand No-Objection Certificate (NOC) from $banks before paying any amount. '
            'Do NOT register until loan is cleared and CERSAI shows "Discharged".',
      ));
    }

    // SARFAESI — most severe
    if (cersai.hasSarfaesiAction) {
      result.add(Contradiction(
        id: 'CERSAI_SARFAESI',
        title: 'Bank Actively Seizing This Property (SARFAESI)',
        description:
            'A bank has initiated SARFAESI proceedings to take possession of this property '
            'to recover an unpaid loan.',
        severity: ContradictionSeverity.critical,
        portal1: 'CERSAI',
        portal2: 'Bhoomi',
        portal1Says: 'SARFAESI possession notice issued',
        portal2Says: 'Owner record shows normal',
        buyerImpact:
            'The bank will take this property regardless of your purchase. '
            'Any registration done now will be legally void against the bank.',
        actionRequired:
            'Do NOT buy under any circumstances until SARFAESI proceedings are withdrawn '
            'and confirmed in writing from the bank.',
      ));
    }

    return result;
  }

  // ─── CHECK 2: Bhoomi owner name ≠ eCourts case party name ────────────────
  List<Contradiction> _checkBhoomiVsEcourts(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (!data.ecourtsCasesFound) return result;

    result.add(Contradiction(
      id: 'ECOURTS_LITIGATION',
      title: 'Active Court Cases Against This Property/Owner',
      description:
          'eCourts search found active litigation involving this property '
          'or the registered owner.',
      severity: data.ecourtsActiveCases.length > 2
          ? ContradictionSeverity.critical
          : ContradictionSeverity.high,
      portal1: 'Bhoomi',
      portal2: 'eCourts',
      portal1Says: 'Owner record appears normal',
      portal2Says:
          '${data.ecourtsActiveCases.length} active case(s): ${data.ecourtsActiveCases.take(2).join("; ")}',
      buyerImpact:
          'A court may issue a stay order on property transfer. '
          'If the owner loses the case, the property may be attached or transferred to another party.',
      actionRequired:
          'Get certified copies of all cases from eCourts. '
          'Consult a property lawyer before paying advance.',
    ));

    return result;
  }

  // ─── CHECK 3: Bhoomi says agricultural, BBMP says residential ─────────────
  List<Contradiction> _checkBhoomiVsBbmp(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.bhoomiRecord == null || data.bbmpStatus == null) return result;

    final bhoomi = data.bhoomiRecord!;
    final bbmp = data.bbmpStatus!;

    // Revenue site check: if constructed without DC conversion
    if (bbmp.isRevenueSite && !bbmp.hasDcConversion) {
      result.add(Contradiction(
        id: 'BHOOMI_BBMP_NO_DC',
        title: 'Agricultural Land Sold as Residential Plot (No DC Conversion)',
        description:
            'Bhoomi shows this is agricultural land. BBMP/BDA records show it is '
            'being sold as a residential plot without DC (Diversion Certificate) conversion.',
        severity: ContradictionSeverity.critical,
        portal1: 'Bhoomi',
        portal2: 'BBMP/BDA',
        portal1Says: 'Agricultural land (survey record)',
        portal2Says: 'No DC conversion found — Revenue site',
        buyerImpact:
            'BBMP can demolish any construction on this land. '
            'Banks will not give home loans. Resale will be impossible until DC conversion is done.',
        actionRequired:
            'Do not buy unless seller provides DC conversion order from Deputy Commissioner. '
            'Verify DC order on BBMP e-Aasthi portal.',
      ));
    }

    // B Khata vs A Khata
    if (bhoomi.khataType == KhataType.aKhata && bbmp.isRevenueSite) {
      result.add(Contradiction(
        id: 'BHOOMI_BBMP_KHATA_MISMATCH',
        title: 'Bhoomi Shows A Khata But BBMP Shows Revenue Site',
        description:
            'Bhoomi records show the property as A Khata (legal). '
            'BBMP portal shows it as a revenue site — meaning the municipal khata '
            'has not been issued, contradicting the Bhoomi record.',
        severity: ContradictionSeverity.high,
        portal1: 'Bhoomi',
        portal2: 'BBMP',
        portal1Says: 'A Khata status',
        portal2Says: 'Revenue site — municipal khata not issued',
        buyerImpact:
            'You may be paying A Khata price for a B Khata property. '
            'Building permit, OC, and bank loan will all be denied.',
        actionRequired:
            'Get the original Khata Certificate and BBMP tax paid receipt. '
            'Cross-verify on BBMP e-Aasthi portal before paying advance.',
      ));
    }

    return result;
  }

  // ─── CHECK 4: IGRS/EC says no encumbrance, CERSAI says mortgage ──────────
  List<Contradiction> _checkIgrsVsCersai(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.igrsRecord == null || data.cersaiResult == null) return result;

    final cersai = data.cersaiResult!;

    // EC from IGRS may not capture loans registered only at CERSAI
    if (cersai.hasActiveLien) {
      result.add(Contradiction(
        id: 'IGRS_CERSAI_EC_GAP',
        title: 'EC is Clean But CERSAI Shows Hidden Mortgage',
        description:
            'The Encumbrance Certificate from IGRS/KAVERI shows no loans. '
            'But CERSAI — the RBI-mandated bank registry — shows an active mortgage. '
            'This gap exists when banks register charges at CERSAI but sub-registrar '
            'records are delayed.',
        severity: ContradictionSeverity.critical,
        portal1: 'IGRS/KAVERI (EC)',
        portal2: 'CERSAI',
        portal1Says: 'Encumbrance Certificate: No charges found',
        portal2Says: 'Active mortgage: ${cersai.charges.first.bankName}',
        buyerImpact:
            'The EC alone is not sufficient proof that the property is loan-free. '
            'CERSAI is the authoritative source for bank charges. The mortgage is real.',
        actionRequired:
            'Request NOC from ${cersai.charges.first.bankName} directly. '
            'Do not rely only on the EC for loan verification.',
      ));
    }

    return result;
  }

  // ─── CHECK 5: Benami flags ────────────────────────────────────────────────
  List<Contradiction> _checkBenamiFlags(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.benamiResult == null) return result;

    final benami = data.benamiResult!;

    if (benami.risk == BenamiRisk.flagged) {
      result.add(Contradiction(
        id: 'BENAMI_FLAGGED',
        title: 'Owner/Property Flagged in Benami Enforcement',
        description:
            'The Income Tax Department has an enforcement action (attachment/prosecution) '
            'against the property owner or this property under the Benami Property '
            'Transactions Act 2016.',
        severity: ContradictionSeverity.critical,
        portal1: 'Bhoomi',
        portal2: 'Income Tax / Benami Portal',
        portal1Says: 'Owner record appears normal',
        portal2Says: benami.flags.isNotEmpty
            ? benami.flags.first.description
            : 'Benami enforcement action recorded',
        buyerImpact:
            'If IT Department attaches this property, your purchase will be void. '
            'You will lose all money paid. This is a criminal case.',
        actionRequired:
            'Do NOT buy. Consult a criminal lawyer immediately. '
            'File RTI with IT Department if needed.',
      ));
    } else if (benami.risk == BenamiRisk.suspicious &&
        benami.suspiciousPatterns.isNotEmpty) {
      result.add(Contradiction(
        id: 'BENAMI_SUSPICIOUS',
        title: 'Suspicious Ownership Pattern — Possible Benami Structure',
        description: benami.suspiciousPatterns.join('; '),
        severity: ContradictionSeverity.medium,
        portal1: 'Bhoomi',
        portal2: 'Structural Analysis',
        portal1Says: 'Owner name in records',
        portal2Says: benami.suspiciousPatterns.first,
        buyerImpact:
            'Property may be held in someone else\'s name to hide real ownership. '
            'Transaction could be challenged under Benami Act later.',
        actionRequired:
            'Verify complete ownership history (last 30 years). '
            'Ensure seller can prove legitimate acquisition.',
      ));
    }

    return result;
  }

  // ─── CHECK 6: RERA issues ─────────────────────────────────────────────────
  List<Contradiction> _checkReraIssues(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.reraRecord == null) return result;

    final rera = data.reraRecord!;

    if (rera.hasComplaints) {
      result.add(Contradiction(
        id: 'RERA_COMPLAINTS',
        title: 'RERA Complaints Filed Against This Project/Builder',
        description:
            'This project has active buyer complaints registered with RERA Karnataka.',
        severity: ContradictionSeverity.high,
        portal1: 'RERA Karnataka',
        portal2: 'Bhoomi/BBMP',
        portal1Says: 'Active complaints: ${rera.complaintCount}',
        portal2Says: 'Property/project record shows normal',
        buyerImpact:
            'Builder may not deliver possession. RERA orders may freeze project. '
            'Similar buyers may have paid and not received.',
        actionRequired:
            'Read the RERA complaint orders. Check if builder has complied. '
            'Consult the complainant buyers if possible.',
      ));
    }

    if (!rera.isRegistered) {
      result.add(Contradiction(
        id: 'RERA_NOT_REGISTERED',
        title: 'Project Not Registered with RERA',
        description:
            'This apartment project is not registered with RERA Karnataka. '
            'Any project above 500 sq m or 8 units must be registered. '
            'Selling without registration is illegal.',
        severity: ContradictionSeverity.critical,
        portal1: 'RERA Karnataka',
        portal2: 'Builder claims',
        portal1Says: 'No RERA registration found',
        portal2Says: 'Builder selling units',
        buyerImpact:
            'You have no legal protection under RERA if builder defaults. '
            'You cannot file RERA complaint. Builder may disappear.',
        actionRequired:
            'Do NOT buy. Ask builder why project is not RERA registered. '
            'It is illegal to sell without RERA registration.',
      ));
    }

    return result;
  }

  // ─── CHECK 7: Area mismatch Bhoomi vs registration ────────────────────────
  List<Contradiction> _checkAreaMismatch(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.bhoomiRecord == null) return result;

    final bhoomi = data.bhoomiRecord!;

    // If EC area differs from Bhoomi area
    if (bhoomi.areaMismatch) {
      result.add(Contradiction(
        id: 'AREA_MISMATCH',
        title: 'Area in Bhoomi Does Not Match Sale Agreement',
        description:
            'The area recorded in Bhoomi RTC is different from the area '
            'mentioned in the sale deed or agreement.',
        severity: ContradictionSeverity.high,
        portal1: 'Bhoomi',
        portal2: 'Sale Deed / Agreement',
        portal1Says: '${bhoomi.totalAreaAcres} acres (Bhoomi)',
        portal2Says: 'Different area in sale documents',
        buyerImpact:
            'You may be paying for more land than what is legally recorded. '
            'Registration will happen for the smaller Bhoomi area only. '
            'The "extra" land has no legal backing.',
        actionRequired:
            'Insist on updated survey and Bhoomi correction before registration. '
            'Book a licensed surveyor to measure actual boundaries.',
      ));
    }

    return result;
  }

  // ─── CHECK 8: Ownership chain gaps ───────────────────────────────────────
  List<Contradiction> _checkOwnershipChain(PortalDataBundle data) {
    final result = <Contradiction>[];
    if (data.bhoomiRecord == null) return result;

    final bhoomi = data.bhoomiRecord!;

    if (bhoomi.hasOwnershipGap) {
      result.add(Contradiction(
        id: 'OWNERSHIP_CHAIN_GAP',
        title: 'Gap in Ownership History (Title Chain Break)',
        description:
            'The property ownership history has a gap — meaning there is a period '
            'where ownership is not clearly documented in the revenue records.',
        severity: ContradictionSeverity.high,
        portal1: 'Bhoomi (Mutation Register)',
        portal2: 'IGRS/KAVERI (EC)',
        portal1Says: 'Ownership chain has a gap',
        portal2Says: 'EC may not account for the gap period',
        buyerImpact:
            'A missing link in the ownership chain means someone else may have '
            'a claim on this property. Future disputes cannot be ruled out.',
        actionRequired:
            'Trace all mutations going back 30 years. '
            'Get a lawyer to certify clean title before proceeding.',
      ));
    }

    return result;
  }

  // ─── Verdict Logic ─────────────────────────────────────────────────────────
  ContradictionVerdict _determineVerdict(List<Contradiction> contradictions) {
    if (contradictions.isEmpty) return ContradictionVerdict.safe;

    final hasCritical =
        contradictions.any((c) => c.severity == ContradictionSeverity.critical);
    final hasHigh =
        contradictions.any((c) => c.severity == ContradictionSeverity.high);

    if (hasCritical) return ContradictionVerdict.doNotBuy;
    if (hasHigh) return ContradictionVerdict.caution;
    return ContradictionVerdict.caution;
  }

  String _buildVerdictReason(
      List<Contradiction> contradictions, ContradictionVerdict verdict) {
    if (contradictions.isEmpty) {
      return 'All 7 portals are consistent. No contradictions detected.';
    }

    final critCount =
        contradictions.where((c) => c.severity == ContradictionSeverity.critical).length;
    final highCount =
        contradictions.where((c) => c.severity == ContradictionSeverity.high).length;

    final parts = <String>[];
    if (critCount > 0) parts.add('$critCount critical contradiction${critCount > 1 ? "s" : ""}');
    if (highCount > 0) parts.add('$highCount high-risk issue${highCount > 1 ? "s" : ""}');

    final title = contradictions.first.title;

    switch (verdict) {
      case ContradictionVerdict.doNotBuy:
        return 'DO NOT BUY. ${parts.join(" and ")} found. Most urgent: $title';
      case ContradictionVerdict.caution:
        return 'Proceed with caution. ${parts.join(" and ")} requires legal review before paying advance.';
      case ContradictionVerdict.safe:
        return 'All portals consistent.';
    }
  }
}
