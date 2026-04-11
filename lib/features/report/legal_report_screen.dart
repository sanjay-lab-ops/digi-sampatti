import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/payment_service.dart';

class LegalReportScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? reportData;
  const LegalReportScreen({super.key, this.reportData});

  @override
  ConsumerState<LegalReportScreen> createState() => _LegalReportScreenState();
}

class _LegalReportScreenState extends ConsumerState<LegalReportScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _pdfPath;
  bool _isGeneratingPdf = false;
  bool _isPaid = true; // PDF generation is free — payment gate removed
  bool _isVerifyingPayment = false;
  String? _pendingRequestId;
  final _paymentService = PaymentService();
  late AnimationController _scoreCtrl;
  late Animation<int> _scoreAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _paymentService.initialize();
    _paymentService.onSuccess = _onPaymentSuccess;
    _paymentService.onFailure = _onPaymentFailure;
    // When opened from history, reportData contains the saved report JSON.
    // Load it into currentReportProvider so the screen can render it.
    if (widget.reportData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final report = LegalReport.fromJson(widget.reportData!);
          ref.read(currentReportProvider.notifier).state = report;
          if (report.isPaid) setState(() => _isPaid = true);
        } catch (_) {}
      });
    }
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  // Called when user returns from Instamojo browser
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingRequestId != null) {
      _verifyInstamojoPayment(_pendingRequestId!);
    }
  }

  void _animateScore(int target) {
    _scoreAnim = IntTween(begin: 0, end: target).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut),
    );
    _scoreCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scoreCtrl.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _startPayment(String reportId) async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';
    final name  = user?.displayName ?? 'Customer';

    try {
      final requestId = await _paymentService.openReportPayment(
        reportId: reportId,
        userPhone: phone,
        userName: name,
      );

      // Instamojo returns a requestId — save it so we can verify when user returns
      if (requestId != null && mounted) {
        setState(() => _pendingRequestId = requestId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open payment gateway. Please check your internet connection and try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyInstamojoPayment(String requestId) async {
    if (_isVerifyingPayment) return;
    setState(() => _isVerifyingPayment = true);
    try {
      final paid = await _paymentService.verifyInstamojoPayment(requestId);
      if (!mounted) return;
      if (paid) {
        setState(() => _pendingRequestId = null);
        // onSuccess callback handles the rest
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not confirmed yet. Complete payment and return.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingPayment = false);
    }
  }

  void _onPaymentSuccess(String paymentId) {
    setState(() => _isPaid = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Generating your PDF...'),
        backgroundColor: AppColors.safe,
        duration: Duration(seconds: 2),
      ),
    );
    _generatePdf();
  }

  void _onPaymentFailure(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final path = await ref.read(propertyCheckNotifierProvider.notifier).generatePdf();
      if (mounted) setState(() => _pdfPath = path);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _openPdf() async {
    if (_pdfPath != null) {
      await OpenFile.open(_pdfPath!);
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath != null) {
      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'DigiSampatti Report — Property Verification',
      );
    }
  }

  Widget _buildPaymentCard(String reportId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Download Full PDF Report',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get the complete legal report as PDF — share with your lawyer, bank, or family.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹149', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('one-time · instant download', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isVerifyingPayment ? null : () => _startPayment(reportId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isVerifyingPayment
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)))
                    : const Text('Pay & Download', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── UPI direct pay (works immediately)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final report = ref.read(currentReportProvider);
                final id = report?.reportId ?? 'RPT';
                final opened = await PaymentService.openUpiPayment(
                  amountInRupees: PaymentService.reportPrice,
                  reportId: id,
                );
                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No UPI app found. Use WhatsApp option below.')),
                  );
                }
              },
              icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 16),
              label: const Text('Pay ₹149 via UPI (PhonePe / GPay)',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── WhatsApp fallback
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final report = ref.read(currentReportProvider);
                PaymentService.openWhatsAppPayment(
                  reportId: report?.reportId ?? 'RPT',
                  amountInRupees: PaymentService.reportPrice,
                );
              },
              icon: const Icon(Icons.chat, color: Colors.white70, size: 14),
              label: const Text('Pay via WhatsApp (manual confirm)',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          // Show "verify payment" button if user went to Instamojo
          if (_pendingRequestId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _verifyInstamojoPayment(_pendingRequestId!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Verify Instamojo payment'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthenticitySection(LegalReport report) {
    final portals = <String>[];
    final scan = report.scan;
    if (scan.surveyNumber != null) portals.add('Bhoomi RTC');
    portals.add('Kaveri EC');
    portals.add('eCourts');
    portals.add('CERSAI');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source chain
        Row(children: [
          _authBadge('${portals.length} Portals', Icons.verified, AppColors.safe),
          const SizedBox(width: 8),
          _authBadge('Claude AI', Icons.auto_awesome, const Color(0xFF4A148C)),
          const SizedBox(width: 8),
          _authBadge('30+ Rules', Icons.rule, const Color(0xFF0D47A1)),
        ]),
        const SizedBox(height: 10),
        // What was checked
        ...portals.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.safe, size: 14),
            const SizedBox(width: 6),
            Text(p, style: const TextStyle(fontSize: 12)),
          ]),
        )),
        const SizedBox(height: 8),
        Text('Report ID: ${report.reportId}  ·  Generated: ${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
            style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'This report is based on documents provided and government portals '
            'accessible at time of check. It does not replace a lawyer\'s opinion. '
            'Every risk flag shows its source — tap any flag to see the raw evidence.',
            style: TextStyle(fontSize: 10, color: Colors.black45, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _authBadge(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold, color: color)),
    ]),
  );

  Future<void> _shareWhatsApp(LegalReport report) async {
    final score = report.riskAssessment.score;
    final text = '''
*DigiSampatti — Property Verification Report*

Survey No: ${report.scan.surveyNumber ?? 'N/A'}
District: ${report.scan.district ?? 'N/A'}
Risk Score: $score/100
Verdict: ${report.riskAssessment.recommendation}
Bank Loan: ${report.riskAssessment.isBankLoanEligible ? "ELIGIBLE ✓" : "NOT ELIGIBLE ✗"}

${report.riskAssessment.summary}

_Verified by DigiSampatti — Property Verification Platform_
''';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(currentReportProvider);
    if (report == null) {
      return const Scaffold(body: Center(child: Text('No report available')));
    }

    final assessment = report.riskAssessment;
    final score = assessment.score;
    final color = score >= 70 ? AppColors.safe
        : score >= 40 ? AppColors.warning
        : AppColors.danger;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Trigger score animation on first build
    if (!_scoreCtrl.isAnimating && _scoreCtrl.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateScore(score));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Legal Report'),
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Share Report',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Report Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SAFETY SCORE', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                          AnimatedBuilder(
                            animation: _scoreCtrl,
                            builder: (_, __) {
                              final display = _scoreCtrl.value == 0 ? score
                                  : _scoreAnim.value;
                              return Text('$display/100', style: TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold, color: color,
                              ));
                            },
                          ),
                          Text(assessment.level.displayName,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(assessment.recommendation,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bank Loan: ${assessment.isBankLoanEligible ? "ELIGIBLE ✓" : "NOT ELIGIBLE ✗"}',
                            style: TextStyle(
                              color: assessment.isBankLoanEligible ? AppColors.safe : AppColors.danger,
                              fontWeight: FontWeight.w600, fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Report ID: ${report.reportId}',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                      Text(dateFormat.format(report.generatedAt),
                          style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Analysis Authenticity — what backs this report
            _ReportSection(
              title: 'Analysis Basis',
              icon: Icons.verified_outlined,
              child: _buildAuthenticitySection(report),
            ),
            const SizedBox(height: 12),

            // ── Summary
            _ReportSection(
              title: 'AI Analysis Summary',
              icon: Icons.psychology,
              child: Text(assessment.summary,
                  style: const TextStyle(height: 1.6, fontSize: 14)),
            ),
            const SizedBox(height: 12),

            // ── Property Info
            _ReportSection(
              title: 'Property Location',
              icon: Icons.location_on,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.scan.surveyNumber != null)
                    _ReportRow('Survey No.', report.scan.surveyNumber!),
                  if (report.scan.district != null)
                    _ReportRow('District', report.scan.district!),
                  if (report.scan.taluk != null)
                    _ReportRow('Taluk', report.scan.taluk!),
                  if (report.scan.location != null)
                    _ReportRow('GPS', report.scan.location!.coordinatesString),
                  if (report.scan.location?.address != null)
                    _ReportRow('Address', report.scan.location!.address!),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── All Flags
            _ReportSection(
              title: 'What We Found',
              icon: Icons.find_in_page_outlined,
              child: Column(
                children: assessment.flags.map((f) {
                  final fc = f.status == FlagStatus.clear ? AppColors.safe
                      : f.status == FlagStatus.warning ? AppColors.warning
                      : f.status == FlagStatus.danger ? AppColors.danger
                      : AppColors.textMedium;
                  final icon = f.status == FlagStatus.clear ? Icons.check_circle_outline
                      : Icons.info_outline;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fc.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: fc.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: fc, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(f.title,
                                style: TextStyle(fontWeight: FontWeight.bold, color: fc, fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(f.details, style: const TextStyle(fontSize: 12, height: 1.4)),
                        if (f.actionRequired != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(child: Text(f.actionRequired!,
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Action Items
            _ReportSection(
              title: 'Your Next Steps',
              icon: Icons.checklist,
              child: Column(
                children: assessment.actionItems.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value,
                            style: const TextStyle(fontSize: 13, height: 1.4))),
                      ],
                    ),
                  )).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                AppStrings.disclaimer,
                style: TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // ── FinSelf Lite — Loan Eligibility CTA ──────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.account_balance, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Can you afford this property?',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                    'Check your home loan eligibility in 2 minutes. '
                    'Property report + your financial profile = '
                    'faster bank approval.',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/loan-eligibility'),
                      icon: const Icon(Icons.arrow_forward,
                          color: Color(0xFF0D47A1), size: 16),
                      label: const Text('Check Loan Eligibility — FinSelf Lite',
                          style: TextStyle(
                              color: Color(0xFF0D47A1), fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Demo · Powered by India\'s Account Aggregator (RBI)',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // ── PDF Actions
            if (_pdfPath == null) ...[
              if (!_isPaid) _buildPaymentCard(report.reportId)
              else ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generatePdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Download PDF Report'),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Next Steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Next Steps', style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/verification'),
                      icon: const Icon(Icons.checklist),
                      label: const Text('Physical Verification Checklist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareWhatsApp(report),
                      icon: const Icon(Icons.share),
                      label: const Text('Share Report on WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/partners'),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Get Expert Help — Lawyer / Bank / Insurance'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Apply & Track
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_turned_in, size: 16, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Text('Government Services — Apply Online',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apply for EC, RTC, Mutation & more — directly on official portals',
                    style: TextStyle(fontSize: 12, color: Color(0xFF388E3C)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/gov-services', extra: {
                        'surveyNumber': report.scan.surveyNumber,
                        'district': report.scan.district,
                      }),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apply & Track Applications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ReportSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReportRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
