import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Financial Tools — All calculators inline, one screen, no tabs ────────────
// Property Tax · EMI · Total Cost · Stamp Duty · Loan Eligibility
// User flows straight down — no navigation, no extra screens.
// ─────────────────────────────────────────────────────────────────────────────

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Tools'),
        backgroundColor: Colors.white,
      ),
      body: const _ToolsBody(),
    );
  }
}

class _ToolsBody extends StatelessWidget {
  const _ToolsBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.safe]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Know the True Cost',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('All calculators in one place — EMI, property tax, stamp duty, loan',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 11, height: 1.4)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // ── 1. Property Tax Estimator ──────────────────────────────────────
        const _SectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Property Tax Estimator',
            subtitle: 'BBMP · Panchayat · All India 2024-25',
            color: AppColors.teal),
        const SizedBox(height: 10),
        const _PropertyTaxCard(),
        const SizedBox(height: 20),

        // ── 2. EMI Calculator ──────────────────────────────────────────────
        const _SectionHeader(
            icon: Icons.calculate_outlined,
            title: 'EMI Calculator',
            subtitle: 'Monthly home loan payment',
            color: AppColors.primary),
        const SizedBox(height: 10),
        const _EmiCard(),
        const SizedBox(height: 20),

        // ── 3. Stamp Duty + Registration ───────────────────────────────────
        const _SectionHeader(
            icon: Icons.receipt_outlined,
            title: 'Stamp Duty & Registration',
            subtitle: 'What you pay to register the sale deed',
            color: const Color(0xFF7C3AED)),
        const SizedBox(height: 10),
        const _StampDutyCard(),
        const SizedBox(height: 20),

        // ── 4. Total Cost of Buying ────────────────────────────────────────
        const _SectionHeader(
            icon: Icons.account_balance_outlined,
            title: 'Total Cost of Buying',
            subtitle: 'Price + stamp duty + interiors + hidden costs',
            color: AppColors.deepOrange),
        const SizedBox(height: 10),
        const _TotalCostCard(),
        const SizedBox(height: 20),

        // ── 5. Loan Eligibility ────────────────────────────────────────────
        const _SectionHeader(
            icon: Icons.fingerprint,
            title: 'Home Loan Eligibility',
            subtitle: 'How much loan your salary qualifies for',
            color: AppColors.arthBlue),
        const SizedBox(height: 10),
        const _LoanEligibilityCard(),
        const SizedBox(height: 24),

        // SRO locator note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.arthBlue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.arthBlue.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.location_city_outlined,
                color: AppColors.arthBlue, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Find your Sub-Registrar Office (SRO) — '
              'use the SRO Locator in Quick Tools on the home screen.',
              style: TextStyle(fontSize: 11, color: AppColors.arthBlue,
                  height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionHeader({required this.icon, required this.title,
      required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: color, size: 18),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 14, color: color)),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textLight)),
      ],
    )),
  ]);
}

// ─── Card wrapper ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: child,
  );
}

// ─── 1. Property Tax Estimator ────────────────────────────────────────────────
class _PropertyTaxCard extends StatefulWidget {
  const _PropertyTaxCard();

  @override
  State<_PropertyTaxCard> createState() => _PropertyTaxCardState();
}

class _PropertyTaxCardState extends State<_PropertyTaxCard> {
  final _areaCtrl = TextEditingController();
  String _zone    = 'A';
  String _usage   = 'Residential';
  String _state   = 'Karnataka';

  // BBMP rates ₹/sqft/year — Zone A-F
  static const _bbmpRates = {
    'A': {'Residential': 5.0, 'Commercial': 10.0},
    'B': {'Residential': 4.0, 'Commercial': 8.0},
    'C': {'Residential': 3.5, 'Commercial': 7.0},
    'D': {'Residential': 3.0, 'Commercial': 6.0},
    'E': {'Residential': 2.0, 'Commercial': 4.0},
    'F': {'Residential': 1.5, 'Commercial': 3.0},
  };

  // Other state flat rates ₹/sqft/year (approximate)
  static const _stateRates = {
    'Tamil Nadu':       {'Residential': 3.0, 'Commercial': 7.0},
    'Maharashtra':      {'Residential': 6.0, 'Commercial': 12.0},
    'Andhra Pradesh':   {'Residential': 2.5, 'Commercial': 6.0},
    'Telangana':        {'Residential': 2.5, 'Commercial': 5.5},
    'Kerala':           {'Residential': 2.0, 'Commercial': 5.0},
    'Delhi':            {'Residential': 4.0, 'Commercial': 9.0},
    'Gujarat':          {'Residential': 3.0, 'Commercial': 7.0},
  };

  static const _states = [
    'Karnataka', 'Tamil Nadu', 'Maharashtra', 'Andhra Pradesh',
    'Telangana', 'Kerala', 'Delhi', 'Gujarat', 'Other',
  ];

  double get _area => double.tryParse(_areaCtrl.text.replaceAll(',', '')) ?? 0;

  double get _rate {
    if (_state == 'Karnataka') {
      return _bbmpRates[_zone]?[_usage] ?? 3.0;
    }
    return _stateRates[_state]?[_usage] ?? 2.5;
  }

  double get _annual => _area * _rate;

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculated = _area > 0;
    return _Card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State selector
        DropdownButtonFormField<String>(
          value: _state,
          decoration: const InputDecoration(
            labelText: 'State / City',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _state = v!),
        ),
        const SizedBox(height: 12),
        // Zone (only for Karnataka)
        if (_state == 'Karnataka') ...[
          const Text('BBMP Zone',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12,
                  color: AppColors.textMedium)),
          const Text('A=Indiranagar/Koramangala  B=JP Nagar  C=Whitefield  D=Marathahalli  E=Yelahanka  F=Outer',
              style: TextStyle(fontSize: 10, color: AppColors.textLight)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['A','B','C','D','E','F'].map((z) => GestureDetector(
                onTap: () => setState(() => _zone = z),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 50, height: 38,
                  decoration: BoxDecoration(
                    color: _zone == z ? AppColors.teal : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _zone == z ? AppColors.teal : AppColors.borderColor),
                  ),
                  child: Center(child: Text('Zone $z',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: _zone == z ? Colors.white : AppColors.textDark))),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Usage
        Row(children: ['Residential', 'Commercial'].map((u) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _usage = u),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _usage == u ? AppColors.teal : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(u, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _usage == u ? Colors.white : Colors.grey.shade700)),
              ),
            ),
          ),
        )).toList()),
        const SizedBox(height: 12),
        TextField(
          controller: _areaCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Built-up Area (sq ft)',
            hintText: 'e.g. 1200',
            border: OutlineInputBorder(),
            suffixText: 'sq ft',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (calculated) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Annual Property Tax',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('₹${_annual.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 30, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _taxStat('Half-yearly', '₹${(_annual / 2).toStringAsFixed(0)}'),
                _taxStat('Monthly', '₹${(_annual / 12).toStringAsFixed(0)}'),
                _taxStat('Rate/sqft', '₹${_rate.toStringAsFixed(1)}/yr'),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '• 5% rebate if paid full year before April 30\n'
              '• BBMP bills twice a year (April & October)\n'
              '• Verify exact amount at bbmp.gov.in before paying',
              style: TextStyle(fontSize: 11, height: 1.5,
                  color: Colors.black87),
            ),
          ),
        ],
      ],
    ));
  }

  Widget _taxStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white,
        fontWeight: FontWeight.bold, fontSize: 13)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}

// ─── 2. EMI Calculator ─────────────────────────────────────────────────────────
class _EmiCard extends StatefulWidget {
  const _EmiCard();

  @override
  State<_EmiCard> createState() => _EmiCardState();
}

class _EmiCardState extends State<_EmiCard> {
  double _principal  = 5000000;
  double _rate       = 8.5;
  int    _tenureYrs  = 20;

  double get _emi {
    final r = _rate / 12 / 100;
    final n = _tenureYrs * 12;
    if (r == 0) return _principal / n;
    return _principal * r * (1 + r).toInt().toDouble().abs() /
        (1 - 1 / (1 + r)) / n;
  }

  double get _emiCalc {
    final r = _rate / 12 / 100;
    final n = (_tenureYrs * 12).toDouble();
    if (r == 0) return _principal / n;
    final pow = (1 + r);
    double powN = 1;
    for (int i = 0; i < n; i++) powN *= pow;
    return _principal * r * powN / (powN - 1);
  }

  int get _totalPayable => (_emiCalc * _tenureYrs * 12).round();
  int get _totalInterest => _totalPayable - _principal.round();

  String _fmt(num v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${v.round()}';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderRow('Loan Amount', _fmt(_principal),
            _principal, 500000, 10000000, 100000,
            (v) => setState(() => _principal = v)),
        const SizedBox(height: 12),
        _sliderRow('Interest Rate', '${_rate.toStringAsFixed(1)}%',
            _rate, 6.0, 14.0, 0.25,
            (v) => setState(() => _rate = v)),
        const SizedBox(height: 12),
        _sliderRow('Tenure', '$_tenureYrs years',
            _tenureYrs.toDouble(), 5, 30, 1,
            (v) => setState(() => _tenureYrs = v.round())),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            const Text('Monthly EMI',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('₹${_emiCalc.round()}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 30, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _emiStat('Principal', _fmt(_principal)),
              _emiStat('Total Interest', _fmt(_totalInterest)),
              _emiStat('Total Payable', _fmt(_totalPayable)),
            ]),
          ]),
        ),
      ],
    ));
  }

  Widget _sliderRow(String label, String valueStr, double value,
      double min, double max, double divisions, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12,
                color: AppColors.textMedium)),
        const Spacer(),
        Text(valueStr,
            style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: AppColors.primary)),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) / divisions).round(),
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _emiStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white,
        fontWeight: FontWeight.bold, fontSize: 12)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}

// ─── 3. Stamp Duty + Registration ────────────────────────────────────────────
class _StampDutyCard extends StatefulWidget {
  const _StampDutyCard();

  @override
  State<_StampDutyCard> createState() => _StampDutyCardState();
}

class _StampDutyCardState extends State<_StampDutyCard> {
  final _priceCtrl = TextEditingController();
  String _state    = 'Karnataka';
  String _gender   = 'Male';

  static const _stampRates = {
    'Karnataka':      {'Male': 5.6,  'Female': 5.0,  'Joint': 5.0,  'reg': 1.0},
    'Tamil Nadu':     {'Male': 7.0,  'Female': 7.0,  'Joint': 7.0,  'reg': 1.0},
    'Maharashtra':    {'Male': 5.0,  'Female': 4.0,  'Joint': 4.5,  'reg': 1.0},
    'Andhra Pradesh': {'Male': 5.0,  'Female': 5.0,  'Joint': 5.0,  'reg': 0.5},
    'Telangana':      {'Male': 4.0,  'Female': 4.0,  'Joint': 4.0,  'reg': 0.5},
    'Kerala':         {'Male': 8.0,  'Female': 8.0,  'Joint': 8.0,  'reg': 2.0},
    'Delhi':          {'Male': 6.0,  'Female': 4.0,  'Joint': 5.0,  'reg': 1.0},
    'Gujarat':        {'Male': 4.9,  'Female': 4.9,  'Joint': 4.9,  'reg': 1.0},
    'UP':             {'Male': 7.0,  'Female': 6.0,  'Joint': 6.5,  'reg': 1.0},
    'Rajasthan':      {'Male': 5.0,  'Female': 4.0,  'Joint': 4.5,  'reg': 1.0},
    'MP':             {'Male': 7.5,  'Female': 7.5,  'Joint': 7.5,  'reg': 3.0},
    'Punjab':         {'Male': 5.0,  'Female': 5.0,  'Joint': 5.0,  'reg': 1.0},
    'Haryana':        {'Male': 5.0,  'Female': 3.0,  'Joint': 4.0,  'reg': 1.0},
    'West Bengal':    {'Male': 5.0,  'Female': 5.0,  'Joint': 5.0,  'reg': 1.0},
  };

  static const _states = [
    'Karnataka', 'Tamil Nadu', 'Maharashtra', 'Andhra Pradesh',
    'Telangana', 'Kerala', 'Delhi', 'Gujarat', 'UP', 'Rajasthan',
    'MP', 'Punjab', 'Haryana', 'West Bengal',
  ];

  double get _price => double.tryParse(_priceCtrl.text.replaceAll(',', '').replaceAll('₹', '')) ?? 0;

  double get _stampPct => (_stampRates[_state]?[_gender] ?? 5.0);
  double get _regPct   => (_stampRates[_state]?['reg']   ?? 1.0);
  double get _stamp    => _price * _stampPct / 100;
  double get _reg      => _price * _regPct / 100;
  double get _total    => _stamp + _reg;

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${v.round()}';
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculated = _price > 0;
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _state,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _state = v!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Buyer',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: 'Male',   child: Text('Male',   style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Joint',  child: Text('Joint',  style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Property Price (₹)',
            hintText: 'e.g. 5000000',
            border: OutlineInputBorder(),
            prefixText: '₹ ',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (calculated) ...[
          const SizedBox(height: 14),
          _row('Stamp Duty (${_stampPct.toStringAsFixed(1)}%)', _fmt(_stamp)),
          _row('Registration Fee (${_regPct.toStringAsFixed(1)}%)', _fmt(_reg)),
          const Divider(height: 12),
          _row('Total Registration Cost', _fmt(_total), bold: true),
          const SizedBox(height: 4),
          Text('Property Value: ${_fmt(_price)} + Registration: ${_fmt(_total)} = ${_fmt(_price + _total)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ],
    ));
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label,
          style: TextStyle(fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? AppColors.textDark : AppColors.textMedium))),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: bold ? const Color(0xFF7C3AED) : null)),
    ]),
  );
}

// ─── 4. Total Cost of Buying ──────────────────────────────────────────────────
class _TotalCostCard extends StatefulWidget {
  const _TotalCostCard();

  @override
  State<_TotalCostCard> createState() => _TotalCostCardState();
}

class _TotalCostCardState extends State<_TotalCostCard> {
  double _price      = 5000000;
  bool   _interiors  = true;
  bool   _agentFee   = true;
  bool   _shifting   = true;

  double get _stamp      => _price * 0.056;
  double get _reg        => _price * 0.01;
  double get _interiorEst => _price * 0.10;
  double get _agentEst   => _price * 0.01;
  double get _shiftingEst => 30000;
  double get _digiReport => 499;

  double get _total =>
      _price + _stamp + _reg +
      (_interiors ? _interiorEst : 0) +
      (_agentFee  ? _agentEst  : 0) +
      (_shifting  ? _shiftingEst : 0) +
      _digiReport;

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${v.round()}';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderRow('Property Price', _fmt(_price), _price, 1000000, 20000000, 500000,
            (v) => setState(() => _price = v)),
        const Divider(height: 16),
        _costRow('Property Price', _fmt(_price), null, false),
        _costRow('Stamp Duty (5.6%)', _fmt(_stamp), null, false),
        _costRow('Registration (1%)', _fmt(_reg), null, false),
        _toggleRow('Interiors (~10%)', _fmt(_interiorEst),
            _interiors, (v) => setState(() => _interiors = v)),
        _toggleRow('Agent/Broker (1%)', _fmt(_agentEst),
            _agentFee, (v) => setState(() => _agentFee = v)),
        _toggleRow('Shifting/Moving', _fmt(_shiftingEst),
            _shifting, (v) => setState(() => _shifting = v)),
        _costRow('Arth ID Report', '₹499', null, false),
        const Divider(height: 12),
        _costRow('TOTAL COST OF BUYING', _fmt(_total),
            AppColors.deepOrange, true),
      ],
    ));
  }

  Widget _sliderRow(String label, String valueStr, double value,
      double min, double max, double divisions, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 12, color: AppColors.textMedium)),
        const Spacer(),
        Text(valueStr,
            style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: AppColors.deepOrange)),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min, max: max,
        divisions: ((max - min) / divisions).round(),
        activeColor: AppColors.deepOrange,
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _costRow(String label, String value, Color? color, bool bold) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
      Expanded(child: Text(label,
          style: TextStyle(fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color)),
    ]));

  Widget _toggleRow(String label, String value, bool active, ValueChanged<bool> onChanged) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Switch(
        value: active,
        onChanged: onChanged,
        activeColor: AppColors.deepOrange,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      const SizedBox(width: 4),
      Expanded(child: Text(label,
          style: TextStyle(fontSize: 12,
              color: active ? AppColors.textDark : AppColors.textLight))),
      Text(active ? value : '—',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? null : AppColors.textLight)),
    ]));
}

// ─── 5. Loan Eligibility ──────────────────────────────────────────────────────
class _LoanEligibilityCard extends StatefulWidget {
  const _LoanEligibilityCard();

  @override
  State<_LoanEligibilityCard> createState() => _LoanEligibilityCardState();
}

class _LoanEligibilityCardState extends State<_LoanEligibilityCard> {
  double _salary        = 80000;
  double _existingEmi   = 0;
  double _rate          = 8.5;
  int    _tenureYrs     = 20;

  // Bank formula: max EMI = 50% of net salary; max loan = EMI × factor
  double get _availableEmi => _salary * 0.50 - _existingEmi;

  double get _maxLoan {
    if (_availableEmi <= 0) return 0;
    final r = _rate / 12 / 100;
    final n = _tenureYrs * 12;
    double powN = 1;
    for (int i = 0; i < n; i++) powN *= (1 + r);
    return _availableEmi * (powN - 1) / (r * powN);
  }

  double get _maxProperty => _maxLoan / 0.80; // bank gives 80% of property value

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${v.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _maxLoan > 0;
    return _Card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderRow('Monthly Net Salary', _fmt(_salary),
            _salary, 20000, 500000, 5000,
            (v) => setState(() => _salary = v)),
        const SizedBox(height: 4),
        _sliderRow('Existing EMI (if any)', _fmt(_existingEmi),
            _existingEmi, 0, 100000, 2000,
            (v) => setState(() => _existingEmi = v)),
        const SizedBox(height: 4),
        _sliderRow('Interest Rate', '${_rate.toStringAsFixed(1)}%',
            _rate, 6.5, 14.0, 0.25,
            (v) => setState(() => _rate = v)),
        const SizedBox(height: 4),
        _sliderRow('Tenure', '$_tenureYrs years',
            _tenureYrs.toDouble(), 5, 30, 1,
            (v) => setState(() => _tenureYrs = v.round())),
        const SizedBox(height: 16),
        if (eligible) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.arthBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Maximum Loan Eligible',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_fmt(_maxLoan),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Max EMI', _fmt(_availableEmi)),
                _stat('Max Property', _fmt(_maxProperty)),
                _stat('Down Payment', _fmt(_maxProperty * 0.20)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Text(
            '🏦 Top banks: SBI at ${_rate.toStringAsFixed(1)}%, HDFC/ICICI at ${(_rate + 0.1).toStringAsFixed(1)}%\n'
            '💡 Women get 0.05% lower rate from most banks',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Existing EMI exceeds 50% of salary — no new loan eligible.\n'
              'Reduce existing EMI or increase salary to qualify.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    ));
  }

  Widget _sliderRow(String label, String valueStr, double value,
      double min, double max, double divisions, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 12, color: AppColors.textMedium)),
        const Spacer(),
        Text(valueStr,
            style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: AppColors.arthBlue)),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min, max: max,
        divisions: ((max - min) / divisions).round(),
        activeColor: AppColors.arthBlue,
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white,
        fontWeight: FontWeight.bold, fontSize: 12)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}
