import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── NRI Stamp Duty + FEMA Compliance Screen ──────────────────────────────────
// Covers:
//   1. Stamp duty rates for NRI buyers (same as residents for most property)
//   2. TDS on NRI seller (buyer must deduct 22.88%)
//   3. FEMA allowed/prohibited property types for NRI
//   4. Repatriation rules (how NRI sends money back abroad)
//   5. Power of Attorney (NRI can't visit — PoA guide)
//   6. Tax implications (double taxation, DTAA)
// ──────────────────────────────────────────────────────────────────────────────

class NriStampDutyScreen extends ConsumerStatefulWidget {
  const NriStampDutyScreen({super.key});
  @override
  ConsumerState<NriStampDutyScreen> createState() => _NriStampDutyScreenState();
}

class _NriStampDutyScreenState extends ConsumerState<NriStampDutyScreen> {
  // Calculator inputs
  double _propertyValue = 0;
  String _propertyType = 'residential'; // residential / commercial / agricultural
  String _buyerType    = 'nri';         // nri / pio / foreign_national
  String _sellerType   = 'resident';    // resident / nri
  bool   _isFirstHome  = true;
  bool   _isFemale     = false;
  String _selectedCountry = 'UAE / Dubai';

  // Repatriation calculator
  double _saleProceeds  = 0;
  double _purchasePrice = 0;
  double _improvementCost = 0;

  static const _countries = [
    'UAE / Dubai', 'USA', 'UK', 'Singapore', 'Canada',
    'Australia', 'Germany', 'Saudi Arabia', 'Kuwait', 'Qatar',
    'Bahrain', 'Oman', 'Malaysia', 'New Zealand', 'South Africa',
  ];

  // Karnataka stamp duty rates (2024)
  double get _stampDutyRate {
    if (_propertyValue <= 2000000) return 0.03;        // Up to ₹20L: 3%
    if (_propertyValue <= 4500000) return 0.05;        // ₹20L–45L: 5%
    return _isFemale ? 0.055 : 0.056;                 // Above ₹45L: 5.5% (F) / 5.6% (M)
  }

  double get _registrationFee => _propertyValue * 0.01;  // 1% flat
  double get _stampDuty       => _propertyValue * _stampDutyRate;
  double get _totalTransactionCost => _stampDuty + _registrationFee;

  // TDS on NRI seller: 22.88% (20% + surcharge + cess)
  double get _tdsOnNriSeller {
    if (_sellerType != 'nri') return 0;
    // Long-term (>2 years): 22.88%, Short-term: 33.99%
    return _propertyValue * 0.2288;
  }

  // Long-term capital gains for NRI seller
  double get _ltcg {
    if (_saleProceeds <= 0 || _purchasePrice <= 0) return 0;
    final indexedCost = _purchasePrice * 1.4; // approximate indexation
    final gain = _saleProceeds - indexedCost - _improvementCost;
    return gain > 0 ? gain * 0.20 : 0; // 20% LTCG for NRI
  }

  // Repatriable amount
  double get _repatriableAmount {
    if (_saleProceeds <= 0) return 0;
    return _saleProceeds - _ltcg - (_sellerType == 'nri' ? _tdsOnNriSeller : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NRI Property Guide'),
        backgroundColor: AppColors.arthBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _femaBanner(),
            const SizedBox(height: 20),

            // ── Tab-style sections ────────────────────────────────────────
            _sectionHeader('NRI Buying', Icons.shopping_cart_outlined,
                AppColors.arthBlue),
            _buildNriBuyingRules(),
            const SizedBox(height: 20),

            _sectionHeader('Stamp Duty Calculator',
                Icons.calculate_outlined, AppColors.primary),
            _buildStampDutyCalc(),
            const SizedBox(height: 20),

            _sectionHeader('TDS on NRI Seller',
                Icons.account_balance_outlined, AppColors.seller),
            _buildTdsSection(),
            const SizedBox(height: 20),

            _sectionHeader('Repatriation Calculator',
                Icons.flight_takeoff, const Color(0xFF00695C)),
            _buildRepatriationCalc(),
            const SizedBox(height: 20),

            _sectionHeader('Power of Attorney (NRI Can\'t Visit)',
                Icons.person_pin_outlined, AppColors.slate),
            _buildPoaGuide(),
            const SizedBox(height: 20),

            _sectionHeader('DTAA — Avoid Double Taxation',
                Icons.balance_outlined, const Color(0xFF4527A0)),
            _buildDtaaGuide(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── FEMA Banner ────────────────────────────────────────────────────────────
  Widget _femaBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [AppColors.arthBlue, AppColors.info]),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text('🇮🇳', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('FEMA — What NRI Can & Cannot Buy',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        _femaRow('✅ CAN BUY', [
          'Residential property (flat, house, villa)',
          'Commercial property (shop, office)',
          'Multiple properties — no limit',
          'Joint purchase with resident Indian',
        ], Colors.greenAccent),
        const SizedBox(height: 10),
        _femaRow('❌ CANNOT BUY (without RBI permission)', [
          'Agricultural land',
          'Plantation property (coffee, tea, rubber estates)',
          'Farm house',
          'Rural land / patta land',
        ], Colors.redAccent),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'The Survey 67 Hunnigere property is AGRICULTURAL land — '
            'NRI cannot buy this without special RBI permission. '
            'It must be DC converted to residential first.',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _femaRow(String label, List<String> items, Color dotColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
          color: dotColor, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 4),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(Icons.circle, size: 6, color: dotColor),
          const SizedBox(width: 8),
          Text(item, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      )),
    ],
  );

  // ── NRI Buying Rules ───────────────────────────────────────────────────────
  Widget _buildNriBuyingRules() {
    const rules = [
      (Icons.payments_outlined, 'Payment must be in INR',
       'NRI must pay through NRE/NRO bank account in India. '
       'Direct foreign currency payment is NOT allowed. '
       'Money must come via banking channel — no cash, no hawala.'),
      (Icons.account_balance, 'Home loan is allowed',
       'NRI can get home loan from Indian banks (SBI, HDFC, ICICI). '
       'Repayment can be from NRE/NRO account or rental income. '
       'Typically 70–80% LTV (Loan to Value).'),
      (Icons.people_outline, 'Joint purchase with resident Indian',
       'Allowed. The resident Indian co-owner can help with physical '
       'formalities (visit Sub-Registrar, sign papers).'),
      (Icons.how_to_vote_outlined, 'NRI status proof needed',
       'Passport + Visa + overseas address proof. '
       'PIO/OCI card holders have same rights as NRI.'),
      (Icons.currency_rupee, 'Stamp duty — same as resident',
       'NRI pays the same stamp duty as a resident Indian buyer. '
       'No extra stamp duty for NRI purchase (unlike Singapore\'s ABSD).'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: rules.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.arthBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(r.$1, color: AppColors.arthBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$2, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(r.$3, style: const TextStyle(
                    fontSize: 11, color: Colors.black54, height: 1.4)),
              ],
            )),
          ]),
        )).toList(),
      ),
    );
  }

  // ── Stamp Duty Calculator ──────────────────────────────────────────────────
  Widget _buildStampDutyCalc() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Property Value (₹)',
            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (v) => setState(() =>
              _propertyValue = double.tryParse(v.replaceAll(',', '')) ?? 0),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Text('Buyer is female?', style: TextStyle(fontSize: 13)),
          const Spacer(),
          Switch(
            value: _isFemale,
            onChanged: (v) => setState(() => _isFemale = v),
            activeColor: AppColors.primary,
          ),
        ]),
        const SizedBox(height: 4),
        if (_isFemale)
          const Text('Female buyer: 5.5% stamp duty (0.1% concession)',
              style: TextStyle(fontSize: 11, color: AppColors.safe)),
        if (_propertyValue > 0) ...[
          const Divider(height: 24),
          _calcRow('Property Value', '₹${_fmt(_propertyValue)}'),
          _calcRow('Stamp Duty Rate', '${(_stampDutyRate * 100).toStringAsFixed(1)}%'),
          _calcRow('Stamp Duty', '₹${_fmt(_stampDuty)}'),
          _calcRow('Registration Fee', '₹${_fmt(_registrationFee)}  (1% flat)'),
          const Divider(height: 16),
          _calcRow('Total Transaction Cost',
              '₹${_fmt(_totalTransactionCost)}', bold: true),
          const SizedBox(height: 8),
          const Text(
            'Karnataka rates (2024). Stamp duty applies on the higher of '
            'guidance value or agreement value.',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ],
    ),
  );

  // ── TDS on NRI Seller ──────────────────────────────────────────────────────
  Widget _buildTdsSection() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.seller.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.seller.withOpacity(0.3)),
          ),
          child: const Text(
            'If SELLER is an NRI:\n'
            'Buyer MUST deduct TDS before paying seller.\n'
            'Rate: 22.88% (20% + 10% surcharge + 4% cess) on FULL sale value\n'
            'For short-term gain (< 2 years): 33.99%\n\n'
            'If buyer fails to deduct TDS → buyer faces penalty + interest from IT dept.',
            style: TextStyle(fontSize: 12, height: 1.5,
                color: AppColors.seller),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          const Text('Is the seller an NRI?', style: TextStyle(fontSize: 13)),
          const Spacer(),
          DropdownButton<String>(
            value: _sellerType,
            items: const [
              DropdownMenuItem(value: 'resident', child: Text('Resident Indian')),
              DropdownMenuItem(value: 'nri', child: Text('NRI / OCI')),
            ],
            onChanged: (v) => setState(() => _sellerType = v!),
          ),
        ]),
        if (_sellerType == 'nri') ...[
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sale Value (₹)',
              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() =>
                _propertyValue = double.tryParse(v.replaceAll(',', '')) ?? 0),
          ),
          if (_propertyValue > 0) ...[
            const Divider(height: 20),
            _calcRow('Sale Value', '₹${_fmt(_propertyValue)}'),
            _calcRow('TDS to deduct (22.88%)', '₹${_fmt(_tdsOnNriSeller)}',
                color: Colors.red),
            _calcRow('Amount to pay seller',
                '₹${_fmt(_propertyValue - _tdsOnNriSeller)}', bold: true),
            const SizedBox(height: 12),
            const Text('How to pay TDS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...[
              'Deduct TDS from payment to seller',
              'Deposit TDS online using Form 27Q (not 26QB — NRI seller)',
              'Deposit within 7 days of end of month of payment',
              'Issue Form 16A certificate to seller',
              'File TDS return quarterly (Form 27Q)',
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.circle, size: 5, color: AppColors.seller),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
              ]),
            )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://www.incometax.gov.in/iec/foportal/');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser, size: 14),
                label: const Text('File Form 27Q on Income Tax Portal →'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seller,
                    side: const BorderSide(color: AppColors.seller)),
              ),
            ),
          ],
        ],
        if (_sellerType == 'resident') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Seller is resident Indian: TDS is 1% (Form 26QB) '
              'on properties above ₹50 lakh. No TDS for below ₹50L.',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        ],
      ],
    ),
  );

  // ── Repatriation Calculator ────────────────────────────────────────────────
  Widget _buildRepatriationCalc() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'If NRI is SELLING a property and wants to send proceeds abroad:',
          style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 12),
        // Country selector
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: 'Sending money to',
            prefixIcon: const Icon(Icons.flight_takeoff, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _countries.map((c) => DropdownMenuItem(
            value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCountry = v!),
        ),
        const SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Sale Proceeds (₹)',
            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (v) => setState(() =>
              _saleProceeds = double.tryParse(v.replaceAll(',', '')) ?? 0),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Original Purchase Price (₹)',
            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (v) => setState(() =>
              _purchasePrice = double.tryParse(v.replaceAll(',', '')) ?? 0),
        ),
        if (_saleProceeds > 0 && _purchasePrice > 0) ...[
          const Divider(height: 20),
          _calcRow('Sale Proceeds', '₹${_fmt(_saleProceeds)}'),
          _calcRow('LTCG Tax (20%)', '₹${_fmt(_ltcg)}', color: Colors.orange),
          _calcRow('TDS already deducted (22.88%)',
              '₹${_fmt(_tdsOnNriSeller)}', color: Colors.red),
          _calcRow('Repatriable Amount (approx)',
              '₹${_fmt(_repatriableAmount)}', bold: true),
          const SizedBox(height: 12),
          const Text('FEMA Repatriation Rules:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...[
            'Max repatriation: USD 1 million per year per person',
            'Must be from NRO account after paying all taxes',
            'Need CA Certificate (Form 15CA + 15CB) for RBI compliance',
            'Proceeds from property held < 2 years: taxed as short-term gain',
            'DTAA treaty may reduce tax if you file in both countries',
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.circle, size: 5, color: Color(0xFF00695C)),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
            ]),
          )),
        ],
      ],
    ),
  );

  // ── Power of Attorney Guide ────────────────────────────────────────────────
  Widget _buildPoaGuide() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NRI cannot physically visit India for every step. '
          'A Power of Attorney (PoA) lets a trusted person act on your behalf.',
          style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 14),
        ...[
          ('General PoA vs Specific PoA',
           'Use SPECIFIC PoA — only for this one property transaction. '
           'General PoA gives too much power and is risky if misused.'),
          ('Attestation procedure',
           '1. Draft PoA in India\n'
           '2. Send to NRI abroad\n'
           '3. Sign before Indian consulate / notary in that country\n'
           '4. Apostille stamp (for Hague Convention countries)\n'
           '5. Send original to India — register at Sub-Registrar'),
          ('What PoA holder CAN do',
           'Sign sale agreement, appear at Sub-Registrar, sign sale deed, '
           'collect possession, pay property tax — whatever you specify.'),
          ('What PoA holder CANNOT do',
           'PoA is revoked automatically on NRI\'s death. '
           'PoA holder cannot sell to themselves. '
           'Biometric registration may still need NRI to visit once.'),
          ('Cost',
           'Consulate attestation: USD 25–50. Apostille: country-specific. '
           'Registration in India: ₹1,000–2,000.'),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$1, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Text(item.$2, style: const TextStyle(
                fontSize: 11, color: Colors.black54, height: 1.4)),
          ]),
        )),
      ],
    ),
  );

  // ── DTAA Guide ────────────────────────────────────────────────────────────
  Widget _buildDtaaGuide() {
    const countries = [
      ('USA', 'Yes — DTAA signed. Capital gains taxed in India; credit available in USA.'),
      ('UK',  'Yes — DTAA signed. Property income taxed in India; credit in UK.'),
      ('UAE', 'Yes — DTAA signed. UAE has 0% income tax — pay only India tax.'),
      ('Singapore', 'Yes — DTAA signed. Favourable rates on capital gains.'),
      ('Canada', 'Yes — DTAA signed. Mutual credit for taxes paid.'),
      ('Australia', 'Yes — DTAA signed. Gains taxed per Indian rules; credit in AUS.'),
      ('Germany', 'Yes — DTAA signed. Credit mechanism available.'),
      ('Saudi Arabia', 'Yes — DTAA signed.'),
      ('Qatar', 'Yes — DTAA signed.'),
      ('Kuwait', 'Yes — DTAA signed.'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Double Taxation Avoidance Agreement (DTAA) — India has DTAA with '
            '90+ countries. If you pay tax on property income/gains in India, '
            'your country of residence gives you a tax credit — you don\'t pay twice.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          const Text('DTAA Status for Common NRI Countries:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...countries.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle, color: AppColors.safe, size: 16),
              const SizedBox(width: 8),
              Expanded(child: RichText(text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(text: '${c.$1}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  TextSpan(text: c.$2,
                      style: const TextStyle(fontSize: 11,
                          color: Colors.black54)),
                ],
              ))),
            ]),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(
                    'https://www.incometax.gov.in/iec/foportal/help/international-taxation/dtaa');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 14),
              label: const Text('View all India DTAA treaties →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: color)),
    ]),
  );

  Widget _calcRow(String label, String value,
      {bool bold = false, Color? color}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
        Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (bold ? AppColors.primary : null))),
      ]),
    );

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}
