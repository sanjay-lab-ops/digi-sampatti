import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Document Completeness Checker ────────────────────────────────────────────
// Before AI analysis runs, check which documents exist and ask for missing ones.
//
// Each document type has:
//   • Required level: CRITICAL / IMPORTANT / OPTIONAL
//   • Status: uploaded / fetched / missing / skipped
//   • Source: camera upload / Bhoomi fetch / Kaveri fetch / manual entry
//
// Analysis confidence is based on completeness:
//   Critical docs missing → analysis BLOCKED
//   Important docs missing → analysis runs with WARNING
//   Optional docs missing → analysis runs normally
// ──────────────────────────────────────────────────────────────────────────────

enum DocLevel    { critical, important, optional }
enum DocStatus   { missing, uploaded, fetched, skipped }

class RequiredDoc {
  final String id;
  final String title;
  final String titleKannada;
  final String description;   // what it is and why it matters
  final String whyNeeded;     // what analysis misses without it
  final DocLevel level;
  DocStatus status;
  String? sourceName;         // e.g. 'Bhoomi', 'User Upload', 'Kaveri'
  String? uploadedPath;       // local file path if uploaded
  DateTime? verifiedAt;
  final List<String> propertyTypes; // which property types need this

  RequiredDoc({
    required this.id,
    required this.title,
    required this.titleKannada,
    required this.description,
    required this.whyNeeded,
    required this.level,
    this.status = DocStatus.missing,
    this.sourceName,
    this.uploadedPath,
    this.verifiedAt,
    this.propertyTypes = const ['site', 'house', 'apartment', 'bda_layout'],
  });

  bool get isComplete =>
      status == DocStatus.uploaded ||
      status == DocStatus.fetched  ||
      status == DocStatus.skipped;

  bool get isVerified =>
      status == DocStatus.uploaded || status == DocStatus.fetched;
}

// Provider stores the document list for this analysis session
final requiredDocsProvider =
    StateProvider<List<RequiredDoc>>((ref) => _buildDocList(ref));

List<RequiredDoc> _buildDocList(Ref ref) {
  final propType = ref.read(propertyTypeProvider);
  return [
    RequiredDoc(
      id: 'rtc',
      title: 'RTC / Pahani',
      titleKannada: 'ಆರ್‌ಟಿಸಿ / ಪಹಣಿ',
      description: 'Record of Rights, Tenancy & Crops — the land\'s birth certificate. '
          'Shows owner name, land type, extent, and mutation history.',
      whyNeeded: 'Without RTC: cannot verify owner name, land type, or court injunctions. '
          'Analysis will be INCOMPLETE — 40% of risk checks cannot run.',
      level: DocLevel.critical,
      propertyTypes: const ['site', 'house', 'bda_layout'],
    ),
    RequiredDoc(
      id: 'ec',
      title: 'Encumbrance Certificate (EC)',
      titleKannada: 'ಭಾರ ರಹಿತ ಪ್ರಮಾಣ ಪತ್ರ',
      description: 'Lists every transaction on this property for the last 30 years — '
          'mortgages, loans, sales, liens, court attachments.',
      whyNeeded: 'Without EC: cannot detect hidden loans, prior sales, or bank mortgages. '
          'CERSAI catches bank charges; EC catches everything registered at SRO.',
      level: DocLevel.critical,
    ),
    RequiredDoc(
      id: 'khata',
      title: 'Khata Certificate',
      titleKannada: 'ಖಾತಾ ಪ್ರಮಾಣ ಪತ್ರ',
      description: 'Municipal property registration certificate from BBMP/Panchayat. '
          'A-Khata = approved. B-Khata = revenue site with legal issues.',
      whyNeeded: 'Without Khata: cannot confirm A/B Khata status. Bank loans depend on '
          'A-Khata. Missing = significant financing risk.',
      level: DocLevel.important,
      propertyTypes: const ['house', 'apartment', 'bda_layout'],
    ),
    RequiredDoc(
      id: 'mutation',
      title: 'Latest Mutation Order',
      titleKannada: 'ಇತ್ತೀಚಿನ ಪರಿವರ್ತನೆ ಆದೇಶ',
      description: 'Most recent mutation entry in Bhoomi — confirms the latest transfer '
          'of ownership and that seller\'s name is registered.',
      whyNeeded: 'Without mutation: seller\'s ownership chain may have a gap. '
          'If mutation is pending from a previous sale, seller may not have clear title.',
      level: DocLevel.important,
    ),
    RequiredDoc(
      id: 'sale_deed',
      title: 'Previous Sale Deed',
      titleKannada: 'ಹಿಂದಿನ ಮಾರಾಟ ಪತ್ರ',
      description: 'Registered sale deed from when current seller bought this property. '
          'Shows how they acquired it and whether the chain is clean.',
      whyNeeded: 'Without previous deed: ownership chain verification is incomplete. '
          'Gift deeds, inheritance, or disputed transfers may be hidden.',
      level: DocLevel.important,
    ),
    RequiredDoc(
      id: 'rera',
      title: 'RERA Certificate',
      titleKannada: 'ರೇರಾ ಪ್ರಮಾಣ ಪತ್ರ',
      description: 'RERA registration certificate for the apartment/builder project. '
          'Mandatory for all residential projects above 500 sq.m.',
      whyNeeded: 'Without RERA: cannot verify if builder is registered, project is approved, '
          'or escrow account is funded.',
      level: DocLevel.critical,
      propertyTypes: const ['apartment'],
    ),
    RequiredDoc(
      id: 'building_plan',
      title: 'Sanctioned Building Plan',
      titleKannada: 'ಮಂಜೂರು ಕಟ್ಟಡ ಯೋಜನೆ',
      description: 'BBMP/BDA approved building plan showing what was permitted. '
          'Actual structure must match — deviations = demolition risk.',
      whyNeeded: 'Without plan: cannot verify if construction is authorized. '
          'Unauthorized floors or extensions = bank loan rejection.',
      level: DocLevel.important,
      propertyTypes: const ['house', 'apartment'],
    ),
    RequiredDoc(
      id: 'tax_receipt',
      title: 'Latest Property Tax Receipt',
      titleKannada: 'ಆಸ್ತಿ ತೆರಿಗೆ ರಸೀದಿ',
      description: 'Proof that BBMP/Panchayat property tax is paid up to date. '
          'Outstanding tax becomes the new owner\'s liability.',
      whyNeeded: 'Without receipt: cannot confirm tax status. If seller has 5 years '
          'of arrears, you inherit them after purchase.',
      level: DocLevel.optional,
    ),
    RequiredDoc(
      id: 'dc_conversion',
      title: 'DC Conversion Order',
      titleKannada: 'ಡಿಸಿ ಪರಿವರ್ತನೆ ಆದೇಶ',
      description: 'Order from Deputy Commissioner converting agricultural land '
          'to residential/commercial use.',
      whyNeeded: 'Without DC conversion: agricultural land cannot legally be used '
          'for residential construction. No BBMP plan approval possible.',
      level: DocLevel.critical,
      propertyTypes: const ['site', 'bda_layout'],
    ),
  ].where((d) => d.propertyTypes.contains(propType)).toList();
}

class DocumentCompletenessScreen extends ConsumerStatefulWidget {
  const DocumentCompletenessScreen({super.key});
  @override
  ConsumerState<DocumentCompletenessScreen> createState() =>
      _DocumentCompletenessScreenState();
}

class _DocumentCompletenessScreenState
    extends ConsumerState<DocumentCompletenessScreen> {
  final _picker = ImagePicker();
  bool _proceeding = false;

  int get _completedCount =>
      ref.read(requiredDocsProvider).where((d) => d.isComplete).length;

  int get _totalCount => ref.read(requiredDocsProvider).length;

  bool get _canProceed {
    final docs = ref.read(requiredDocsProvider);
    // Cannot proceed if any CRITICAL doc is missing (not uploaded, fetched, or skipped)
    return docs
        .where((d) => d.level == DocLevel.critical)
        .every((d) => d.isComplete);
  }

  String get _completenessLabel {
    final pct = (_completedCount / _totalCount * 100).round();
    if (pct == 100) return 'Complete — full analysis available';
    if (pct >= 70)  return 'Good — analysis with minor gaps';
    if (pct >= 40)  return 'Partial — important checks may be incomplete';
    return 'Incomplete — critical documents missing';
  }

  Color get _completenessColor {
    final pct = (_completedCount / _totalCount * 100).round();
    if (pct == 100) return AppColors.safe;
    if (pct >= 70)  return Colors.orange;
    return Colors.red;
  }

  Future<void> _uploadDocument(RequiredDoc doc) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docs = [...ref.read(requiredDocsProvider)];
    final idx  = docs.indexWhere((d) => d.id == doc.id);
    if (idx < 0) return;
    docs[idx] = RequiredDoc(
      id: doc.id,
      title: doc.title,
      titleKannada: doc.titleKannada,
      description: doc.description,
      whyNeeded: doc.whyNeeded,
      level: doc.level,
      status: DocStatus.uploaded,
      sourceName: 'Camera Upload',
      uploadedPath: picked.path,
      verifiedAt: DateTime.now(),
      propertyTypes: doc.propertyTypes,
    );
    ref.read(requiredDocsProvider.notifier).state = docs;
  }

  void _skipDocument(RequiredDoc doc) {
    final docs = [...ref.read(requiredDocsProvider)];
    final idx  = docs.indexWhere((d) => d.id == doc.id);
    if (idx < 0) return;
    docs[idx] = RequiredDoc(
      id: doc.id,
      title: doc.title,
      titleKannada: doc.titleKannada,
      description: doc.description,
      whyNeeded: doc.whyNeeded,
      level: doc.level,
      status: DocStatus.skipped,
      propertyTypes: doc.propertyTypes,
    );
    ref.read(requiredDocsProvider.notifier).state = docs;
  }

  void _proceedToAnalysis() {
    context.push('/auto-scan');
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(requiredDocsProvider);
    final critical = docs.where((d) => d.level == DocLevel.critical).toList();
    final important = docs.where((d) => d.level == DocLevel.important).toList();
    final optional  = docs.where((d) => d.level == DocLevel.optional).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Checklist'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExplainer(),
                const SizedBox(height: 20),
                _buildDocGroup('Critical — Required for Analysis',
                    critical, AppColors.critical),
                const SizedBox(height: 16),
                _buildDocGroup('Important — Affects Accuracy',
                    important, Colors.orange.shade800),
                if (optional.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDocGroup('Optional — Adds Confidence',
                      optional, AppColors.primary),
                ],
                const SizedBox(height: 24),
                _buildProceedButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final pct = _completedCount / _totalCount;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_completedCount of $_totalCount documents',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_completenessLabel,
                      style: TextStyle(fontSize: 12,
                          color: _completenessColor)),
                ],
              ),
            ),
            Container(
              width: 52, height: 52,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_completenessColor),
                ),
                Text('${(pct * 100).round()}%',
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _completenessColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_completenessColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainer() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.arthBlue.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.arthBlue.withOpacity(0.2)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.info_outline, color: AppColors.arthBlue, size: 18),
          SizedBox(width: 8),
          Text('Why documents matter',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13, color: AppColors.arthBlue)),
        ]),
        SizedBox(height: 6),
        Text(
          'DigiSampatti\'s analysis is only as accurate as the documents provided. '
          'Each document adds evidence to the risk score — the more documents, '
          'the more confident the verdict. Missing a critical document means '
          'a major risk category cannot be checked.\n\n'
          'Upload a photo of each document. You can skip optional ones, '
          'but critical documents are required for a valid analysis.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _buildDocGroup(String heading, List<RequiredDoc> docs, Color color) {
    if (docs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(heading, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 10),
        ...docs.map((doc) => _buildDocCard(doc, color)),
      ],
    );
  }

  Widget _buildDocCard(RequiredDoc doc, Color levelColor) {
    final isComplete = doc.isComplete;
    final isMissing  = doc.status == DocStatus.missing;
    final isSkipped  = doc.status == DocStatus.skipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? (isSkipped ? Colors.orange.shade200 : AppColors.safe.withOpacity(0.4))
              : levelColor.withOpacity(0.3),
          width: isMissing && doc.level == DocLevel.critical ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _statusIcon(doc),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(doc.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                    _levelBadge(doc.level),
                  ]),
                  Text(doc.titleKannada,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                  if (doc.status == DocStatus.fetched ||
                      doc.status == DocStatus.uploaded) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.verified, color: AppColors.safe, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${doc.sourceName ?? "Provided"}'
                        '${doc.verifiedAt != null ? " · ${_dateStr(doc.verifiedAt!)}" : ""}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.safe),
                      ),
                    ]),
                  ],
                ],
              )),
            ]),
          ),

          // Description + action
          if (isMissing || isSkipped) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.description,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.4)),
                  if (isMissing) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber, size: 13, color: levelColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(doc.whyNeeded,
                              style: TextStyle(
                                  fontSize: 11, color: levelColor,
                                  height: 1.4)),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadDocument(doc),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Upload Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 38),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (doc.level != DocLevel.critical) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _skipDocument(doc),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            foregroundColor: Colors.grey,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: Text(isSkipped ? 'Skipped' : 'Skip'),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],

          // Uploaded preview
          if (doc.uploadedPath != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(doc.uploadedPath!),
                      width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Document uploaded',
                          style: TextStyle(color: AppColors.safe,
                              fontWeight: FontWeight.w600, fontSize: 12)),
                      const Text('AI will read this during analysis',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final docs = [...ref.read(requiredDocsProvider)];
                    final idx = docs.indexWhere((d) => d.id == doc.id);
                    if (idx < 0) return;
                    docs[idx].status = DocStatus.missing;
                    docs[idx].uploadedPath = null;
                    ref.read(requiredDocsProvider.notifier).state = [...docs];
                  },
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIcon(RequiredDoc doc) {
    switch (doc.status) {
      case DocStatus.fetched:
      case DocStatus.uploaded:
        return const Icon(Icons.check_circle, color: AppColors.safe, size: 24);
      case DocStatus.skipped:
        return const Icon(Icons.remove_circle_outline,
            color: Colors.orange, size: 24);
      case DocStatus.missing:
        return Icon(
          doc.level == DocLevel.critical
              ? Icons.error : Icons.radio_button_unchecked,
          color: doc.level == DocLevel.critical
              ? Colors.red : Colors.orange,
          size: 24,
        );
    }
  }

  Widget _levelBadge(DocLevel level) {
    final label = switch (level) {
      DocLevel.critical  => 'CRITICAL',
      DocLevel.important => 'IMPORTANT',
      DocLevel.optional  => 'OPTIONAL',
    };
    final color = switch (level) {
      DocLevel.critical  => AppColors.critical,
      DocLevel.important => Colors.orange.shade800,
      DocLevel.optional  => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildProceedButton() {
    final missing = ref.watch(requiredDocsProvider)
        .where((d) => d.level == DocLevel.critical && d.status == DocStatus.missing)
        .toList();

    if (missing.isNotEmpty) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.block, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Cannot proceed — critical documents missing',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: Colors.red, fontSize: 13)),
              ]),
              const SizedBox(height: 6),
              ...missing.map((d) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.close, color: Colors.red, size: 14),
                  const SizedBox(width: 6),
                  Text(d.title,
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                ]),
              )),
            ],
          ),
        ),
      ]);
    }

    final skipped = ref.watch(requiredDocsProvider)
        .where((d) => d.level == DocLevel.important && d.status == DocStatus.missing)
        .length;

    return Column(children: [
      if (skipped > 0) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$skipped important document${skipped > 1 ? "s" : ""} missing. '
                'Analysis will run but some checks will be incomplete.',
                style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
            ),
          ]),
        ),
      ],
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _proceeding ? null : _proceedToAnalysis,
          icon: const Icon(Icons.auto_awesome),
          label: Text(_completedCount == _totalCount
              ? 'Run Full Analysis →'
              : 'Run Analysis with Available Documents →'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ]);
  }

  String _dateStr(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';
}
