import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class TotalCostScreen extends StatefulWidget {
  const TotalCostScreen({super.key});

  @override
  State<TotalCostScreen> createState() => _TotalCostScreenState();
}

class _TotalCostScreenState extends State<TotalCostScreen> {
  final _priceController = TextEditingController();
  String _ownerType = 'Male';
  bool _needsInterior = false;
  bool _needsAdvocate = true;
  bool _isCalculated = false;

  double get _price => double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;

  double get _stampDutyRate {
    if (_price <= 2000000) return _ownerType == 'Woman' ? 0.03 : 0.05;
    if (_price <= 4500000) return _ownerType == 'Woman' ? 0.04 : 0.056;
    return _ownerType == 'Woman' ? 0.05 : 0.056;
  }

  double get _stampDuty => _price * _stampDutyRate;
  double get _registration => _price * 0.01;
  double get _advocateFee => _needsAdvocate ? (_price < 3000000 ? 10000 : 20000) : 0;
  double get _interiorCost => _needsInterior ? (_price * 0.1).clamp(200000, 2000000) : 0;
  double get _miscCharges => 5000; // franking, notary, etc.
  double get _totalCost => _price + _stampDuty + _registration + _advocateFee + _interiorCost + _miscCharges;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Total Cost Calculator')),
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
                Expanded(child: Text('Most buyers are surprised by the true cost. This shows the complete picture.',
                  style: TextStyle(fontSize: 12, color: AppColors.primary))),
              ]),
            ),
            const SizedBox(height: 20),

            const Text('Property Price (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 5000000', prefixText: '₹ '),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 16),

            const Text('Buyer Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Woman', 'Joint'].map((t) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _ownerType = t; _isCalculated = false; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _ownerType == t ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ownerType == t ? AppColors.primary : AppColors.borderColor),
                      ),
                      child: Text(t, textAlign: TextAlign.center, style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: _ownerType == t ? Colors.white : AppColors.textDark,
                      )),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Include Additional Costs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            _Switch('Advocate / Legal Fees (₹10,000–₹20,000)', _needsAdvocate,
              (v) => setState(() { _needsAdvocate = v; _isCalculated = false; })),
            _Switch('Interior / Renovation (~10% of price)', _needsInterior,
              (v) => setState(() { _needsInterior = v; _isCalculated = false; })),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () { if (_price > 0) setState(() => _isCalculated = true); },
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Total Cost'),
            ),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              _buildBreakdown(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown() {
    final items = [
      ('Property Price', _price, AppColors.primary),
      ('Stamp Duty (${(_stampDutyRate * 100).toStringAsFixed(1)}%)', _stampDuty, AppColors.warning),
      ('Registration (1%)', _registration, AppColors.warning),
      if (_needsAdvocate) ('Advocate Fees', _advocateFee, AppColors.info),
      ('Misc (franking, notary)', _miscCharges, AppColors.textMedium),
      if (_needsInterior) ('Interior / Renovation', _interiorCost, AppColors.violet),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('Total Money Needed', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text('₹${_fmt(_totalCost)}',
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
              if (_ownerType == 'Woman') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Woman concession applied ✓', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cost Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(height: 16),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 13))),
                      Text('₹${_fmt(item.$2)}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: item.$3)),
                    ],
                  ),
                )),
                const Divider(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Text('₹${_fmt(_totalCost)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}

class _Switch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
