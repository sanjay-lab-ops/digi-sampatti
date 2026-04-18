import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _openIndex;
  String _search = '';

  static const _faqs = [
    _Faq('What is Arth ID?',
      'Arth ID is a Karnataka property verification app. It checks land records from Bhoomi portal, runs AI risk analysis, and gives you a legal report before you buy any property.',
      'General'),
    _Faq('Where does the data come from?',
      'Arth ID opens the official Karnataka government portals — Bhoomi, Kaveri, RERA, eCourts, CERSAI — directly inside the app. You see the real government data. The AI risk analysis and legal report are generated from that official data.',
      'General'),
    _Faq('What is RTC and why does it matter?',
      'RTC (Record of Rights, Tenancy and Crops) is the main land ownership document from Karnataka\'s Bhoomi portal. It shows owner name, land type, area, and khata number. Always verify RTC before buying any land.',
      'Land Records'),
    _Faq('What is the difference between A Khata and B Khata?',
      'A Khata = fully legal property, bank loans available, can sell freely. B Khata = property has legal irregularities (revenue site, unapproved construction). Banks won\'t give loans on B Khata. Always insist on A Khata.',
      'Land Records'),
    _Faq('What is EC (Encumbrance Certificate)?',
      'EC is a document listing all transactions on a property — loans, mortgages, sale deeds. Get EC for the last 30 years before buying. A clean EC means no pending loans or claims on the property.',
      'Land Records'),
    _Faq('What is DC Conversion?',
      'DC Conversion is the official government order changing agricultural land to residential/commercial use. Without DC conversion, building on agricultural land is illegal and BBMP will not give building plan approval.',
      'Land Records'),
    _Faq('What is stamp duty in Karnataka?',
      'Stamp duty is a tax paid to Karnataka government when buying property. Rate: 5%–5.6% for men, 3%–5% for women, based on property value. Plus 1% registration charge. Use our Stamp Duty Calculator for exact amounts.',
      'Payments'),
    _Faq('Can women buyers save on stamp duty?',
      'Yes. Karnataka gives women buyers a concession: 3% for properties up to ₹20L, 4% for ₹20L–₹45L, 5% above ₹45L. Men pay 5%–5.6%. Registering in wife\'s name or joint (wife first) saves money.',
      'Payments'),
    _Faq('What is RERA and do I need to check it?',
      'RERA is Karnataka\'s real estate regulator. All residential projects above 500 sq m must be registered. Check on rera.karnataka.gov.in before booking any flat or villa. No RERA = no legal protection.',
      'Apartments'),
    _Faq('What is OC (Occupancy Certificate)?',
      'OC is issued by BBMP/BDA after verifying that construction is complete and safe to occupy. Without OC, the building is technically illegal. Banks need OC for home loans on resale flats.',
      'Apartments'),
    _Faq('What is UDS in apartments?',
      'Undivided Share of Land — your share of the land in an apartment complex. Formula: (Your flat area ÷ Total building area) × Total land area. Higher UDS = more land value. Always check UDS before booking.',
      'Apartments'),
    _Faq('Which authority approves layouts in Bengaluru?',
      'BBMP for city areas. BDA for planned layouts. BMRDA for areas within 40km of Bengaluru (Devanahalli, Ramanagara, Doddaballapur). BIAAPA for airport corridor. CMC/TMC for smaller towns. Always check which authority has jurisdiction.',
      'Authorities'),
    _Faq('What is mutation and when should I do it?',
      'Mutation is updating government records (RTC and Khata) in your name after purchase. Do Bhoomi mutation first, then Khata transfer. Must be done within 3 months of registration. Without mutation, legally you are not the owner in records.',
      'Transfer'),
    _Faq('How long does property registration take?',
      'The registration itself takes 2–4 hours at SRO on the day. But preparation takes time: booking appointment (1–2 days), paying stamp duty (1 day), printing deed on stamp paper (1 day). Book online at kaveri2.karnataka.gov.in.',
      'Transfer'),
    _Faq('What is a revenue site and is it safe to buy?',
      'Revenue site is a plot developed on agricultural land without DC conversion or BDA/BBMP approval. Banks won\'t give home loans on revenue sites. Very risky — BBMP can demolish structures. Avoid unless DC conversion is done.',
      'Red Flags'),
    _Faq('How much home loan can I get?',
      'Banks give maximum 80% of property value as loan (LTV ratio). Your EMI cannot exceed 50% of net salary (FOIR). Use our Home Loan Eligibility calculator for exact amount. CIBIL score above 750 gets best rates.',
      'Finance'),
    _Faq('What is CIBIL score and how to check it?',
      'CIBIL score (300–900) shows your credit history. Above 750 = best loan rates. Below 650 = loan rejection risk. Check free on Paytm, PhonePe, or CIBIL app. Takes 30 seconds.',
      'Finance'),
    _Faq('What is a JDA (Joint Development Agreement)?',
      'JDA is when a landowner gives land to a builder, who constructs and shares flats/revenue. Very common in Bengaluru. Risk: if landowner and builder dispute, your flat is stuck. Always verify JDA is registered at Sub-Registrar office.',
      'Legal'),
    _Faq('Can NRIs buy property in Karnataka?',
      'Yes, NRIs (Non-Resident Indians) can buy residential and commercial property in India. Cannot buy agricultural land. Need registered Power of Attorney if not present for registration. Special TDS rules apply on resale.',
      'Legal'),
    _Faq('What happens if I buy a property with legal issues?',
      'If title is disputed, court can cancel your ownership even after paying full amount. If revenue site, BBMP can demolish. If fake EC, bank\'s claim remains. Always verify with Arth ID before paying any advance.',
      'Red Flags'),
  ];

  List<_Faq> get _filtered {
    if (_search.isEmpty) return _faqs;
    final q = _search.toLowerCase();
    return _faqs.where((f) =>
      f.question.toLowerCase().contains(q) ||
      f.answer.toLowerCase().contains(q) ||
      f.category.toLowerCase().contains(q)
    ).toList();
  }

  static final _catColors = {
    'General': AppColors.primary,
    'Land Records': AppColors.violet,
    'Payments': AppColors.safe,
    'Apartments': AppColors.info,
    'Authorities': const Color(0xFFB45309),
    'Transfer': AppColors.warning,
    'Red Flags': AppColors.danger,
    'Finance': AppColors.primary,
    'Legal': AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('FAQ')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() { _search = v; _openIndex = null; }),
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('${filtered.length} questions', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final faq = filtered[i];
                final isOpen = _openIndex == i;
                final color = _catColors[faq.category] ?? AppColors.primary;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isOpen ? color.withOpacity(0.3) : AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _openIndex = isOpen ? null : i),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(faq.category, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(faq.question,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                                  color: isOpen ? color : AppColors.textDark))),
                              Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                                color: isOpen ? color : AppColors.textLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (isOpen)
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: color.withOpacity(0.15))),
                          ),
                          child: Text(faq.answer,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.6)),
                        ),
                    ],
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

class _Faq {
  final String question;
  final String answer;
  final String category;
  const _Faq(this.question, this.answer, this.category);
}
