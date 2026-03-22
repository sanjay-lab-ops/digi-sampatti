import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class LegalGlossaryScreen extends StatefulWidget {
  const LegalGlossaryScreen({super.key});

  @override
  State<LegalGlossaryScreen> createState() => _LegalGlossaryScreenState();
}

class _LegalGlossaryScreenState extends State<LegalGlossaryScreen> {
  String _search = '';

  static const _terms = [
    _Term('RTC', 'Record of Rights, Tenancy and Crops', 'Form 9 — the main land ownership document from Bhoomi portal. Shows owner name, land area, type (wet/dry), khata number. First document to check for any land.', 'Land Records'),
    _Term('EC', 'Encumbrance Certificate', 'Lists all transactions on a property — loans, mortgages, sale deeds, gifts. Get last 30 years EC before buying. A clear EC = no pending loans or claims.', 'Legal'),
    _Term('Khata', 'Property Account', 'Municipal record in your name for property tax. Two types: A Khata (fully legal, bank loan possible) and B Khata (irregularities, banks won\'t give loan).', 'Municipal'),
    _Term('A Khata', 'Regular Khata', 'Property is fully legal, within approved plan, DC converted. Banks give home loans. Can sell freely. This is what you want.', 'Municipal'),
    _Term('B Khata', 'Provisional Khata', 'Property has some illegality — revenue site, unapproved construction, non-converted agricultural land. Banks won\'t give loans. Risky to buy.', 'Municipal'),
    _Term('UDS', 'Undivided Share of Land', 'Your share of the total land in an apartment complex. E.g., 1000 sq ft flat in 20,000 sq ft building on 5,000 sq ft land = 250 sq ft UDS. Higher is better.', 'Apartment'),
    _Term('OC', 'Occupancy Certificate', 'BBMP/BDA certificate that building is safe to occupy and built as per plan. Mandatory for getting water, electricity connection legally. No OC = illegal building.', 'Apartment'),
    _Term('CC', 'Completion Certificate', 'Confirms building is built as per approved plan. Issued before OC. Both CC and OC required for a fully legal building.', 'Apartment'),
    _Term('RERA', 'Real Estate Regulatory Authority', 'Karnataka\'s real estate regulator. All residential projects above 500 sq m must register. Protects buyers from delays and cheating.', 'Apartment'),
    _Term('Sale Deed', 'Registered Sale Deed', 'Final ownership transfer document. Executed and registered at Sub-Registrar office. After registration, you are the legal owner. Most important document.', 'Legal'),
    _Term('Mother Deed', 'Parent Title Deed', 'The oldest sale deed showing original ownership. Establishes complete chain of ownership from beginning. Essential for title verification.', 'Legal'),
    _Term('DC Conversion', 'Deputy Commissioner Conversion', 'Government order changing land use from agricultural to non-agricultural (residential/commercial/industrial). Mandatory before constructing on agricultural land.', 'Land'),
    _Term('Revenue Site', 'Revenue Layout', 'Plot developed on agricultural land without DC conversion or BDA/BBMP approval. Banks won\'t give loans. Legally risky. Very common in Bengaluru outskirts.', 'Land'),
    _Term('Mutation', 'Name Transfer in Records', 'Updating government records (RTC/Khata) in new owner\'s name after sale. Two types: Bhoomi mutation (RTC) and Khata mutation (BBMP/Panchayat). Must be done after registration.', 'Transfer'),
    _Term('SRO', 'Sub-Registrar Office', 'Government office where property documents are registered. Every district has multiple SROs based on area. Registration must happen at SRO having jurisdiction over property location.', 'Transfer'),
    _Term('Stamp Duty', 'State Tax on Property Transfer', 'Tax paid to Karnataka government on property purchase. Rate: 3%–5.6% depending on value and buyer gender. Paid before registration. Without payment, deed cannot be registered.', 'Tax'),
    _Term('JDA', 'Joint Development Agreement', 'Contract between landowner and builder. Landowner provides land, builder constructs, they share flats or revenue. Registered JDA is legal. Unregistered JDA is risky for buyers.', 'Legal'),
    _Term('POA', 'Power of Attorney', 'Legal document authorizing someone else to act on your behalf. If seller gives registered POA to another person, that person can sign sale deed. Common for NRIs.', 'Legal'),
    _Term('Bhoomi', 'Karnataka Land Records Portal', 'bhoomi.karnataka.gov.in — official Karnataka government portal for RTC, mutation, land records. All land data is here. Free to use.', 'Portal'),
    _Term('Kaveri', 'Document Registration Portal', 'kaveri2.karnataka.gov.in — for booking SRO appointments, checking EC online, downloading registered documents. Free to use.', 'Portal'),
    _Term('BDA', 'Bangalore Development Authority', 'Plans and develops layouts in Bengaluru. BDA approved layouts are legal and bank loanable. BDA also acquires land for roads and projects.', 'Authority'),
    _Term('BBMP', 'Bruhat Bengaluru Mahanagara Palike', 'Bengaluru city municipal corporation. Issues Khata, OC, building plan approvals, and collects property tax within BBMP limits.', 'Authority'),
    _Term('KIADB', 'Karnataka Industrial Areas Development Board', 'Develops and allots industrial land in Karnataka. KIADB plots are pre-approved for industrial use. Faster than DC conversion for industrial purpose.', 'Authority'),
    _Term('Guideline Value', 'Government Guidance Value', 'Minimum price per sq ft set by Karnataka government for each area. Stamp duty is calculated on guideline value or actual price — whichever is higher.', 'Tax'),
    _Term('FTL', 'Full Tank Level', 'Water level boundary of lakes. No construction allowed within FTL boundary. BBMP and BDA map shows FTL boundaries. Very common issue in Bengaluru lake-adjacent areas.', 'Restriction'),
    _Term('Raja Kaluve', 'Storm Water Drain', 'Government storm drain network. No construction allowed within 30 ft (primary) or 15 ft (secondary) buffer. Many illegal buildings exist on Raja Kaluve buffer.', 'Restriction'),
  ];

  List<_Term> get _filtered {
    if (_search.isEmpty) return _terms;
    final q = _search.toLowerCase();
    return _terms.where((t) =>
      t.short.toLowerCase().contains(q) ||
      t.full.toLowerCase().contains(q) ||
      t.description.toLowerCase().contains(q)
    ).toList();
  }

  static const _categoryColors = {
    'Land Records': AppColors.primary,
    'Legal': Color(0xFF7C3AED),
    'Municipal': AppColors.info,
    'Apartment': AppColors.safe,
    'Land': Color(0xFFB45309),
    'Transfer': AppColors.warning,
    'Tax': AppColors.danger,
    'Portal': AppColors.primary,
    'Authority': AppColors.info,
    'Restriction': AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Legal Glossary')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search terms — RTC, EC, Khata, OC...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final t = filtered[i];
                final color = _categoryColors[t.category] ?? AppColors.primary;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t.short, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.full, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(t.category, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(t.description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
                      ],
                    ),
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

class _Term {
  final String short;
  final String full;
  final String description;
  final String category;
  const _Term(this.short, this.full, this.description, this.category);
}
