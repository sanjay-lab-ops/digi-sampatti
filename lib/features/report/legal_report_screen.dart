import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

class LegalReportScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? reportData;
  const LegalReportScreen({super.key, this.reportData});

  @override
  ConsumerState<LegalReportScreen> createState() => _LegalReportScreenState();
}

class _LegalReportScreenState extends ConsumerState<LegalReportScreen> {
  String? _pdfPath;
  bool _isGeneratingPdf = false;

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
        text: 'DigiSampatti Report — Karnataka Land Verification',
      );
    }
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
                          const Text('RISK SCORE', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                          Text('$score/100', style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold, color: color,
                          )),
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
              title: 'Legal Flags (${assessment.flags.length})',
              icon: Icons.gavel,
              child: Column(
                children: assessment.flags.map((f) {
                  final fc = f.status == FlagStatus.clear ? AppColors.safe
                      : f.status == FlagStatus.warning ? AppColors.warning
                      : f.status == FlagStatus.danger ? AppColors.danger
                      : AppColors.textMedium;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: fc.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${f.category}] ${f.title}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: fc, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(f.details, style: const TextStyle(fontSize: 12, height: 1.4)),
                        if (f.actionRequired != null) ...[
                          const SizedBox(height: 4),
                          Text('→ ${f.actionRequired}',
                              style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600)),
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
              title: 'Before You Buy — Action Items',
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

            // ── PDF Actions
            if (_pdfPath == null)
              ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generatePdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Download PDF Report'),
              )
            else
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
