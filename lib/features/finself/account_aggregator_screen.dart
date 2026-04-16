import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/income_analysis_service.dart';
import 'package:digi_sampatti/features/finself/buyer_financial_profile_screen.dart';

// ─── Account Aggregator Consent Screen ──────────────────────────────────────
// India's Account Aggregator (AA) framework (RBI regulated) lets users
// securely share bank statement data with financial services providers.
//
// Production flow (Finvu/Sahamati):
//   1. App calls AA to create consent request
//   2. AA sends OTP to user's bank-linked mobile
//   3. User enters OTP → consent granted
//   4. AA shares encrypted bank statements
//   5. App decrypts and analyses
//
// Registration: sahamati.org.in → Technical Member registration
// Finvu SDK:    finvu.in/developer → Flutter SDK available
// Sandbox:      Test with demo Aadhaar numbers
//
// For MVP (this file): simulated AA flow with real income analysis engine.
// Replace _simulateAaConsent() with real Finvu SDK calls for production.
// ──────────────────────────────────────────────────────────────────────────────

enum _AaStep {
  explain,      // show what AA is and why we need it
  enterPhone,   // user enters Aadhaar-linked phone
  consent,      // show what data will be shared
  otp,          // user enters OTP from bank
  fetching,     // AA is fetching data
  done,
  error,
}

class AccountAggregatorScreen extends ConsumerStatefulWidget {
  const AccountAggregatorScreen({super.key});
  @override
  ConsumerState<AccountAggregatorScreen> createState() =>
      _AccountAggregatorScreenState();
}

class _AccountAggregatorScreenState
    extends ConsumerState<AccountAggregatorScreen> {
  _AaStep _step = _AaStep.explain;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool _loading = false;
  String? _error;
  FinancialProfile? _profile;

  // Which data sources user consents to share
  final Map<String, bool> _consent = {
    'Bank accounts & statements (12 months)': true,
    'Mutual fund / investment portfolio': true,
    'Fixed deposits & savings': true,
    'EPF / Provident Fund balance': true,
  };
  final Map<String, bool> _optionalConsent = {
    'GST returns (if you have a business)': false,
    'Trading account (Zerodha / Groww)': false,
  };

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_phoneCtrl.text.length < 10) return;
    setState(() { _loading = true; _error = null; });

    // Production: call Finvu AA SDK to initiate consent request
    // await FinvuSDK.initConsent(phone: _phoneCtrl.text, ...);

    // MVP: simulate OTP sent
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _loading = false; _step = _AaStep.otp; });
  }

  Future<void> _verifyOtpAndFetch() async {
    if (_otpCtrl.text.length < 4) return;
    setState(() { _loading = true; _error = null; _step = _AaStep.fetching; });

    try {
      // Production: Finvu SDK verifies OTP, fetches and decrypts bank data
      // final data = await FinvuSDK.verifyConsentAndFetch(otp: _otpCtrl.text);

      // MVP: simulate fetched transactions and run real analysis
      await Future.delayed(const Duration(seconds: 3));
      final demoTransactions = _buildDemoTransactions();

      final analysis = IncomeAnalysisService();
      final profile  = await analysis.analyseStatements(
        transactions:        demoTransactions,
        userName:            'Buyer',
        epfoSalaryMonthly:   _consent['EPF / Provident Fund balance'] == true ? 45000 : null,
        tradingPnlMonthly:   _optionalConsent['Trading account (Zerodha / Groww)'] == true ? 18000 : null,
        gstTurnoverMonthly:  _optionalConsent['GST returns (if you have a business)'] == true ? 200000 : null,
      );

      setState(() { _loading = false; _profile = profile; _step = _AaStep.done; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().split('\n').first;
        _step = _AaStep.error;
      });
    }
  }

  // ── Demo transaction data (replaced by real AA data in production) ────────
  List<Map<String, dynamic>> _buildDemoTransactions() {
    return [
      for (int m = 0; m < 6; m++) ...[
        {'type': 'credit', 'amount': 45000, 'narration': 'SALARY HDFC PAYROLL', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-01'},
        {'type': 'credit', 'amount': 18000, 'narration': 'ZERODHA TRADING PAYOUT', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-05'},
        {'type': 'debit',  'amount': 12000, 'narration': 'HDFC HOME LOAN EMI', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-05'},
        {'type': 'debit',  'amount': 8000,  'narration': 'GROCERY BIGBASKET', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-10'},
        {'type': 'debit',  'amount': 5000,  'narration': 'UTILITY BESCOM', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-15'},
        {'type': 'credit', 'amount': 5000,  'narration': 'DIVIDEND NSDL', 'date': '2025-${(12-m).toString().padLeft(2,'0')}-20'},
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(children: [
          Image.asset('assets/images/arth_id_logo.png',
              height: 28, width: 28,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.fingerprint, size: 28, color: Color(0xFFB8860B))),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FinSelf Lite',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('Simulation — RBI AA registration pending',
                  style: TextStyle(fontSize: 9, color: Colors.orange,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          _AaStep.explain   => _buildExplain(),
          _AaStep.enterPhone=> _buildEnterPhone(),
          _AaStep.consent   => _buildConsent(),
          _AaStep.otp       => _buildOtp(),
          _AaStep.fetching  => _buildFetching(),
          _AaStep.done      => _buildDone(),
          _AaStep.error     => _buildError(),
        },
      ),
    );
  }

  // ── Step 1: Explain ──────────────────────────────────────────────────────
  Widget _buildExplain() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.arthBlue, AppColors.info],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Text('🏦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Check Your Home Loan Eligibility',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Connect your bank account via India\'s official Account Aggregator '
              '(RBI regulated). We read your income and tell you exactly which bank '
              'will give you what loan amount.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.lock, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'RBI regulated · Data encrypted · You own it · '
                  'Banks see score, not raw data',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                )),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('What we analyse:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...[
          ('📊', 'Average monthly income', 'From all credit entries in your account'),
          ('💳', 'Existing EMIs', 'All current loan repayments'),
          ('💰', 'Disposable income', 'What\'s left after EMIs and expenses'),
          ('🏠', 'Max loan eligible', 'Calculated at current bank rates (HDFC 8.4%)'),
          ('🏅', 'FinSelf Score 0–900', 'Your overall financial health score'),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Text(item.$1, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$2, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                Text(item.$3, style: const TextStyle(
                    fontSize: 11, color: Colors.black54)),
              ],
            )),
          ]),
        )),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = _AaStep.enterPhone),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.arthBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue →',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Skip for now',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    ),
  );

  // ── Step 2: Phone number ─────────────────────────────────────────────────
  Widget _buildEnterPhone() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Aadhaar-linked mobile number',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text(
          'We send consent request to your bank via this number. '
          'Your bank sends OTP for approval. Data sharing requires your active confirmation.',
          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixText: '+91 ',
            prefixIcon: const Icon(Icons.phone, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 18, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        const Text(
          'Account Aggregator (AA) is built by RBI and NPCI — '
          'the same organisations that built UPI. '
          'Your bank can only share data with your explicit OTP approval.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => setState(() => _step = _AaStep.consent),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.arthBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Next →'),
          ),
        ),
      ],
    ),
  );

  // ── Step 3: Consent selection ─────────────────────────────────────────────
  Widget _buildConsent() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose what to share',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 6),
        const Text(
          'Tick what you want to share. More data = more accurate eligibility. '
          'You can revoke access anytime from your bank\'s AA section.',
          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
        const Text('Required',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                color: Colors.black45, letterSpacing: 1)),
        const SizedBox(height: 8),
        ..._consent.keys.map((key) => _consentTile(key, _consent, true)),
        const SizedBox(height: 16),
        const Text('Optional — adds accuracy',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                color: Colors.black45, letterSpacing: 1)),
        const SizedBox(height: 8),
        ..._optionalConsent.keys.map((key) => _consentTile(key, _optionalConsent, false)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Duration: 1 use only. This consent expires after this single check. '
            'We never store your raw bank data.',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _requestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.arthBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send OTP to Bank →'),
          ),
        ),
      ],
    ),
  );

  Widget _consentTile(String key, Map<String, bool> map, bool required) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: map[key] == true
            ? AppColors.arthBlue.withOpacity(0.4) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CheckboxListTile(
        value: map[key],
        onChanged: required ? null : (v) => setState(() => map[key] = v!),
        title: Text(key, style: const TextStyle(fontSize: 13)),
        activeColor: AppColors.arthBlue,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );

  // ── Step 4: OTP ──────────────────────────────────────────────────────────
  Widget _buildOtp() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sms_outlined, size: 48, color: AppColors.arthBlue),
        const SizedBox(height: 16),
        const Text('Enter OTP from your bank',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 8),
        const Text(
          'Your bank sent a one-time password to your registered mobile. '
          'This approves sharing your financial data — one time only.',
          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtpAndFetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.arthBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Verify & Fetch Data →'),
          ),
        ),
      ],
    ),
  );

  // ── Step 5: Fetching ─────────────────────────────────────────────────────
  Widget _buildFetching() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.arthBlue, strokeWidth: 3),
          const SizedBox(height: 24),
          const Text('Analysing your financial data...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...[
            'Reading bank statements...',
            'Calculating monthly income...',
            'Checking existing EMIs...',
            'Computing loan eligibility...',
            'Generating FinSelf Score...',
          ].map((s) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s, style: const TextStyle(
                color: Colors.black54, fontSize: 13)),
          )),
        ],
      ),
    ),
  );

  // ── Step 6: Done — redirect to profile screen ────────────────────────────
  Widget _buildDone() {
    if (_profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerFinancialProfileScreen(profile: _profile!),
          ),
        );
      });
    }
    return const Center(child: CircularProgressIndicator());
  }

  // ── Error ────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Connection failed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {
              _step = _AaStep.explain;
              _error = null;
            }),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}