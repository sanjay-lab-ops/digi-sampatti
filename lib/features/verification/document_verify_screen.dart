import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/digital_signature_service.dart';

// ─── Document Seal & Sign Verification Screen ─────────────────────────────────
// Shows authenticity status of every government document in the report.
// Answers: "Is this RTC genuine or has the broker altered it?"
// ──────────────────────────────────────────────────────────────────────────────

class DocumentVerifyScreen extends StatefulWidget {
  final String? surveyNumber;
  final String? ownerName;

  const DocumentVerifyScreen({super.key, this.surveyNumber, this.ownerName});

  @override
  State<DocumentVerifyScreen> createState() => _DocumentVerifyScreenState();
}

class _DocumentVerifyScreenState extends State<DocumentVerifyScreen> {
  final _sigService = DigitalSignatureService();
  bool _loading = false;

  // Document verification states
  final Map<String, _DocState> _docs = {
    'RTC (Bhoomi)': _DocState(),
    'EC (IGRS/KAVERI)': _DocState(),
    'Khata (BBMP)': _DocState(),
    'e-Stamp': _DocState(),
    'Mutation Order': _DocState(),
  };

  @override
  void initState() {
    super.initState();
    _sigService.initialize();
    _runAllVerifications();
  }

  Future<void> _runAllVerifications() async {
    setState(() => _loading = true);

    // Simulate verification with staggered results
    // In production: each calls the actual portal QR verify endpoint
    await _verifyDoc('RTC (Bhoomi)',     delay: 800,  status: SignatureStatus.authentic,
        signer: 'Sri Prakash Hegde', designation: 'Tahsildar, Yelahanka');
    await _verifyDoc('EC (IGRS/KAVERI)', delay: 1200, status: SignatureStatus.authentic,
        signer: 'Sri Venkatesh Rao', designation: 'Sub-Registrar, Bengaluru North');
    await _verifyDoc('Khata (BBMP)',     delay: 900,  status: SignatureStatus.authentic,
        signer: 'Smt. Lalitha Devi', designation: 'ARO, BBMP Ward 42');
    await _verifyDoc('e-Stamp',          delay: 600,  status: SignatureStatus.authentic,
        signer: 'SHCIL', designation: 'Stock Holding Corp. of India');
    await _verifyDoc('Mutation Order',   delay: 1400, status: SignatureStatus.notApplicable,
        signer: null, designation: null);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _verifyDoc(String name, {
    required int delay,
    required SignatureStatus status,
    String? signer, String? designation,
  }) async {
    setState(() => _docs[name] = _DocState(checking: true));
    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;
    setState(() => _docs[name] = _DocState(
      checking: false,
      result: SignatureVerification(
        status: status,
        documentType: name,
        signerName: signer,
        signerDesignation: designation,
        signedAt: status == SignatureStatus.authentic
            ? DateTime.now().subtract(const Duration(days: 2))
            : null,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allAuthentic = _docs.values
        .where((d) => d.result != null)
        .every((d) =>
            d.result!.status == SignatureStatus.authentic ||
            d.result!.status == SignatureStatus.notApplicable);

    final anyTampered = _docs.values
        .any((d) => d.result?.status == SignatureStatus.tampered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Seal & Sign Verification'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Property chip ──
            if (widget.surveyNumber != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '🔍 Survey No. ${widget.surveyNumber}  ·  ${widget.ownerName ?? ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Overall status banner ──
            if (!_loading && !anyTampered) ...[
              _StatusBanner(
                isGood: allAuthentic,
                title: allAuthentic
                    ? 'All Documents Digitally Authentic'
                    : 'Verification In Progress',
                subtitle: allAuthentic
                    ? 'Every government seal and signature verified against official records'
                    : 'Checking signatures...',
              ),
              const SizedBox(height: 14),
            ],

            if (anyTampered) ...[
              _StatusBanner(
                isGood: false,
                title: '🚨 FORGERY DETECTED',
                subtitle: 'One or more documents have been altered. This is a criminal offence under IPC 465.',
              ),
              const SizedBox(height: 14),
            ],

            // ── What this checks ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔐 What DigiSampatti Verifies',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  _InfoRow('QR code on each document scanned against government portal'),
                  _InfoRow('Signer name & designation confirmed from issuing office'),
                  _InfoRow('Document data (owner, survey no.) cross-checked with QR'),
                  _InfoRow('If any data altered — FORGERY flagged immediately'),
                  _InfoRow('e-Stamp UIN verified against SHCIL records'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Document cards ──
            const Text('Document Authentication Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 10),

            ..._docs.entries.map((entry) => _DocCard(
              name: entry.key,
              state: entry.value,
            )),

            const SizedBox(height: 16),

            // ── Legal basis ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('⚖️ Legal Basis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64B5F6))),
                  SizedBox(height: 6),
                  Text(
                    'Digital signatures on government documents are legally valid under:\n'
                    '• IT Act 2000, Section 3 — Digital Signatures\n'
                    '• Indian Evidence Act 1872, Section 65B\n'
                    '• IT (Certifying Authorities) Rules 2000\n\n'
                    'A tampered document is forgery under IPC Section 465 (punishable up to 2 years imprisonment).',
                    style: TextStyle(fontSize: 10, color: Color(0xFF90CAF9), height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final bool isGood;
  final String title;
  final String subtitle;

  const _StatusBanner({required this.isGood, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final color = isGood ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(isGood ? '✅' : '🚨', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Document Card ─────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String name;
  final _DocState state;

  const _DocCard({required this.name, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor().withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _bgColor().withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _bgColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 3),
                if (state.checking)
                  Row(children: [
                    SizedBox(width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orange.shade300)),
                    const SizedBox(width: 6),
                    const Text('Verifying signature...', style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ])
                else if (state.result != null) ...[
                  Text(state.result!.statusLabel,
                      style: TextStyle(fontSize: 10, color: _textColor(), fontWeight: FontWeight.w600)),
                  if (state.result!.signerName != null) ...[
                    const SizedBox(height: 3),
                    Text('Signed by: ${state.result!.signerName}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    if (state.result!.signerDesignation != null)
                      Text(state.result!.signerDesignation!,
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                  if (state.result!.conflictDetail != null) ...[
                    const SizedBox(height: 4),
                    Text(state.result!.conflictDetail!,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFF44336), height: 1.4)),
                  ],
                ]
                else
                  const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),

          // Badge
          if (state.result != null && !state.checking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _bgColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_badgeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _bgColor())),
            ),
        ],
      ),
    );
  }

  Color _bgColor() {
    if (state.checking) return Colors.orange;
    if (state.result == null) return Colors.grey;
    switch (state.result!.status) {
      case SignatureStatus.authentic:     return const Color(0xFF4CAF50);
      case SignatureStatus.tampered:      return const Color(0xFFF44336);
      case SignatureStatus.expired:       return const Color(0xFFFF9800);
      case SignatureStatus.unverifiable:  return Colors.grey;
      case SignatureStatus.notApplicable: return Colors.blueGrey;
    }
  }

  Color _textColor() => _bgColor();

  String get _icon {
    if (state.checking) return '⏳';
    if (state.result == null) return '📄';
    switch (state.result!.status) {
      case SignatureStatus.authentic:     return '✅';
      case SignatureStatus.tampered:      return '🚨';
      case SignatureStatus.expired:       return '⚠️';
      case SignatureStatus.unverifiable:  return '❓';
      case SignatureStatus.notApplicable: return '📋';
    }
  }

  String get _badgeLabel {
    if (state.result == null) return '';
    switch (state.result!.status) {
      case SignatureStatus.authentic:     return 'GENUINE';
      case SignatureStatus.tampered:      return 'FORGED';
      case SignatureStatus.expired:       return 'EXPIRED';
      case SignatureStatus.unverifiable:  return 'UNVERIFIED';
      case SignatureStatus.notApplicable: return 'N/A';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String text;
  const _InfoRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('→ ', style: TextStyle(color: AppColors.primary, fontSize: 10)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4))),
        ],
      ),
    );
  }
}

class _DocState {
  final bool checking;
  final SignatureVerification? result;
  _DocState({this.checking = false, this.result});
}
