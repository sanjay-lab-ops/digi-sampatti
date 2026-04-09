import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/features/portal_checklist/portal_checklist_screen.dart';

class AiAnalysisScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? recordData;
  const AiAnalysisScreen({super.key, this.recordData});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  Future<void> _runAnalysis() async {
    // Pass the real portal findings collected by the user in the checklist
    final findings = ref.read(portalFindingsProvider);
    await ref.read(propertyCheckNotifierProvider.notifier)
        .runAnalysisAndGenerateReport(portalFindings: findings);
  }

  @override
  Widget build(BuildContext context) {
    final asyncReport = ref.watch(propertyCheckNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Legal Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: asyncReport.when(
        loading: () => const _PortalScanningView(),
        error: (e, _) => _ErrorView(message: e.toString(), onRetry: _runAnalysis),
        data: (report) {
          if (report == null) return const _PortalScanningView();
          return _AnalysisResultView(
            report: report,
            onViewFullReport: () => context.push('/report'),
          );
        },
      ),
    );
  }
}

// ─── Portal Scanning Animation ─────────────────────────────────────────────────
class _PortalScanningView extends StatefulWidget {
  const _PortalScanningView();

  @override
  State<_PortalScanningView> createState() => _PortalScanningViewState();
}

class _PortalScanningViewState extends State<_PortalScanningView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _doneCount = 0;

  static const _portals = [
    _Portal('Bhoomi Karnataka', 'Fetching RTC / Land Records', Icons.article_outlined, Color(0xFF1B5E20)),
    _Portal('Kaveri Online (IGRS)', 'Checking Encumbrance Certificate', Icons.account_balance_outlined, Color(0xFF0D47A1)),
    _Portal('RERA Karnataka', 'Verifying builder registration', Icons.business_outlined, Color(0xFF4A148C)),
    _Portal('BDA / BBMP Records', 'Checking jurisdiction & approvals', Icons.location_city_outlined, Color(0xFF37474F)),
    _Portal('eCourts India', 'Scanning for active litigation', Icons.gavel_outlined, Color(0xFFBF360C)),
    _Portal('CERSAI Registry', 'Checking registered mortgages', Icons.lock_outline, Color(0xFF1565C0)),
    _Portal('Claude AI Analysis', 'Running deep legal analysis...', Icons.psychology_outlined, Color(0xFF5E35B1)),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _simulateProgress();
  }

  void _simulateProgress() async {
    for (int i = 0; i < _portals.length; i++) {
      await Future.delayed(Duration(milliseconds: 1000 + i * 300));
      if (mounted) setState(() => _doneCount = i + 1);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _portals.isEmpty ? 0.0 : _doneCount / _portals.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1 + 0.06 * _pulse.value),
              ),
              child: const Icon(Icons.security, color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Scanning 7 Government Portals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'We check every database so you don\'t have to',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMedium, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.borderColor,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text('$_doneCount / ${_portals.length} portals checked',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 20),
          ..._portals.asMap().entries.map((entry) {
            final i = entry.key;
            final portal = entry.value;
            final isDone = i < _doneCount;
            final isActive = i == _doneCount;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDone ? AppColors.statusClearBg : isActive ? Colors.white : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDone ? AppColors.safe : isActive ? portal.color : AppColors.borderColor,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.safe.withOpacity(0.15)
                          : portal.color.withOpacity(isDone || isActive ? 0.12 : 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: isDone
                        ? const Icon(Icons.check_circle, color: AppColors.safe, size: 22)
                        : isActive
                            ? Padding(
                                padding: const EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: portal.color),
                              )
                            : Icon(portal.icon, color: Colors.grey.shade400, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(portal.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDone ? AppColors.safe : isActive ? portal.color : AppColors.textMedium,
                            )),
                        Text(
                          isDone ? 'Completed ✓' : portal.subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDone ? AppColors.safe : AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Portal {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Portal(this.name, this.subtitle, this.icon, this.color);
}

// ─── Analysis Result View ──────────────────────────────────────────────────────
class _AnalysisResultView extends StatelessWidget {
  final LegalReport report;
  final VoidCallback onViewFullReport;

  const _AnalysisResultView({required this.report, required this.onViewFullReport});

  @override
  Widget build(BuildContext context) {
    final a = report.riskAssessment;
    final score = a.score;
    final color = score >= 70 ? AppColors.safe : score >= 40 ? AppColors.warning : AppColors.danger;
    final icon = score >= 70 ? Icons.check_circle : score >= 40 ? Icons.warning_amber : Icons.cancel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Verdict Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 48),
                const SizedBox(height: 8),
                Text(a.recommendation,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Pill('Risk Score', '$score/100', color),
                    const SizedBox(width: 12),
                    _Pill(
                      'Bank Loan',
                      a.isBankLoanEligible ? 'ELIGIBLE ✓' : 'NOT ELIGIBLE ✗',
                      a.isBankLoanEligible ? AppColors.safe : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(a.summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMedium, height: 1.5, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── What You SHOULD DO (positives = good signs)
          if (a.positives.isNotEmpty)
            _Section(
              title: '✅  What You Should DO',
              color: AppColors.safe,
              bgColor: AppColors.statusClearBg,
              items: a.positives,
              icon: Icons.check_circle_outline,
            ),
          const SizedBox(height: 12),

          // ── What You Should NOT DO (concerns)
          if (a.concerns.isNotEmpty)
            _Section(
              title: '🚫  What You Should NOT DO',
              color: AppColors.danger,
              bgColor: AppColors.statusDangerBg,
              items: a.concerns,
              icon: Icons.cancel_outlined,
            ),
          const SizedBox(height: 12),

          // ── Next Steps (actionItems — distinct from positives/concerns)
          if (a.actionItems.isNotEmpty && a.actionItems.any(
              (i) => !a.positives.contains(i) && !a.concerns.contains(i)))
            _Section(
              title: '📋  Your Action Steps',
              color: AppColors.primary,
              bgColor: const Color(0xFFE8F5E9),
              items: a.actionItems.where(
                (i) => !a.positives.contains(i) && !a.concerns.contains(i)
              ).toList(),
              icon: Icons.arrow_forward_ios,
            ),
          const SizedBox(height: 12),

          // ── Detailed Flags
          if (a.flags.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.find_in_page_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Detailed Findings',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const Divider(height: 16),
                    ...a.flags.map((f) => _FlagTile(flag: f)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── CTA — Full Report
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Download Full Legal Report',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('PDF with all records — share with lawyer, bank, or family.',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('₹149',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('one-time · instant', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onViewFullReport,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Get Full Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Pill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final Color bgColor;
  final List<String> items;
  final IconData icon;

  const _Section({
    required this.title,
    required this.color,
    required this.bgColor,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final LegalFlag flag;
  const _FlagTile({required this.flag});

  @override
  Widget build(BuildContext context) {
    final color = flag.status == FlagStatus.clear
        ? AppColors.safe
        : flag.status == FlagStatus.warning
            ? AppColors.warning
            : flag.status == FlagStatus.danger
                ? AppColors.danger
                : AppColors.textMedium;

    final bg = flag.status == FlagStatus.clear
        ? AppColors.statusClearBg
        : flag.status == FlagStatus.warning
            ? AppColors.statusWarningBg
            : flag.status == FlagStatus.danger
                ? AppColors.statusDangerBg
                : AppColors.dividerColor;

    final icon = flag.status == FlagStatus.clear
        ? Icons.check_circle_outline
        : flag.status == FlagStatus.danger
            ? Icons.cancel_outlined
            : Icons.warning_amber_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text('[${flag.category}]', style: TextStyle(color: color, fontSize: 10)),
            const SizedBox(width: 4),
            Expanded(child: Text(flag.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13))),
          ]),
          const SizedBox(height: 4),
          Text(flag.details, style: const TextStyle(fontSize: 12, height: 1.4)),
          if (flag.actionRequired != null) ...[
            const SizedBox(height: 4),
            Text('→ ${flag.actionRequired}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
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
            const Text('Analysis Failed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: AppColors.textMedium),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
