import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/ocr_service.dart';
import 'package:digi_sampatti/core/services/ocr_to_findings_mapper.dart';
import 'package:digi_sampatti/features/portal_checklist/portal_checklist_screen.dart';

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
enum DocStatus   { missing, uploaded, fetched, skipped, physicalVisit, notExists }

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
      status == DocStatus.skipped  ||
      status == DocStatus.physicalVisit;
  // notExists is NOT complete — it's a blocker

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

// Smart insight from reading a document
class _DocInsight {
  final Color color;
  final IconData icon;
  final String message;
  const _DocInsight({required this.color, required this.icon, required this.message});
}

class _DocumentCompletenessScreenState
    extends ConsumerState<DocumentCompletenessScreen> {
  final _picker    = ImagePicker();
  final _ocrService = OcrService();
  bool _proceeding  = false;
  // Tracks which doc is currently running OCR
  final Set<String> _ocrRunning = {};
  // Stores OCR summary per doc id
  final Map<String, String> _ocrSummary = {};
  // Stores smart flags per doc id
  final Map<String, List<_DocInsight>> _docInsights = {};
  // Tracks which card is currently selected/tapped
  String? _selectedDocId;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
  }

  int get _completedCount =>
      ref.read(requiredDocsProvider).where((d) => d.isComplete).length;

  int get _totalCount => ref.read(requiredDocsProvider).length;

  bool get _canProceed {
    final docs = ref.read(requiredDocsProvider);
    // Cannot proceed if any CRITICAL doc is missing or explicitly doesn't exist
    // physicalVisit = allowed (analysis runs with reduced confidence)
    // notExists = allowed but flagged as critical risk in report
    return docs
        .where((d) => d.level == DocLevel.critical)
        .every((d) => d.status != DocStatus.missing);
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
    final choice = await _showSourceDialog();
    if (choice == null) return;

    String? filePath;

    if (choice == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      filePath = result?.files.single.path;
    } else {
      final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      filePath = picked?.path;
    }

    if (filePath == null || !mounted) return;

    // Mark as uploaded immediately so UI updates
    _updateDocStatus(doc, DocStatus.uploaded, filePath);

    // Run OCR in background — show "Reading document..." indicator
    setState(() => _ocrRunning.add(doc.id));
    try {
      final ocrResult = await _ocrService.extractFromDocument(filePath);
      if (!mounted) return;

      // Build a human-readable summary of what was extracted
      final parts = <String>[];
      if (ocrResult.surveyNumber != null) parts.add('Survey: ${ocrResult.surveyNumber}');
      if (ocrResult.ownerName    != null) parts.add('Owner: ${ocrResult.ownerName}');
      if (ocrResult.district     != null) parts.add('District: ${ocrResult.district}');
      if (ocrResult.taluk        != null) parts.add('Taluk: ${ocrResult.taluk}');
      if (ocrResult.documentType != null) parts.add('Type: ${ocrResult.documentType}');

      // Detect critical flags
      if (ocrResult.hasUsefulData) {
        // Merge findings into portal findings provider for auto-scan rule engine
        final findings = OcrToFindingsMapper.fromOcrResult(ocrResult);
        final existing = ref.read(portalFindingsProvider);
        ref.read(portalFindingsProvider.notifier).state = existing.copyWith(
          bhoomiOpened:  (existing.bhoomiOpened  ?? false) || (findings.bhoomiOpened  ?? false),
          hasCourtCases: (existing.hasCourtCases ?? false) || (findings.hasCourtCases ?? false),
          hasActiveLoan: (existing.hasActiveLoan ?? false) || (findings.hasActiveLoan ?? false),
          kaveriOpened:  (existing.kaveriOpened  ?? false) || (findings.kaveriOpened  ?? false),
        );
      }

      // Build smart insights from rawText
      final insights = _buildInsights(ocrResult, doc);

      setState(() {
        _ocrRunning.remove(doc.id);
        _ocrSummary[doc.id] = parts.isEmpty
            ? 'Document read — check insights below'
            : parts.join(' · ');
        _docInsights[doc.id] = insights;
      });

      // If agricultural land detected, auto-add DC conversion to critical list
      if (ocrResult.agriculturalLand) {
        final docs = [...ref.read(requiredDocsProvider)];
        final dcIdx = docs.indexWhere((d) => d.id == 'dc_conversion');
        if (dcIdx >= 0 && docs[dcIdx].status == DocStatus.skipped) {
          docs[dcIdx] = RequiredDoc(
            id: docs[dcIdx].id, title: docs[dcIdx].title,
            titleKannada: docs[dcIdx].titleKannada,
            description: docs[dcIdx].description,
            whyNeeded: docs[dcIdx].whyNeeded,
            level: docs[dcIdx].level, status: DocStatus.missing,
            propertyTypes: docs[dcIdx].propertyTypes,
          );
          ref.read(requiredDocsProvider.notifier).state = docs;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _ocrRunning.remove(doc.id));
    }
  }

  // ── Smart insight generation from OCR result ────────────────────────────────
  List<_DocInsight> _buildInsights(OcrResult ocr, RequiredDoc doc) {
    final insights = <_DocInsight>[];

    // 1. INJUNCTION — highest priority, use structured flag
    if (ocr.injunctionDetected) {
      insights.add(const _DocInsight(
        color: Colors.red,
        icon: Icons.gavel,
        message: 'Court injunction or stay order detected — do NOT proceed without a lawyer',
      ));
    }

    // 2. Liabilities in RTC
    if (ocr.liabilities != null && ocr.liabilities!.isNotEmpty) {
      insights.add(_DocInsight(
        color: Colors.red.shade700,
        icon: Icons.warning,
        message: 'Liabilities noted in document: ${ocr.liabilities}',
      ));
    }

    // 3. Remarks (may contain court notices, government acquisition, etc.)
    if (ocr.remarks != null && ocr.remarks!.isNotEmpty) {
      insights.add(_DocInsight(
        color: Colors.orange.shade800,
        icon: Icons.info_outline,
        message: 'Remarks: ${ocr.remarks}',
      ));
    }

    // 4. Agricultural land → DC conversion needed (structured flag)
    if (ocr.agriculturalLand) {
      insights.add(_DocInsight(
        color: Colors.deepOrange,
        icon: Icons.agriculture,
        message: 'Land type: ${ocr.landType ?? "Agricultural"} — '
            'DC Conversion Order required before construction',
      ));
    }

    // 5. EC: mortgage / encumbrance (structured)
    if (ocr.hasActiveMortgage) {
      insights.add(const _DocInsight(
        color: Colors.orange,
        icon: Icons.account_balance,
        message: 'Active mortgage or loan found in EC — must be cleared before purchase',
      ));
    }
    if (ocr.encumbranceFree == true) {
      insights.add(const _DocInsight(
        color: Colors.green,
        icon: Icons.verified_outlined,
        message: 'EC is encumbrance-free — no loans or mortgages on record',
      ));
    }
    if (ocr.ecTransactionCount != null && ocr.ecTransactionCount! > 0) {
      final types = ocr.ecTransactions
          .map((t) => t['type']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet().join(', ');
      insights.add(_DocInsight(
        color: Colors.blue.shade700,
        icon: Icons.list_alt,
        message: '${ocr.ecTransactionCount} transaction(s) in EC'
            '${types.isNotEmpty ? ": $types" : ""}',
      ));
    }

    // 6. Sale deed — seller name
    if (ocr.sellerName != null) {
      insights.add(_DocInsight(
        color: Colors.blue.shade800,
        icon: Icons.swap_horiz,
        message: 'Sale Deed: Seller = ${ocr.sellerName}'
            '${ocr.buyerName != null ? " → Buyer = ${ocr.buyerName}" : ""}',
      ));
    }

    // 7. Owner name — verify against seller
    if (ocr.ownerName != null && doc.id == 'rtc') {
      insights.add(_DocInsight(
        color: Colors.green.shade700,
        icon: Icons.person_outline,
        message: 'RTC Owner: ${ocr.ownerName} — confirm this matches seller\'s Aadhaar/PAN',
      ));
    }

    // 8. Extent / area
    if (ocr.extent != null) {
      insights.add(_DocInsight(
        color: Colors.teal,
        icon: Icons.straighten,
        message: 'Land extent: ${ocr.extent}',
      ));
    }

    // 9. "Next document" guidance
    final nextDoc = _nextDocNeeded(doc.id);
    if (nextDoc != null) {
      insights.add(_DocInsight(
        color: Colors.blue.shade600,
        icon: Icons.arrow_forward_outlined,
        message: nextDoc,
      ));
    }

    return insights;
  }

  bool _isAgriculturalLand(String raw) =>
      raw.contains('agricultural') ||
      raw.contains('wet land') || raw.contains('wetland') ||
      raw.contains('dry land') || raw.contains('dryland') ||
      raw.contains('krishi') || raw.contains('bagayat') ||
      raw.contains('kharab') || raw.contains('shivar');

  String? _nextDocNeeded(String docId) => switch (docId) {
    'rtc'        => 'Next: Upload EC to check for loans, mortgages, and past transactions',
    'ec'         => 'Next: Upload Sale Deed to verify the ownership chain',
    'sale_deed'  => 'Next: Upload Khata Certificate to confirm municipal registration',
    'khata'      => 'Next: Upload Property Tax Receipt to confirm no outstanding dues',
    _            => null,
  };

  Future<String?> _showSourceDialog() async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Upload Document',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          const SizedBox(height: 4),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Photo or PDF — AI reads both.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
                textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.surfaceGreen,
                child: Icon(Icons.camera_alt, color: AppColors.primary)),
            title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Camera — best for physical documents'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.photo_library, color: Colors.blue.shade700)),
            title: const Text('Pick Image from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Screenshot from Bhoomi / Kaveri portal'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.red.shade50,
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700)),
            title: const Text('Upload PDF', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Downloaded EC, RTC PDF, or digitally signed doc'),
            onTap: () => Navigator.pop(context, 'pdf'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _updateDocStatus(RequiredDoc doc, DocStatus status, String? path) {
    final docs = [...ref.read(requiredDocsProvider)];
    final idx  = docs.indexWhere((d) => d.id == doc.id);
    if (idx < 0) return;
    docs[idx] = RequiredDoc(
      id: doc.id, title: doc.title, titleKannada: doc.titleKannada,
      description: doc.description, whyNeeded: doc.whyNeeded,
      level: doc.level, status: status,
      sourceName: 'Camera Upload', uploadedPath: path,
      verifiedAt: DateTime.now(), propertyTypes: doc.propertyTypes,
    );
    ref.read(requiredDocsProvider.notifier).state = docs;
    _syncDocGapsToFindings(docs);
  }

  void _skipDocument(RequiredDoc doc) => _setDocStatus(doc, DocStatus.skipped);

  void _setDocStatus(RequiredDoc doc, DocStatus status) {
    final docs = [...ref.read(requiredDocsProvider)];
    final idx  = docs.indexWhere((d) => d.id == doc.id);
    if (idx < 0) return;
    docs[idx] = RequiredDoc(
      id: doc.id, title: doc.title, titleKannada: doc.titleKannada,
      description: doc.description, whyNeeded: doc.whyNeeded,
      level: doc.level, status: status, propertyTypes: doc.propertyTypes,
    );
    ref.read(requiredDocsProvider.notifier).state = docs;
    _syncDocGapsToFindings(docs);
  }

  /// Syncs document gap flags to portalFindingsProvider so auto-scan and
  /// AI analysis know exactly what was and wasn't verified.
  void _syncDocGapsToFindings(List<RequiredDoc> docs) {
    DocStatus statusOf(String id) =>
        docs.firstWhere((d) => d.id == id,
            orElse: () => RequiredDoc(
                id: id, title: '', titleKannada: '', description: '',
                whyNeeded: '', level: DocLevel.optional))
            .status;

    final physicalDocs = docs
        .where((d) => d.status == DocStatus.physicalVisit)
        .map((d) => d.title)
        .toList();
    final notExistsDocs = docs
        .where((d) => d.status == DocStatus.notExists)
        .map((d) => d.title)
        .toList();

    final existing = ref.read(portalFindingsProvider);
    ref.read(portalFindingsProvider.notifier).state = existing.copyWith(
      // EC not provided → encumbrance unknown
      ecNotProvided: statusOf('ec') == DocStatus.notExists ||
          statusOf('ec') == DocStatus.physicalVisit,
      // Kaveri opened only if EC was actually uploaded
      kaveriOpened: statusOf('ec') == DocStatus.uploaded ||
          statusOf('ec') == DocStatus.fetched,
      // DC conversion explicitly doesn't exist
      dcConversionNotExists: statusOf('dc_conversion') == DocStatus.notExists,
      // Mutation not approved
      mutationPending: statusOf('mutation') == DocStatus.notExists,
      // Tax dues unknown
      taxDuesUnknown: statusOf('tax_receipt') == DocStatus.notExists ||
          statusOf('tax_receipt') == DocStatus.missing,
      // Khata not available
      khataNotAvailable: statusOf('khata') == DocStatus.notExists,
      physicalVisitDocs: physicalDocs,
      notExistsDocs: notExistsDocs,
    );
  }

  // Show "I can't get this" options dialog
  Future<void> _showCannotGetDialog(RequiredDoc doc) async {
    final state = ref.read(selectedStateProvider);
    final officeHint = _physicalOfficeHint(doc.id, state);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Cannot get ${doc.title}?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Tell us why — it changes your risk score',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.directions_walk, color: Colors.blue)),
            title: const Text('Will get physically', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(officeHint),
            onTap: () {
              Navigator.pop(context);
              _setDocStatus(doc, DocStatus.physicalVisit);
            },
          ),
          if (doc.id == 'dc_conversion')
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.block, color: Colors.red.shade700)),
              title: const Text('DC Conversion does not exist',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Agricultural land was never legally converted — '
                  'construction on this land is ILLEGAL'),
              onTap: () {
                Navigator.pop(context);
                _setDocStatus(doc, DocStatus.notExists);
                _showCriticalBlockDialog(
                  'DC Conversion Not Found',
                  'This agricultural land has no DC Conversion Order. '
                  'Under the Karnataka Land Revenue Act, constructing on '
                  'unconverted agricultural land is ILLEGAL. You cannot:\n\n'
                  '• Get BBMP building plan approval\n'
                  '• Get a bank home loan on this property\n'
                  '• Register a sale deed for residential use\n\n'
                  'Ask the seller to produce the conversion order before proceeding.',
                );
              },
            )
          else if (doc.id == 'ec')
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange.shade50,
                  child: Icon(Icons.warning_amber, color: Colors.orange.shade700)),
              title: const Text('EC not available — encumbrance unknown',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Without EC, hidden loans and mortgages CANNOT be detected'),
              onTap: () {
                Navigator.pop(context);
                _setDocStatus(doc, DocStatus.notExists);
              },
            )
          else
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.help_outline, color: Colors.red.shade700)),
              title: const Text('Seller cannot produce this document',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('This will be flagged in the risk report'),
              onTap: () {
                Navigator.pop(context);
                _setDocStatus(doc, DocStatus.notExists);
              },
            ),
          if (doc.level != DocLevel.critical)
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF3E5F5),
                  child: Icon(Icons.skip_next, color: Colors.purple)),
              title: const Text('Skip for now', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Not critical — analysis will note the gap'),
              onTap: () {
                Navigator.pop(context);
                _setDocStatus(doc, DocStatus.skipped);
              },
            ),
          // Legal support CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showLegalSupportDialog(doc);
              },
              icon: const Icon(Icons.support_agent, size: 16),
              label: const Text('Get Legal Support'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: AppColors.arthBlue,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  void _showCriticalBlockDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.dangerous, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(title,
              style: const TextStyle(color: Colors.red, fontSize: 16))),
        ]),
        content: Text(message,
            style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Understood')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showLegalSupportDialog(null);
            },
            icon: const Icon(Icons.support_agent, size: 16),
            label: const Text('Get Legal Advice'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showLegalSupportDialog(RequiredDoc? doc) {
    final state = ref.read(selectedStateProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.support_agent, color: AppColors.arthBlue),
          SizedBox(width: 8),
          Text('Legal Support', style: TextStyle(fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doc != null) ...[
              Text('Issue with: ${doc.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
            ],
            Text(
              'A property lawyer can help you:\n'
              '• Check if the missing document can be obtained\n'
              '• Assess legal risk before purchase\n'
              '• Send a legal notice to the seller\n'
              '• Review the sale agreement',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.arthBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Where to get help in $state:\n'
                '${_legalSupportInfo(state)}',
                style: const TextStyle(fontSize: 11, height: 1.5,
                    color: AppColors.arthBlue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  // State-specific physical office to visit for a given document
  String _physicalOfficeHint(String docId, String state) {
    final offices = switch (state) {
      'Karnataka' => {
        'ec':           'Visit Sub-Registrar Office (SRO) with survey no. — EC in 1-2 days',
        'rtc':          'Visit Village Accountant (VA) or Bhoomi kiosk at Taluk office',
        'dc_conversion':'Visit DC office or landconversion.karnataka.gov.in',
        'khata':        'Visit BBMP ward office or Panchayat office',
        'mutation':     'Visit Tahsildar office with previous sale deed',
        'sale_deed':    'Visit SRO where deed was registered',
        'tax_receipt':  'Visit BBMP ward office or paytm.com/property-tax',
        'rera':         'Visit RERA Karnataka office, Bengaluru or rera.karnataka.gov.in',
        'building_plan':'Visit BBMP/BDA plan approval section',
      },
      'Tamil Nadu' => {
        'ec':           'Visit Sub-Registrar Office with property details — EC in same day',
        'rtc':          'Visit Taluk office for Patta & Chitta — tnlandconsolidation.in',
        'dc_conversion':'Visit District Collectorate',
        'khata':        'Visit local panchayat or municipality office',
        'mutation':     'Visit Tahsildar office',
        'sale_deed':    'Visit SRO where deed was registered',
        'tax_receipt':  'Visit local municipality office',
        'rera':         'rera.tn.gov.in or TNRERA office Chennai',
        'building_plan':'Visit CMDA / DTCP local office',
      },
      'Maharashtra' => {
        'ec':           'Visit Sub-Registrar Office — EC (Index II) available same day',
        'rtc':          'Visit Tehsil office for 7/12 Satbara extract',
        'dc_conversion':'Visit District Collectorate NA order section',
        'khata':        'Visit local municipal corporation / gram panchayat',
        'mutation':     'Visit Tehsil / Talathi office',
        'sale_deed':    'Visit SRO where deed was registered',
        'tax_receipt':  'Visit municipal corporation office',
        'rera':         'maharerait.maharashtra.gov.in or MahaRERA office Mumbai',
        'building_plan':'Visit local municipal corporation',
      },
      'Telangana' => {
        'ec':           'Visit Sub-Registrar Office — EC available same day',
        'rtc':          'Visit MeeSeva centre or Mandal Revenue Office for Pahani',
        'dc_conversion':'Visit District Collectorate',
        'khata':        'Visit GHMC / municipality office',
        'mutation':     'Visit MRO (Mandal Revenue Officer) office',
        'sale_deed':    'Visit SRO where deed was registered',
        'tax_receipt':  'Visit GHMC / municipality office',
        'rera':         'rera.telangana.gov.in or TSRERA office Hyderabad',
        'building_plan':'Visit GHMC / HMDA office',
      },
      _ => {
        'ec':           'Visit Sub-Registrar Office (SRO) with survey/property details',
        'rtc':          'Visit Taluk / Tehsil office or state land records portal',
        'dc_conversion':'Visit District Collectorate (DC/DM office)',
        'khata':        'Visit local municipal corporation or panchayat',
        'mutation':     'Visit Tehsildar / Talathi office',
        'sale_deed':    'Visit SRO where deed was originally registered',
        'tax_receipt':  'Visit local municipal corporation or panchayat',
        'rera':         'Visit state RERA authority office',
        'building_plan':'Visit local municipal corporation',
      },
    };
    return offices[docId] ?? 'Visit local Taluk / District office';
  }

  // State-specific legal support info
  String _legalSupportInfo(String state) => switch (state) {
    'Karnataka' => 'Karnataka Bar Council: karnatakabarcouncil.gov.in\n'
        'Lok Adalat: nalsa.nic.in (free for disputes)\n'
        'District Legal Services Authority (DLSA): your district court',
    'Tamil Nadu' => 'Tamil Nadu Bar Council: tnbarcouncil.in\n'
        'TNLSA Lok Adalat: tnlsa.gov.in (free for disputes)\n'
        'District Legal Services Authority at District Court',
    'Maharashtra'=> 'Maharashtra Bar Council: barcouncilofmaharashtra.org\n'
        'MSLA Lok Adalat: msla.gov.in (free for disputes)\n'
        'District Legal Services Authority at District Court',
    'Telangana'  => 'Telangana Bar Council: tsbarcouncil.in\n'
        'TSLSA Lok Adalat: tslsa.in (free for disputes)\n'
        'District Legal Services Authority at District Court',
    _            => 'State Bar Council of your state\n'
        'NALSA Lok Adalat: nalsa.nic.in (free for disputes)\n'
        'District Legal Services Authority at your District Court',
  };

  void _proceedToAnalysis() {
    context.push('/payment');
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
          'Arth ID\'s analysis is only as accurate as the documents provided. '
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
    final isSelected = _selectedDocId == doc.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDocId = doc.id);
        // If missing, open upload immediately on tap
        if (isMissing || isSkipped) _uploadDocument(doc);
      },
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD600)   // yellow highlight on tap
              : isComplete
                  ? (isSkipped ? Colors.orange.shade200 : AppColors.safe.withOpacity(0.4))
                  : levelColor.withOpacity(0.3),
          width: isSelected ? 2.5
              : isMissing && doc.level == DocLevel.critical ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(
                color: const Color(0xFFFFD600).withOpacity(0.25),
                blurRadius: 8, spreadRadius: 1)]
            : null,
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

          // Physical visit banner
          if (doc.status == DocStatus.physicalVisit) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Physical visit pending — analysis will run with reduced confidence '
                  'for this document until you upload it.',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800, height: 1.3),
                )),
              ]),
            ),
          ],
          // Not exists banner
          if (doc.status == DocStatus.notExists) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.block, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    'Seller could not produce this document',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade800,
                        fontWeight: FontWeight.bold),
                  )),
                ]),
                const SizedBox(height: 4),
                Text(doc.whyNeeded,
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700, height: 1.3)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showLegalSupportDialog(doc),
                  child: Row(children: [
                    Icon(Icons.support_agent, size: 13, color: AppColors.arthBlue),
                    const SizedBox(width: 4),
                    Text('Get Legal Support →',
                        style: TextStyle(fontSize: 11, color: AppColors.arthBlue,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ],

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
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 38),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCannotGetDialog(doc),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          foregroundColor: Colors.grey.shade700,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text("Can't get this"),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],

          // Uploaded preview + OCR result
          if (doc.uploadedPath != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: doc.uploadedPath!.toLowerCase().endsWith('.pdf')
                      ? Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.picture_as_pdf,
                              color: Colors.red.shade700, size: 32),
                        )
                      : Image.file(File(doc.uploadedPath!),
                          width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ocrRunning.contains(doc.id)
                      ? const Row(children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('AI reading document...',
                              style: TextStyle(fontSize: 12, color: AppColors.primary)),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Document uploaded',
                              style: TextStyle(color: AppColors.safe,
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                          Text(
                            _ocrSummary[doc.id] ?? 'AI will read this during analysis',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ]),
                  ),
                  TextButton(
                    onPressed: () {
                      final docs = [...ref.read(requiredDocsProvider)];
                      final idx = docs.indexWhere((d) => d.id == doc.id);
                      if (idx < 0) return;
                      docs[idx].status = DocStatus.missing;
                      docs[idx].uploadedPath = null;
                      setState(() {
                        _ocrSummary.remove(doc.id);
                        _docInsights.remove(doc.id);
                        _selectedDocId = null;
                      });
                      ref.read(requiredDocsProvider.notifier).state = [...docs];
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                  ),
                ]),
                // Smart insights
                if (_docInsights[doc.id]?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  ..._docInsights[doc.id]!.map((insight) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: insight.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: insight.color.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(insight.icon, size: 14, color: insight.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(insight.message,
                          style: TextStyle(fontSize: 11, color: insight.color,
                              height: 1.3, fontWeight: FontWeight.w500))),
                    ]),
                  )),
                ],
              ]),
            ),
          ],
        ],
      ),
      ), // AnimatedContainer
    ); // GestureDetector
  }

  Widget _statusIcon(RequiredDoc doc) {
    switch (doc.status) {
      case DocStatus.fetched:
      case DocStatus.uploaded:
        return const Icon(Icons.check_circle, color: AppColors.safe, size: 24);
      case DocStatus.skipped:
        return const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 24);
      case DocStatus.physicalVisit:
        return const Icon(Icons.directions_walk, color: Colors.blue, size: 24);
      case DocStatus.notExists:
        return const Icon(Icons.block, color: Colors.red, size: 24);
      case DocStatus.missing:
        return Icon(
          doc.level == DocLevel.critical ? Icons.error : Icons.radio_button_unchecked,
          color: doc.level == DocLevel.critical ? Colors.red : Colors.orange,
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
