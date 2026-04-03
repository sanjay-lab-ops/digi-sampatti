import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/karnataka_legal_rules.dart';
import 'package:digi_sampatti/features/portal_checklist/portal_checklist_screen.dart';

// ─── Next Steps Screen ────────────────────────────────────────────────────────
// Shown after AI analysis verdict.
// Tells user EXACTLY what to do next — step by step — based on what was found.
// Covers: conversion paths, loan process, lawyer connection, govt applications.
// ──────────────────────────────────────────────────────────────────────────────

class NextStepsScreen extends ConsumerWidget {
  const NextStepsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(currentReportProvider);
    final findings = ref.watch(portalFindingsProvider);
    final legalResult = KarnatakaLegalEngine().analyse(findings);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Next Steps')),
        body: const Center(child: Text('Run analysis first')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('What to Do Next'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Verdict banner
          _VerdictBanner(result: legalResult, report: report),
          const SizedBox(height: 16),

          // Conversion paths (if any)
          if (legalResult.conversionPaths.isNotEmpty) ...[
            _SectionHeader('Conversion / Remedy Path', Icons.autorenew, Colors.blue),
            ...legalResult.conversionPaths.map((path) => _InfoCard(
                  text: path,
                  color: Colors.blue,
                  icon: Icons.route_outlined,
                )),
            const SizedBox(height: 16),
          ],

          // Rulings — one card per issue
          if (legalResult.rulings.isNotEmpty) ...[
            _SectionHeader('Issues Found & What to Do', Icons.gavel, Colors.orange),
            ...legalResult.rulings.map((r) => _RulingCard(ruling: r)),
            const SizedBox(height: 16),
          ],

          // What to DO
          _SectionHeader('What YOU Must DO', Icons.check_circle_outline, AppColors.primary),
          ...legalResult.whatToDo.take(8).map((item) => _ActionItem(
                text: item,
                isPositive: true,
              )),
          const SizedBox(height: 16),

          // What NOT to DO
          _SectionHeader('What You Must NOT DO', Icons.cancel_outlined, Colors.red),
          ...legalResult.whatNotToDo.take(6).map((item) => _ActionItem(
                text: item,
                isPositive: false,
              )),
          const SizedBox(height: 16),

          // Stamp duty & registration info
          _StampDutyCard(info: legalResult.stampDutyInfo),
          const SizedBox(height: 16),

          // Registration process
          _RegistrationCard(info: legalResult.registrationInfo),
          const SizedBox(height: 16),

          // Connect to experts
          _ExpertHelpCard(),
          const SizedBox(height: 16),

          // View full report
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/report'),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View / Download Full Report',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Verdict Banner ───────────────────────────────────────────────────────────
class _VerdictBanner extends StatelessWidget {
  final KarnatakaLegalResult result;
  final LegalReport report;

  const _VerdictBanner({required this.result, required this.report});

  @override
  Widget build(BuildContext context) {
    final color = result.verdict == 'SAFE'
        ? const Color(0xFF1B5E20)
        : result.verdict == 'CAUTION'
            ? Colors.orange[800]!
            : Colors.red[800]!;

    final icon = result.verdict == 'SAFE'
        ? Icons.check_circle
        : result.verdict == 'CAUTION'
            ? Icons.warning_amber
            : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result.recommendation,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: color)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${result.score}/100',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Badge(
                label: result.canGetBankLoan ? 'Bank Loan: YES' : 'Bank Loan: NO',
                ok: result.canGetBankLoan,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: result.canRegister ? 'Can Register: YES' : 'Can Register: NO',
                ok: result.canRegister,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Survey: ${report.scan.surveyNumber ?? '-'} · ${report.scan.district ?? ''} · ${report.scan.taluk ?? ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool ok;
  const _Badge({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF1B5E20).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: ok
                ? const Color(0xFF1B5E20).withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ok ? const Color(0xFF1B5E20) : Colors.red[700])),
    );
  }
}

// ─── Ruling Card ──────────────────────────────────────────────────────────────
class _RulingCard extends StatelessWidget {
  final LegalRuling ruling;
  const _RulingCard({required this.ruling});

  @override
  Widget build(BuildContext context) {
    final color = ruling.verdict == 'SAFE'
        ? const Color(0xFF1B5E20)
        : ruling.verdict == 'DO_NOT_BUY' || ruling.verdict == 'BLOCKED'
            ? Colors.red[700]!
            : Colors.orange[700]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(
          ruling.verdict == 'SAFE'
              ? Icons.check_circle
              : ruling.verdict == 'DO_NOT_BUY'
                  ? Icons.cancel
                  : Icons.warning_amber,
          color: color,
          size: 22,
        ),
        title: Text(ruling.title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark)),
        subtitle: Text(ruling.lawSection,
            style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
        children: [
          Text(ruling.explanation,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textDark, height: 1.5)),
          if (ruling.conversionPath != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route_outlined, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(ruling.conversionPath!,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.black87,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...ruling.whatToDo.map((d) => _MiniAction(text: d, isPositive: true)),
          ...ruling.whatNotToDo
              .map((d) => _MiniAction(text: d, isPositive: false)),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String text;
  final bool isPositive;
  const _MiniAction({required this.text, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check : Icons.close,
            size: 13,
            color: isPositive ? const Color(0xFF1B5E20) : Colors.red[700],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDark,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Action Item ──────────────────────────────────────────────────────────────
class _ActionItem extends StatelessWidget {
  final String text;
  final bool isPositive;
  const _ActionItem({required this.text, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? const Color(0xFF1B5E20) : Colors.red[700]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.block_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textDark, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Stamp Duty Card ──────────────────────────────────────────────────────────
class _StampDutyCard extends StatelessWidget {
  final StampDutyInfo info;
  const _StampDutyCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return _ExpandCard(
      title: 'Stamp Duty & Registration Charges (Karnataka 2024–25)',
      subtitle: info.totalEffective,
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF5E35B1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...info.rates.map((r) => _Row(r)),
          const Divider(height: 16),
          _Row('Registration: ${info.registrationCharge}'),
          const SizedBox(height: 8),
          Text('Important:',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
          ...info.notes.map((n) => _Row(n, icon: Icons.info_outline)),
          const SizedBox(height: 4),
          Text(info.law,
              style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

// ─── Registration Card ────────────────────────────────────────────────────────
class _RegistrationCard extends StatelessWidget {
  final RegistrationInfo info;
  const _RegistrationCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return _ExpandCard(
      title: 'Registration Process — Step by Step',
      subtitle: info.timeFrame,
      icon: Icons.how_to_reg_outlined,
      color: const Color(0xFF0D47A1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Steps:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ...info.process.map((s) => _Row(s)),
          const Divider(height: 16),
          const Text('Documents Required:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ...info.mandatoryDocuments.map((d) => _Row(d, icon: Icons.check_box_outline_blank)),
          const SizedBox(height: 6),
          Text('Cost: ${info.cost}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

// ─── Expert Help Card ────────────────────────────────────────────────────────
class _ExpertHelpCard extends StatelessWidget {
  const _ExpertHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.support_agent, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Get Expert Help',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          _ExpertRow(
            icon: Icons.gavel,
            title: 'Property Lawyer',
            subtitle: 'Title verification, sale deed drafting, court matters',
            color: const Color(0xFFBF360C),
            badge: 'From ₹5,000',
          ),
          _ExpertRow(
            icon: Icons.account_balance,
            title: 'Bank Home Loan',
            subtitle: 'SBI, HDFC, ICICI — get loan eligibility in 10 minutes',
            color: const Color(0xFF0D47A1),
            badge: 'Free check',
          ),
          _ExpertRow(
            icon: Icons.maps_home_work,
            title: 'Licensed Surveyor',
            subtitle: 'Physical survey, boundary verification, sketch map',
            color: const Color(0xFF1565C0),
            badge: 'From ₹5,000',
          ),
          _ExpertRow(
            icon: Icons.description_outlined,
            title: 'RERA Complaint',
            subtitle: 'Builder not complying? File complaint at RERA Karnataka',
            color: const Color(0xFF4A148C),
            badge: 'Free',
          ),
          _ExpertRow(
            icon: Icons.transform,
            title: 'B Khata Conversion',
            subtitle: 'Betterment charges + BBMP application assistance',
            color: const Color(0xFF1B5E20),
            badge: 'From ₹2,000',
          ),
        ],
      ),
    );
  }
}

class _ExpertRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badge;

  const _ExpertRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMedium)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: color)),
        ],
      ),
    );
  }
}

class _ExpandCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  const _ExpandCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(icon, color: color, size: 20),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.textDark)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
        children: [child],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Row(this.text, {this.icon = Icons.arrow_right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textMedium),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textDark, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
