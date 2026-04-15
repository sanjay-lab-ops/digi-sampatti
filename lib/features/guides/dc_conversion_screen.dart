import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class DcConversionScreen extends StatefulWidget {
  const DcConversionScreen({super.key});

  @override
  State<DcConversionScreen> createState() => _DcConversionScreenState();
}

class _DcConversionScreenState extends State<DcConversionScreen> {
  String _activeType = 'Residential';

  static const _types = ['Residential', 'Commercial', 'Industrial', 'Joint Dev'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('DC Conversion Guide')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conversion Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeType = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeType == t ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _activeType == t ? AppColors.primary : AppColors.borderColor),
                          ),
                          child: Text(t, style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            color: _activeType == t ? Colors.white : AppColors.textDark,
                          )),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeType == 'Joint Dev'
              ? _buildJDA()
              : _buildConversionGuide(_activeType),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionGuide(String type) {
    final info = _getInfo(type);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agricultural → $type Conversion', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
              const SizedBox(height: 6),
              Text(info['description']!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Step-by-Step Process', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...List<Widget>.from((info['steps'] as List<String>).asMap().entries.map((e) =>
          _StepCard('${e.key + 1}', e.value)
        )),

        const SizedBox(height: 16),
        const Text('Documents Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
          child: Column(
            children: (info['docs'] as List<String>).map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(d, style: const TextStyle(fontSize: 13))),
              ]),
            )).toList(),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.statusWarningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.access_time, size: 16, color: AppColors.warning),
                SizedBox(width: 6),
                Text('Time & Cost', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(info['timeline']!, style: const TextStyle(fontSize: 12, color: AppColors.warning, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildJDA() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.violet.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.violet.withOpacity(0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Joint Development Agreement (JDA)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.violet, fontSize: 14)),
              SizedBox(height: 6),
              Text('Landowner gives land to builder. Builder constructs. They share flats or revenue. Very common in Bengaluru. High risk for flat buyers if not done legally.',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('What Buyer Must Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...[
          ('JDA is registered at Sub-Registrar office', true),
          ('Power of Attorney given to builder is registered', true),
          ('Land title still in original owner\'s name — check EC', true),
          ('RERA registration shows JDA details', true),
          ('Builder share of flats is clearly defined', true),
          ('No dispute between landowner and builder', true),
          ('Bank approved the JDA project for home loans', true),
          ('Khata is in original landowner\'s name', true),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.$2 ? AppColors.danger.withOpacity(0.3) : AppColors.borderColor),
            ),
            child: Row(children: [
              Icon(item.$2 ? Icons.priority_high : Icons.check, size: 16, color: item.$2 ? AppColors.danger : AppColors.safe),
              const SizedBox(width: 8),
              Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 13))),
            ]),
          ),
        )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withOpacity(0.2))),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.report_problem, size: 16, color: AppColors.danger),
                SizedBox(width: 6),
                Text('Biggest JDA Risk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13)),
              ]),
              SizedBox(height: 8),
              Text('If landowner and builder dispute — court can freeze the project. Your flat is stuck for years. Always verify JDA is registered AND builder has given performance guarantee to landowner.',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Map<String, dynamic> _getInfo(String type) {
    switch (type) {
      case 'Residential':
        return {
          'description': 'Most plots sold as "residential" in Karnataka were originally agricultural land. DC Conversion is the official government order changing land use from agricultural to residential. Without it, BBMP/BDA will not give building plan approval.',
          'steps': [
            'Visit Tahsildar office with land documents. Get Form 1 (application for conversion)',
            'Submit: RTC, Sale Deed, Sketch, Aadhar, Property Tax receipts, Survey map',
            'Tahsildar sends notice to Village Accountant for inspection and report',
            'DC (Deputy Commissioner) office reviews and issues Conversion Order (Form 9)',
            'Pay conversion fee: ₹2–₹5 per sq ft depending on zone and district',
            'Submit Conversion Order to BBMP/BDA for building plan approval',
            'Apply for Khata in new (non-agricultural) category',
          ],
          'docs': [
            'Original RTC (Form 9) and Pahani',
            'Sale Deed / Title Deed',
            'Aadhar of applicant',
            'Property tax paid receipt',
            'Land survey sketch (Form 53)',
            'NOC from irrigation department (if near canal)',
            'Passport photo of applicant',
          ],
          'timeline': 'Time: 3–6 months. Fee: ₹2–₹5 per sq ft. Hire a document agent (₹5,000–₹15,000) to follow up. Ensure the Conversion Order mentions "Residential" specifically — not just "Non-Agricultural".',
        };
      case 'Commercial':
        return {
          'description': 'Converting agricultural land for shops, offices, hotels, or commercial complexes. Requires DC approval + Town and Country Planning (TCP) approval. Higher fees than residential.',
          'steps': [
            'Apply to DC office with commercial purpose clearly stated',
            'TCP (Town Planning) department inspection and NOC required',
            'Gram Panchayat or BBMP NOC depending on location',
            'Environmental clearance if above 20,000 sq ft',
            'DC issues Commercial Conversion Order',
            'BBMP/BDA commercial building plan approval',
            'Fire NOC, lift NOC for multi-floor commercial',
          ],
          'docs': [
            'All residential conversion documents plus:',
            'TCP department application form',
            'Business plan / intended use declaration',
            'NOC from neighbors (in some cases)',
            'Environmental impact statement (for large projects)',
          ],
          'timeline': 'Time: 6–12 months. Fee: ₹10–₹20 per sq ft. Commercial conversion is strictly zone-dependent — agricultural land near highways or industrial areas is easier to convert commercially.',
        };
      case 'Industrial':
        return {
          'description': 'For factories, warehouses, IT parks. Handled by KIADB (Karnataka Industrial Areas Development Board) or DC depending on size. Separate industrial zone approval needed.',
          'steps': [
            'Check if land falls in KIADB notified industrial area or not',
            'If KIADB area: apply directly to KIADB for plot allotment',
            'If non-KIADB: apply to DC + Department of Industries and Commerce',
            'Factory plan approval from Directorate of Factories',
            'Pollution Control Board NOC (mandatory for manufacturing)',
            'Power connection from BESCOM for industrial use',
            'Labour department registration after setup',
          ],
          'docs': [
            'All standard conversion documents plus:',
            'Industry type declaration and project report',
            'NOC from Pollution Control Board',
            'KIADB allotment letter (if applicable)',
            'Power requirement certificate from BESCOM',
          ],
          'timeline': 'Time: 6–18 months. KIADB industrial plots are faster. Non-KIADB conversion is complex and often refused near residential zones. Hire an industrial consultant (₹25,000–₹50,000) for this process.',
        };
      default:
        return {'description': '', 'steps': [], 'docs': [], 'timeline': ''};
    }
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String text;
  const _StepCard(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderColor)),
              child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
