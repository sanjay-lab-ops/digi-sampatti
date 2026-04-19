import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';

class AdvanceReceiptScreen extends ConsumerStatefulWidget {
  const AdvanceReceiptScreen({super.key});

  @override
  ConsumerState<AdvanceReceiptScreen> createState() => _AdvanceReceiptScreenState();
}

class _AdvanceReceiptScreenState extends ConsumerState<AdvanceReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  // Buyer
  final _buyerName = TextEditingController();
  final _buyerPhone = TextEditingController();
  final _buyerAadhaar = TextEditingController();

  // Seller
  final _sellerName = TextEditingController();
  final _sellerPhone = TextEditingController();

  // Property
  final _surveyNo = TextEditingController();
  final _village = TextEditingController();
  final _taluk = TextEditingController();
  final _district = TextEditingController();
  final _extent = TextEditingController();

  // Transaction
  final _totalPrice = TextEditingController();
  final _advanceAmount = TextEditingController();
  final _paymentMode = TextEditingController();
  final _chequeNo = TextEditingController();
  final _balanceDueDate = TextEditingController();
  final _registrationDeadline = TextEditingController();
  final _notes = TextEditingController();

  bool _generating = false;
  String? _pdfPath;

  @override
  void dispose() {
    for (final c in [
      _buyerName, _buyerPhone, _buyerAadhaar, _sellerName, _sellerPhone,
      _surveyNo, _village, _taluk, _district, _extent,
      _totalPrice, _advanceAmount, _paymentMode, _chequeNo,
      _balanceDueDate, _registrationDeadline, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generatePdf(bool isKn) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _generating = true; _pdfPath = null; });

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd MMM yyyy').format(now);
      final timeStr = DateFormat('HH:mm:ss').format(now);
      final receiptId = 'DS-${DateFormat('yyyyMMdd').format(now)}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1B5E20),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('DigiSampatti',
                        style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 20,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Property Verification Platform',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('ADVANCE PAYMENT RECEIPT',
                        style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('ಮುಂಗಡ ಹಣ ರಸೀದಿ',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Date & receipt ID
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: $dateStr  $timeStr',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Receipt ID: $receiptId',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Property
              _pdfSection('PROPERTY DETAILS / ಆಸ್ತಿ ವಿವರ', [
                _pdfRow('Survey No.', _surveyNo.text),
                _pdfRow('Village / ಗ್ರಾಮ', _village.text),
                _pdfRow('Taluk / ತಾಲ್ಲೂಕು', _taluk.text),
                _pdfRow('District / ಜಿಲ್ಲೆ', _district.text),
                if (_extent.text.isNotEmpty) _pdfRow('Extent / ವಿಸ್ತೀರ್ಣ', _extent.text),
              ]),
              pw.SizedBox(height: 10),

              // Transaction
              _pdfSection('TRANSACTION DETAILS / ವ್ಯವಹಾರ ವಿವರ', [
                _pdfRow('Total Sale Price / ಒಟ್ಟು ಮಾರಾಟ ಬೆಲೆ', '₹${_totalPrice.text}'),
                _pdfRow('Advance Amount Paid / ಮುಂಗಡ ಮೊತ್ತ', '₹${_advanceAmount.text}'),
                _pdfRow('Balance Amount / ಬಾಕಿ ಮೊತ್ತ',
                    '₹${_balanceAmount()}'),
                _pdfRow('Payment Mode / ಪಾವತಿ ವಿಧಾನ', _paymentMode.text),
                if (_chequeNo.text.isNotEmpty)
                  _pdfRow('Cheque / RTGS No.', _chequeNo.text),
                if (_balanceDueDate.text.isNotEmpty)
                  _pdfRow('Balance Due Date / ಬಾಕಿ ದಿನಾಂಕ', _balanceDueDate.text),
                if (_registrationDeadline.text.isNotEmpty)
                  _pdfRow('Registration Deadline / ನೋಂದಣಿ ದಿನಾಂಕ', _registrationDeadline.text),
              ]),
              pw.SizedBox(height: 10),

              // Buyer
              _pdfSection('BUYER / ಖರೀದಿದಾರ', [
                _pdfRow('Name / ಹೆಸರು', _buyerName.text),
                _pdfRow('Phone / ಫೋನ್', _buyerPhone.text),
                if (_buyerAadhaar.text.isNotEmpty)
                  _pdfRow('Aadhaar (last 4)', 'XXXX-XXXX-${_buyerAadhaar.text}'),
              ]),
              pw.SizedBox(height: 10),

              // Seller
              _pdfSection('SELLER / ಮಾರಾಟಗಾರ', [
                _pdfRow('Name / ಹೆಸರು', _sellerName.text),
                _pdfRow('Phone / ಫೋನ್', _sellerPhone.text),
              ]),

              if (_notes.text.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _pdfSection('ADDITIONAL TERMS / ಹೆಚ್ಚುವರಿ ಷರತ್ತುಗಳು', [
                  pw.Text(_notes.text, style: const pw.TextStyle(fontSize: 9)),
                ]),
              ],

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 150, height: 40,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide()))),
                      pw.SizedBox(height: 4),
                      pw.Text('Buyer Signature / ಖರೀದಿದಾರ ಸಹಿ',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(_buyerName.text, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 150, height: 40,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide()))),
                      pw.SizedBox(height: 4),
                      pw.Text('Seller Signature / ಮಾರಾಟಗಾರ ಸಹಿ',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(_sellerName.text, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Legal disclaimer box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LEGAL DISCLAIMER / ಕಾನೂನು ಸೂಚನೆ',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '1. This advance receipt is a legally binding document under Indian Contract Act, 1872.\n'
                      '2. Both parties agree balance amount shall be paid by the date mentioned above.\n'
                      '3. Failure to pay balance: advance forfeiture/refund as mutually agreed shall apply.\n'
                      '4. This receipt does NOT substitute a registered Agreement for Sale.\n'
                      '5. Property registration must be completed at the Sub-Registrar Office (SRO).\n'
                      '6. DigiSampatti is a verification platform and is not a party to this transaction.',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Data sources chain
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F5E9),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DATA VERIFIED BY GOVERNMENT OFFICIALS',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1B5E20))),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Land records in this report are sourced from Karnataka Government databases — '
                      'verified and certified by: Village Accountant (VA) → Revenue Inspector (RI) → '
                      'Tahsildar → Sub-Registrar (SRO) → Inspector General of Registration (IGR). '
                      'Data authenticity is governed by the Karnataka Land Revenue Act and IT Act 2000.',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text('Sources: Bhoomi (Revenue Dept) · Kaveri Online (IGR Karnataka) · '
                        'SAKALA · eCourts (Ministry of Law, GoI) · Karnataka RERA',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Generated by DigiSampatti',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1B5E20))),
                      pw.Text('India\'s Property Verification Platform',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      pw.Text('Startup India ID: IN-0326-9427JD',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Receipt: $receiptId',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      pw.Text('Generated: $dateStr $timeStr',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      pw.Text('For informational purposes only',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/advance_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) setState(() => _pdfPath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _balanceAmount() {
    final total = double.tryParse(_totalPrice.text.replaceAll(',', '')) ?? 0;
    final advance = double.tryParse(_advanceAmount.text.replaceAll(',', '')) ?? 0;
    final balance = total - advance;
    return balance <= 0 ? '—' : NumberFormat('#,##,###').format(balance);
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: const PdfColor.fromInt(0xFFE8F5E9),
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1B5E20))),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150,
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
          pw.Expanded(
              child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isKn = lang == 'kn';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/transaction'); },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/transaction')),
        title: Text(isKn ? 'ಮುಂಗಡ ರಸೀದಿ' : 'Advance Receipt')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.safe, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isKn
                            ? 'ಎಲ್ಲ ವಿವರ ಭರ್ತಿ ಮಾಡಿ. PDF ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ ಎರಡೂ ಕಡೆ ಸಹಿ ಮಾಡಿ.'
                            : 'Fill all details. Download PDF and get signatures from both parties.',
                        style: const TextStyle(fontSize: 12, color: AppColors.safe, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Required fields — minimal
              _sectionTitle(isKn ? 'ಮುಖ್ಯ ವಿವರ (ಕಡ್ಡಾಯ)' : 'Essential Details *required'),
              _buildField(_buyerName, isKn ? 'ಖರೀದಿದಾರ ಹೆಸರು' : 'Buyer Name', required: true),
              _buildField(_sellerName, isKn ? 'ಮಾರಾಟಗಾರ ಹೆಸರು' : 'Seller Name', required: true),
              Row(children: [
                Expanded(child: _buildField(_totalPrice, isKn ? 'ಒಟ್ಟು ಬೆಲೆ (₹)' : 'Total Price (₹)', required: true, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(_advanceAmount, isKn ? 'ಮುಂಗಡ (₹)' : 'Advance Paid (₹)', required: true, keyboardType: TextInputType.number)),
              ]),

              const SizedBox(height: 6),
              _sectionTitle(isKn ? 'ಆಸ್ತಿ ವಿವರ (ಐಚ್ಛಿಕ)' : 'Property Details (optional)'),
              _buildField(_surveyNo, isKn ? 'ಸರ್ವೆ ಸಂಖ್ಯೆ' : 'Survey Number'),
              Row(children: [
                Expanded(child: _buildField(_village, isKn ? 'ಗ್ರಾಮ / ಬಡಾವಣೆ' : 'Village / Layout')),
                const SizedBox(width: 10),
                Expanded(child: _buildField(_district, isKn ? 'ಜಿಲ್ಲೆ' : 'District')),
              ]),
              _buildField(_extent, isKn ? 'ಅಳತೆ' : 'Extent (acres / sq.ft)'),

              const SizedBox(height: 6),
              _sectionTitle(isKn ? 'ಪಾವತಿ ವಿವರ (ಐಚ್ಛಿಕ)' : 'Payment Details (optional)'),
              DropdownButtonFormField<String>(
                value: _paymentMode.text.isEmpty ? null : _paymentMode.text,
                hint: Text(isKn ? 'ಪಾವತಿ ವಿಧಾನ ಆಯ್ಕೆ ಮಾಡಿ' : 'Select Payment Mode'),
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                items: ['Cash', 'UPI', 'NEFT', 'RTGS', 'Cheque', 'Demand Draft']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMode.text = v ?? ''),
              ),
              const SizedBox(height: 10),
              _buildField(_chequeNo, isKn ? 'ಚೆಕ್ / RTGS ಸಂಖ್ಯೆ' : 'Reference / Cheque Number (if any)'),
              Row(children: [
                Expanded(child: _buildDateField(_balanceDueDate, isKn ? 'ಬಾಕಿ ದಿನಾಂಕ' : 'Balance Due Date')),
                const SizedBox(width: 10),
                Expanded(child: _buildDateField(_registrationDeadline, isKn ? 'ನೋಂದಣಿ ಗಡುವು' : 'Registration Deadline')),
              ]),

              const SizedBox(height: 6),
              _sectionTitle(isKn ? 'ಸಂಪರ್ಕ (ಐಚ್ಛಿಕ)' : 'Contact Details (optional)'),
              Row(children: [
                Expanded(child: _buildField(_buyerPhone, isKn ? 'ಖರೀದಿದಾರ ಫೋನ್' : 'Buyer Phone', keyboardType: TextInputType.phone)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(_sellerPhone, isKn ? 'ಮಾರಾಟಗಾರ ಫೋನ್' : 'Seller Phone', keyboardType: TextInputType.phone)),
              ]),
              _buildField(_buyerAadhaar, isKn ? 'ಆಧಾರ್ ಕೊನೆ 4 ಅಂಕೆ (ಐಚ್ಛಿಕ)' : 'Aadhaar last 4 digits (optional)', keyboardType: TextInputType.number, maxLength: 4),

              const SizedBox(height: 6),
              _sectionTitle(isKn ? 'ಹೆಚ್ಚುವರಿ ಷರತ್ತುಗಳು (ಐಚ್ಛಿಕ)' : 'Additional Terms (Optional)'),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isKn
                      ? 'ಯಾವುದೇ ವಿಶೇಷ ಷರತ್ತುಗಳು, ಅಳವಡಿಕೆ ವಿವರ...'
                      : 'Any special conditions, fixtures included, access rights...',
                ),
              ),
              const SizedBox(height: 20),

              // Balance preview
              if (_totalPrice.text.isNotEmpty && _advanceAmount.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isKn ? 'ಬಾಕಿ ಮೊತ್ತ:' : 'Balance Amount:',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('₹${_balanceAmount()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : () => _generatePdf(isKn),
                  icon: _generating
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(isKn ? 'PDF ರಸೀದಿ ರಚಿಸಿ' : 'Generate PDF Receipt'),
                ),
              ),

              if (_pdfPath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => OpenFile.open(_pdfPath!),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(isKn ? 'ತೆರೆಯಿರಿ' : 'Open'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Share.shareXFiles([XFile(_pdfPath!)],
                            text: 'Advance Receipt — ${_surveyNo.text}, ${_district.text}'),
                        icon: const Icon(Icons.share),
                        label: Text(isKn ? 'ಹಂಚಿಕೊಳ್ಳಿ' : 'Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isKn
                        ? 'PDF ತಯಾರಾಗಿದೆ. WhatsApp ಮೂಲಕ ಮಾರಾಟಗಾರರಿಗೆ ಕಳುಹಿಸಿ, ಪ್ರಿಂಟ್ ತೆಗೆದು ಎರಡೂ ಕಡೆ ಸಹಿ ಮಾಡಿ.'
                        : 'PDF ready. Share via WhatsApp with seller, print and get signatures from both parties.',
                    style: const TextStyle(fontSize: 12, color: AppColors.safe, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.account_balance_outlined, color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 8),
                      Text('Next Step: Digital Escrow',
                        style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      'Your advance amount will be held securely in a digital escrow account. It is released to the seller ONLY after property registration is complete.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/escrow'),
                        icon: const Icon(Icons.lock_outline),
                        label: Text(isKn ? 'ಡಿಜಿಟಲ್ ಎಸ್ಕ್ರೋ ಸ್ಥಾಪಿಸಿ →' : 'Set Up Digital Escrow →'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),
            ],
            ],
          ),
        ),
      ),
    ));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          counterText: '',
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          );
          if (picked != null) {
            setState(() => ctrl.text = DateFormat('dd-MM-yyyy').format(picked));
          }
        },
        child: IgnorePointer(
          child: TextFormField(
            controller: ctrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
