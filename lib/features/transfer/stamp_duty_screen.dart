import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class StampDutyScreen extends StatefulWidget {
  const StampDutyScreen({super.key});

  @override
  State<StampDutyScreen> createState() => _StampDutyScreenState();
}

class _StampDutyScreenState extends State<StampDutyScreen> {
  final _valueController = TextEditingController();
  String _ownerType = 'Male';
  String _propertyType = 'Residential';
  bool _isCalculated = false;

  double get _propertyValue => double.tryParse(_valueController.text.replaceAll(',', '')) ?? 0;

  // Karnataka stamp duty rates 2024
  double get _stampDutyRate {
    if (_propertyValue <= 2000000) {
      return _ownerType == 'Woman' ? 0.03 : 0.05;
    } else if (_propertyValue <= 4500000) {
      return _ownerType == 'Woman' ? 0.04 : 0.056;
    } else {
      return _ownerType == 'Woman' ? 0.05 : 0.056;
    }
  }

  double get _stampDuty => _propertyValue * _stampDutyRate;
  double get _registrationCharge => _propertyValue * 0.01;
  double get _total => _stampDuty + _registrationCharge;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Stamp Duty Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Karnataka Stamp Duty rates 2024-25. Women get concession.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Property Value
            const Text('Property Value (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'e.g. 5000000',
                prefixText: '₹ ',
              ),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 16),

            // Owner Type
            const Text('Owner Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Woman', 'Joint'].map((type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _ownerType = type; _isCalculated = false; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _ownerType == type ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ownerType == type ? AppColors.primary : AppColors.borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(type, style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            color: _ownerType == type ? Colors.white : AppColors.textDark,
                          )),
                          if (type == 'Woman')
                            Text('Concession', style: TextStyle(
                              fontSize: 10,
                              color: _ownerType == type ? Colors.white70 : AppColors.safe,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                if (_propertyValue > 0) setState(() => _isCalculated = true);
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Stamp Duty'),
            ),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
              const SizedBox(height: 16),
              _buildRateCard(),
            ],
            const SizedBox(height: 20),
            _buildNoteCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Total Transfer Cost', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text('₹${_formatAmount(_total)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ResultItem('Stamp Duty\n(${(_stampDutyRate * 100).toStringAsFixed(1)}%)', '₹${_formatAmount(_stampDuty)}'),
              _ResultItem('Registration\n(1%)', '₹${_formatAmount(_registrationCharge)}'),
              _ResultItem('Property\nValue', '₹${_formatAmount(_propertyValue)}'),
            ],
          ),
          if (_ownerType == 'Woman') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Woman owner concession applied ✓', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateCard() {
    const rates = [
      ('Up to ₹20 Lakhs', 'Men: 5%', 'Women: 3%'),
      ('₹20L – ₹45L', 'Men: 5.6%', 'Women: 4%'),
      ('Above ₹45 Lakhs', 'Men: 5.6%', 'Women: 5%'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Karnataka Stamp Duty Rates 2024-25', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 16),
            ...rates.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
                  Text(r.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Text(r.$3, style: const TextStyle(fontSize: 12, color: AppColors.safe, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusWarningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Additional charges may apply: advocate fees (₹5,000-₹20,000), franking charges, and e-stamp paper. Verify exact rates at your Sub-Registrar office.',
              style: TextStyle(fontSize: 11, color: AppColors.warning, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)} L';
    return amount.toStringAsFixed(0);
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  const _ResultItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}
