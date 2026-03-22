import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentReports = ref.watch(recentReportsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DigiSampatti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner
            _WelcomeBanner(userName: user?.phoneNumber ?? ''),
            const SizedBox(height: 20),

            // ── Quick Action Buttons
            const Text(
              'Start Property Check',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.camera_alt,
                    title: 'Scan Property',
                    subtitle: 'Take photo + GPS',
                    color: AppColors.primary,
                    onTap: () => context.push('/scan/camera'),
                  ),
                ),
                    const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.search,
                    title: 'Manual Search',
                    subtitle: 'Survey number',
                    color: AppColors.info,
                    onTap: () => context.push('/scan/manual'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history,
                    title: 'My Reports',
                    subtitle: 'Past searches',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push('/history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.people,
                    title: 'Broker Zone',
                    subtitle: '5 free reports',
                    color: const Color(0xFFD97706),
                    onTap: () => context.push('/broker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BannerCard(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              icon: Icons.home_work,
              title: 'Property Transfer',
              subtitle: 'Stamp Duty · Mutation · SRO · Registration',
              onTap: () => context.push('/transfer'),
            ),
            const SizedBox(height: 10),
            _BannerCard(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              icon: Icons.account_balance_wallet,
              title: 'Financial Tools',
              subtitle: 'EMI · Total Cost · Property Tax · Loan',
              onTap: () => context.push('/tools'),
            ),
            const SizedBox(height: 10),
            _BannerCard(
              colors: [Color(0xFF4A1942), Color(0xFF6B2D5E)],
              icon: Icons.school,
              title: 'Buyer Guides',
              subtitle: 'Apartment · DC Conversion · Glossary · Red Flags',
              onTap: () => context.push('/guides'),
            ),
            const SizedBox(height: 24),

            // ── What We Check Section
            const Text(
              'What We Verify',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const _VerificationList(),
            const SizedBox(height: 24),

            // ── Recent Reports
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.recentReports,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (recentReports.isNotEmpty)
                  TextButton(
                    onPressed: () {},
                    child: const Text(AppStrings.viewAll),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentReports.isEmpty)
              _EmptyReportsCard()
            else
              ...recentReports.take(5).map((r) => _RecentReportCard(report: r)),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.subscriptions_outlined),
              title: const Text('Subscribe - ₹999/month'),
              subtitle: const Text('Unlimited Reports'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (ctx.mounted) ctx.go('/auth');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Banner ────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String userName;
  const _WelcomeBanner({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Know Before You Buy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Karnataka property verification in minutes',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.title,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
            )),
            Text(subtitle, style: const TextStyle(
              color: Colors.white70, fontSize: 12,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Banner Card ───────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BannerCard({required this.colors, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 13),
          ],
        ),
      ),
    );
  }
}

// ─── Verification List ─────────────────────────────────────────────────────────
class _VerificationList extends StatelessWidget {
  const _VerificationList();

  @override
  Widget build(BuildContext context) {
    const checks = [
      ('Bhoomi RTC Records', 'Owner, land type, khata', Icons.article_outlined),
      ('Revenue Site Check', 'BDA/BBMP/CMC jurisdiction', Icons.gavel),
      ('Encumbrance (EC)', 'Mortgages, loans, claims', Icons.account_balance),
      ('Government Notices', 'BDA acquisition, road widening', Icons.notification_important),
      ('Raja Kaluve Buffer', 'Storm drain no-build zone', Icons.water),
      ('Lake Bed & FTL', 'Lake boundary restrictions', Icons.waves),
      ('RERA Registration', 'Builder & project verification', Icons.business),
      ('AI Risk Score', 'Claude AI legal analysis', Icons.psychology),
    ];

    return Card(
      child: Column(
        children: checks.asMap().entries.map((e) => Column(
          children: [
            ListTile(
              dense: true,
              leading: Icon(e.value.$3, color: AppColors.primary, size: 20),
              title: Text(e.value.$1, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
              )),
              subtitle: Text(e.value.$2, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.check_circle, color: AppColors.safe, size: 18),
            ),
            if (e.key < checks.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        )).toList(),
      ),
    );
  }
}

// ─── Empty Reports ─────────────────────────────────────────────────────────────
class _EmptyReportsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open, size: 48, color: AppColors.textLight),
          SizedBox(height: 12),
          Text(AppStrings.noReports,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium)),
          SizedBox(height: 4),
          Text(AppStrings.startScan,
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }
}

// ─── Recent Report Card ────────────────────────────────────────────────────────
class _RecentReportCard extends StatelessWidget {
  final LegalReport report;
  const _RecentReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final score = report.riskAssessment.score;
    final color = score >= 70 ? AppColors.safe
        : score >= 40 ? AppColors.warning
        : AppColors.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            '$score',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          report.scan.surveyNumber ?? report.scan.location?.address ?? 'Unknown Property',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${report.scan.district ?? ""} • ${report.riskAssessment.recommendation}',
          style: TextStyle(color: color, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/report', extra: report.toJson()),
      ),
    );
  }
}
