import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class ApartmentGuideScreen extends StatefulWidget {
  const ApartmentGuideScreen({super.key});

  @override
  State<ApartmentGuideScreen> createState() => _ApartmentGuideScreenState();
}

class _ApartmentGuideScreenState extends State<ApartmentGuideScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Apartment Buyer Guide')),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('RERA', 0),
                  _buildTab('OC / CC', 1),
                  _buildTab('UDS', 2),
                  _buildTab('Builder Check', 3),
                  _buildTab('Checklist', 4),
                ],
              ),
            ),
          ),
          Expanded(
            child: _activeTab == 0 ? _buildRERA()
              : _activeTab == 1 ? _buildOCCC()
              : _activeTab == 2 ? _buildUDS()
              : _activeTab == 3 ? _buildBuilderCheck()
              : _buildChecklist(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: _activeTab == index ? AppColors.primary : Colors.transparent,
            width: 2.5,
          )),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: _activeTab == index ? AppColors.primary : AppColors.textLight,
        )),
      ),
    );
  }

  Widget _buildRERA() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(AppColors.danger, Icons.warning_amber, 'Why RERA Matters',
          'Any residential project above 500 sq m or 8 units MUST be RERA registered. If not registered, builder cannot legally sell. Your money has no protection.'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.primary, Icons.search, 'How to Check RERA',
          'Visit rera.karnataka.gov.in → Search Projects → Enter project name or builder name → Verify registration number, completion date, and complaints.'),
        const SizedBox(height: 12),
        _SectionTitle('What to Verify in RERA'),
        _CheckItem('Project registration number is valid'),
        _CheckItem('Approved plan matches what builder shows you'),
        _CheckItem('Completion date mentioned in RERA'),
        _CheckItem('No pending complaints or penalties on builder'),
        _CheckItem('Escrow account details present'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.warning, Icons.report_problem, 'Red Flag',
          'Builder says "RERA applied, registration pending" — DO NOT pay more than 10% booking amount until RERA number is issued.'),
      ],
    );
  }

  Widget _buildOCCC() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(AppColors.danger, Icons.home, 'OC — Occupancy Certificate',
          'OC is issued by BBMP/BDA after construction is complete and inspected. Without OC, the building is technically illegal. Banks need OC for home loans.'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.primary, Icons.assignment, 'CC — Completion Certificate',
          'CC is issued by BBMP confirming building is built as per approved plan. Different from OC — both are required for a fully legal apartment.'),
        const SizedBox(height: 12),
        _SectionTitle('How to Verify OC'),
        _CheckItem('Ask builder for OC copy — must be original BBMP/BDA issued'),
        _CheckItem('Check date of OC — should be recent and match handover date'),
        _CheckItem('Verify on BBMP portal: bbmp.gov.in'),
        _CheckItem('Check that your floor and unit number appears in OC'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.warning, Icons.report_problem, 'Common Cheating',
          'Builder gives "OC Applied" letter instead of actual OC. This is not valid. Buying without OC means you cannot sell the flat in future without getting OC first — very expensive process.'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.safe, Icons.lightbulb_outline, 'Resale Apartments',
          'For resale flats, ask previous owner for OC copy. If they don\'t have it, visit BBMP ward office to get certified copy before buying.'),
      ],
    );
  }

  Widget _buildUDS() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(AppColors.primary, Icons.pie_chart, 'What is UDS?',
          'Undivided Share of Land (UDS) is the % of the total land that you own when you buy a flat. Land value appreciates — flat structure depreciates. UDS is your real asset.'),
        const SizedBox(height: 12),
        _SectionTitle('UDS Formula'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UDS = (Your flat area ÷ Total built-up area) × Total land area',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 12),
              const Text('Example:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('• Your flat: 1000 sq ft\n• Total building: 20,000 sq ft (20 flats × 1000)\n• Total land: 5,000 sq ft\n• Your UDS = (1000 ÷ 20,000) × 5,000 = 250 sq ft',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMedium)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(AppColors.warning, Icons.report_problem, 'What to Check',
          'UDS must be mentioned in your Sale Agreement and Sale Deed. A higher UDS = more land ownership = more value. Ask builder for exact UDS calculation sheet before booking.'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.safe, Icons.lightbulb_outline, 'Good UDS vs Bad UDS',
          'For a 1000 sq ft flat — UDS above 200 sq ft is good. Less than 100 sq ft means very high-density building with little land value. Compare UDS across projects before deciding.'),
      ],
    );
  }

  Widget _buildBuilderCheck() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Check These Before Trusting a Builder'),
        _CheckItem('RERA registration active on rera.karnataka.gov.in'),
        _CheckItem('Previous projects delivered on time (ask residents)'),
        _CheckItem('No RERA complaints or penalties filed'),
        _CheckItem('Company is registered — check MCA portal (mca.gov.in)'),
        _CheckItem('Land title is in builder\'s name (not JDA without disclosure)'),
        _CheckItem('Bank loans available — HDFC/SBI approved project'),
        _CheckItem('Building plan approved by BBMP/BDA — not "applied"'),
        const SizedBox(height: 16),
        _InfoCard(AppColors.danger, Icons.report_problem, 'Biggest Red Flags',
          '• Heavily discounted price vs market rate\n• "Limited time offer — pay today"\n• No RERA number\n• Land still in original owner\'s name\n• Refuses to show approved building plan'),
        const SizedBox(height: 12),
        _InfoCard(AppColors.primary, Icons.people, 'Talk to Existing Residents',
          'Best verification: visit builder\'s previous completed project. Ask residents about: delay, quality, OC received, Khata issued, lift/generator working. 30 minutes = saves lakhs.'),
      ],
    );
  }

  Widget _buildChecklist() {
    final Set<int> checked = {};
    final docs = [
      'RERA registration certificate',
      'Building plan approval from BBMP/BDA',
      'Land title deed in builder\'s name',
      'EC (Encumbrance Certificate) for the land',
      'Sale Agreement with UDS clearly mentioned',
      'Payment schedule linked to construction stages',
      'Khata in builder\'s name for the land',
      'No objection from existing landowner (if JDA)',
      'Bank approval letter (HDFC/SBI/ICICI)',
      'Estimated OC date mentioned in agreement',
      'Penalty clause for delay in handover',
      'Specification sheet (flooring, fittings, brands)',
      'Association formation clause',
      'Car parking allotment in writing',
      'Maintenance deposit amount and terms',
    ];

    return StatefulBuilder(
      builder: (context, setStateLocal) => Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: LinearProgressIndicator(
              value: checked.length / docs.length,
              backgroundColor: AppColors.borderColor,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final isChecked = checked.contains(i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isChecked ? AppColors.safe.withOpacity(0.4) : AppColors.borderColor),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    onChanged: (_) => setStateLocal(() {
                      if (isChecked) checked.remove(i); else checked.add(i);
                    }),
                    title: Text(docs[i], style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? AppColors.textLight : AppColors.textDark,
                    )),
                    activeColor: AppColors.safe,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard(this.color, this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.safe),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMedium))),
        ],
      ),
    );
  }
}
