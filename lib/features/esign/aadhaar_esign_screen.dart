import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Aadhaar e-Sign Screen ─────────────────────────────────────────────────────
// Lets buyer generate a Sale Agreement draft and e-sign it using
// Aadhaar OTP via DigiLocker / eMudhra.
//
// Flow:
//   1. App generates a pre-filled sale agreement from scan data
//   2. Buyer reviews and edits key fields
//   3. Opens DigiLocker / eMudhra / Signzy for Aadhaar-based e-sign
//   4. Signed document is shared via WhatsApp / saved to DigiLocker
//
// Note: Full Aadhaar e-sign requires an ASP (Application Service Provider)
// licence from UIDAI. This screen uses eMudhra / Signzy (licensed ASPs)
// via deeplink. The actual signing happens in their certified app.
// ──────────────────────────────────────────────────────────────────────────────

class AadhaarEsignScreen extends ConsumerStatefulWidget {
  const AadhaarEsignScreen({super.key});
  @override
  ConsumerState<AadhaarEsignScreen> createState() => _AadhaarEsignScreenState();
}

class _AadhaarEsignScreenState extends ConsumerState<AadhaarEsignScreen> {
  // Agreement fields
  final _buyerNameCtrl     = TextEditingController();
  final _buyerAadhaarCtrl  = TextEditingController();
  final _buyerAddressCtrl  = TextEditingController();
  final _sellerNameCtrl    = TextEditingController();
  final _sellerAadhaarCtrl = TextEditingController();
  final _sellerAddressCtrl = TextEditingController();
  final _amountCtrl        = TextEditingController();
  final _advanceCtrl       = TextEditingController();
  final _dateCtrl          = TextEditingController();
  final _registrationCtrl  = TextEditingController();

  bool _draftGenerated = false;
  String _draftText = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill from current scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = ref.read(currentScanProvider);
      if (scan != null) {
        _dateCtrl.text = _today();
        _registrationCtrl.text =
            '${scan.surveyNumber ?? ""}, ${scan.village ?? ""}, '
            '${scan.taluk ?? ""}, ${scan.district ?? ""}';
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _buyerNameCtrl, _buyerAadhaarCtrl, _buyerAddressCtrl,
      _sellerNameCtrl, _sellerAadhaarCtrl, _sellerAddressCtrl,
      _amountCtrl, _advanceCtrl, _dateCtrl, _registrationCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  String _today() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  void _generateDraft() {
    if (_buyerNameCtrl.text.isEmpty || _sellerNameCtrl.text.isEmpty ||
        _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill buyer name, seller name and sale amount')),
      );
      return;
    }
    setState(() {
      _draftText = _buildAgreementText();
      _draftGenerated = true;
    });
  }

  String _buildAgreementText() => '''
SALE AGREEMENT / ಮಾರಾಟ ಒಪ್ಪಂದ

This Sale Agreement is made on ${_dateCtrl.text}

SELLER:
  Name    : ${_sellerNameCtrl.text}
  Aadhaar : ${_sellerAadhaarCtrl.text.isNotEmpty ? 'XXXX-XXXX-${_sellerAadhaarCtrl.text.substring(_sellerAadhaarCtrl.text.length > 4 ? _sellerAadhaarCtrl.text.length - 4 : 0)}' : 'Not provided'}
  Address : ${_sellerAddressCtrl.text}

BUYER:
  Name    : ${_buyerNameCtrl.text}
  Aadhaar : ${_buyerAadhaarCtrl.text.isNotEmpty ? 'XXXX-XXXX-${_buyerAadhaarCtrl.text.substring(_buyerAadhaarCtrl.text.length > 4 ? _buyerAadhaarCtrl.text.length - 4 : 0)}' : 'Not provided'}
  Address : ${_buyerAddressCtrl.text}

PROPERTY:
  ${_registrationCtrl.text}

TERMS:
  Total Sale Value : ₹${_amountCtrl.text}
  Advance Paid     : ₹${_advanceCtrl.text.isNotEmpty ? _advanceCtrl.text : '0'}
  Balance Amount   : ₹${_balanceAmount()}
  Registration by  : Within 3 months of this agreement

DECLARATIONS BY SELLER:
  1. I am the absolute owner of the above property.
  2. The property is free from all encumbrances, mortgages and liens.
  3. There is no court case, injunction or government notice on this property.
  4. I have not entered into any prior sale agreement for this property.
  5. I will co-operate for registration within the agreed period.

DECLARATIONS BY BUYER:
  1. I have verified the property documents and am satisfied.
  2. I have conducted due diligence via DigiSampatti (Report ID attached).
  3. I agree to pay the balance amount at the time of registration.

This agreement is subject to full registration at the Sub-Registrar Office.
Advance paid is refundable if seller fails to register within agreed period.

Signed by SELLER: ____________________    Date: ${_dateCtrl.text}
Signed by BUYER : ____________________    Date: ${_dateCtrl.text}

Witness 1: ____________________
Witness 2: ____________________

---
This draft was generated by DigiSampatti. Have a lawyer review it before signing.
''';

  String _balanceAmount() {
    try {
      final total   = double.parse(_amountCtrl.text.replaceAll(',', ''));
      final advance = double.parse(_advanceCtrl.text.isEmpty ? '0' : _advanceCtrl.text.replaceAll(',', ''));
      return (total - advance).toStringAsFixed(0);
    } catch (_) { return '—'; }
  }

  Future<void> _shareAgreement() async {
    await Share.share(
      _draftText,
      subject: 'Sale Agreement Draft — ${_registrationCtrl.text}',
    );
  }

  Future<void> _openEsignService(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sale Agreement + e-Sign'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox(),
            const SizedBox(height: 20),

            // ── Step 1: Fill agreement ────────────────────────────────────
            _stepCard(
              step: '1',
              title: 'Fill Sale Agreement Details',
              color: AppColors.primary,
              child: _buildForm(),
            ),
            const SizedBox(height: 16),

            // ── Step 2: Generate draft ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateDraft,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Generate Agreement Draft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),

            if (_draftGenerated) ...[
              const SizedBox(height: 16),

              // ── Draft preview ─────────────────────────────────────────
              _stepCard(
                step: '2',
                title: 'Review Agreement',
                color: AppColors.arthBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(_draftText,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 11, height: 1.5)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareAgreement,
                        icon: const Icon(Icons.share),
                        label: const Text('Share Draft via WhatsApp / Email'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Step 3: e-Sign ────────────────────────────────────────
              _stepCard(
                step: '3',
                title: 'e-Sign with Aadhaar OTP',
                color: const Color(0xFF6A1B9A),
                child: _buildEsignOptions(),
              ),
              const SizedBox(height: 16),

              // ── Step 4: Register ──────────────────────────────────────
              _stepCard(
                step: '4',
                title: 'Next: Get it Registered',
                color: AppColors.deepOrange,
                child: _buildRegistrationGuide(),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoBox() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.fingerprint, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Aadhaar e-Sign for Property Agreements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                  color: AppColors.primary)),
        ]),
        SizedBox(height: 8),
        Text(
          'An Aadhaar-based e-signature is legally valid under the IT Act 2000 '
          'and the Indian Evidence Act. It is equivalent to a physical signature '
          'for most documents EXCEPT sale deeds that need Sub-Registrar stamp.\n\n'
          'Use this for: Sale Agreement (before registration), Advance Receipt, '
          'Power of Attorney, Cancellation Letter.\n\n'
          'NOT a replacement for: Final Sale Deed (must be physically registered '
          'at Sub-Registrar office with both parties present).',
          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _buildForm() => Column(
    children: [
      _label('SELLER DETAILS'),
      _field(_sellerNameCtrl, 'Seller Full Name (as in Aadhaar)', Icons.person),
      _field(_sellerAadhaarCtrl, 'Seller Aadhaar Number (12 digits)',
          Icons.credit_card, keyboardType: TextInputType.number, maxLength: 12),
      _field(_sellerAddressCtrl, 'Seller Address', Icons.home, maxLines: 2),
      const SizedBox(height: 12),
      _label('BUYER DETAILS'),
      _field(_buyerNameCtrl, 'Buyer Full Name (as in Aadhaar)', Icons.person),
      _field(_buyerAadhaarCtrl, 'Buyer Aadhaar Number (12 digits)',
          Icons.credit_card, keyboardType: TextInputType.number, maxLength: 12),
      _field(_buyerAddressCtrl, 'Buyer Address', Icons.home, maxLines: 2),
      const SizedBox(height: 12),
      _label('PROPERTY & PRICE'),
      _field(_registrationCtrl, 'Property (Survey No, Village, Taluk, District)',
          Icons.map, maxLines: 2),
      _field(_amountCtrl, 'Total Sale Value (₹)', Icons.currency_rupee,
          keyboardType: TextInputType.number),
      _field(_advanceCtrl, 'Advance Amount Paid (₹)', Icons.payments,
          keyboardType: TextInputType.number),
      _field(_dateCtrl, 'Agreement Date (DD/MM/YYYY)', Icons.calendar_today),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: AppColors.textLight, letterSpacing: 0.5)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, int? maxLength}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          counterText: '',
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );

  Widget _buildEsignOptions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Choose a licensed Aadhaar e-Sign provider. '
        'These are UIDAI-authorised ASPs — sign with your Aadhaar OTP.',
        style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
      ),
      const SizedBox(height: 12),
      _esignProvider(
        'eMudhra',
        'Government-licensed CA. Most widely used for property documents.',
        'https://www.emudhra.com/esign',
        const Color(0xFF6A1B9A),
      ),
      const SizedBox(height: 8),
      _esignProvider(
        'Signzy',
        'API-based e-sign. Used by banks and NBFCs for property loans.',
        'https://signzy.com',
        AppColors.info,
      ),
      const SizedBox(height: 8),
      _esignProvider(
        'DigiLocker e-Sign',
        'Government of India\'s own e-sign service. Free, Aadhaar OTP based.',
        'https://www.digilocker.gov.in',
        AppColors.primary,
      ),
      const SizedBox(height: 8),
      _esignProvider(
        'Leegality',
        'India\'s largest e-sign platform. Supports Aadhaar + DSC signing.',
        'https://leegality.com',
        const Color(0xFF00695C),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Text(
          'Steps inside the e-sign app:\n'
          '1. Upload the agreement PDF\n'
          '2. Enter your Aadhaar number\n'
          '3. Enter OTP received on Aadhaar-linked mobile\n'
          '4. Sign is embedded in the PDF digitally\n'
          '5. Download signed PDF — share with seller',
          style: TextStyle(fontSize: 11, height: 1.5, color: Colors.brown),
        ),
      ),
    ],
  );

  Widget _esignProvider(String name, String desc, String url, Color color) =>
    InkWell(
      onTap: () => _openEsignService(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fingerprint, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13, color: color)),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          Icon(Icons.open_in_new, color: color, size: 16),
        ]),
      ),
    );

  Widget _buildRegistrationGuide() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'A sale agreement (even e-signed) is NOT the final step. '
        'You MUST register the Sale Deed at the Sub-Registrar Office.',
        style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
      ),
      const SizedBox(height: 12),
      ...[
        ('1', 'Book SRO appointment online',
         'kaveri.karnataka.gov.in → Appointment → select your SRO'),
        ('2', 'Pay stamp duty',
         'Calculate on Guidance Value × Area. Pay via SHCIL e-stamp or SBI.'),
        ('3', 'Both parties visit SRO with originals',
         'Seller + buyer + 2 witnesses. Carry: Aadhaar, PAN, 2 passport photos each.'),
        ('4', 'Biometric verification',
         'Both thumbprints scanned at SRO. Process takes 30–60 minutes.'),
        ('5', 'Collect registered deed',
         'Get digitally signed registered deed same day. '
         'Upload to DigiLocker for permanent storage.'),
      ].map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.deepOrange, shape: BoxShape.circle),
            child: Text(s.$1, style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.$2, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
              Text(s.$3, style: const TextStyle(
                  fontSize: 11, color: Colors.black54, height: 1.3)),
            ],
          )),
        ]),
      )),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse('https://kaverionline.karnataka.gov.in');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_browser, size: 16),
          label: const Text('Book SRO Appointment on Kaveri Online →'),
        ),
      ),
    ],
  );

  Widget _stepCard({
    required String step,
    required String title,
    required Color color,
    required Widget child,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(step, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(14), child: child),
    ]),
  );
}
