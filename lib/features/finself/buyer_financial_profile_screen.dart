import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/income_analysis_service.dart';

// ─── Buyer Financial Profile Screen ──────────────────────────────────────────
// Shows the output of FinSelf Lite analysis:
//   • FinSelf Score 0–900
//   • Verified monthly income
//   • Existing EMIs
//   • Disposable income
//   • Max home loan eligible
//   • Which banks will approve + at what rate
//   • How to apply (one tap to each bank)
//
// This screen + the Arth ID property risk report together form the
// complete "buyer + property" package sent to banks.
// ──────────────────────────────────────────────────────────────────────────────

class BuyerFinancialProfileScreen extends ConsumerWidget {
  final FinancialProfile profile;
  const BuyerFinancialProfileScreen({super.key, required this.profile});

  Color get _scoreColor {
    if (profile.finSelfScore >= 750) return AppColors.emerald;
    if (profile.finSelfScore >= 650) return const Color(0xFF1a6dff);
    if (profile.finSelfScore >= 550) return Colors.orange.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Financial Profile'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProfile(context),
            tooltip: 'Share with bank',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 16),
            _buildIncomeBreakdown(),
            const SizedBox(height: 16),
            if (profile.emis.isNotEmpty) ...[
              _buildEmiSection(),
              const SizedBox(height: 16),
            ],
            _buildLoanEligibility(),
            const SizedBox(height: 16),
            _buildBankProducts(context),
            const SizedBox(height: 16),
            _buildCombinedPackage(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── FinSelf Score Card ─────────────────────────────────────────────────────
  Widget _buildScoreCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _scoreColor.withOpacity(0.85),
          _scoreColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('FinSelf Score',
                style: TextStyle(color: Colors.white70,
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${profile.finSelfScore}',
          style: const TextStyle(
              color: Colors.white, fontSize: 64,
              fontWeight: FontWeight.w900, height: 1),
        ),
        Text('/ 900 — ${profile.scoreCategory}',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 16),
        // Score bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: profile.finSelfScore / 900,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        // 3 key numbers
        Row(children: [
          _miniStat('Monthly Income', profile.monthlyIncomeLabel),
          _vDivider(),
          _miniStat('Max Loan', profile.maxLoanLabel),
          _vDivider(),
          _miniStat('Net Worth ~', profile.netWorthLabel),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            profile.analysisSummary,
            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _miniStat(String label, String value) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  );

  Widget _vDivider() => Container(
      width: 1, height: 28,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  // ── Income Breakdown ───────────────────────────────────────────────────────
  Widget _buildIncomeBreakdown() => _card(
    title: 'Verified Income',
    icon: Icons.account_balance_wallet_outlined,
    color: AppColors.emerald,
    child: Column(children: [
      ...profile.incomeSources.map((s) => _row(
        s.name,
        _fmt(s.monthly),
        sub: s.verified,
        color: AppColors.emerald,
      )),
      const Divider(height: 20),
      _row('Total Monthly Income', profile.monthlyIncomeLabel,
          bold: true, color: AppColors.emerald),
      _row('Existing EMIs', '-${_fmt(profile.existingEmiPerMonth)}',
          color: Colors.orange),
      _row('Regular Expenses', '-${_fmt(profile.averageMonthlyExpenses)}',
          color: Colors.grey),
      const Divider(height: 12),
      _row('Disposable Income', profile.disposableLabel,
          bold: true, color: const Color(0xFF1a6dff)),
    ]),
  );

  // ── EMI Section ────────────────────────────────────────────────────────────
  Widget _buildEmiSection() => _card(
    title: 'Current Loan EMIs',
    icon: Icons.credit_card_outlined,
    color: Colors.orange.shade700,
    child: Column(
      children: [
        ...profile.emis.map((e) => _row(
          '${e.lender} (${e.type})',
          _fmt(e.monthly),
          color: Colors.orange.shade700,
        )),
        const Divider(height: 16),
        _row('Total EMIs/month', _fmt(profile.existingEmiPerMonth),
            bold: true, color: Colors.orange.shade700),
      ],
    ),
  );

  // ── Loan Eligibility ───────────────────────────────────────────────────────
  Widget _buildLoanEligibility() => _card(
    title: 'Home Loan Eligibility',
    icon: Icons.home_outlined,
    color: const Color(0xFF1a6dff),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1a6dff).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You are eligible for a home loan up to:',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(profile.maxLoanLabel,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: Color(0xFF1a6dff))),
              Text(
                'Based on your income of ${profile.monthlyIncomeLabel}/month\n'
                'EMI capacity: ${_fmt(profile.maxMonthlyEmi)}/month (50% of income)',
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'How this is calculated:\n'
          '• Max EMI = 50% of monthly income (bank norm)\n'
          '• Less your existing EMIs = available EMI for new loan\n'
          '• Max loan = available EMI ÷ 0.00868 (HDFC 8.4%, 20 years)',
          style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.6),
        ),
      ],
    ),
  );

  // ── Bank Products ──────────────────────────────────────────────────────────
  Widget _buildBankProducts(BuildContext context) => _card(
    title: 'Banks That Will Approve You',
    icon: Icons.account_balance_outlined,
    color: AppColors.arthBlue,
    child: Column(children: [
      ...profile.eligibleLoans.map((loan) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: loan.preApproved
              ? AppColors.emerald.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: loan.preApproved
                ? AppColors.emerald.withOpacity(0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(loan.bankName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              if (loan.preApproved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  child: const Text('PRE-APPROVED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                          color: AppColors.emerald)),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _loanStat('Up to', _fmtL(loan.maxAmount)),
              _loanStat('Rate', '${loan.interestRate}%'),
              _loanStat('EMI/mo', _fmt(loan.emiFor20yr)),
              _loanStat('Time', loan.approvalTime),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _applyToBank(context, loan.bankName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.arthBlue,
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: AppColors.arthBlue),
                ),
                child: Text('Apply to ${loan.bankName} →',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      )),
    ]),
  );

  Widget _loanStat(String label, String value) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 12)),
      Text(label, style: const TextStyle(
          fontSize: 10, color: Colors.black45)),
    ]),
  );

  // ── Combined Package (Arth ID + FinSelf) ─────────────────────────────
  Widget _buildCombinedPackage(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF0a1628), Color(0xFF0b3d8e)]),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.star_outlined, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Text('Send Combined Package to Bank',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Arth ID Property Report + FinSelf Financial Profile = '
          'bank gets everything in one package. '
          'Faster approval. Better rate. No more document follow-ups.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _packageTag('Property Risk: Verified', AppColors.emerald)),
          const SizedBox(width: 8),
          Expanded(child: _packageTag('Buyer Score: ${profile.finSelfScore}/900', Colors.amber)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _shareProfile(context),
            icon: const Icon(Icons.share),
            label: const Text('Share Package with Bank'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0b3d8e),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _packageTag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
        textAlign: TextAlign.center),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(14), child: child),
    ]),
  );

  Widget _row(String label, String value, {
    bool bold = false, Color? color, String? sub}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
                fontSize: 13, color: Colors.black54)),
            if (sub != null)
              Text(sub, style: const TextStyle(
                  fontSize: 10, color: Colors.black38)),
          ],
        )),
        Text(value, style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color)),
      ]),
    );

  String _fmt(double v) => '₹${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _fmtL(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)}L';
    return _fmt(v);
  }

  Future<void> _applyToBank(BuildContext context, String bankName) async {
    final urls = {
      'HDFC Bank':  'https://www.hdfcbank.com/personal/borrow/popular-loans/home-loan',
      'SBI':        'https://homeloans.sbi/products/view/regular-home-loan',
      'ICICI Bank': 'https://www.icicibank.com/personal-banking/loans/home-loan',
      'Axis Bank':  'https://www.axisbank.com/retail/loans/home-loan',
    };
    final url = urls[bankName] ?? 'https://google.com/search?q=$bankName+home+loan+apply';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareProfile(BuildContext context) async {
    final text =
        'FinSelf Financial Profile\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━\n'
        'FinSelf Score: ${profile.finSelfScore}/900 (${profile.scoreCategory})\n'
        'Verified Monthly Income: ${profile.monthlyIncomeLabel}\n'
        'Existing EMIs: ${_fmt(profile.existingEmiPerMonth)}/month\n'
        'Disposable Income: ${profile.disposableLabel}/month\n'
        'Max Home Loan Eligible: ${profile.maxLoanLabel}\n\n'
        'Top Matches:\n'
        '${profile.eligibleLoans.take(2).map((l) => '• ${l.bankName}: ${_fmtL(l.maxAmount)} @ ${l.interestRate}%').join('\n')}\n\n'
        'Generated by Arth ID + FinSelf Lite\n'
        'Property verified + Buyer eligible = faster loan approval';
    await Share.share(text, subject: 'My Financial Profile — Home Loan Application');
  }
}
