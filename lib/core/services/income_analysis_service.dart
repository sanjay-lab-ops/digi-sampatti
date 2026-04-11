import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';

// ─── Income Analysis Service (FinSelf Lite) ───────────────────────────────────
// Analyses bank statement data from Account Aggregator (AA) to produce:
//   • Average monthly income (from credit patterns)
//   • Existing EMI obligations (recurring debits)
//   • Disposable income
//   • Net worth estimate
//   • Home loan eligibility
//   • FinSelf Score (0–900)
//
// Data source: Account Aggregator (Finvu / Sahamati ecosystem)
//   Registration: sahamati.org.in → FIP entity registration (free)
//   Finvu sandbox: finvu.in/developer
//
// For production: replace mock data with real AA API calls.
// ──────────────────────────────────────────────────────────────────────────────

class FinancialProfile {
  final double averageMonthlyIncome;     // verified from bank credits
  final double existingEmiPerMonth;      // recurring debits identified as EMIs
  final double averageMonthlyExpenses;   // other regular debits
  final double disposableIncome;         // income - EMIs - expenses
  final double estimatedNetWorth;        // savings + investments estimate
  final double maxHomeLoanEligible;      // max loan at current income
  final double maxMonthlyEmi;            // max EMI bank will approve
  final int    finSelfScore;             // 0–900 composite score
  final String scoreCategory;            // Excellent / Good / Fair / Poor
  final List<IncomeSource> incomeSources;
  final List<EmiEntry> emis;
  final List<LoanProduct> eligibleLoans;
  final String analysisSummary;
  final DateTime analysedAt;

  const FinancialProfile({
    required this.averageMonthlyIncome,
    required this.existingEmiPerMonth,
    required this.averageMonthlyExpenses,
    required this.disposableIncome,
    required this.estimatedNetWorth,
    required this.maxHomeLoanEligible,
    required this.maxMonthlyEmi,
    required this.finSelfScore,
    required this.scoreCategory,
    required this.incomeSources,
    required this.emis,
    required this.eligibleLoans,
    required this.analysisSummary,
    required this.analysedAt,
  });

  String get monthlyIncomeLabel   => _fmt(averageMonthlyIncome);
  String get disposableLabel      => _fmt(disposableIncome);
  String get maxLoanLabel         => _fmtL(maxHomeLoanEligible);
  String get netWorthLabel        => _fmtL(estimatedNetWorth);

  static String _fmt(double v) =>
      '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  static String _fmtL(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
    return _fmt(v);
  }
}

class IncomeSource {
  final String name;    // 'Salary', 'Trading', 'Rental', 'Dividend', etc.
  final double monthly;
  final String verified; // 'EPFO', 'AA', 'GST', 'Broker API', 'Bank credits'
  const IncomeSource(this.name, this.monthly, this.verified);
}

class EmiEntry {
  final String lender;
  final double monthly;
  final String type;    // 'Home Loan', 'Personal Loan', 'Car Loan', etc.
  const EmiEntry(this.lender, this.monthly, this.type);
}

class LoanProduct {
  final String bankName;
  final double maxAmount;
  final double interestRate;
  final double emiFor20yr;
  final String approvalTime;
  final bool   preApproved;
  const LoanProduct({
    required this.bankName,
    required this.maxAmount,
    required this.interestRate,
    required this.emiFor20yr,
    required this.approvalTime,
    required this.preApproved,
  });
}

class IncomeAnalysisService {
  static final _instance = IncomeAnalysisService._();
  factory IncomeAnalysisService() => _instance;
  IncomeAnalysisService._();

  // ─── Analyse bank statement JSON from Account Aggregator ─────────────────
  // In production: receives real transaction data from Finvu/Sahamati AA
  // In sandbox:    uses the demo data passed here
  Future<FinancialProfile> analyseStatements({
    required List<Map<String, dynamic>> transactions,
    required String userName,
    double? tradingPnlMonthly,
    double? gstTurnoverMonthly,
    double? epfoSalaryMonthly,
  }) async {
    // ── Step 1: Extract income from credits ───────────────────────────────
    final credits = transactions
        .where((t) => (t['type'] as String? ?? '').toLowerCase() == 'credit'
            || (t['amount'] as num? ?? 0) > 0)
        .toList();

    final debits = transactions
        .where((t) => (t['type'] as String? ?? '').toLowerCase() == 'debit'
            || (t['amount'] as num? ?? 0) < 0)
        .toList();

    // Group by month, average credits
    double avgMonthlyCredits = _averageMonthly(credits);

    // ── Step 2: Identify EMIs (recurring debits of similar amount) ─────────
    final detectedEmis = _detectEmis(debits);
    final totalEmiPerMonth = detectedEmis.fold(0.0, (s, e) => s + e.monthly);

    // ── Step 3: Other expenses ────────────────────────────────────────────
    double avgDebits = _averageMonthly(debits).abs();
    double otherExpenses = (avgDebits - totalEmiPerMonth).clamp(0.0, double.infinity);

    // ── Step 4: Add verified income sources ───────────────────────────────
    final sources = <IncomeSource>[];
    if (epfoSalaryMonthly != null && epfoSalaryMonthly > 0) {
      sources.add(IncomeSource('Salary', epfoSalaryMonthly, 'EPFO Verified'));
      avgMonthlyCredits = avgMonthlyCredits.clamp(epfoSalaryMonthly, double.infinity);
    }
    if (tradingPnlMonthly != null && tradingPnlMonthly > 0) {
      sources.add(IncomeSource('Trading P&L', tradingPnlMonthly, 'Broker API'));
      avgMonthlyCredits += tradingPnlMonthly;
    }
    if (gstTurnoverMonthly != null && gstTurnoverMonthly > 0) {
      final businessIncome = gstTurnoverMonthly * 0.25; // 25% profit margin estimate
      sources.add(IncomeSource('Business Income', businessIncome, 'GST Verified'));
      avgMonthlyCredits += businessIncome;
    }
    if (sources.isEmpty) {
      sources.add(IncomeSource('Bank Credits', avgMonthlyCredits, 'AA Bank Statement'));
    }

    // ── Step 5: Disposable income ─────────────────────────────────────────
    final disposable = avgMonthlyCredits - totalEmiPerMonth - otherExpenses;

    // ── Step 6: Loan eligibility ──────────────────────────────────────────
    // Banks allow 40-50% of gross income as total EMI
    // Max new EMI = 50% income - existing EMIs
    final maxNewEmi = (avgMonthlyCredits * 0.50) - totalEmiPerMonth;
    // Max loan at 8.5% for 20 years: EMI = Loan × 0.00868
    final maxLoan = maxNewEmi > 0 ? (maxNewEmi / 0.00868) : 0.0;

    // ── Step 7: FinSelf Score ─────────────────────────────────────────────
    int score = 500; // base
    if (avgMonthlyCredits > 100000) score += 100;
    else if (avgMonthlyCredits > 50000) score += 60;
    else if (avgMonthlyCredits > 30000) score += 30;
    if (totalEmiPerMonth / avgMonthlyCredits < 0.3) score += 80; // low debt
    else if (totalEmiPerMonth / avgMonthlyCredits < 0.5) score += 40;
    if (transactions.length > 100) score += 50; // active account
    if (sources.any((s) => s.verified == 'EPFO Verified')) score += 80;
    if (tradingPnlMonthly != null && tradingPnlMonthly > 0) score += 40;
    score = score.clamp(300, 900);

    String category;
    if (score >= 750) category = 'Excellent';
    else if (score >= 650) category = 'Good';
    else if (score >= 550) category = 'Fair';
    else category = 'Poor';

    // ── Step 8: Eligible loan products ───────────────────────────────────
    final loans = _buildLoanProducts(maxLoan, avgMonthlyCredits, score);

    // ── Step 9: AI summary ────────────────────────────────────────────────
    final summary = await _generateSummary(
      name: userName,
      income: avgMonthlyCredits,
      emis: totalEmiPerMonth,
      disposable: disposable,
      maxLoan: maxLoan,
      score: score,
    );

    final netWorth = (avgMonthlyCredits * 24) * 0.3; // rough estimate

    return FinancialProfile(
      averageMonthlyIncome:   avgMonthlyCredits,
      existingEmiPerMonth:    totalEmiPerMonth,
      averageMonthlyExpenses: otherExpenses,
      disposableIncome:       disposable,
      estimatedNetWorth:      netWorth,
      maxHomeLoanEligible:    maxLoan,
      maxMonthlyEmi:          maxNewEmi.clamp(0, double.infinity),
      finSelfScore:           score,
      scoreCategory:          category,
      incomeSources:          sources,
      emis:                   detectedEmis,
      eligibleLoans:          loans,
      analysisSummary:        summary,
      analysedAt:             DateTime.now(),
    );
  }

  // ─── Detect recurring EMI-like debits ────────────────────────────────────
  List<EmiEntry> _detectEmis(List<Map<String, dynamic>> debits) {
    final emis = <EmiEntry>[];
    // Group debits by narration keywords that suggest EMI
    for (final d in debits) {
      final narration = (d['narration'] ?? d['description'] ?? '').toString().toUpperCase();
      final amount = (d['amount'] as num? ?? 0).abs().toDouble();
      if (amount < 1000) continue; // skip small transactions

      if (narration.contains('EMI') || narration.contains('LOAN') ||
          narration.contains('HOUSING') || narration.contains('MORTGAGE')) {
        final lender = _extractLenderName(narration);
        final type = narration.contains('HOUSING') || narration.contains('HOME')
            ? 'Home Loan'
            : narration.contains('CAR') || narration.contains('AUTO')
            ? 'Car Loan' : 'Loan EMI';
        emis.add(EmiEntry(lender, amount, type));
      }
    }
    return emis;
  }

  String _extractLenderName(String narration) {
    for (final bank in ['HDFC', 'SBI', 'ICICI', 'AXIS', 'KOTAK', 'BAJAJ',
      'TATA', 'IDFC', 'YES BANK', 'CANARA', 'UNION', 'PNB']) {
      if (narration.contains(bank)) return bank;
    }
    return 'Bank/NBFC';
  }

  double _averageMonthly(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) return 0;
    final total = transactions.fold(0.0,
        (s, t) => s + (t['amount'] as num? ?? 0).abs().toDouble());
    // Assume 6 months of data
    return total / 6;
  }

  List<LoanProduct> _buildLoanProducts(double maxLoan, double income, int score) {
    if (maxLoan <= 0) return [];
    return [
      LoanProduct(
        bankName: 'HDFC Bank',
        maxAmount: maxLoan,
        interestRate: score > 750 ? 8.40 : 8.75,
        emiFor20yr: maxLoan * 0.00868,
        approvalTime: '24 hours',
        preApproved: score > 720,
      ),
      LoanProduct(
        bankName: 'SBI',
        maxAmount: maxLoan * 0.9,
        interestRate: score > 750 ? 8.50 : 9.00,
        emiFor20yr: maxLoan * 0.9 * 0.00868,
        approvalTime: '3–5 days',
        preApproved: false,
      ),
      LoanProduct(
        bankName: 'ICICI Bank',
        maxAmount: maxLoan,
        interestRate: score > 750 ? 8.60 : 8.90,
        emiFor20yr: maxLoan * 0.00868,
        approvalTime: '48 hours',
        preApproved: score > 700,
      ),
      LoanProduct(
        bankName: 'Axis Bank',
        maxAmount: maxLoan * 0.95,
        interestRate: 8.75,
        emiFor20yr: maxLoan * 0.95 * 0.00868,
        approvalTime: '48 hours',
        preApproved: false,
      ),
    ];
  }

  Future<String> _generateSummary({
    required String name,
    required double income,
    required double emis,
    required double disposable,
    required double maxLoan,
    required int score,
  }) async {
    // Try Claude for richer explanation
    try {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      if (apiKey.isEmpty) return _defaultSummary(income, maxLoan, score);

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.claudeBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));

      final resp = await dio.post('/messages',
        options: Options(headers: ApiConstants.claudeHeaders(apiKey)),
        data: jsonEncode({
          'model': ApiConstants.claudeModel,
          'max_tokens': 200,
          'messages': [{
            'role': 'user',
            'content':
              'Financial profile summary for an Indian property buyer. '
              'Monthly income: ₹${income.toStringAsFixed(0)}. '
              'Existing EMIs: ₹${emis.toStringAsFixed(0)}/month. '
              'Disposable income: ₹${disposable.toStringAsFixed(0)}/month. '
              'Max home loan eligible: ₹${(maxLoan/100000).toStringAsFixed(1)} lakhs. '
              'FinSelf Score: $score/900. '
              'Write 2 sentences for a first-time buyer: what this means for their home loan. Plain language, no jargon.',
          }],
        }),
      );

      if (resp.statusCode == 200) {
        final content = resp.data['content'] as List;
        return (content.first['text'] as String).trim();
      }
    } catch (_) {}

    return _defaultSummary(income, maxLoan, score);
  }

  String _defaultSummary(double income, double maxLoan, int score) {
    final loanL = (maxLoan / 100000).toStringAsFixed(1);
    final incomeK = (income / 1000).toStringAsFixed(0);
    return 'Based on your verified monthly income of ₹${incomeK}K, you are eligible for a home loan up to ₹$loanL lakhs. '
        'Your FinSelf Score of $score/900 qualifies you for preferential interest rates from HDFC Bank and ICICI Bank.';
  }
}
