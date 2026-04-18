import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Authenticity Layer ────────────────────────────────────────────────────────
// Every risk finding in Arth ID must show:
//   1. Source — which document/portal this finding came from
//   2. Raw evidence — the actual text/data that triggered the flag
//   3. Confidence — how certain is this finding
//   4. Verifiability — how to independently verify
//
// This answers the question: "How do I know this analysis is real?"
// Answer: every finding is traceable to an official document or government portal.
// ──────────────────────────────────────────────────────────────────────────────

enum EvidenceSource {
  bhoomiPortal,     // Official Bhoomi Karnataka portal
  kaveriPortal,     // Kaveri EC portal (IGR)
  ecourtsPortal,    // eCourts India
  cersaiPortal,     // CERSAI national registry
  userUpload,       // Document photographed by user
  aiExtraction,     // AI extracted from uploaded document
  manualEntry,      // User entered manually
  guidanceValue,    // IGR guidance value database
  bbmpPortal,       // BBMP e-Aasthi
}

enum ConfidenceLevel {
  verified,   // Directly from official government portal
  high,       // AI read from official document user uploaded
  medium,     // AI inferred from context clues in document
  low,        // Estimated / calculated / not from primary source
  unverified, // Cannot be independently verified
}

class EvidenceItem {
  final EvidenceSource source;
  final String sourceName;
  final String rawText;        // exact text/data that triggered this finding
  final String explanation;    // plain language: what this means
  final ConfidenceLevel confidence;
  final String? verifyUrl;     // official URL to verify independently
  final String? verifyInstructions;
  final DateTime? fetchedAt;

  const EvidenceItem({
    required this.source,
    required this.sourceName,
    required this.rawText,
    required this.explanation,
    required this.confidence,
    this.verifyUrl,
    this.verifyInstructions,
    this.fetchedAt,
  });

  String get confidenceLabel => switch (confidence) {
    ConfidenceLevel.verified   => 'VERIFIED — Official Portal',
    ConfidenceLevel.high       => 'HIGH — Official Document',
    ConfidenceLevel.medium     => 'MEDIUM — AI Extracted',
    ConfidenceLevel.low        => 'LOW — Estimated',
    ConfidenceLevel.unverified => 'NOT VERIFIED',
  };

  Color get confidenceColor => switch (confidence) {
    ConfidenceLevel.verified   => AppColors.safe,
    ConfidenceLevel.high       => AppColors.info,
    ConfidenceLevel.medium     => Colors.orange,
    ConfidenceLevel.low        => Colors.red.shade300,
    ConfidenceLevel.unverified => Colors.grey,
  };

  IconData get sourceIcon => switch (source) {
    EvidenceSource.bhoomiPortal   => Icons.article_outlined,
    EvidenceSource.kaveriPortal   => Icons.account_balance_outlined,
    EvidenceSource.ecourtsPortal  => Icons.gavel_outlined,
    EvidenceSource.cersaiPortal   => Icons.lock_outlined,
    EvidenceSource.userUpload     => Icons.upload_file,
    EvidenceSource.aiExtraction   => Icons.auto_awesome,
    EvidenceSource.manualEntry    => Icons.edit_note,
    EvidenceSource.guidanceValue  => Icons.attach_money,
    EvidenceSource.bbmpPortal     => Icons.location_city_outlined,
  };
}

// ─── Evidence Card Widget ─────────────────────────────────────────────────────
// Shown below each risk finding in the legal report.
class EvidenceCard extends StatefulWidget {
  final EvidenceItem evidence;
  final String findingTitle;

  const EvidenceCard({
    super.key,
    required this.evidence,
    required this.findingTitle,
  });

  @override
  State<EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<EvidenceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.evidence;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: e.confidenceColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: e.confidenceColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Icon(e.sourceIcon, size: 15, color: e.confidenceColor),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source: ${e.sourceName}',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: e.confidenceColor)),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: e.confidenceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(e.confidenceLabel,
                            style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: e.confidenceColor)),
                      ),
                      if (e.fetchedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(_dateStr(e.fetchedAt!),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey)),
                      ],
                    ]),
                  ],
                )),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: Colors.grey),
              ]),
            ),
          ),

          // Expanded — raw evidence + verify
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Raw evidence text
                  const Text('Evidence from document:',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.rawText.isNotEmpty
                                ? '"${e.rawText}"'
                                : '(extracted by AI from document)',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.black87,
                                height: 1.4),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: e.rawText));
                          },
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Explanation
                  Text(e.explanation,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.4)),
                  // Verify independently
                  if (e.verifyUrl != null || e.verifyInstructions != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.arthBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Verify this independently:',
                              style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.arthBlue)),
                          if (e.verifyInstructions != null) ...[
                            const SizedBox(height: 3),
                            Text(e.verifyInstructions!,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dateStr(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';
}

// ─── Analysis Authenticity Summary ────────────────────────────────────────────
// Shown at top of legal report — overall confidence of the analysis.
class AnalysisAuthenticitySummary extends StatelessWidget {
  final int documentsChecked;
  final int portalsVerified;
  final int aiExtracted;
  final DateTime analysisTime;
  final String reportId;

  const AnalysisAuthenticitySummary({
    super.key,
    required this.documentsChecked,
    required this.portalsVerified,
    required this.aiExtracted,
    required this.analysisTime,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.verified_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Analysis Basis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _stat('$portalsVerified', 'Portals\nchecked', AppColors.safe),
            const SizedBox(width: 12),
            _stat('$documentsChecked', 'Documents\nread', AppColors.arthBlue),
            const SizedBox(width: 12),
            _stat('$aiExtracted', 'AI findings\nextracted', AppColors.esign),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Authenticity chain
          _chainStep(Icons.article_outlined, 'Documents provided',
              'User uploaded official documents or app fetched from government portals',
              AppColors.safe),
          _chainStep(Icons.auto_awesome, 'Claude AI reads documents',
              'claude-sonnet-4-6 extracts data from every document — any Indian language',
              AppColors.esign),
          _chainStep(Icons.rule, '30+ rules checked',
              'Deterministic rule engine checks: injunctions, loans, land type, encumbrances',
              AppColors.arthBlue),
          _chainStep(Icons.score, 'Risk score calculated',
              'Each risk deducts from 100. Score is transparent — see what reduced it',
              Colors.orange),
          _chainStep(Icons.fingerprint, 'Report sealed',
              'Report ID: $reportId · ${_dateStr(analysisTime)} · Tamper-evident',
              AppColors.primary),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Limitation: Arth ID analysis is based on documents provided '
              'and government portals accessible at time of check. '
              'It does not replace a registered property lawyer\'s opinion. '
              'Always verify with a lawyer before registration.',
              style: TextStyle(fontSize: 11, color: Colors.black45, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String num, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(num, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    ),
  );

  Widget _chainStep(IconData icon, String title, String desc, Color color) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
            Text(desc, style: const TextStyle(
                fontSize: 11, color: Colors.grey, height: 1.3)),
          ],
        )),
      ]),
    );

  String _dateStr(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ─── Pre-built evidence for known risk types ──────────────────────────────────
// Used by legal_report_screen to attach evidence to each finding.
class EvidenceBuilder {

  static EvidenceItem forInjunction({
    required String rawMutationText,
    required String caseNumber,
    required DateTime fetchedAt,
  }) => EvidenceItem(
    source: EvidenceSource.bhoomiPortal,
    sourceName: 'Bhoomi RTC — Mutation Register',
    rawText: rawMutationText,
    explanation:
        'A Civil Court issued a Temporary Injunction on this property. '
        'This is recorded in the official Bhoomi mutation register. '
        'The Sub-Registrar cross-checks mutations before accepting any '
        'sale deed — this property CANNOT be registered until the case is resolved.',
    confidence: ConfidenceLevel.verified,
    fetchedAt: fetchedAt,
    verifyUrl: 'https://services.ecourts.gov.in/ecourtindia_v6/',
    verifyInstructions:
        'Open eCourts → Case Status → search "$caseNumber" → '
        'confirm if injunction is still active or vacated.',
  );

  static EvidenceItem forBankLoan({
    required String lenderName,
    required String amount,
    required DateTime fetchedAt,
  }) => EvidenceItem(
    source: EvidenceSource.cersaiPortal,
    sourceName: 'CERSAI — Central Bank Mortgage Registry',
    rawText: 'Lender: $lenderName | Amount: $amount | Status: ACTIVE',
    explanation:
        'This property is registered as security for a bank loan in CERSAI — '
        'the national mortgage registry. If the owner defaults, the bank '
        'will auction this property. The bank\'s charge must be cleared '
        'before you can get a clean title.',
    confidence: ConfidenceLevel.verified,
    fetchedAt: fetchedAt,
    verifyUrl: 'https://cersai.org.in',
    verifyInstructions:
        'Open CERSAI → Secured Asset Search → enter survey number → '
        'confirm if charge is listed and whether it has been satisfied.',
  );

  static EvidenceItem forEncumbrance({
    required int transactionCount,
    required String ecPeriod,
    required DateTime fetchedAt,
  }) => EvidenceItem(
    source: EvidenceSource.kaveriPortal,
    sourceName: 'Kaveri IGRS — Encumbrance Certificate',
    rawText: '$transactionCount transaction(s) found in EC for period: $ecPeriod',
    explanation:
        'The EC lists $transactionCount registered transaction(s) on this property. '
        'Each transaction (sale, mortgage, loan, gift) is a legal event. '
        'Review each entry to confirm the chain of ownership is clean '
        'and no prior sale is outstanding.',
    confidence: ConfidenceLevel.verified,
    fetchedAt: fetchedAt,
    verifyUrl: 'https://kaverionline.karnataka.gov.in',
    verifyInstructions:
        'Open Kaveri Online → EC Search → same survey number → '
        'download EC and compare transaction details.',
  );

  static EvidenceItem forOwnerName({
    required String rtcOwner,
    required String sellerName,
    required DateTime fetchedAt,
  }) => EvidenceItem(
    source: EvidenceSource.bhoomiPortal,
    sourceName: 'Bhoomi RTC — Owner Column',
    rawText: 'RTC shows: "$rtcOwner"\nSeller claims: "$sellerName"',
    explanation: rtcOwner.toLowerCase().trim() == sellerName.toLowerCase().trim()
        ? 'Seller name matches the RTC owner name — ownership verified.'
        : 'WARNING: Seller name does NOT exactly match RTC owner. '
          'This could be a spelling variation, a name change, or fraud. '
          'Ask seller for proof that they are the same person as in RTC.',
    confidence: ConfidenceLevel.verified,
    fetchedAt: fetchedAt,
    verifyUrl: 'https://landrecords.karnataka.gov.in',
    verifyInstructions:
        'Open Bhoomi → enter survey number → check owner column '
        'matches seller\'s Aadhaar name exactly.',
  );

  static EvidenceItem forLandType({
    required String landType,
    required DateTime fetchedAt,
  }) => EvidenceItem(
    source: EvidenceSource.bhoomiPortal,
    sourceName: 'Bhoomi RTC — Land Type Column',
    rawText: 'Land type: "$landType"',
    explanation: _landTypeExplanation(landType),
    confidence: ConfidenceLevel.verified,
    fetchedAt: fetchedAt,
    verifyUrl: 'https://landrecords.karnataka.gov.in',
    verifyInstructions:
        'Open Bhoomi → enter survey number → check "Type of Land" column.',
  );

  static EvidenceItem fromUserUpload({
    required String documentType,
    required String extracted,
    required DateTime uploadedAt,
  }) => EvidenceItem(
    source: EvidenceSource.userUpload,
    sourceName: 'User Uploaded — $documentType',
    rawText: extracted,
    explanation:
        'This finding was extracted by Claude AI from a document '
        'you photographed. The accuracy depends on image quality. '
        'Verify with the original document.',
    confidence: ConfidenceLevel.high,
    fetchedAt: uploadedAt,
    verifyInstructions:
        'Compare with the physical document. If different, re-photograph '
        'in better lighting and rerun analysis.',
  );

  static String _landTypeExplanation(String landType) {
    final lt = landType.toLowerCase();
    if (lt.contains('forest'))     return 'FOREST land: Cannot be sold or built on. Government protected.';
    if (lt.contains('government')) return 'GOVERNMENT land: Cannot be sold. Any sale is void.';
    if (lt.contains('kharab'))     return 'KHARAB land: Wasteland, often disputed. Check for government claims.';
    if (lt.contains('agricultural') || lt.contains('agi')) {
      return 'AGRICULTURAL land: Cannot be used for residential construction without DC Conversion order. '
          'NRI cannot buy agricultural land without RBI permission.';
    }
    if (lt.contains('residential')) return 'RESIDENTIAL land: Approved for building. Verify BBMP/BDA conversion.';
    return 'Land type "$landType" — verify with a lawyer what restrictions apply.';
  }
}
