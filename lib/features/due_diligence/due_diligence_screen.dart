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

            // ── 7. France Diagnostics → India Building Condition ───────────
            _section(
              flag: '🇫🇷',
              globalModel: 'France Diagnostics Immobiliers',
              title: 'Building Condition Check',
              subtitle: 'In France, seller MUST provide 9 mandatory diagnostic '
                  'certificates before any sale. India has NO equivalent — '
                  'buyers discover problems after purchase. Check these manually.',
              color: const Color(0xFF1565C0),
              icon: Icons.home_repair_service_outlined,
              child: _buildFranceDiagnostics(),
            ),

            const SizedBox(height: 20),

            // ── 8. Germany Grundbuch → Unregistered Deal Warning ──────────
            _section(
              flag: '🇩🇪',
              globalModel: 'Germany Grundbuch + Mandatory Notary',
              title: 'Registration is NOT Optional',
              subtitle: 'In Germany, ALL property sales MUST go through a notary '
                  'and be registered in the Grundbuch. In India, '
                  'unregistered agreements are common but DANGEROUS.',
              color: const Color(0xFF37474F),
              icon: Icons.how_to_reg_outlined,
              child: _buildGermanyLesson(),
            ),

            const SizedBox(height: 20),

            // ── 9. Australia Vendor Statement → Planning Overlay ───────────
            _section(
              flag: '🇦🇺',
              globalModel: 'Australia Section 32 Vendor Statement',
              title: 'Planning & Zoning Check',
              subtitle: 'In Australia, seller must disclose ALL planning overlays '
                  '(flood, heritage, road widening) BEFORE sale. '
                  'In India, check BDA/BBMP Master Plan and road widening plans.',
              color: const Color(0xFF00695C),
              icon: Icons.map_outlined,
              child: _buildAustraliaCheck(),
            ),

            const SizedBox(height: 20),

            // ── 10. Brazil Certidões → Seller Background Check ────────────
            _section(
              flag: '🇧🇷',
              globalModel: 'Brazil Certidões Negativas',
              title: 'Seller Personal Background Check',
              subtitle: 'Brazil requires 12+ certificates about the SELLER — '
                  'tax dues, court cases, bankruptcy. If seller owes money, '
                  'courts can cancel your sale even after registration.',
              color: const Color(0xFF4E342E),
              icon: Icons.person_search_outlined,
              child: _buildBrazilCheck(),
            ),

            const SizedBox(height: 20),

            // ── 11. Singapore CPF/EPF → Buyer Fund Check ──────────────────
            _section(
              flag: '🇸🇬',
              globalModel: 'Singapore CPF Usage Rules',
              title: 'Using EPF / PF Money to Buy',
              subtitle: 'Singapore has strict CPF (like India\'s EPF/PF) rules '
                  'for property purchase. In India, you CAN withdraw EPF '
                  'for property — but with conditions.',
              color: const Color(0xFF00838F),
              icon: Icons.savings_outlined,
              child: _buildSingaporeCheck(),
            ),

            const SizedBox(height: 20),

            // ── 12. Malaysia Land Restrictions → India SC/ST + Agri Land ──
            _section(
              flag: '🇲🇾',
              globalModel: 'Malaysia Bumi Lot Restrictions',
              title: 'Land Restriction Check',
              subtitle: 'Malaysia restricts sale of "Bumi lots" to non-Bumiputera. '
                  'India has similar restrictions: SC/ST land, tribal land, '
                  'agricultural land to non-agriculturists.',
              color: const Color(0xFF1B5E20),
              icon: Icons.do_not_disturb_alt_outlined,
              child: _buildMalaysiaCheck(),
            ),

            const SizedBox(height: 20),

            // ── 13. New Zealand LIM → DigiSampatti IS the LIM ─────────────
            _section(
              flag: '🇳🇿',
              globalModel: 'New Zealand LIM Report',
              title: 'What DigiSampatti IS Building',
              subtitle: 'New Zealand\'s LIM (Land Information Memorandum) '
                  'is one document from the council that covers everything — '
                  'zoning, hazards, drainage, consents, valuations. '
                  'DigiSampatti is India\'s version of the LIM.',
              color: AppColors.primary,
              icon: Icons.lightbulb_outlined,
              child: _buildNzLesson(),
            ),

            const SizedBox(height: 20),

            // ── 14. Sweden BankID → India Aadhaar for Property ────────────
            _section(
              flag: '🇸🇪',
              globalModel: 'Sweden BankID Digital Signing',
              title: 'Digital Property Transactions (India\'s Future)',
              subtitle: 'Sweden does ALL property transactions digitally — '
                  'signed with BankID (like Aadhaar). India is moving toward '
                  'this with DigiLocker + Aadhaar e-sign.',
              color: const Color(0xFF0D47A1),
              icon: Icons.fingerprint,
              child: _buildSwedenLesson(),
            ),

            const SizedBox(height: 20),

            // ── 15. South Africa FICA → AML Check on Seller ───────────────
            _section(
              flag: '🇿🇦',
              globalModel: 'South Africa FICA Compliance',
              title: 'Anti-Money Laundering Check',
              subtitle: 'South Africa\'s FICA requires identity and source-of-funds '
                  'verification. India\'s ED and IT department track property '
                  'transactions above ₹30L. Know your obligations.',
              color: const Color(0xFFBF360C),
              icon: Icons.security_outlined,
              child: _buildSaCheck(),
            ),

            const SizedBox(height: 20),

            // ── 16. Italy Conformità → Approved Plan vs Actual ────────────
            _section(
              flag: '🇮🇹',
              globalModel: 'Italy Conformità Urbanistica',
              title: 'Building Plan vs Actual Structure',
              subtitle: 'In Italy, sale is VOID if actual construction doesn\'t '
                  'match the approved plan. In India, same rule applies — '
                  'BBMP can demolish unapproved structures.',
              color: const Color(0xFF880E4F),
              icon: Icons.compare_outlined,
              child: _buildItalyCheck(),
            ),

            const SizedBox(height: 20),

            // ── 17. Canada Title Insurance → India ────────────────────────
            _section(
              flag: '🇨🇦',
              globalModel: 'Canada Title Insurance (Widespread)',
              title: 'Title Insurance — Coming to India',
              subtitle: 'Canada has near-universal title insurance. In India, '
                  'a few insurers have started. If DigiSampatti misses something, '
                  'title insurance is your last safety net.',
              color: const Color(0xFF4527A0),
              icon: Icons.shield_outlined,
              child: _buildCanadaCheck(),
            ),

            const SizedBox(height: 20),

            // ── Expert Connect (Revenue Layer) ─────────────────────────────
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
          const Wrap(spacing: 6, runSpacing: 4, children: [
            _Flag('🇺🇸'), _Flag('🇯🇵'), _Flag('🇰🇷'), _Flag('🇦🇪'),
            _Flag('🇬🇧'), _Flag('🇩🇪'), _Flag('🇫🇷'), _Flag('🇦🇺'),
            _Flag('🇸🇬'), _Flag('🇧🇷'), _Flag('🇲🇾'), _Flag('🇿🇦'),
            _Flag('🇳🇿'), _Flag('🇮🇹'), _Flag('🇸🇪'), _Flag('🇨🇦'),
          ]),
          const SizedBox(height: 6),
          const Text('16 countries → adapted for India',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
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

  // ─── France: Building Condition Diagnostics ───────────────────────────────
  Widget _buildFranceDiagnostics() {
    const checks = [
      ('🔧', 'Structural integrity', 'Any cracks in walls, foundation, roof slab? Get a civil engineer to inspect.'),
      ('💧', 'Water & drainage', 'Check plumbing age, sump, overhead tank, sewage connection to BBMP drain.'),
      ('⚡', 'Electrical wiring', 'Old wiring (pre-2000)? Check for earthing. Get electrician report.'),
      ('🐜', 'Pest / termite', 'Especially in ground floor / wooden structures. Get pest control certificate.'),
      ('🏗️', 'Asbestos roof/sheets', 'Common in older Karnataka buildings. Asbestos removal is mandatory in EU. India: health risk.'),
      ('🌊', 'Waterproofing', 'Terrace and bathroom waterproofing quality. Leaks damage structure over years.'),
      ('🔥', 'Fire safety', 'For apartments: is there a fire NOC from Fire Department? Mandatory above 15m height.'),
      ('📐', 'Setbacks & margins', 'Front: 3m, sides: 1.5m from boundary. BBMP can demolish violations.'),
      ('🌡️', 'Energy efficiency', 'France rates energy A-G. India has no rating. But check orientation, ventilation, roof insulation.'),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'France law: Seller pays for 9 certified diagnostics BEFORE listing. '
            'India has NO such law — buyers discover cracks, termites, leaks AFTER paying. '
            'Do this yourself before signing any agreement.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...checks.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.$1, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(c.$3, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
            ])),
          ]),
        )),
      ],
    );
  }

  // ─── Germany: Registration is NOT Optional ────────────────────────────────
  Widget _buildGermanyLesson() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _compareRow('Germany', 'India', [
          ('Every sale registered in Grundbuch (land register)', 'People do unregistered sale agreements'),
          ('Notary mandatory — personally explains terms to both parties', 'No notary required — only stamp paper'),
          ('Title is transferred ONLY after Grundbuch entry', 'Title transfers on agreement date — risky'),
          ('Cannot sell same property twice — Grundbuch prevents it', 'Double sale fraud is common in India'),
        ]),
        const SizedBox(height: 12),
        _dangerBox(
          '⚠️ Never do an unregistered property deal in India',
          'An unregistered agreement has limited legal standing. '
          'Register EVERY agreement at the Sub-Registrar office — even a sale agreement. '
          'Registration fee is small. Protection is massive.',
        ),
        const SizedBox(height: 8),
        _checkStep('Rule', 'Any payment above ₹2 lakh must have a paper trail',
            'Cash transactions for property are flagged by Income Tax. Seller can demand black money — refuse. '
            'Pay only via bank transfer / DD. Keep all receipts.'),
      ],
    );
  }

  // ─── Australia: Planning & Zoning ─────────────────────────────────────────
  Widget _buildAustraliaCheck() {
    const links = [
      ('BDA Master Plan 2031', 'Is this land in green belt, industrial, or residential zone?',
        'https://bdabangalore.org/masterplan2031.html'),
      ('BBMP Zoning Map', 'What is the permitted Floor Area Ratio (FAR) for this area?',
        'https://bbmpeaasthi.karnataka.gov.in'),
      ('Road Widening Check', 'Is this plot in an upcoming road widening alignment? BBMP can acquire without notice.',
        'https://bbmpeaasthi.karnataka.gov.in'),
      ('TDR (Transfer of Dev Rights)', 'If road widened, owner gets TDR. Check if TDR is already consumed.',
        'https://bdabangalore.org'),
      ('BMRDA Approval', 'For peri-urban areas: Is layout BDA/BMRDA approved or unapproved revenue layout?',
        'https://bmrda.karnataka.gov.in'),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Australia\'s Section 32: Seller must disclose road widening, heritage overlays, '
            'development restrictions BEFORE you sign. India has no such law — '
            'you must check BDA/BBMP master plan yourself.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(l.$3);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.open_in_browser, color: Color(0xFF00695C), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(l.$2, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ])),
              ]),
            ),
          ),
        )),
      ],
    );
  }

  // ─── Brazil: Seller Background Check ─────────────────────────────────────
  Widget _buildBrazilCheck() {
    const certifications = [
      ('🏛️', 'Income Tax Clearance', 'Ask seller for last 3 years IT returns. No returns = tax dept can freeze property post-sale.'),
      ('⚖️', 'Civil Court Cases on Seller', 'Search seller name on eCourts. If seller owes money, creditors can reverse your sale.'),
      ('🏦', 'CIBIL / Credit Score of Seller', 'Not legally required but tells you if seller is under financial distress.'),
      ('💼', 'GST Registration Check', 'If seller is a company or builder: check GST filing history. Defaulting companies face tax attachment.'),
      ('🏠', 'Multiple Property Check', 'Ask seller to show all properties he owns (Form 26AS shows property transactions). Is he selling under distress?'),
      ('👤', 'ID Verification', 'Seller\'s Aadhaar + PAN must match exactly. Mismatch = possible fraud. Verify on UIDAI portal.'),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Brazil requires 12 "Certidões Negativas" about the SELLER — court cases, tax dues, '
            'bankruptcy. In India there\'s no requirement — but creditors CAN cancel your sale '
            'if seller owes them money. Check the seller, not just the property.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...certifications.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.$1, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(c.$3, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
            ])),
          ]),
        )),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://www.pan.utiitsl.com/PAN/mainPage.html');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.search, size: 14),
            label: const Text('Verify Seller PAN on Income Tax Portal →'),
          ),
        ),
      ],
    );
  }

  // ─── Singapore: EPF/PF Usage ──────────────────────────────────────────────
  Widget _buildSingaporeCheck() {
    const rules = [
      ('✅', 'You CAN withdraw EPF for home loan EMI payment', 'Form 31 withdrawal — for repayment of home loan taken for residential property'),
      ('✅', 'You CAN withdraw EPF for property purchase', 'Must be residential, not commercial. Minimum 5 years EPF membership.'),
      ('✅', 'NPS (National Pension System) withdrawal allowed', 'Up to 25% for house purchase after 10 years of subscription'),
      ('⚠️', 'EPF withdrawal for agricultural land is NOT allowed', 'EPF only for residential property. Agricultural plot = not eligible.'),
      ('⚠️', 'Tax on EPF withdrawal if < 5 years service', 'TDS deducted at 10% if PAN given, 30% if not. Plan accordingly.'),
      ('❌', 'Cannot withdraw EPF if property is under construction', 'Must be ready-to-move. Some exceptions for self-construction.'),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Singapore\'s CPF (Central Provident Fund) has strict rules — can only use for '
            'HDB flats or private property up to valuation limit. India\'s EPF has similar '
            'but less-known rules. Many buyers don\'t know they can use PF for EMIs.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...rules.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$1, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(r.$3, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
            ])),
          ]),
        )),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://unifiedportal-mem.epfindia.gov.in');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_browser, size: 14),
            label: const Text('Check EPF withdrawal eligibility →'),
          ),
        ),
      ],
    );
  }

  // ─── Malaysia: Land Restrictions ─────────────────────────────────────────
  Widget _buildMalaysiaCheck() {
    const restrictions = [
      ('🔴', 'SC/ST Reserved Land', 'Cannot be sold to non-SC/ST buyer without collector permission. Violation = sale void.', true),
      ('🔴', 'Tribal / Adivasi Land', 'Especially in Kodagu, Dakshina Kannada, North Karnataka. Special permission needed.', true),
      ('🔴', 'Agricultural Land to Non-Agriculturist', 'Karnataka law: agricultural land cannot be sold to non-agriculturist without DC conversion.', true),
      ('🔴', 'Inam / Grant Land', 'Government grant land (Inam) has resale restrictions. Check RTC for "Inam" classification.', true),
      ('🟡', 'Wakf Property', 'Muslim religious endowment. Cannot be sold without Wakf Board permission.', false),
      ('🟡', 'Temple / Mutt Land', 'Hindu Religious Endowment properties. HR&CE permission needed.', false),
      ('🟡', 'Land Ceiling Surplus', 'If landowner holds more than ceiling limit, surplus is government — cannot be sold.', false),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Malaysia restricts who can buy "Bumi lots" (reserved for Bumiputera). '
            'India has MORE complex restrictions — agricultural, tribal, SC/ST, Inam, Wakf. '
            'These show in the RTC land type field. Know them before paying.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...restrictions.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: r.$4 ? Colors.red.shade50 : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: r.$4 ? Colors.red.shade200 : Colors.amber.shade200),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$1, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.$2, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                  color: r.$4 ? Colors.red.shade800 : Colors.amber.shade900)),
              const SizedBox(height: 2),
              Text(r.$3, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
            ])),
          ]),
        )),
      ],
    );
  }

  // ─── New Zealand: DigiSampatti IS the LIM ────────────────────────────────
  Widget _buildNzLesson() {
    const nzLim = [
      ('Zone', 'Residential / Rural / Industrial'),
      ('Hazards', 'Flood, earthquake, landslide risk'),
      ('Drainage', 'Stormwater connection, sewer'),
      ('Building consents', 'All permitted structures and amendments'),
      ('Outstanding notices', 'Any council enforcement notices'),
      ('Rates arrears', 'Unpaid council rates'),
      ('Valuations', 'Capital value, land value, improvement value'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Text(
            'New Zealand\'s LIM Report = one document that tells you EVERYTHING '
            'about a property from the council. Takes 10 working days. '
            'DigiSampatti is building India\'s equivalent — one app, all official data.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        const Text('NZ LIM covers → DigiSampatti covers:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...nzLim.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text('${n.$1}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Expanded(child: Text(n.$2, style: const TextStyle(fontSize: 12, color: Colors.black54))),
          ]),
        )),
        const SizedBox(height: 8),
        const Text('Missing from DigiSampatti (building next):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        ...[
          'Stormwater / sewer connection certificate',
          'Outstanding BBMP enforcement notices',
          'Valuation comparison (guidance vs market)',
        ].map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 14),
            const SizedBox(width: 8),
            Text(m, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        )),
      ],
    );
  }

  // ─── Sweden: Digital Future of India Property ────────────────────────────
  Widget _buildSwedenLesson() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _compareRow('Sweden (Today)', 'India (Moving toward)', [
          ('BankID = digital identity, sign everything online', 'Aadhaar + OTP = digital identity, e-sign growing'),
          ('Lantmäteriet = instant online title search, ₹300', 'Bhoomi = online but manual form filling'),
          ('Title transfer = 100% digital, 1-2 weeks', 'Sub-Registrar office = physical presence mandatory'),
          ('No paper documents needed anywhere', 'Still requires physical stamp paper + presence'),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'India is moving toward digital registration. Already available:\n'
            '• DigiLocker — store and share property documents digitally\n'
            '• Aadhaar e-sign — sign documents without physical presence\n'
            '• CERSAI — fully digital mortgage registry\n'
            '• Kaveri Online — EC available online\n\n'
            'Coming soon: Full digital registration without visiting Sub-Registrar office.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ─── South Africa: AML / Tax Check ───────────────────────────────────────
  Widget _buildSaCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'South Africa\'s FICA: Every property transaction requires identity '
            'verification and source-of-funds proof. India\'s Income Tax Act has similar '
            'but buyers are often unaware of their obligations.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        _checkStep('IT Rule', 'TDS on property purchase above ₹50 lakh',
            'Buyer must deduct 1% TDS (26QB) from purchase price and pay to govt. '
            'If not done, buyer faces penalty + interest. NRI seller = 22.88% TDS.'),
        _checkStep('IT Rule', 'Report property purchase in ITR',
            'Property above ₹30 lakh must be reported in Schedule AL (Assets-Liabilities) '
            'of your Income Tax Return. Both buyer and seller.'),
        _checkStep('PMLA', 'Property > ₹50 lakh = AML reporting',
            'Real estate agents and builders must report transactions > ₹50 lakh '
            'to Financial Intelligence Unit (FIU-IND) under PMLA 2002.'),
        _checkStep('GST', 'GST on under-construction property',
            '5% GST on under-construction property (1% for affordable housing). '
            'Completed/ready-to-move = NO GST. Know before paying.'),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://www.incometax.gov.in/iec/foportal');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.receipt_long, size: 14),
            label: const Text('File TDS (26QB) on Income Tax Portal →'),
          ),
        ),
      ],
    );
  }

  // ─── Italy: Building Plan vs Actual ──────────────────────────────────────
  Widget _buildItalyCheck() {
    const checks = [
      ('Plan check', 'Get sanctioned building plan from BBMP/BDA. Compare with actual structure.',
       'Any extra floor, extra room, extended balcony = violation.'),
      ('Completion Certificate', 'Has BBMP issued Occupancy Certificate (OC)?',
       'No OC = building is not officially complete. Banks won\'t give loan.'),
      ('Deviation list', 'Ask builder/owner for list of deviations (if any)',
       'Minor deviations can be regularised by paying penalty. Major = demolition.'),
      ('Plan date', 'When was plan sanctioned? Has it expired?',
       'Building plans expire in 3-5 years. Construction must finish within validity.'),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Italy: A sale is legally VOID if the property doesn\'t match the approved plan. '
            'Karnataka BBMP has similar powers — can issue demolition notice for unauthorized '
            'construction. In Bengaluru, thousands of buildings have violations.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...checks.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('▸ ${c.$1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(c.$2, style: const TextStyle(fontSize: 12, height: 1.3)),
            Text(c.$3, style: const TextStyle(fontSize: 11, color: Colors.red, height: 1.3)),
          ]),
        )),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://bbmpeaasthi.karnataka.gov.in');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_browser, size: 14),
            label: const Text('Check BBMP building plan approval →'),
          ),
        ),
      ],
    );
  }

  // ─── Canada: Title Insurance ──────────────────────────────────────────────
  Widget _buildCanadaCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Canada: 95%+ of residential buyers get title insurance. '
            'If ANY defect in title is found after purchase, insurer pays. '
            'India: Title insurance exists but almost nobody buys it. '
            'DigiSampatti reduces the risk — title insurance covers the residual.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Title Insurance in India — Available from:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...[
          ('HDFC Ergo', 'Home loan protection + title cover', 'https://www.hdfcergo.com'),
          ('Bajaj Allianz', 'Property insurance with title cover', 'https://www.bajajallianz.com'),
          ('New India Assurance', 'Government insurer — title protection', 'https://www.newindia.co.in'),
          ('ICICI Lombard', 'Comprehensive property cover', 'https://www.icicilombard.com'),
        ].map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(i.$3);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.shield, color: Color(0xFF4527A0), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(i.$2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
                const Icon(Icons.open_in_new, color: Color(0xFF4527A0), size: 14),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 8),
        const Text(
          'Typical cost: ₹3,000–15,000 one-time premium for ₹50L property. '
          'Covers: forged documents, hidden owners, survey errors, '
          'court decrees against previous owners.',
          style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }

  // ─── Compare row helper ────────────────────────────────────────────────────
  Widget _compareRow(String colA, String colB, List<(String, String)> rows) {
    return Column(children: [
      Row(children: [
        Expanded(child: Container(
          padding: const EdgeInsets.all(6),
          color: Colors.grey.shade100,
          child: Text(colA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        )),
        const SizedBox(width: 4),
        Expanded(child: Container(
          padding: const EdgeInsets.all(6),
          color: AppColors.primary.withOpacity(0.1),
          child: Text(colB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
              color: AppColors.primary)),
        )),
      ]),
      ...rows.map((r) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Text(r.$1, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
        )),
        const SizedBox(width: 4),
        Expanded(child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Text(r.$2, style: const TextStyle(fontSize: 11, height: 1.3)),
        )),
      ])),
    ]);
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
