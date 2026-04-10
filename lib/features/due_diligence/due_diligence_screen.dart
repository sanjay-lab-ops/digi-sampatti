import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Due Diligence Screen ──────────────────────────────────────────────────────
// India-adapted global checks:
//   🇯🇵 Japan Hazard Map   → KSNDMC Flood + Disaster Zone
//   🇰🇷 Korea Occupancy    → Adverse Possession + Tenant Rights
//   🇦🇪 Dubai NOC          → Builder/Society No-Objection
//   🇺🇸 USA Disclosure     → Seller Declaration Form
//   🇺🇸 USA Comparable     → Nearby Sales from EC/Guidance Value
//   🇬🇧 UK Survey          → Physical Inspection Checklist (built)
// ──────────────────────────────────────────────────────────────────────────────

class DueDiligenceScreen extends ConsumerStatefulWidget {
  const DueDiligenceScreen({super.key});
  @override
  ConsumerState<DueDiligenceScreen> createState() => _DueDiligenceScreenState();
}

class _DueDiligenceScreenState extends ConsumerState<DueDiligenceScreen> {
  // Seller disclosure answers
  final Map<String, bool?> _disclosure = {};
  bool _disclosureSubmitted = false;

  // Occupancy check answers
  bool? _isOccupied;
  bool? _hasLease;
  bool? _occupiedMoreThan12Years;
  bool? _hasRentReceipts;

  // NOC check (apartments)
  bool? _hasBuilderNoc;
  bool? _hasSocietyNoc;
  bool? _hasMaintArrears;

  static const _disclosureQuestions = [
    ('court_case',       'Are you aware of any court case on this property?'),
    ('prior_agreement',  'Have you signed a sale agreement with anyone else for this property?'),
    ('loan',             'Is there any outstanding bank loan against this property?'),
    ('family_dispute',   'Is there any family dispute or co-owner objection?'),
    ('govt_acquisition', 'Has any government notice been received for acquisition or demolition?'),
    ('encroachment',     'Is there any encroachment on the boundaries of this property?'),
    ('tenant',           'Is there a tenant or occupant currently on this property?'),
    ('conversion',       'Has this agricultural land been converted for non-agricultural use?'),
    ('poa',              'Has any Power of Attorney been given to anyone for this property?'),
    ('forged_docs',      'Are all documents original and not forged to your knowledge?'),
  ];

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(currentScanProvider);
    final propType = ref.watch(propertyTypeProvider);
    final isApartment = propType == 'apartment' || propType == 'bda_layout';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Advanced Due Diligence'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — what this screen is
            _header(scan?.surveyNumber),

            const SizedBox(height: 20),

            // ── 1. Seller Disclosure Form (USA model → India) ──────────────
            _section(
              flag: '🇮🇳',
              globalModel: 'USA Seller Disclosure',
              title: 'Seller Declaration Form',
              subtitle: 'Ask the seller these questions. Record their answers. '
                  'Any "Yes" = must be resolved before purchase.',
              color: const Color(0xFF1B5E20),
              icon: Icons.assignment_outlined,
              child: _buildDisclosureForm(),
            ),

            const SizedBox(height: 20),

            // ── 2. Flood / Disaster Zone (Japan Hazard Map → India) ────────
            _section(
              flag: '🌊',
              globalModel: 'Japan Hazard Map',
              title: 'Flood & Disaster Zone Check',
              subtitle: 'Check if this land is in a flood zone, lake bed, or '
                  'disaster-prone area. BBMP rejects buildings on flood zones.',
              color: const Color(0xFF0D47A1),
              icon: Icons.water_damage_outlined,
              child: _buildFloodCheck(scan),
            ),

            const SizedBox(height: 20),

            // ── 3. Occupancy / Adverse Possession (Korea → India) ──────────
            _section(
              flag: '🏠',
              globalModel: 'Korea Occupancy Check',
              title: 'Occupancy & Adverse Possession',
              subtitle: 'In India, if someone has lived on land for 12+ years '
                  'openly and continuously, they can claim ownership in court. '
                  'This is called Adverse Possession.',
              color: const Color(0xFF6A1B9A),
              icon: Icons.people_outlined,
              child: _buildOccupancyCheck(),
            ),

            const SizedBox(height: 20),

            // ── 4. NOC Check (Dubai model → India apartments) ──────────────
            if (isApartment) ...[
              _section(
                flag: '🏢',
                globalModel: 'Dubai NOC System',
                title: 'No-Objection Certificates (Apartments)',
                subtitle: 'For flats/apartments: builder and society must both '
                    'confirm no dues before transfer. Missing NOC = sale blocked.',
                color: const Color(0xFF00695C),
                icon: Icons.verified_outlined,
                child: _buildNocCheck(),
              ),
              const SizedBox(height: 20),
            ],

            // ── 5. Mortgage Stack Check (Korea → India) ────────────────────
            _section(
              flag: '🏦',
              globalModel: 'Korea Mortgage Stack Check',
              title: 'Total Debt vs Property Value',
              subtitle: 'If total loans on this property exceed 70% of its '
                  'value, you are at HIGH RISK even if you buy it.',
              color: const Color(0xFF880E4F),
              icon: Icons.account_balance_outlined,
              child: _buildMortgageStackCheck(scan),
            ),

            const SizedBox(height: 20),

            // ── 6. Comparable Sales (USA MLS → India) ─────────────────────
            _section(
              flag: '💰',
              globalModel: 'USA Comparable Sales (MLS)',
              title: 'Is the Price Fair?',
              subtitle: 'In India there\'s no MLS. But you can check '
                  'Guidance Value (government floor price) and recent EC '
                  'transactions to know what similar land sold for.',
              color: const Color(0xFF006064),
              icon: Icons.trending_up,
              child: _buildPriceCheck(scan),
            ),

            const SizedBox(height: 20),

            // ── 7. Expert Connect (Revenue Layer) ─────────────────────────
            _buildExpertRevenue(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _header(String? surveyNo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advanced Due Diligence',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            surveyNo != null
                ? 'Survey $surveyNo — 6 additional checks from global best practices'
                : '6 additional checks from global best practices',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Row(children: [
            _Flag('🇺🇸'), SizedBox(width: 8),
            _Flag('🇯🇵'), SizedBox(width: 8),
            _Flag('🇰🇷'), SizedBox(width: 8),
            _Flag('🇦🇪'), SizedBox(width: 8),
            _Flag('🇬🇧'), SizedBox(width: 8),
            Expanded(child: Text('Adapted for India',
                style: TextStyle(color: Colors.white60, fontSize: 11))),
          ]),
        ],
      ),
    );
  }

  // ─── Section wrapper ────────────────────────────────────────────────────────
  Widget _section({
    required String flag,
    required String globalModel,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(flag, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(title,
                            style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 14, color: color)),
                      ]),
                      Text(globalModel,
                          style: const TextStyle(fontSize: 10,
                              color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textMedium, height: 1.4)),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Seller Disclosure Form ─────────────────────────────────────────────
  Widget _buildDisclosureForm() {
    if (_disclosureSubmitted) {
      final yesCount = _disclosure.values.where((v) => v == true).length;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: yesCount > 0 ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: yesCount > 0 ? Colors.red.shade200 : Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(yesCount > 0 ? Icons.warning : Icons.check_circle,
                  color: yesCount > 0 ? Colors.red : Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(yesCount > 0
                  ? '$yesCount issue(s) disclosed by seller — must be resolved'
                  : 'Seller declared no known issues',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: yesCount > 0 ? Colors.red : Colors.green)),
            ]),
            if (yesCount > 0) ...[
              const SizedBox(height: 8),
              ..._disclosureQuestions
                  .where((q) => _disclosure[q.$1] == true)
                  .map((q) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.close, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(q.$2,
                          style: const TextStyle(fontSize: 11, color: Colors.red))),
                    ]),
                  )),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _disclosureSubmitted = false),
              child: const Text('Edit answers'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._disclosureQuestions.map((q) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(q.$2,
                    style: const TextStyle(fontSize: 12, height: 1.3)),
              ),
              const SizedBox(width: 12),
              _YesNo(
                value: _disclosure[q.$1],
                onChanged: (v) => setState(() => _disclosure[q.$1] = v),
              ),
            ],
          ),
        )),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _disclosure.isNotEmpty
                ? () => setState(() => _disclosureSubmitted = true)
                : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Save Seller Declaration',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tip: Screenshot this and share with your lawyer. '
          'A false declaration by seller is grounds for legal action.',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ─── 2. Flood / Disaster Zone ──────────────────────────────────────────────
  Widget _buildFloodCheck(scan) {
    final checks = [
      (
        Icons.water, const Color(0xFF0D47A1),
        'BBMP Flood Zones',
        'Check if property is in BBMP-marked flood/FTL (Full Tank Level) zone',
        'https://bbmpeaasthi.karnataka.gov.in',
      ),
      (
        Icons.warning_amber, Colors.orange,
        'KSNDMC Disaster Map',
        'Karnataka State Disaster Monitoring — earthquake, landslide, flood risk',
        'https://ksndmc.org',
      ),
      (
        Icons.terrain, Colors.brown,
        'Bhuvan NRSC Hazard Map',
        'ISRO\'s official natural hazard map — check your survey number location',
        'https://bhuvan-app1.nrsc.gov.in/disaster/disaster.php',
      ),
      (
        Icons.location_city, const Color(0xFF1B5E20),
        'BBMP Lake / FTL Check',
        'Check if land is within 30m of a lake (FTL/buffer zone) — cannot build',
        'https://bbmpeaasthi.karnataka.gov.in',
      ),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Why this matters: In Karnataka, thousands of lake beds (kere) were '
            'sold as plots. BBMP and courts are demolishing such buildings. '
            'Japan solved this with a public hazard map — we check Karnataka '
            'government sources instead.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...checks.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(c.$5);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: c.$2.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(c.$1, color: c.$2, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.$3, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(c.$4, style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                  ],
                )),
                Icon(Icons.open_in_new, color: c.$2, size: 16),
              ]),
            ),
          ),
        )),
      ],
    );
  }

  // ─── 3. Occupancy / Adverse Possession ────────────────────────────────────
  Widget _buildOccupancyCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'India Law: If a person occupies land openly for 12+ years without '
            'the owner\'s objection, they can file for Adverse Possession '
            '(Section 65, Limitation Act). This has ended many property sales.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        _question('Is anyone currently living on or using this land?',
            _isOccupied, (v) => setState(() => _isOccupied = v)),
        if (_isOccupied == true) ...[
          const SizedBox(height: 10),
          _question('Do they have any lease or rent agreement?',
              _hasLease, (v) => setState(() => _hasLease = v)),
          _question('Have they been there for 12+ years?',
              _occupiedMoreThan12Years,
              (v) => setState(() => _occupiedMoreThan12Years = v)),
          _question('Do they have rent receipts or any documents?',
              _hasRentReceipts,
              (v) => setState(() => _hasRentReceipts = v)),
          if (_occupiedMoreThan12Years == true)
            _dangerBox(
              '🔴 HIGH RISK — Adverse Possession Possible',
              'This occupant may have a legal claim on the land. '
              'You need a court order or legal settlement with them before purchase. '
              'Do NOT proceed without a lawyer.',
            ),
          if (_occupiedMoreThan12Years == false && _hasLease == true)
            _warningBox(
              '⚠️ Tenant with lease — must be vacated before registration',
              'Get a legal vacation notice. Tenant must surrender before you register. '
              'Check if lease is registered (registered lease has stronger protection).',
            ),
        ],
        if (_isOccupied == false)
          _safeBox('No occupant found. Physical inspection recommended to confirm.'),
      ],
    );
  }

  // ─── 4. NOC Check (Apartments) ────────────────────────────────────────────
  Widget _buildNocCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Dubai model adapted for India: For apartment resale, you need '
            '(1) Builder NOC — confirms no dues to builder, '
            '(2) Society NOC — confirms maintenance paid, '
            '(3) Bank NOC — if seller had home loan, bank clears charge. '
            'Missing any one = Sub-Registrar rejects registration.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        _question('Has builder given NOC for this resale?',
            _hasBuilderNoc, (v) => setState(() => _hasBuilderNoc = v)),
        _question('Has housing society given NOC? (maintenance paid?)',
            _hasSocietyNoc, (v) => setState(() => _hasSocietyNoc = v)),
        _question('Are there any pending maintenance arrears?',
            _hasMaintArrears, (v) => setState(() => _hasMaintArrears = v)),
        if (_hasBuilderNoc == false)
          _dangerBox('Builder NOC missing',
            'Contact builder office with sale agreement. Builder will check '
            'if all dues (parking, clubhouse, extra work) are cleared before giving NOC.'),
        if (_hasSocietyNoc == false)
          _dangerBox('Society NOC missing',
            'Get last 2 years maintenance receipts from seller. Pay any pending amount. '
            'Society secretary issues NOC on letterhead.'),
        if (_hasMaintArrears == true)
          _warningBox('Maintenance arrears pending',
            'Negotiate with seller to clear before registration. '
            'Get written proof from society that dues are cleared.'),
      ],
    );
  }

  // ─── 5. Mortgage Stack Check ───────────────────────────────────────────────
  Widget _buildMortgageStackCheck(scan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Korea lesson: In Korea, properties with loans > 80% of value '
            'are called "깡통전세" (empty-can properties). Buyer loses everything '
            'if bank auctions it. In India, same risk exists with multiple loans.\n\n'
            'Safe rule: Total loans on property should be LESS than 60% of guidance value.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        const Text('How to check:', style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        _checkStep('1', 'Get CERSAI report (from auto-scan above)',
            'Shows all registered bank charges. Note each loan amount.'),
        _checkStep('2', 'Get Kaveri EC (30 years)',
            'Shows any loan registered in Sub-Registrar office. Add these too.'),
        _checkStep('3', 'Compare with Guidance Value',
            'Guidance Value × Area = minimum property value. If total loans > 60% of this value, risk is HIGH.'),
        _checkStep('4', 'Ask seller for latest loan statement',
            'Outstanding balance may be lower than original loan. Bank NOC letter shows current balance.'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://cersai.org.in/CERSAI/homePage.prg');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('Check CERSAI for all bank charges →'),
          ),
        ),
      ],
    );
  }

  // ─── 6. Price Fairness Check ───────────────────────────────────────────────
  Widget _buildPriceCheck(scan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyan.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'USA has MLS — a database of every sold property price. India doesn\'t. '
            'But you can approximate: Guidance Value is the floor, '
            'and EC shows what others paid for similar land in the same village.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        _checkStep('1', 'Check Guidance Value (from auto-scan)',
            'This is the government\'s minimum price/sqft for this taluk. '
            'If seller asks less than this, ask why — stamp duty must be paid on guidance value anyway.'),
        _checkStep('2', 'Check recent EC transactions',
            'Kaveri EC shows past sale amounts for THIS specific survey number. '
            'Compare with what seller is quoting.'),
        _checkStep('3', 'Check IGR Karnataka registration data',
            'IGR shows all registered sale deeds in the same SRO (Sub-Registrar Office). '
            'You can see what Survey 65, 66, 68 sold for recently.'),
        _checkStep('4', 'Check 99acres / MagicBricks listings nearby',
            'Not official but gives market rate. If seller asks 3× guidance value, '
            'verify with at least 3 nearby listings.'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://igr.karnataka.gov.in/english');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('Check IGR Karnataka for market rates →'),
          ),
        ),
      ],
    );
  }

  // ─── Expert Connect + Revenue ──────────────────────────────────────────────
  Widget _buildExpertRevenue() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.support_agent, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Get Expert Help Now',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Once you\'ve done the self-check above, get professionals to verify.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _expertCard(
            Icons.gavel, '⚖️ Get Legal Opinion — ₹999',
            'A registered property lawyer reviews your DigiSampatti report + '
            'RTC + EC and gives a written legal opinion. '
            'Banks require this before home loan.',
            () => context.push('/partners'),
          ),
          const SizedBox(height: 10),
          _expertCard(
            Icons.account_balance, '🏦 Get Bank Pre-Approval',
            'Share this report with partner banks. They check title and '
            'give in-principle loan approval before you finalize the deal.',
            () => context.push('/partners'),
          ),
          const SizedBox(height: 10),
          _expertCard(
            Icons.verified_user, '🛡️ Title Insurance (New in India)',
            'Some insurers now offer title insurance for Indian properties. '
            'If title defect found later — insurer compensates. '
            'Available from HDFC Ergo, Bajaj Allianz.',
            () async {
              final uri = Uri.parse('https://www.hdfcergo.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 10),
          _expertCard(
            Icons.home_work, '🏗️ Building Plan Verification',
            'For houses/apartments: verify if the structure is BBMP/BDA approved. '
            'Unapproved structures = no bank loan + demolition risk.',
            () async {
              final uri = Uri.parse('https://bbmpeaasthi.karnataka.gov.in');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _expertCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                  color: Colors.white70, fontSize: 11, height: 1.3)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
        ]),
      ),
    );
  }

  // ─── Helper widgets ────────────────────────────────────────────────────────
  Widget _question(String q, bool? value, void Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Text(q, style: const TextStyle(fontSize: 12, height: 1.3))),
        const SizedBox(width: 12),
        _YesNo(value: value, onChanged: onChange),
      ]),
    );
  }

  Widget _checkStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF880E4F).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(num, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: Color(0xFF880E4F))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(
              fontSize: 11, color: Colors.black54, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _dangerBox(String title, String body) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.red.shade800, fontSize: 12)),
      const SizedBox(height: 4),
      Text(body, style: TextStyle(fontSize: 11, color: Colors.red.shade700, height: 1.4)),
    ]),
  );

  Widget _warningBox(String title, String body) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 12)),
      const SizedBox(height: 4),
      Text(body, style: TextStyle(fontSize: 11, color: Colors.orange.shade700, height: 1.4)),
    ]),
  );

  Widget _safeBox(String msg) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: TextStyle(fontSize: 11, color: Colors.green.shade700))),
    ]),
  );
}

// ─── Yes/No toggle widget ─────────────────────────────────────────────────────
class _YesNo extends StatelessWidget {
  final bool? value;
  final void Function(bool) onChanged;
  const _YesNo({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: () => onChanged(true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: value == true ? Colors.red.shade50 : Colors.grey.shade100,
            border: Border.all(
              color: value == true ? Colors.red : Colors.grey.shade300),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
          ),
          child: Text('Yes',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: value == true ? Colors.red : Colors.grey)),
        ),
      ),
      GestureDetector(
        onTap: () => onChanged(false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: value == false ? Colors.green.shade50 : Colors.grey.shade100,
            border: Border.all(
              color: value == false ? Colors.green : Colors.grey.shade300),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
          ),
          child: Text('No',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: value == false ? Colors.green : Colors.grey)),
        ),
      ),
    ],
  );
}

class _Flag extends StatelessWidget {
  final String flag;
  const _Flag(this.flag);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(flag, style: const TextStyle(fontSize: 14)),
  );
}
