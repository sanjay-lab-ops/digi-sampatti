import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class PropertyTaxScreen extends StatefulWidget {
  const PropertyTaxScreen({super.key});

  @override
  State<PropertyTaxScreen> createState() => _PropertyTaxScreenState();
}

class _PropertyTaxScreenState extends State<PropertyTaxScreen> {
  final _areaController = TextEditingController();
  String _zone = 'A';
  String _usage = 'Residential';
  bool _isCalculated = false;

  // BBMP property tax rates per sq ft per year (approximate 2024-25)
  static const _rates = {
    'A': {'Residential': 5.0, 'Commercial': 10.0},
    'B': {'Residential': 4.0, 'Commercial': 8.0},
    'C': {'Residential': 3.5, 'Commercial': 7.0},
    'D': {'Residential': 3.0, 'Commercial': 6.0},
    'E': {'Residential': 2.0, 'Commercial': 4.0},
    'F': {'Residential': 1.5, 'Commercial': 3.0},
  };

  double get _area => double.tryParse(_areaController.text.replaceAll(',', '')) ?? 0;
  double get _ratePerSqft => _rates[_zone]?[_usage] ?? 3.0;
  double get _annualTax => _area * _ratePerSqft;
  double get _halfYearlyTax => _annualTax / 2;
  double get _monthlyEquivalent => _annualTax / 12;

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Property Tax Estimator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceGreen, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('BBMP property tax 2024-25. Rates vary by zone (A=prime areas, F=outskirts).',
                  style: TextStyle(fontSize: 12, color: AppColors.primary))),
              ]),
            ),
            const SizedBox(height: 20),

            const Text('Built-up Area (sq ft)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 1200', suffixText: 'sq ft'),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 16),

            const Text('BBMP Zone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('A=Indiranagar/Koramangala  B=JP Nagar  C=Whitefield  D=Marathahalli  E=Yelahanka  F=Outer areas',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['A', 'B', 'C', 'D', 'E', 'F'].map((z) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _zone = z; _isCalculated = false; }),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _zone == z ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _zone == z ? AppColors.primary : AppColors.borderColor),
                      ),
                      child: Center(child: Text('Zone $z', textAlign: TextAlign.center, style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 11,
                        color: _zone == z ? Colors.white : AppColors.textDark,
                      ))),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Property Usage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: ['Residential', 'Commercial'].map((u) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _usage = u; _isCalculated = false; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _usage == u ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _usage == u ? AppColors.primary : AppColors.borderColor),
                      ),
                      child: Text(u, textAlign: TextAlign.center, style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: _usage == u ? Colors.white : AppColors.textDark,
                      )),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () { if (_area > 0) setState(() => _isCalculated = true); },
              icon: const Icon(Icons.calculate),
              label: const Text('Estimate Property Tax'),
            ),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Text('Annual Property Tax', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('₹${_annualTax.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TaxItem('Half-yearly\n(BBMP bill)', '₹${_halfYearlyTax.toStringAsFixed(0)}'),
                        _TaxItem('Monthly\nequivalent', '₹${_monthlyEquivalent.toStringAsFixed(0)}'),
                        _TaxItem('Rate\n(₹/sqft/yr)', '₹${_ratePerSqft.toStringAsFixed(1)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Important Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Divider(height: 16),
                      _Note('BBMP sends bills twice a year — pay by April 30 and Oct 31'),
                      _Note('5% rebate for paying full year before April 30'),
                      _Note('2% surcharge per month if delayed'),
                      _Note('Women property owners get 10% rebate in some zones'),
                      _Note('Verify exact amount on bbmp.gov.in before paying'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TaxItem extends StatelessWidget {
  final String label;
  final String value;
  const _TaxItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
  ]);
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.circle, size: 6, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
    ]),
  );
}
