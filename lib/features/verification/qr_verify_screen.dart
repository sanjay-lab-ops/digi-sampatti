import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/digital_signature_service.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── QR Verify Screen ──────────────────────────────────────────────────────────
// Scan the QR code printed on any Karnataka government document:
//   RTC → Bhoomi land.kar.nic.in verification
//   EC  → Kaveri kaverionline.karnataka.gov.in
//   e-Stamp → SHCIL shcilestamps.com
//   Khata → BBMP eAasthi
//
// Returns REAL government portal response:
//   - Authentic: officer name, designation, date signed
//   - Tampered:  what was changed (owner name, survey number)
//   - Expired:   QR link has expired, re-download needed
// ─────────────────────────────────────────────────────────────────────────────

class QrVerifyScreen extends StatefulWidget {
  final String? expectedOwner;
  final String? expectedSurveyNumber;
  final String documentType; // 'RTC', 'EC', 'Khata', 'e-Stamp'

  const QrVerifyScreen({
    super.key,
    this.expectedOwner,
    this.expectedSurveyNumber,
    this.documentType = 'RTC',
  });

  @override
  State<QrVerifyScreen> createState() => _QrVerifyScreenState();
}

class _QrVerifyScreenState extends State<QrVerifyScreen> {
  final _sigService = DigitalSignatureService();
  final _controller = MobileScannerController();

  bool _scanned = false;
  bool _verifying = false;
  String? _qrValue;
  SignatureVerification? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sigService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(String qrData) async {
    if (_scanned) return;
    setState(() {
      _scanned = true;
      _verifying = true;
      _qrValue = qrData;
    });
    await _controller.stop();

    try {
      SignatureVerification result;
      switch (widget.documentType) {
        case 'EC':
          result = await _sigService.verifyKaveriEc(
            qrData: qrData,
            expectedOwner: widget.expectedOwner,
          );
        case 'Khata':
          result = await _sigService.verifyKhata(
            qrData: qrData,
            expectedOwner: widget.expectedOwner,
          );
        case 'e-Stamp':
          // e-Stamp UIN is in QR — extract 24-digit number
          final uin = RegExp(r'\d{20,24}').firstMatch(qrData)?.group(0) ?? qrData;
          result = await _sigService.verifyEStamp(
            uin: uin,
            state: 'Karnataka',
          );
        case 'RTC':
        default:
          result = await _sigService.verifyBhoomiRtc(
            qrData: qrData,
            expectedOwner: widget.expectedOwner,
            expectedSurveyNumber: widget.expectedSurveyNumber,
          );
      }
      if (mounted) setState(() { _result = result; _verifying = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Verification failed: $e'; _verifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Scan ${widget.documentType} QR Code',
            style: const TextStyle(color: Colors.white)),
        actions: [
          if (!_scanned)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
        ],
      ),
      body: _scanned ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) {
              _onQrDetected(barcode!.rawValue!);
            }
          },
        ),
        // Overlay frame
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Instruction
        Positioned(
          bottom: 60,
          left: 0, right: 0,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _instructionText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _instructionText() {
    switch (widget.documentType) {
      case 'RTC': return 'Point camera at the QR code on the bottom-right of the Bhoomi RTC printout';
      case 'EC':  return 'Point at QR code on the Kaveri Encumbrance Certificate';
      case 'Khata': return 'Point at QR code on BBMP Khata certificate';
      case 'e-Stamp': return 'Point at QR code on the SHCIL e-Stamp paper';
      default: return 'Point camera at the QR code on the document';
    }
  }

  Widget _buildResult() {
    if (_verifying) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text('Verifying with government portal...',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorCard(_error!);
    }

    final result = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatusBanner(result),
          const SizedBox(height: 16),
          if (result.status == SignatureStatus.authentic) _buildAuthenticCard(result),
          if (result.status == SignatureStatus.tampered)  _buildTamperedCard(result),
          if (result.status == SignatureStatus.expired)   _buildExpiredCard(result),
          if (result.status == SignatureStatus.unverifiable) _buildUnverifiableCard(result),
          const SizedBox(height: 16),
          _buildQrValueCard(),
          const SizedBox(height: 16),
          _buildActionButtons(result),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _scanned = false;
              _result = null;
              _qrValue = null;
              _error = null;
              _controller.start();
            }),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text('Scan Again', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(SignatureVerification result) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (result.status) {
      case SignatureStatus.authentic:
        color = AppColors.safe;
        icon = Icons.verified;
        title = '${widget.documentType} is GENUINE ✓';
        subtitle = 'Government portal confirms this document is authentic';
      case SignatureStatus.tampered:
        color = Colors.red;
        icon = Icons.gpp_bad;
        title = 'FORGERY DETECTED ⚠';
        subtitle = 'Document does not match government records — DO NOT proceed';
      case SignatureStatus.expired:
        color = Colors.orange;
        icon = Icons.schedule;
        title = 'QR Code Expired';
        subtitle = 'Re-download a fresh RTC from Bhoomi portal';
      case SignatureStatus.unverifiable:
        color = Colors.grey;
        icon = Icons.cloud_off;
        title = 'Could Not Verify';
        subtitle = result.failReason == VerifyFailReason.portalDown
            ? 'Government portal is currently down — try again later'
            : result.failDetail ?? 'Verification service unavailable';
      case SignatureStatus.notApplicable:
        color = Colors.grey;
        icon = Icons.info_outline;
        title = 'Not Applicable';
        subtitle = 'This document type does not carry a digital signature';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticCard(SignatureVerification result) {
    return _InfoCard(
      title: 'Verified by Government Portal',
      color: AppColors.safe,
      rows: [
        if (result.signerName != null)
          _InfoRow('Signed by', result.signerName!),
        if (result.signerDesignation != null)
          _InfoRow('Designation', result.signerDesignation!),
        if (result.signedAt != null)
          _InfoRow('Signed on',
              '${result.signedAt!.day}/${result.signedAt!.month}/${result.signedAt!.year}'),
        if (widget.expectedOwner != null)
          _InfoRow('Owner matches', widget.expectedOwner!),
        if (widget.expectedSurveyNumber != null)
          _InfoRow('Survey No. matches', widget.expectedSurveyNumber!),
      ],
    );
  }

  Widget _buildTamperedCard(SignatureVerification result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('What was changed:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ]),
          const SizedBox(height: 10),
          Text(result.conflictDetail ?? 'Document data does not match government records.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.red)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'This is a criminal offence under IPC Section 465 (Forgery). '
              'Do NOT pay any advance. Report to the nearest police station.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredCard(SignatureVerification result) {
    return _InfoCard(
      title: 'QR Link Expired',
      color: Colors.orange,
      rows: [
        _InfoRow('Action needed', 'Visit Bhoomi portal and download a fresh RTC'),
        _InfoRow('URL', 'landrecords.karnataka.gov.in/Service2'),
        _InfoRow('Note', 'Old QR codes expire. The land record itself is still valid.'),
      ],
    );
  }

  Widget _buildUnverifiableCard(SignatureVerification result) {
    return _InfoCard(
      title: 'Verification Unavailable',
      color: Colors.grey,
      rows: [
        _InfoRow('Reason', result.failDetail ?? result.failReason.name),
        _InfoRow('What to do', 'Check manually — open the verify URL in your browser'),
      ],
    );
  }

  Widget _buildQrValueCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QR Data Scanned',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            _qrValue ?? '',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SignatureVerification result) {
    final verifyUrl = result.verifyUrl;
    return Column(
      children: [
        if (verifyUrl != null)
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(verifyUrl);
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open Verify URL in Browser'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, _result),
          icon: const Icon(Icons.check),
          label: const Text('Done — Back to Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: result.status == SignatureStatus.authentic
                ? AppColors.safe
                : Colors.grey,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _scanned = false;
                _error = null;
                _controller.start();
              }),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }
}
