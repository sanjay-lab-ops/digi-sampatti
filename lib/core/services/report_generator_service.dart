import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';

class ReportGeneratorService {
  static final ReportGeneratorService _instance = ReportGeneratorService._internal();
  factory ReportGeneratorService() => _instance;
  ReportGeneratorService._internal();

  // ─── Generate PDF Report ───────────────────────────────────────────────────
  Future<String?> generatePdfReport(LegalReport report) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

      // Load fonts
      final font = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(boldFont, report),
          footer: (context) => _buildFooter(font, context),
          build: (context) => [
            // ── Title Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PROPERTY LEGAL DUE DILIGENCE REPORT',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Report ID: ${report.reportId}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Generated: ${dateFormat.format(report.generatedAt)}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Risk Score
            _buildRiskScoreSection(boldFont, font, report.riskAssessment),
            pw.SizedBox(height: 16),

            // ── Property Details
            _buildPropertyDetailsSection(boldFont, font, report),
            pw.SizedBox(height: 16),

            // ── Land Records
            if (report.landRecord != null) ...[
              _buildLandRecordsSection(boldFont, font, report.landRecord!),
              pw.SizedBox(height: 16),
            ],

            // ── Legal Flags
            _buildLegalFlagsSection(boldFont, font, report.riskAssessment.flags),
            pw.SizedBox(height: 16),

            // ── AI Analysis Summary
            _buildAiSummarySection(boldFont, font, report),
            pw.SizedBox(height: 16),

            // ── Action Items
            _buildActionItemsSection(boldFont, font, report.riskAssessment.actionItems),
            pw.SizedBox(height: 16),

            // ── RERA Status
            if (report.reraRecord != null) ...[
              _buildReraSection(boldFont, font, report.reraRecord!),
              pw.SizedBox(height: 16),
            ],

            // ── Disclaimer
            _buildDisclaimer(font),
          ],
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final filePath = '${reportsDir.path}/report_${report.reportId}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      return null;
    }
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(pw.Font boldFont, LegalReport report) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'DigiSampatti',
          style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.green900),
        ),
        pw.Text(
          'Confidential Report',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Font font, pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey),
        ),
        pw.Text(
          'DigiSampatti — Know Your Property. Own Your Decision.',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey),
        ),
      ],
    );
  }

  // ─── Risk Score Section ────────────────────────────────────────────────────
  pw.Widget _buildRiskScoreSection(
    pw.Font boldFont, pw.Font font, RiskAssessment assessment) {
    final color = assessment.level == RiskLevel.low
        ? PdfColors.green800
        : assessment.level == RiskLevel.medium
            ? PdfColors.orange800
            : PdfColors.red800;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('RISK SCORE', style: pw.TextStyle(font: boldFont, fontSize: 10)),
              pw.Text(
                '${assessment.score}/100',
                style: pw.TextStyle(font: boldFont, fontSize: 36, color: color),
              ),
              pw.Text(assessment.level.displayName,
                  style: pw.TextStyle(font: boldFont, fontSize: 12, color: color)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('RECOMMENDATION', style: pw.TextStyle(font: boldFont, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  assessment.recommendation,
                  style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Bank Loan: ${assessment.isBankLoanEligible ? "ELIGIBLE ✓" : "NOT ELIGIBLE ✗"}',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Property Details ──────────────────────────────────────────────────────
  pw.Widget _buildPropertyDetailsSection(
    pw.Font boldFont, pw.Font font, LegalReport report) {
    return _buildSection(boldFont, font, 'PROPERTY DETAILS', [
      if (report.scan.location != null) ...[
        _buildRow(font, 'GPS Coordinates', report.scan.location!.coordinatesString),
        if (report.scan.location!.address != null)
          _buildRow(font, 'Address', report.scan.location!.address!),
      ],
      if (report.scan.surveyNumber != null)
        _buildRow(font, 'Survey Number', report.scan.surveyNumber!),
      if (report.scan.district != null)
        _buildRow(font, 'District', report.scan.district!),
      if (report.scan.taluk != null)
        _buildRow(font, 'Taluk', report.scan.taluk!),
      if (report.scan.village != null)
        _buildRow(font, 'Village', report.scan.village!),
    ]);
  }

  // ─── Land Records Section ──────────────────────────────────────────────────
  pw.Widget _buildLandRecordsSection(
    pw.Font boldFont, pw.Font font, LandRecord record) {
    return _buildSection(boldFont, font, 'BHOOMI LAND RECORDS (RTC)', [
      _buildRow(font, 'Khata Number', record.khataNumber ?? 'Not available'),
      _buildRow(font, 'Khata Type', record.khataType?.displayName ?? 'Unknown'),
      _buildRow(font, 'Land Type', record.landType ?? 'Unknown'),
      _buildRow(font, 'Total Area', '${record.totalAreaAcres ?? "Unknown"} acres'),
      _buildRow(font, 'Revenue Site', record.isRevenueSite ? 'YES ⚠' : 'No ✓'),
      _buildRow(font, 'Government Land', record.isGovernmentLand ? 'YES ⚠' : 'No ✓'),
      _buildRow(font, 'Forest Land', record.isForestLand ? 'YES ⚠' : 'No ✓'),
      _buildRow(font, 'Lake Bed', record.isLakeBed ? 'YES ⚠' : 'No ✓'),
      if (record.owners.isNotEmpty)
        _buildRow(font, 'Owner(s)',
          record.owners.map((o) => o.name).join(', ')),
    ]);
  }

  // ─── Legal Flags Section ───────────────────────────────────────────────────
  pw.Widget _buildLegalFlagsSection(
    pw.Font boldFont, pw.Font font, List<LegalFlag> flags) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('LEGAL FLAGS', style: pw.TextStyle(font: boldFont, fontSize: 13)),
        pw.SizedBox(height: 8),
        ...flags.map((flag) {
          final color = flag.status == FlagStatus.clear
              ? PdfColors.green100
              : flag.status == FlagStatus.warning
                  ? PdfColors.orange100
                  : flag.status == FlagStatus.danger
                      ? PdfColors.red100
                      : PdfColors.grey100;
          final textColor = flag.status == FlagStatus.clear
              ? PdfColors.green900
              : flag.status == FlagStatus.warning
                  ? PdfColors.orange900
                  : flag.status == FlagStatus.danger
                      ? PdfColors.red900
                      : PdfColors.grey800;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('[${flag.category}] ', style: pw.TextStyle(font: boldFont, fontSize: 9, color: textColor)),
                    pw.Text(flag.title, style: pw.TextStyle(font: boldFont, fontSize: 10, color: textColor)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(flag.details, style: pw.TextStyle(font: font, fontSize: 9)),
                if (flag.actionRequired != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Action: ${flag.actionRequired}',
                    style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blue900),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── AI Summary Section ────────────────────────────────────────────────────
  pw.Widget _buildAiSummarySection(
    pw.Font boldFont, pw.Font font, LegalReport report) {
    return _buildSection(boldFont, font, 'AI ANALYSIS SUMMARY', [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(report.riskAssessment.summary, style: pw.TextStyle(font: font, fontSize: 10)),
      ),
    ]);
  }

  // ─── Action Items Section ──────────────────────────────────────────────────
  pw.Widget _buildActionItemsSection(
    pw.Font boldFont, pw.Font font, List<String> items) {
    return _buildSection(boldFont, font, 'ACTION ITEMS BEFORE PURCHASE', [
      ...items.asMap().entries.map((e) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(
          '${e.key + 1}. ${e.value}',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      )),
    ]);
  }

  // ─── RERA Section ──────────────────────────────────────────────────────────
  pw.Widget _buildReraSection(
    pw.Font boldFont, pw.Font font, ReraRecord rera) {
    return _buildSection(boldFont, font, 'RERA STATUS', [
      _buildRow(font, 'Registered', rera.isRegistered ? 'Yes ✓' : 'No ✗'),
      if (rera.registrationNumber != null)
        _buildRow(font, 'Reg. Number', rera.registrationNumber!),
      if (rera.projectName != null)
        _buildRow(font, 'Project Name', rera.projectName!),
      if (rera.promoterName != null)
        _buildRow(font, 'Promoter', rera.promoterName!),
      _buildRow(font, 'Status', rera.projectStatus ?? 'Unknown'),
    ]);
  }

  // ─── Disclaimer ────────────────────────────────────────────────────────────
  pw.Widget _buildDisclaimer(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'DISCLAIMER: ${AppStrings.disclaimer}',
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  pw.Widget _buildSection(
    pw.Font boldFont, pw.Font font, String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 13)),
        pw.Divider(),
        pw.SizedBox(height: 4),
        ...children,
      ],
    );
  }

  pw.Widget _buildRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
