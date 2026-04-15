import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/property_data_service.dart';

class LoanEligibilityScreen extends StatefulWidget {
  const LoanEligibilityScreen({super.key});

  @override
  State<LoanEligibilityScreen> createState() => _LoanEligibilityScreenState();
}

class _LoanEligibilityScreenState extends State<LoanEligibilityScreen> {
  final _salaryController = TextEditingController();
  final _existingEmiController = TextEditingController();
  double _interestRate = 8.5;
  double _tenureYears = 20;
  bool _isCalculated = false;
  bool _enquirySent = false;
  String _preferredBank = 'SBI';

  double get _salary => double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
  double get _existingEmi => double.tryParse(_existingEmiController.text.replaceAll(',', '')) ?? 0;

  // Banks allow max 50% of salary as total EMI (FOIR)
  double get _availableEmi => (_salary * 0.50) - _existingEmi;

  double get _maxLoan {
    if (_availableEmi <= 0) return 0;
    final r = _interestRate / 12 / 100;
    final n = _tenureYears * 12;
    return _availableEmi * (pow1(1 + r, n) - 1) / (r * pow1(1 + r, n));
  }

  double pow1(double base, double exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  double get _maxProperty => _maxLoan / 0.80; // banks give max 80% LTV

  @override
  void dispose() {
    _salaryController.dispose();
    _existingEmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Home Loan Eligibility')),
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
                Expanded(child: Text('Banks allow max 50% of net salary as total EMI. Result is an estimate — actual eligibility depends on credit score and bank policy.',
                  style: TextStyle(fontSize: 12, color: AppColors.primary))),
              ]),
            ),
            const SizedBox(height: 20),

            const Text('Monthly Net Salary (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 80000', prefixText: '₹ '),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 16),

            const Text('Existing EMIs per month (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Text('Car loan, personal loan, credit card EMI — leave 0 if none',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _existingEmiController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0', prefixText: '₹ '),
              onChanged: (_) => setState(() => _isCalculated = false),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Interest Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${_interestRate.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _interestRate, min: 6.0, max: 15.0, divisions: 90,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() { _interestRate = double.parse(v.toStringAsFixed(1)); _isCalculated = false; }),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Loan Tenure', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${_tenureYears.toInt()} years', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _tenureYears, min: 5, max: 30, divisions: 25,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() { _tenureYears = v.roundToDouble(); _isCalculated = false; }),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () { if (_salary > 0) setState(() => _isCalculated = true); },
              icon: const Icon(Icons.calculate),
              label: const Text('Check Eligibility'),
            ),

            if (_isCalculated) ...[
              const SizedBox(height: 24),
              if (_availableEmi <= 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.warning_amber, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(child: Text('Your existing EMIs exceed 50% of salary. Banks will likely reject home loan application. Clear other loans first.',
                      style: TextStyle(color: AppColors.danger, fontSize: 13))),
                  ]),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Maximum Home Loan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('₹${_fmt(_maxLoan)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _EligItem('Available\nEMI/month', '₹${_availableEmi.toStringAsFixed(0)}'),
                          _EligItem('Max Property\n(80% LTV)', '₹${_fmt(_maxProperty)}'),
                          _EligItem('Down\nPayment (20%)', '₹${_fmt(_maxProperty * 0.20)}'),
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
                        const Text('Improve Your Eligibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Divider(height: 16),
                        _Tip(Icons.credit_score, 'CIBIL score above 750 gets best rates. Check free on Paytm or CIBIL app.'),
                        _Tip(Icons.person_add, 'Add wife/parent as co-applicant — combined salary = higher loan'),
                        _Tip(Icons.cancel, 'Close credit card EMIs before applying — improves FOIR ratio'),
                        _Tip(Icons.trending_up, 'Longer tenure = lower EMI = higher eligibility (but more interest)'),
                        _Tip(Icons.woman, 'Women co-applicant gets 0.05% lower rate at SBI and most banks'),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Bank connect CTA
              if (!_enquirySent)
                _BankConnectCard(
                  maxLoan: _maxLoan,
                  salary: _salary,
                  preferredBank: _preferredBank,
                  onBankChanged: (b) => setState(() => _preferredBank = b),
                  onConnect: () async {
                    await PropertyDataService().saveLoanEnquiry(
                      propertyValue: _maxProperty,
                      monthlyIncome: _salary,
                      loanAmount: _maxLoan,
                      preferredBank: _preferredBank,
                    );
                    if (mounted) setState(() => _enquirySent = true);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Enquiry sent! A partner bank will contact you within 24 hours.',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    )),
                  ]),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}

class _EligItem extends StatelessWidget {
  final String label;
  final String value;
  const _EligItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
  ]);
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
    ]),
  );
}

class _BankConnectCard extends StatelessWidget {
  final double maxLoan;
  final double salary;
  final String preferredBank;
  final ValueChanged<String> onBankChanged;
  final VoidCallback onConnect;

  const _BankConnectCard({
    required this.maxLoan,
    required this.salary,
    required this.preferredBank,
    required this.onBankChanged,
    required this.onConnect,
  });

  static const _banks = ['SBI', 'HDFC Bank', 'ICICI Bank', 'Axis Bank',
      'Kotak Bank', 'Bank of Baroda', 'Canara Bank', 'LIC Housing'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.info, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_balance, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Connect with a Bank', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 4),
          const Text('A partner bank loan officer will call you — no spam, no obligation',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: preferredBank,
            dropdownColor: AppColors.info,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _banks.map((b) => DropdownMenuItem(
              value: b,
              child: Text(b, style: const TextStyle(color: Colors.white)),
            )).toList(),
            onChanged: (v) { if (v != null) onBankChanged(v); },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.phone_in_talk, size: 16),
              label: const Text('Request Callback', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
