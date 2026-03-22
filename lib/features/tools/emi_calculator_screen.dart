import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _loanController = TextEditingController();
  double _interestRate = 8.5;
  double _tenureYears = 20;
  bool _isCalculated = false;

  double get _loanAmount => double.tryParse(_loanController.text.replaceAll(',', '')) ?? 0;

  double get _emi {
    if (_loanAmount <= 0) return 0;
    final r = _interestRate / 12 / 100;
    final n = _tenureYears * 12;
    return _loanAmount * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  double get _totalPayment => _emi * _tenureYears * 12;
  double get _totalInterest => _totalPayment - _loanAmount;

  @override
  void dispose() {
    _loanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('EMI Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Amount
            const Text('Loan Amount (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loanController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 5000000', prefixText: '₹ '),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 20),

            // Interest Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Interest Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${_interestRate.toStringAsFixed(1)}% per year',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _interestRate,
              min: 6.0, max: 15.0, divisions: 90,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() { _interestRate = double.parse(v.toStringAsFixed(1)); _isCalculated = false; }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('6%', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                Text('Common: SBI 8.5% | HDFC 8.7% | ICICI 8.75%',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                Text('15%', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 20),

            // Tenure
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Loan Tenure', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${_tenureYears.toInt()} years',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _tenureYears,
              min: 1, max: 30, divisions: 29,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() { _tenureYears = v.roundToDouble(); _isCalculated = false; }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('1 yr', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                Text('30 yrs', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                if (_loanAmount > 0) setState(() => _isCalculated = true);
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate EMI'),
            ),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              _buildResult(),
              const SizedBox(height: 16),
              _buildBankRates(),
            ],

            const SizedBox(height: 20),
            _buildTip(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Monthly EMI', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text('₹${_formatAmount(_emi)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Item('Loan\nAmount', '₹${_formatAmount(_loanAmount)}'),
              _Item('Total\nInterest', '₹${_formatAmount(_totalInterest)}'),
              _Item('Total\nPayment', '₹${_formatAmount(_totalPayment)}'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _loanAmount / _totalPayment,
            backgroundColor: Colors.white24,
            color: AppColors.safe,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Principal ${((_loanAmount / _totalPayment) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text('Interest ${((_totalInterest / _totalPayment) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankRates() {
    const banks = [
      ('SBI Home Loan', '8.50%', '₹868/L'),
      ('HDFC Bank', '8.70%', '₹878/L'),
      ('ICICI Bank', '8.75%', '₹881/L'),
      ('Axis Bank', '8.75%', '₹881/L'),
      ('Canara Bank', '8.55%', '₹870/L'),
      ('Bank of Baroda', '8.40%', '₹862/L'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Bank Rates (2024-25)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('EMI per ₹1 Lakh loan for 20 years', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const Divider(height: 16),
            ...banks.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(b.$1, style: const TextStyle(fontSize: 13))),
                  Text(b.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  Text(b.$3, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Smart Tips', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
          ]),
          SizedBox(height: 8),
          Text('• EMI should not exceed 40% of your monthly income\n• Women co-applicants get 0.05% lower rate at most banks\n• Pre-payment reduces total interest significantly\n• Fixed rate is safer if rates are expected to rise',
            style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.5)),
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

class _Item extends StatelessWidget {
  final String label;
  final String value;
  const _Item(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}
