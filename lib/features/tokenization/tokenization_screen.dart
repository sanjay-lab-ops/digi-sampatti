import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Property Tokenization — Demo / Simulation screen.
/// This is a Phase 3+ feature. Currently shows the concept and simulated flow.
/// NOT connected to any real blockchain or SPV.
class TokenizationScreen extends StatefulWidget {
  const TokenizationScreen({super.key});
  @override
  State<TokenizationScreen> createState() => _TokenizationScreenState();
}

class _TokenizationScreenState extends State<TokenizationScreen> {
  int _step = 0; // 0=intro, 1=property, 2=spv, 3=tokens, 4=success

  final _priceCtrl = TextEditingController(text: '75,00,000');
  final _tokensCtrl = TextEditingController(text: '1,00,000');
  bool _simulating = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _tokensCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    setState(() { _simulating = true; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _simulating = false; _step++; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Property Tokenization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text('Demo Simulation — Phase 3 Feature', style: TextStyle(fontSize: 10, color: Colors.amber)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: const Text('DEMO', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _step == 0 ? _buildIntro() : _buildSimulator(),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0533), Color(0xFF0D1B4A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🏗️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('Fractional Real Estate\nOwnership via Tokenization',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.3)),
            const SizedBox(height: 8),
            const Text('Own a fraction of premium properties. Earn rental income. Exit anytime on the secondary market.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'This is a simulation. Real tokenization requires SEBI compliance + SPV formation. DigiSampatti plans to launch this in Phase 3.',
                  style: TextStyle(color: Colors.amber, fontSize: 11, height: 1.4),
                )),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // How it works
        const Text('How Property Tokenization Works', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),

        _HowItem('1', 'Property → SPV', 'A Special Purpose Vehicle (company) is formed. The property is legally transferred to the SPV.', const Color(0xFF42A5F5)),
        _HowItem('2', 'SPV → Tokens', '1,00,000 tokens are minted on Polygon blockchain. Each token = 1 share of the SPV = fractional ownership.', const Color(0xFF66BB6A)),
        _HowItem('3', 'KYC + Invest', 'Investors complete Aadhaar KYC. They deposit INR via escrow. Smart contract mints tokens to their wallet.', const Color(0xFFF59E0B)),
        _HowItem('4', 'Earn Rent', 'Tenant pays rent → goes to SPV → smart contract distributes proportionally to all token holders.', const Color(0xFFCE93D8)),
        _HowItem('5', 'Exit', 'Sell tokens on DigiSampatti private marketplace to other verified investors. No real estate broker needed.', const Color(0xFF26C6DA), isLast: true),

        const SizedBox(height: 24),

        // Stats row
        Row(children: [
          _TokenStat('₹10', 'Min Investment\n(per token)', const Color(0xFF66BB6A)),
          const SizedBox(width: 10),
          _TokenStat('8–12%', 'Target Annual\nRental Yield', const Color(0xFF42A5F5)),
          const SizedBox(width: 10),
          _TokenStat('Polygon', 'Blockchain\nNetwork', const Color(0xFFCE93D8)),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _step = 1),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Try Demo Simulation →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildSimulator() {
    if (_step >= 5) return _buildSuccess();

    final steps = [
      _SimStep('Select Property', 'Choose which property to tokenize', Icons.home_outlined, const Color(0xFF42A5F5)),
      _SimStep('Form SPV', 'Create legal wrapper (Private Ltd)', Icons.business_outlined, const Color(0xFF66BB6A)),
      _SimStep('Mint Tokens', 'Deploy smart contract on Polygon', Icons.token_outlined, const Color(0xFFCE93D8)),
      _SimStep('List for Investment', 'Open to verified investors', Icons.store_outlined, const Color(0xFFF59E0B)),
    ];

    final current = steps[_step - 1];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress
        Row(children: List.generate(4, (i) => Expanded(child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          height: 4,
          decoration: BoxDecoration(
            color: i < _step ? const Color(0xFF7C3AED) : Colors.white12,
            borderRadius: BorderRadius.circular(2),
          ),
        )))),
        const SizedBox(height: 20),

        // Current step
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: current.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: current.color.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: current.color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(current.icon, color: current.color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Step $_step of 4', style: TextStyle(color: current.color, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(current.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ]),
            const SizedBox(height: 12),
            Text(current.desc, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 20),

        // Input for step 1
        if (_step == 1) ...[
          const Text('Property Details', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            style: const TextStyle(color: Colors.white),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Property',
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: 'Survey 45, Whitefield, Bengaluru',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Property Value (₹)',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
        ],

        // Input for step 3
        if (_step == 3) ...[
          const Text('Token Configuration', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _tokensCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Total Token Supply',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white24)),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              _CalcRow('Price per Token', '₹75'),
              _CalcRow('Blockchain', 'Polygon (MATIC)'),
              _CalcRow('Contract Type', 'ERC-20 (Whitelisted)'),
              _CalcRow('Min Investment', '₹750 (10 tokens)'),
            ]),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _simulating ? null : _simulate,
            icon: _simulating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.arrow_forward_rounded),
            label: Text(_simulating ? 'Processing...' : _stepLabel()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  String _stepLabel() {
    switch (_step) {
      case 1: return 'Submit Property Details →';
      case 2: return 'Form SPV (Simulate) →';
      case 3: return 'Deploy Smart Contract →';
      case 4: return 'List for Investment →';
      default: return 'Next →';
    }
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.token_outlined, color: Color(0xFF7C3AED), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Tokenization Complete!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('(Simulation)', style: TextStyle(color: Colors.amber, fontSize: 12)),
          const SizedBox(height: 16),
          _ResultRow('Property Value', '₹75,00,000'),
          _ResultRow('Tokens Minted', '1,00,000 tokens'),
          _ResultRow('Price per Token', '₹75'),
          _ResultRow('Blockchain', 'Polygon'),
          _ResultRow('SPV', 'DS-SPV-001 Pvt Ltd'),
          _ResultRow('Status', '🟢 Live for Investment'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Home'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HowItem extends StatelessWidget {
  final String num, title, body;
  final Color color;
  final bool isLast;
  const _HowItem(this.num, this.title, this.body, this.color, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4))),
          child: Center(child: Text(num, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)))),
        if (!isLast) Container(width: 2, height: 48, color: Colors.white10),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
        ]),
      )),
    ]);
  }
}

class _TokenStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _TokenStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.3), textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _SimStep {
  final String title, desc;
  final IconData icon;
  final Color color;
  const _SimStep(this.title, this.desc, this.icon, this.color);
}

class _CalcRow extends StatelessWidget {
  final String label, value;
  const _CalcRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  const _ResultRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]),
  );
}
