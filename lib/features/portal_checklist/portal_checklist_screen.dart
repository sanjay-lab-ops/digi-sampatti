import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/portal_findings_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

// ─── Portal Checklist Screen ───────────────────────────────────────────────────
// Guides user through checking each government portal.
// After each portal: asks 2-3 simple tap questions (no typing).
// All answers feed into AI analysis — no simulated data.
// ──────────────────────────────────────────────────────────────────────────────

final portalFindingsProvider =
    StateProvider<PortalFindings>((ref) => const PortalFindings());

class PortalChecklistScreen extends ConsumerStatefulWidget {
  const PortalChecklistScreen({super.key});

  @override
  ConsumerState<PortalChecklistScreen> createState() =>
      _PortalChecklistScreenState();
}

class _PortalChecklistScreenState
    extends ConsumerState<PortalChecklistScreen> {
  // Which portal step is expanded for questions (null = none open)
  int? _openStep;
  // Which portals have had their portal opened (not yet answered)
  final Set<int> _portalOpened = {};

  static const _steps = [
    _PortalStep(
      index: 0,
      title: 'Bhoomi RTC',
      subtitle: 'Land Records — Ownership & Khata',
      icon: Icons.article_outlined,
      color: Color(0xFF1B5E20),
      portal: GovPortal.bhoomi,
      tip: 'Search with Survey No + District + Taluk. Look for Owner name, Khata type, and any remarks.',
    ),
    _PortalStep(
      index: 1,
      title: 'Kaveri IGRS',
      subtitle: 'Encumbrance Certificate — Loans & Sales',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF0D47A1),
      portal: GovPortal.kaveri,
      tip: 'Search EC for last 15–30 years. Look for any mortgage, loan, or multiple sale entries.',
    ),
    _PortalStep(
      index: 2,
      title: 'RERA Karnataka',
      subtitle: 'Builder Registration (apartments only)',
      icon: Icons.business_outlined,
      color: Color(0xFF4A148C),
      portal: GovPortal.rera,
      tip: 'Search project name or builder name. Check if registration is Active and not expired.',
    ),
    _PortalStep(
      index: 3,
      title: 'eCourts India',
      subtitle: 'Active Court Cases & Litigation',
      icon: Icons.gavel_outlined,
      color: Color(0xFFBF360C),
      portal: GovPortal.eCourts,
      tip: 'Search by owner name. Check if any civil/criminal cases exist on this property.',
    ),
    _PortalStep(
      index: 4,
      title: 'BBMP Tax',
      subtitle: 'Property Tax & Municipal Records',
      icon: Icons.location_city_outlined,
      color: Color(0xFF004D40),
      portal: GovPortal.bbmp,
      tip: 'Enter PID or owner name. Check if property tax is paid and khata is in seller\'s name.',
    ),
    _PortalStep(
      index: 5,
      title: 'CERSAI',
      subtitle: 'Bank Mortgage Registry',
      icon: Icons.lock_outline,
      color: Color(0xFF37474F),
      portal: GovPortal.cersai,
      tip: 'Search by owner name or property address. Any active entry here means an unpaid bank loan.',
    ),
    _PortalStep(
      index: 6,
      title: 'FMB / Sketch Map',
      subtitle: 'Survey Map & Boundary Verification',
      icon: Icons.map_outlined,
      color: Color(0xFF1565C0),
      portal: GovPortal.dishank,
      tip: 'Search survey number to get the official plot boundary map. Compare with physical property.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final findings = ref.watch(portalFindingsProvider);
    final scan = ref.watch(currentScanProvider);
    final completed = _countCompleted(findings);
    final canAnalyse = completed >= 3; // at least 3 portals answered

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check Government Portals'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: completed / _steps.length,
            backgroundColor: AppColors.borderColor,
            color: AppColors.primary,
            minHeight: 6,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed of ${_steps.length} portals checked',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open each portal → look at the data → answer 2–3 taps. No typing needed.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Steps list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _steps.length,
              itemBuilder: (context, i) {
                final step = _steps[i];
                final isCompleted = _isStepCompleted(findings, i);
                final isOpen = _openStep == i;
                return _PortalCard(
                  step: step,
                  findings: findings,
                  isCompleted: isCompleted,
                  isOpen: isOpen,
                  portalOpened: _portalOpened.contains(i),
                  surveyNumber: scan?.surveyNumber,
                  district: scan?.district,
                  taluk: scan?.taluk,
                  onOpenPortal: () async {
                    setState(() => _portalOpened.add(i));
                    await GovPortalLauncher.open(
                      context,
                      step.portal,
                      surveyNumber: scan?.surveyNumber,
                      district: scan?.district,
                      taluk: scan?.taluk,
                    );
                    // After returning from portal, open the question card
                    if (mounted) setState(() => _openStep = i);
                  },
                  onToggle: () =>
                      setState(() => _openStep = isOpen ? null : i),
                  onAnswer: (updated) {
                    ref.read(portalFindingsProvider.notifier).state = updated;
                    // Auto-close and move to next
                    if (i < _steps.length - 1) {
                      setState(() => _openStep = null);
                    }
                  },
                  onSkip: () {
                    setState(() => _openStep = null);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canAnalyse)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Check at least 3 portals to run AI analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMedium),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canAnalyse
                      ? () => context.go('/analysis')
                      : null,
                  icon: const Icon(Icons.psychology_outlined, size: 18),
                  label: Text(
                    canAnalyse
                        ? 'Run AI Legal Analysis ($completed/${_steps.length} checked)'
                        : 'Check more portals first',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderColor,
                    disabledForegroundColor: AppColors.textMedium,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countCompleted(PortalFindings f) => _steps
      .where((s) => _isStepCompleted(f, s.index))
      .length;

  bool _isStepCompleted(PortalFindings f, int i) {
    switch (i) {
      case 0: return f.khataFound != null || f.bhoomiHasRemarks != null;
      case 1: return f.hasActiveLoan != null;
      case 2: return f.isApartmentProject != null;
      case 3: return f.hasCourtCases != null;
      case 4: return f.propertyTaxPaid != null;
      case 5: return f.hasBankCharge != null;
      case 6: return f.boundariesCorrect != null || f.fmbOpened != null;
      default: return false;
    }
  }
}

// ─── Portal Card ───────────────────────────────────────────────────────────────
class _PortalCard extends StatelessWidget {
  final _PortalStep step;
  final PortalFindings findings;
  final bool isCompleted;
  final bool isOpen;
  final bool portalOpened;
  final String? surveyNumber;
  final String? district;
  final String? taluk;
  final VoidCallback onOpenPortal;
  final VoidCallback onToggle;
  final void Function(PortalFindings) onAnswer;
  final VoidCallback onSkip;

  const _PortalCard({
    required this.step,
    required this.findings,
    required this.isCompleted,
    required this.isOpen,
    required this.portalOpened,
    required this.surveyNumber,
    required this.district,
    required this.taluk,
    required this.onOpenPortal,
    required this.onToggle,
    required this.onAnswer,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? step.color.withOpacity(0.4)
              : isOpen
                  ? step.color.withOpacity(0.6)
                  : AppColors.borderColor,
          width: isCompleted || isOpen ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: step.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? Icon(Icons.check_circle, color: step.color, size: 22)
                        : Icon(step.icon, color: step.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isCompleted
                                    ? step.color
                                    : AppColors.textDark)),
                        Text(step.subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMedium)),
                        if (isCompleted) ...[
                          const SizedBox(height: 3),
                          _buildSummary(),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMedium,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded: tip + open button + questions
          if (isOpen) ...[
            Divider(height: 1, color: AppColors.borderColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tip
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: step.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: step.color, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(step.tip,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textDark,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Open Portal button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOpenPortal,
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: Text(
                        portalOpened
                            ? 'Open ${step.title} Again'
                            : 'Open ${step.title} Portal',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step.color,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // Questions (only after portal was opened)
                  if (portalOpened) ...[
                    const SizedBox(height: 16),
                    Text('What did you see?',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    _buildQuestions(),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onSkip,
                      child: Text('Skip — Couldn\'t load this portal',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium)),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onSkip,
                      child: Text('Skip this portal',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final text = _getSummaryText();
    if (text == null) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.check, size: 11, color: step.color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 11,
                color: step.color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String? _getSummaryText() {
    switch (step.index) {
      case 0:
        if (findings.khataFound == KhataFound.aKhata) return 'A Khata ✓';
        if (findings.khataFound == KhataFound.bKhata) return 'B Khata ⚠';
        if (findings.khataFound == KhataFound.noKhata) return 'No Khata ✗';
        if (findings.bhoomiHasRemarks == false) return 'No remarks';
        if (findings.bhoomiHasRemarks == true) return 'Has remarks ⚠';
        return 'Checked';
      case 1:
        if (findings.hasActiveLoan == true) return 'Active loan found ✗';
        if (findings.hasActiveLoan == false) return 'No loans ✓';
        return 'Checked';
      case 2:
        if (findings.isApartmentProject == false) return 'N/A — Individual plot';
        if (findings.reraRegistered == true) return 'RERA registered ✓';
        if (findings.reraRegistered == false) return 'Not registered ✗';
        return 'Checked';
      case 3:
        if (findings.hasCourtCases == true) return 'Cases found ✗';
        if (findings.hasCourtCases == false) return 'No cases ✓';
        return 'Checked';
      case 4:
        if (findings.propertyTaxPaid == true) return 'Tax paid ✓';
        if (findings.propertyTaxPaid == false) return 'Tax dues pending ⚠';
        return 'Checked';
      case 5:
        if (findings.hasBankCharge == true) return 'Bank charge registered ✗';
        if (findings.hasBankCharge == false) return 'No charge ✓';
        return 'Checked';
      case 6:
        if (findings.boundariesCorrect == true) return 'Boundaries match ✓';
        if (findings.boundariesCorrect == false) return 'Boundaries mismatch ⚠';
        return 'Checked';
      default: return null;
    }
  }

  Widget _buildQuestions() {
    switch (step.index) {
      case 0: return _bhoomiQuestions();
      case 1: return _kaveriQuestions();
      case 2: return _reraQuestions();
      case 3: return _ecourtsQuestions();
      case 4: return _bbmpQuestions();
      case 5: return _cersaiQuestions();
      case 6: return _fmbQuestions();
      default: return const SizedBox.shrink();
    }
  }

  // ── Bhoomi questions ─────────────────────────────────────────────────────
  Widget _bhoomiQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(
          label: 'What Khata type did you see?',
          color: step.color,
          options: const [
            _Option('A Khata', Icons.check_circle, true),
            _Option('B Khata', Icons.warning_amber, false),
            _Option('No Khata', Icons.cancel, false),
            _Option("Couldn't see", Icons.help_outline, null),
          ],
          selected: switch (findings.khataFound) {
            KhataFound.aKhata => 0,
            KhataFound.bKhata => 1,
            KhataFound.noKhata => 2,
            KhataFound.notShown => 3,
            null => null,
          },
          onSelect: (i) => onAnswer(findings.copyWith(
            khataFound: [
              KhataFound.aKhata,
              KhataFound.bKhata,
              KhataFound.noKhata,
              KhataFound.notShown,
            ][i],
          )),
        ),
        // B Khata follow-up — critical: revenue site vs convertible
        if (findings.khataFound == KhataFound.bKhata) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 15),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'B Khata needs one more check — critical difference:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Question(
            label: 'Is this property in a BDA/BBMP APPROVED layout? (Look for Layout Plan number in Bhoomi)',
            color: Colors.orange[700]!,
            options: const [
              _Option('Yes — approved layout (has LP No.)', Icons.check_circle, true),
              _Option('No / Not clear — looks like revenue site', Icons.cancel, false),
              _Option("Couldn't determine", Icons.help_outline, null),
            ],
            selected: findings.isRevenueSite == false ? 0 : findings.isRevenueSite == true ? 1 : null,
            onSelect: (i) => onAnswer(findings.copyWith(isRevenueSite: i == 0 ? false : i == 1 ? true : null)),
          ),
        ],
        const SizedBox(height: 10),
        _Question(
          label: 'Any remarks or red text in the RTC?',
          color: step.color,
          options: const [
            _Option('Yes, remarks found', Icons.warning_amber, false),
            _Option('No remarks', Icons.check_circle, true),
            _Option("Couldn't check", Icons.help_outline, null),
          ],
          selected: findings.bhoomiHasRemarks == true
              ? 0
              : findings.bhoomiHasRemarks == false
                  ? 1
                  : null,
          onSelect: (i) => onAnswer(findings.copyWith(
              bhoomiHasRemarks: i == 0 ? true : i == 1 ? false : null)),
        ),
      ],
    );
  }

  // ── Kaveri questions ─────────────────────────────────────────────────────
  Widget _kaveriQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(
          label: 'Any active loan or mortgage in EC?',
          color: step.color,
          options: const [
            _Option('Yes — loan/mortgage found', Icons.warning_amber, false),
            _Option('No — clear title', Icons.check_circle, true),
            _Option("Couldn't search", Icons.help_outline, null),
          ],
          selected: findings.hasActiveLoan == true
              ? 0
              : findings.hasActiveLoan == false
                  ? 1
                  : null,
          onSelect: (i) => onAnswer(findings.copyWith(
              hasActiveLoan: i == 0 ? true : i == 1 ? false : null)),
        ),
        const SizedBox(height: 10),
        _Question(
          label: 'Multiple sales in last 3 years?',
          color: step.color,
          options: const [
            _Option('Yes — sold multiple times', Icons.warning_amber, false),
            _Option('No — stable', Icons.check_circle, true),
            _Option("Couldn't check", Icons.help_outline, null),
          ],
          selected: findings.multipleSales == true
              ? 0
              : findings.multipleSales == false
                  ? 1
                  : null,
          onSelect: (i) => onAnswer(findings.copyWith(
              multipleSales: i == 0 ? true : i == 1 ? false : null)),
        ),
      ],
    );
  }

  // ── RERA questions ───────────────────────────────────────────────────────
  Widget _reraQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(
          label: 'Are you buying an apartment / flat?',
          color: step.color,
          options: const [
            _Option('Yes — apartment / flat', Icons.apartment, null),
            _Option('No — independent plot / house', Icons.home_outlined, null),
          ],
          selected: findings.isApartmentProject == true
              ? 0
              : findings.isApartmentProject == false
                  ? 1
                  : null,
          onSelect: (i) {
            final isApt = i == 0;
            onAnswer(findings.copyWith(
                isApartmentProject: isApt,
                reraRegistered: isApt ? null : false));
          },
        ),
        if (findings.isApartmentProject == true) ...[
          const SizedBox(height: 10),
          _Question(
            label: 'Is the builder / project registered on RERA?',
            color: step.color,
            options: const [
              _Option('Yes — Active registration', Icons.check_circle, true),
              _Option('No — Not found', Icons.cancel, false),
              _Option('Expired registration', Icons.warning_amber, false),
            ],
            selected: findings.reraRegistered == true
                ? 0
                : findings.reraRegistered == false
                    ? 1
                    : null,
            onSelect: (i) => onAnswer(findings.copyWith(
                reraRegistered: i == 0 ? true : false)),
          ),
        ],
      ],
    );
  }

  // ── eCourts questions ────────────────────────────────────────────────────
  Widget _ecourtsQuestions() {
    return _Question(
      label: 'Any court cases found for this property / owner?',
      color: step.color,
      options: const [
        _Option('Yes — cases found', Icons.warning_amber, false),
        _Option('No — all clear', Icons.check_circle, true),
        _Option("Couldn't search", Icons.help_outline, null),
      ],
      selected: findings.hasCourtCases == true
          ? 0
          : findings.hasCourtCases == false
              ? 1
              : null,
      onSelect: (i) => onAnswer(findings.copyWith(
          hasCourtCases: i == 0 ? true : i == 1 ? false : null)),
    );
  }

  // ── BBMP questions ───────────────────────────────────────────────────────
  Widget _bbmpQuestions() {
    return _Question(
      label: 'Is property tax paid and khata in seller\'s name?',
      color: step.color,
      options: const [
        _Option('Yes — all clear', Icons.check_circle, true),
        _Option('No — dues or mismatch', Icons.warning_amber, false),
        _Option('Not in BBMP limits', Icons.help_outline, null),
      ],
      selected: findings.propertyTaxPaid == true
          ? 0
          : findings.propertyTaxPaid == false
              ? 1
              : null,
      onSelect: (i) => onAnswer(findings.copyWith(
          propertyTaxPaid: i == 0 ? true : i == 1 ? false : null)),
    );
  }

  // ── CERSAI questions ─────────────────────────────────────────────────────
  Widget _cersaiQuestions() {
    return _Question(
      label: 'Any registered bank charge or mortgage?',
      color: step.color,
      options: const [
        _Option('Yes — bank charge found', Icons.warning_amber, false),
        _Option('No — clear', Icons.check_circle, true),
        _Option("Couldn't search", Icons.help_outline, null),
      ],
      selected: findings.hasBankCharge == true
          ? 0
          : findings.hasBankCharge == false
              ? 1
              : null,
      onSelect: (i) => onAnswer(findings.copyWith(
          hasBankCharge: i == 0 ? true : i == 1 ? false : null)),
    );
  }

  // ── FMB questions ────────────────────────────────────────────────────────
  Widget _fmbQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(
          label: 'Could you view the FMB/Sketch map?',
          color: step.color,
          options: const [
            _Option('Yes — map loaded', Icons.check, null),
            _Option("Couldn't load", Icons.help_outline, null),
          ],
          selected: findings.fmbOpened == true ? 0 : findings.fmbOpened == false ? 1 : null,
          onSelect: (i) => onAnswer(findings.copyWith(fmbOpened: i == 0)),
        ),
        if (findings.fmbOpened == true) ...[
          const SizedBox(height: 10),
          _Question(
            label: 'Do the plot boundaries match the physical property?',
            color: step.color,
            options: const [
              _Option('Yes — boundaries match', Icons.check_circle, true),
              _Option('No — mismatch / encroachment', Icons.warning_amber, false),
              _Option("Couldn't verify", Icons.help_outline, null),
            ],
            selected: findings.boundariesCorrect == true
                ? 0
                : findings.boundariesCorrect == false
                    ? 1
                    : null,
            onSelect: (i) => onAnswer(findings.copyWith(
                boundariesCorrect: i == 0 ? true : i == 1 ? false : null)),
          ),
        ],
      ],
    );
  }
}

// ─── Question Widget ───────────────────────────────────────────────────────────
class _Question extends StatelessWidget {
  final String label;
  final Color color;
  final List<_Option> options;
  final int? selected;
  final void Function(int) onSelect;

  const _Question({
    required this.label,
    required this.color,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(options.length, (i) {
            final opt = options[i];
            final isSelected = selected == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isSelected
                          ? color
                          : AppColors.borderColor,
                      width: isSelected ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon,
                        size: 13,
                        color: isSelected ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(opt.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark)),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────────
class _PortalStep {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final GovPortal portal;
  final String tip;

  const _PortalStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.portal,
    required this.tip,
  });
}

class _Option {
  final String label;
  final IconData icon;
  final bool? isPositive; // true=green, false=red, null=neutral

  const _Option(this.label, this.icon, this.isPositive);
}
