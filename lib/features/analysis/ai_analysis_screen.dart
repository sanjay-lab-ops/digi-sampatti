import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/widgets/common_widgets.dart';

class AiAnalysisScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? recordData;
  const AiAnalysisScreen({super.key, this.recordData});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  Future<void> _runAnalysis() async {
    _navigated = false;
    await ref.read(propertyCheckNotifierProvider.notifier).runAnalysisAndGenerateReport();
  }

  @override
  Widget build(BuildContext context) {
    final asyncReport = ref.watch(propertyCheckNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Legal Analysis')),
      body: asyncReport.when(
        loading: () => _LoadingAnalysisView(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: _runAnalysis,
        ),
        data: (report) {
          if (report == null) return _LoadingAnalysisView();
          // Auto-navigate once only
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.push('/report', extra: report.toJson());
            });
          }
          return _LoadingAnalysisView();
        },
      ),
    );
  }
}

// ─── Loading View ──────────────────────────────────────────────────────────────
class _LoadingAnalysisView extends StatefulWidget {
  @override
  State<_LoadingAnalysisView> createState() => _LoadingAnalysisViewState();
}

class _LoadingAnalysisViewState extends State<_LoadingAnalysisView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _stepIndex = 0;

  static const steps = [
    'Connecting to Bhoomi portal...',
    'Fetching RTC records...',
    'Checking encumbrances (EC)...',
    'Verifying RERA registration...',
    'Checking BDA/BBMP jurisdiction...',
    'Scanning for government notices...',
    'Checking Raja Kaluve buffer zone...',
    'Verifying lake bed restrictions...',
    'Running Claude AI analysis...',
    'Generating risk score...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _cycleSteps();
  }

  void _cycleSteps() async {
    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _stepIndex = i);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Legal Analysis',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'re carefully checking everything for you.\nThis takes about 10 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              backgroundColor: AppColors.borderColor,
              color: AppColors.primary,
              value: (_stepIndex + 1) / steps.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                steps[_stepIndex],
                key: ValueKey(_stepIndex),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analysis Result View ──────────────────────────────────────────────────────
class _AnalysisResultView extends StatelessWidget {
  final LegalReport report;
  final VoidCallback onGenerateReport;

  const _AnalysisResultView({required this.report, required this.onGenerateReport});

  @override
  Widget build(BuildContext context) {
    final assessment = report.riskAssessment;
    final score = assessment.score;
    final color = score >= 70 ? AppColors.safe
        : score >= 40 ? AppColors.warning
        : AppColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Risk Score Circle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 12,
                  percent: score / 100,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$score', style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: color,
                      )),
                      const Text('/100', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                  progressColor: color,
                  backgroundColor: AppColors.borderColor,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 16),
                Text(assessment.level.displayName, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color,
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    assessment.recommendation,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bank Loan: ${assessment.isBankLoanEligible ? "ELIGIBLE ✓" : "NOT ELIGIBLE ✗"}',
                  style: TextStyle(
                    color: assessment.isBankLoanEligible ? AppColors.safe : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary
          _AnalysisCard(
            title: 'Analysis Summary',
            icon: Icons.summarize,
            child: Text(assessment.summary, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 12),

          // ── Legal Flags
          _AnalysisCard(
            title: 'What We Found',
            icon: Icons.find_in_page_outlined,
            child: Column(
              children: assessment.flags.map((f) => _FlagTile(flag: f)).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Positives
          if (assessment.positives.isNotEmpty) ...[
            _AnalysisCard(
              title: 'Good Signs',
              icon: Icons.thumb_up_outlined,
              child: Column(
                children: assessment.positives.map((p) => _BulletItem(
                  text: p, color: AppColors.safe, icon: Icons.check_circle,
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Concerns
          if (assessment.concerns.isNotEmpty) ...[
            _AnalysisCard(
              title: 'Points to Verify Before Buying',
              icon: Icons.checklist_rtl_outlined,
              child: Column(
                children: assessment.concerns.map((c) => _BulletItem(
                  text: c, color: AppColors.warning, icon: Icons.warning_amber,
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Action Items
          _AnalysisCard(
            title: 'Your Next Steps',
            icon: Icons.checklist,
            child: Column(
              children: assessment.actionItems.asMap().entries.map((e) =>
                _BulletItem(
                  text: '${e.key + 1}. ${e.value}',
                  color: AppColors.info,
                  icon: Icons.task_alt,
                )).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Generate Report Button
          ElevatedButton.icon(
            onPressed: onGenerateReport,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate Full PDF Report — ₹99'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete legal report with all records and AI analysis',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _AnalysisCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final LegalFlag flag;
  const _FlagTile({required this.flag});

  @override
  Widget build(BuildContext context) {
    final color = flag.status == FlagStatus.clear ? AppColors.safe
        : flag.status == FlagStatus.warning ? AppColors.warning
        : flag.status == FlagStatus.danger ? AppColors.danger
        : AppColors.textMedium;

    final bg = flag.status == FlagStatus.clear ? AppColors.statusClearBg
        : flag.status == FlagStatus.warning ? AppColors.statusWarningBg
        : flag.status == FlagStatus.danger ? AppColors.statusDangerBg
        : AppColors.dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                flag.status == FlagStatus.clear ? Icons.check_circle_outline
                    : Icons.info_outline,
                color: color, size: 18,
              ),
              const SizedBox(width: 6),
              Text('[${flag.category}]', style: TextStyle(color: color, fontSize: 11)),
              const SizedBox(width: 4),
              Expanded(child: Text(flag.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Text(flag.details, style: const TextStyle(fontSize: 12, height: 1.4)),
          if (flag.actionRequired != null) ...[
            const SizedBox(height: 4),
            Text('→ ${flag.actionRequired}',
                style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _BulletItem({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text('Analysis Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
