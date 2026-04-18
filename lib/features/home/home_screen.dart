import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';
import 'package:digi_sampatti/core/services/report_history_service.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';
import 'package:digi_sampatti/features/profile/property_profile_sheet.dart';
import 'package:digi_sampatti/features/marketplace/property_listing_screen.dart';
import 'package:digi_sampatti/widgets/common_widgets.dart';
import 'package:digi_sampatti/core/widgets/ds_logo.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  // 7 sections: greeting, two-blocks, know-your-property, actions, quick-tools, escrow-banner, recent
  static const _count = 6;

  @override
  void initState() {
    super.initState();
    // Load saved reports from SharedPreferences into the in-memory provider.
    // Without this, recentReportsProvider starts empty on every fresh app launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final existing = ref.read(recentReportsProvider);
      if (existing.isEmpty) {
        final saved = await ReportHistoryService().loadReports();
        if (saved.isNotEmpty && mounted) {
          ref.read(recentReportsProvider.notifier).state = saved;
        }
      }
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fades = List.generate(_count, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
    _slides = List.generate(_count, (i) {
      final start = i * 0.15;
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentReports = ref.watch(recentReportsProvider);
    final user = FirebaseAuth.instance.currentUser;
    final l = AppL10n(ref.watch(languageProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/arth_id_logo.png', fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const DSLogo(size: 26)),
            ),
            const SizedBox(width: 10),
            Text(l.homeTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past Reports',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Greeting card ─────────────────────────────────────────
            _animated(0, const _GreetingCard()),
            const SizedBox(height: 16),

            // ── 2. Buyer / Seller mode cards ──────────────────────────────
            _animated(1, _ModeSelectionCards()),
            const SizedBox(height: 16),

            // ── 3. Know Your Property ─────────────────────────────────────
            _animated(2, const _KnowYourProperty()),
            const SizedBox(height: 14),

            // ── 4. Quick-Access Tools ─────────────────────────────────────
            _animated(3, const _QuickToolsGrid()),
            const SizedBox(height: 16),

            // ── 5. Escrow & Agreement flow banner ─────────────────────────
            _animated(4, const _EscrowFlowBanner()),
            const SizedBox(height: 24),

            // ── 6. Recent Reports ─────────────────────────────────────────
            _animated(5, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.recentReports,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    if (recentReports.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push('/history'),
                        child: Text(l.viewAll),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recentReports.isEmpty)
                  _EmptyReportsCard(noReportsText: l.noReports)
                else
                  ...recentReports.take(3).map((r) => _RecentReportCard(report: r)),
              ],
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBdaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Layout Authority Portals',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Which authority approved this property? Use the right portal below.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _BdaTile(
              icon: Icons.home_work_outlined,
              title: 'BDA Layout Approval',
              subtitle: 'housing.bdabangalore.org — Bengaluru planned layouts',
              color: AppColors.indigo,
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GovWebViewScreen(portal: GovPortal.bdaLayout))); },
            ),
            const SizedBox(height: 10),
            _BdaTile(
              icon: Icons.receipt_long_outlined,
              title: 'BDA Property Tax',
              subtitle: 'app.bda.karnataka.gov.in — tax dues & arrears',
              color: AppColors.info,
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GovWebViewScreen(portal: GovPortal.bdaTax))); },
            ),
            const SizedBox(height: 10),
            _BdaTile(
              icon: Icons.map_outlined,
              title: 'BMRDA Layout Approval',
              subtitle: 'bmrda.karnataka.gov.in — within 40km of Bengaluru',
              color: AppColors.teal,
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GovWebViewScreen(portal: GovPortal.bmrda))); },
            ),
            const SizedBox(height: 10),
            _BdaTile(
              icon: Icons.flight_outlined,
              title: 'BIAAPA Layout Approval',
              subtitle: 'biaapa.karnataka.gov.in — airport corridor (Devanahalli, Hoskote)',
              color: const Color(0xFF1A3A6B),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GovWebViewScreen(portal: GovPortal.biaapa))); },
            ),
            const SizedBox(height: 10),
            _BdaTile(
              icon: Icons.picture_as_pdf,
              title: 'IGR Guidance Value PDF',
              subtitle: 'igr.karnataka.gov.in — min price for stamp duty',
              color: AppColors.teal,
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GovWebViewScreen(portal: GovPortal.igrGuidance))); },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Which authority applies to your property?\n\n'
                '• BBMP limit (city): BBMP e-Aasthi for Khata\n'
                '• BDA layout: BDA Housing + BDA Tax\n'
                '• Within 40km, non-BDA: BMRDA approval\n'
                '• Airport corridor (Devanahalli/Hoskote): BIAAPA\n'
                '• Smaller towns (Mysuru, Hubballi etc): CMC/TMC office — no online portal, visit physically\n'
                '• Village / GP area: Gram Panchayat Khata — highest risk\n'
                '• Apartment / builder project: RERA only',
                style: TextStyle(fontSize: 11, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AskSheet(),
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
              leading: const Icon(Icons.subscriptions_outlined, color: AppColors.primary),
              title: const Text('Plans & Pricing'),
              subtitle: const Text('₹499/report · ₹1,999/month unlimited'),
              onTap: () { Navigator.pop(ctx); context.push('/subscription'); },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () { Navigator.pop(ctx); context.push('/privacy'); },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              onTap: () { Navigator.pop(ctx); context.push('/terms'); },
            ),
            const Divider(),
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
  final String headline;
  final String subtitle;
  const _WelcomeBanner({required this.userName, required this.headline, required this.subtitle});

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
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
class _StepChip extends StatelessWidget {
  final String label;
  const _StepChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward, size: 12, color: AppColors.textLight),
    );
  }
}

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

// ─── Tool Row ──────────────────────────────────────────────────────────────────
class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ToolRow(this.icon, this.title, this.subtitle, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
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
  final String noReportsText;
  const _EmptyReportsCard({required this.noReportsText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_open, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(noReportsText,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text(AppStrings.startScan,
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

// ─── How It Works Card — functional, shows real steps + starts check ─────────
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('How to Check a Property',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          _Step('1', Icons.upload_file, 'Upload Any Property Document',
              'Photograph your RTC, sale deed, EC, or agreement. Any state, any language. AI reads it instantly.',
              AppColors.primary),
          _Step('2', Icons.open_in_new, 'AI Checks 8 Government Portals',
              'Bhoomi RTC · Kaveri EC · eCourts · BBMP Khata · CERSAI · RERA · Guidance Value · BDA/BMRDA — automatically.',
              AppColors.info),
          _Step('3', Icons.psychology_outlined, 'Get Legal Verdict + Score',
              'AI analyses all findings → DO BUY / CAUTION / DO NOT BUY with law citations. Score 0–100.',
              const Color(0xFF6A1B9A)),
          _Step('4', Icons.fingerprint, 'Know Your Buying Power (FinSelf Lite)',
              'Check home loan eligibility instantly based on your income + property value.',
              AppColors.deepOrange),
          const SizedBox(height: 4),
          // 3 physical things note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 Things You Still Do In Person:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Colors.black87)),
                SizedBox(height: 6),
                _PhysicalItem(Icons.location_on_outlined, 'Visit the physical property — check boundaries, construction, neighbours'),
                _PhysicalItem(Icons.account_balance_outlined, 'Visit Sub-Registrar Office (SRO) for registration on final deed day'),
                _PhysicalItem(Icons.receipt_outlined, 'Buy e-Stamp paper from authorised bank/SHCIL for sale deed (not from street vendors)'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/scan/guide'),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload Document & Check Property',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Step(this.num, this.icon, this.title, this.desc, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text(num,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4)),
            ],
          )),
        ],
      ),
    );
  }
}

class _PhysicalItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PhysicalItem(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: Colors.amber[800]),
          const SizedBox(width: 6),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3))),
        ],
      ),
    );
  }
}

// ─── Ask Sheet ─────────────────────────────────────────────────────────────────
class _AskSheet extends StatefulWidget {
  const _AskSheet();

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final _controller = TextEditingController();
  String _search = '';

  static const _qa = [
    _QA('Is B Khata safe to buy?',
      'B Khata means the property has legal irregularities — unapproved layout or construction. Banks will NOT give home loans on B Khata. Very risky. Always insist on A Khata before paying any advance.',
      Icons.home_work),
    _QA('What is RTC and why does it matter?',
      'RTC (Record of Rights, Tenancy and Crops) is Karnataka\'s official land ownership document from Bhoomi portal. It shows owner name, land type, area, and khata number. Most important document before buying any land.',
      Icons.article_outlined),
    _QA('What is DC Conversion?',
      'DC Conversion is the government order changing agricultural land to residential or commercial use. Without DC conversion, building is illegal and BBMP will not give building plan approval.',
      Icons.swap_horiz),
    _QA('What is stamp duty in Karnataka?',
      'Tax paid when buying property. Men: 5%–5.6%. Women: 3%–5% (concession). Plus 1% registration charge. Use our Stamp Duty Calculator for exact amount.',
      Icons.receipt),
    _QA('Can I get a home loan on agricultural land?',
      'No. Banks do not give home loans on agricultural land. The land must have DC conversion and BBMP/BDA approved layout with A Khata before banks will consider a loan.',
      Icons.account_balance),
    _QA('What is EC and do I need it?',
      'EC (Encumbrance Certificate) lists all transactions on a property — loans, mortgages, sale deeds. Get EC for last 30 years before buying. If EC shows a mortgage, the bank\'s claim is still active.',
      Icons.find_in_page),
    _QA('What is RERA?',
      'Karnataka\'s real estate regulator. All new residential projects above 500 sq m must be RERA registered. Check rera.karnataka.gov.in before booking any flat. No RERA = no legal protection.',
      Icons.business),
    _QA('What is OC and why do I need it?',
      'Occupancy Certificate issued by BBMP/BDA after verifying building is complete and safe. Without OC, the building is technically illegal. Banks need OC for home loans on resale flats.',
      Icons.verified),
    _QA('What is a revenue site?',
      'A plot on agricultural land without DC conversion or layout approval. Banks won\'t give loans, BBMP can demolish structures. Avoid unless DC conversion and BBMP/BDA layout approval exists.',
      Icons.warning_amber),
    _QA('What is Raja Kaluve?',
      'Karnataka\'s storm drain network. A 50-metre buffer zone around Raja Kaluve is a no-construction zone. If a property falls inside this buffer, construction is illegal and can be demolished.',
      Icons.water),
    _QA('What is mutation?',
      'Updating government records (RTC and Khata) in your name after purchase. Do Bhoomi mutation first, then Khata transfer. Must be done within 3 months of registration.',
      Icons.edit_document),
    _QA('How much home loan can I get?',
      'Banks give max 80% of property value. Your EMI cannot exceed 50% of your net salary. Use our Loan Eligibility Calculator for your exact eligibility.',
      Icons.currency_rupee),
    _QA('What is UDS in an apartment?',
      'Undivided Share of Land — your share of the total land in an apartment complex. Higher UDS = more land value and better resale. Always ask the builder for UDS before booking.',
      Icons.pie_chart),
    _QA('How do I check court cases on a property?',
      'Use Court Case Check in More Tools. Enter owner name and district. Also check directly on services.ecourts.gov.in. Always check for disputes or injunctions before paying any advance.',
      Icons.gavel),
    _QA('Which authority approves layouts in Bengaluru?',
      'BBMP: Bengaluru city. BDA: planned layouts. BMRDA: within 40km of Bengaluru. BIAAPA: airport corridor. CMC/TMC: smaller towns. Gram Panchayat (GP): village areas — highest risk.',
      Icons.account_tree),
  ];

  List<_QA> get _filtered {
    if (_search.isEmpty) return _qa;
    final q = _search.toLowerCase();
    return _qa.where((item) =>
      item.question.toLowerCase().contains(q) ||
      item.answer.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ask About Property',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Free answers — no charge',
                    style: TextStyle(fontSize: 12, color: AppColors.safe)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'e.g. Is B Khata safe? What is stamp duty?',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { _controller.clear(); setState(() => _search = ''); },
                          )
                        : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 40, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('No matches', style: TextStyle(color: AppColors.textLight)),
                        SizedBox(height: 4),
                        Text('Try: khata, loan, stamp duty, RERA',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _QAItem(qa: filtered[i]),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QAItem extends StatefulWidget {
  final _QA qa;
  const _QAItem({required this.qa});

  @override
  State<_QAItem> createState() => _QAItemState();
}

class _QAItemState extends State<_QAItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.qa.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.qa.question,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14,
                      color: _open ? AppColors.primary : AppColors.textDark,
                    )),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: AppColors.textLight),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(widget.qa.answer,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QA {
  final String question, answer;
  final IconData icon;
  const _QA(this.question, this.answer, this.icon);
}

class _BdaTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _BdaTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Icon(Icons.open_in_new, color: color, size: 16),
        ],
      ),
    ),
  );
}

// ─── Mode Selection Cards ─────────────────────────────────────────────────────
class _ModeSelectionCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('What are you here for?',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ModeCard(
          icon: Icons.home_outlined,
          title: "I'm a Buyer",
          subtitle: 'Search, verify & buy property safely',
          gradient: const [AppColors.primary, Color(0xFF1565C0)],
          onTap: () => context.push('/buyer-home'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _ModeCard(
          icon: Icons.sell_outlined,
          title: "I'm a Seller",
          subtitle: 'List, verify docs & connect buyers',
          gradient: const [Color(0xFF1B5E20), AppColors.safe],
          onTap: () => context.push('/seller-home'),
        )),
      ]),
    ]);
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle,
    required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Go', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: Colors.white, size: 12),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Buyer / Seller Toggle ─────────────────────────────────────────────────────
// On tap → opens PropertyProfileSheet (state → district → taluk + property type)
// Profile drives AI personalization throughout the app.
class _BuyerSellerToggle extends ConsumerWidget {
  const _BuyerSellerToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode    = ref.watch(userModeProvider);
    final profile = ref.watch(userProfileProvider);
    final isBuyer = mode == UserMode.buyer;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                ref.read(userModeProvider.notifier).state = UserMode.buyer;
                final result = await showPropertyProfileSheet(context, ref, false);
                if (result != null) {
                  ref.read(userProfileProvider.notifier).state = result;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isBuyer ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search,
                      color: isBuyer ? Colors.white : Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Text('I\'m Buying',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBuyer ? Colors.white : Colors.grey,
                          fontSize: 14)),
                ]),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () async {
                ref.read(userModeProvider.notifier).state = UserMode.seller;
                final result = await showPropertyProfileSheet(context, ref, true);
                if (result != null) {
                  ref.read(userProfileProvider.notifier).state = result;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isBuyer ? AppColors.seller : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.sell_outlined,
                      color: !isBuyer ? Colors.white : Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Text('I\'m Selling',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !isBuyer ? Colors.white : Colors.grey,
                          fontSize: 14)),
                ]),
              ),
            )),
          ]),
        ),
        // Show selected location + property type below toggle
        if (profile.state != null || profile.district != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final result = await showPropertyProfileSheet(
                  context, ref, !isBuyer);
              if (result != null) {
                ref.read(userProfileProvider.notifier).state = result;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.location_on, size: 13,
                    color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  '${profile.locationLabel}  ·  ${profile.propertyTypeLabel}',
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.primary, fontWeight: FontWeight.w500),
                )),
                const Icon(Icons.edit, size: 12, color: AppColors.primary),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Mode-aware primary actions ───────────────────────────────────────────────
class _ModeActions extends ConsumerStatefulWidget {
  const _ModeActions();

  @override
  ConsumerState<_ModeActions> createState() => _ModeActionsState();
}

class _ModeActionsState extends ConsumerState<_ModeActions> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PropertyListing> get _results {
    if (_query.trim().isEmpty) return kMockListings.take(3).toList();
    final q = _query.toLowerCase();
    return kMockListings.where((l) =>
      l.title.toLowerCase().contains(q) ||
      l.locality.toLowerCase().contains(q) ||
      l.city.toLowerCase().contains(q) ||
      l.propertyType.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = ref.watch(userModeProvider) == UserMode.buyer;

    if (isBuyer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search locality, property type...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Results ─────────────────────────────────────────────────────
          if (_results.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('No listings found for that search.',
                    style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              ),
            )
          else
            ...(_results.take(5).map((l) => _InlineListingCard(listing: l))),

          if (_results.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => context.push('/property-search'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Text('View all listings →',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // ── Seller mode ─────────────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/seller-listing'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFAD1457)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.add_home_outlined, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('List Your Property',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Upload docs → Get Document Score → Reach verified buyers.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Start Listing →',
                      style: TextStyle(color: Color(0xFF7B1FA2),
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Active listings feed for seller
        const Text('Active Listings Near You',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...kMockListings.take(2).map((l) => _InlineListingCard(listing: l)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _ActionCard(
            icon: Icons.lock_outlined,
            title: 'Document Locker',
            subtitle: 'Store all property docs',
            color: AppColors.primary,
            onTap: () => context.push('/document-locker'),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionCard(
            icon: Icons.track_changes,
            title: 'Track Property',
            subtitle: 'Mutation · Tax · Resale',
            color: AppColors.slate,
            onTap: () => context.push('/post-purchase'),
          )),
        ]),
      ],
    );
  }
}

// ─── Compact inline listing card ──────────────────────────────────────────────
class _InlineListingCard extends StatelessWidget {
  final PropertyListing listing;
  const _InlineListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ListingDetailSheet(listing: listing),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: listing.isVerified
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(listing.propertyType),
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(listing.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textDark),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (listing.isVerified)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('✓ Verified',
                            style: TextStyle(fontSize: 9,
                                color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text('${listing.locality} · ${listing.city}  ·  ₹${listing.priceInLakhs}L',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 4),
                  Text(listing.highlights.take(2).join(' · '),
                      style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Apartment': return Icons.apartment;
      case 'Villa':     return Icons.villa;
      case 'Plot':      return Icons.crop_square;
      case 'Commercial': return Icons.store;
      default:          return Icons.home;
    }
  }
}

// ─── Listing detail bottom sheet ──────────────────────────────────────────────
class _ListingDetailSheet extends StatefulWidget {
  final PropertyListing listing;
  const _ListingDetailSheet({required this.listing});

  @override
  State<_ListingDetailSheet> createState() => _ListingDetailSheetState();
}

class _ListingDetailSheetState extends State<_ListingDetailSheet> {
  bool _contactUnlocked = false;

  void _unlockContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_outlined, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Unlock Seller Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Pay ₹99 to view seller\'s phone number and start a secure chat.\nYour payment is protected — no contact until both parties agree.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB8D8B8)),
              ),
              child: const Row(children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Seller cannot see your number until you choose to share it. Chat is monitored for safety.',
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                )),
              ]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _contactUnlocked = true);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact unlocked! You can now chat with the seller.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Pay ₹99 & Unlock Contact',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(listing.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            if (listing.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('✓ Arth ID Verified',
                    style: TextStyle(fontSize: 11, color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 6),
          Text('${listing.locality}, ${listing.city} · ₹${listing.priceInLakhs} Lakhs',
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: listing.highlights.map((h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB8D8B8)),
              ),
              child: Text(h, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('${listing.areaSqft.toInt()} sq.ft  ·  ${listing.bedrooms > 0 ? "${listing.bedrooms}BHK" : listing.propertyType}  ·  Posted ${listing.postedDaysAgo}',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          if (_contactUnlocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB8D8B8)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Seller Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(listing.sellerName, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(listing.sellerPhone, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _contactUnlocked
                  ? ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening chat with ${listing.sellerName}…')),
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('Chat with Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _unlockContact(context);
                      },
                      icon: const Icon(Icons.lock_outlined, size: 16),
                      label: const Text('Unlock Contact — ₹99'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Core Transaction Tools (revenue-generating, mode-aware) ─────────────────
class _CoreTools extends ConsumerWidget {
  const _CoreTools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuyer = ref.watch(userModeProvider) == UserMode.buyer;

    final buyerTools = [
      _Tool(Icons.fingerprint, 'FinSelf Lite', 'Know your buying power first',
          AppColors.arthBlue, '/loan-eligibility'),
      _Tool(Icons.how_to_reg_outlined, 'Verify Seller', 'PAN format check · Name match',
          AppColors.seller, '/seller-kyc'),
      _Tool(Icons.location_searching, 'Book Inspection', 'On-ground GPS visit',
          AppColors.slate, '/field-inspection'),
      _Tool(Icons.draw_outlined, 'e-Sign Agreement', 'Aadhaar-based signing',
          AppColors.esign, '/esign'),
      _Tool(Icons.people_outline, 'Expert Help', 'Lawyer · Bank · Insurance',
          AppColors.warning, '/partners'),
      _Tool(Icons.gavel, 'Court Case Check', 'eCourts — owner name search',
          AppColors.critical, '/ecourts'),
    ];

    final sellerTools = [
      _Tool(Icons.lock_outlined, 'Document Locker', 'Store & share all docs',
          AppColors.primary, '/document-locker'),
      _Tool(Icons.notifications_active_outlined, 'Post-Sale Alerts', 'Mutation · Tax · Fraud alerts',
          AppColors.slate, '/post-purchase'),
      _Tool(Icons.draw_outlined, 'e-Sign Agreement', 'Sign with Aadhaar',
          AppColors.esign, '/esign'),
      _Tool(Icons.flight, 'NRI Guide', 'FEMA · TDS · Repatriation',
          AppColors.arthBlue, '/nri-stamp-duty'),
      _Tool(Icons.people_outline, 'Expert Help', 'Lawyer · Insurance',
          AppColors.warning, '/partners'),
      _Tool(Icons.gavel, 'Court Case Check', 'Verify no disputes on property',
          AppColors.critical, '/ecourts'),
    ];

    final tools = isBuyer ? buyerTools : sellerTools;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              isBuyer ? 'Buyer Tools' : 'Seller Tools',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 14, color: AppColors.textDark),
            ),
          ),
          const Divider(height: 1),
          ...tools.map((t) => Column(children: [
            _ToolRow(t.icon, t.title, t.subtitle, t.color,
                () => context.push(t.route)),
            if (t != tools.last) const Divider(height: 1, indent: 56),
          ])),
        ],
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  const _Tool(this.icon, this.title, this.subtitle, this.color, this.route);
}

// ─── Property Estimate & Finance Banner ───────────────────────────────────────
// Single banner containing Guidance Value, SRO Locator, and Financial Tools.
class _PropertyFinanceBanner extends StatelessWidget {
  const _PropertyFinanceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 15),
              SizedBox(width: 6),
              Text('Property Estimate & Finance',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13,
                      letterSpacing: 0.3)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Know the value · Find the office · Run the numbers',
                style: TextStyle(color: Colors.white54, fontSize: 10.5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(children: [
              Expanded(child: _FinanceTile(
                icon: Icons.attach_money,
                label: 'Guidance\nValue',
                sublabel: 'Min IGR price',
                color: const Color(0xFF52B788),
                onTap: () => context.push('/guidance-value'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _FinanceTile(
                icon: Icons.location_city_outlined,
                label: 'SRO\nLocator',
                sublabel: 'Register office',
                color: const Color(0xFF74C0FC),
                onTap: () => context.push('/transfer/sro'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _FinanceTile(
                icon: Icons.calculate_outlined,
                label: 'Financial\nTools',
                sublabel: 'EMI · Tax · Loan',
                color: const Color(0xFFFFD43B),
                onTap: () => context.push('/tools'),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _FinanceTile({required this.icon, required this.label,
      required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 7),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 11, height: 1.25)),
            const SizedBox(height: 2),
            Text(sublabel,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.55),
                    fontSize: 9.5, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ─── More Tools (secondary, collapsed) ───────────────────────────────────────
class _MoreToolsSection extends StatefulWidget {
  const _MoreToolsSection();
  @override
  State<_MoreToolsSection> createState() => _MoreToolsSectionState();
}

class _MoreToolsSectionState extends State<_MoreToolsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              const Icon(Icons.more_horiz, color: AppColors.textLight, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('More Resources',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 14, color: AppColors.textDark)),
              ),
              Text(_expanded ? 'Less' : 'Show',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary, size: 18),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          _ToolRow(Icons.flight, 'NRI Mode', 'UAE · USA · UK · FEMA',
              AppColors.arthBlue, () => context.push('/nri')),
          const Divider(height: 1, indent: 56),
          _ToolRow(Icons.history, 'Report History', 'Past property checks',
              const Color(0xFF6366F1), () => context.push('/history')),
          const Divider(height: 1, indent: 56),
          _ToolRow(Icons.people, 'Broker Zone', 'For property agents',
              const Color(0xFFD97706), () => context.push('/broker')),
        ],
      ]),
    );
  }
}

// ─── Greeting Card ─────────────────────────────────────────────────────────────
class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();

  Widget _buildAvatar(dynamic user, bool isBuyer) {
    final photoUrl = user?.photoURL as String?;
    final displayName = (user?.displayName as String?) ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : null;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 30, backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: isBuyer
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.2),
      child: initials != null
          ? Text(initials,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
          : Icon(
              isBuyer ? Icons.home_outlined : Icons.sell_outlined,
              color: Colors.white,
              size: 28,
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuyer = ref.watch(userModeProvider) == UserMode.buyer;
    final user    = FirebaseAuth.instance.currentUser;
    final name    = user?.displayName?.split(' ').first ?? 'there';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBuyer
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isBuyer ? const Color(0xFF1B5E20) : const Color(0xFF0D47A1))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buyer / Seller toggle ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeToggleChip(
                label: '🏠  Buying',
                active: isBuyer,
                onTap: () => ref.read(userModeProvider.notifier).state = UserMode.buyer,
              ),
              const SizedBox(width: 10),
              _ModeToggleChip(
                label: '🔑  Selling',
                active: !isBuyer,
                onTap: () => ref.read(userModeProvider.notifier).state = UserMode.seller,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── Personalised greeting ─────────────────────────────────────
          Row(
            children: [
              // Avatar — photo if available, else coloured initials circle
              _buildAvatar(user, isBuyer),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBuyer ? 'Hi $name! Ready to buy?' : 'Hi $name! Ready to list?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBuyer
                          ? 'Check any property before you invest.\nEvery property has a story — know it.'
                          : 'List your property and reach verified buyers.\nGet paid safely with digital escrow.',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Quick stats ───────────────────────────────────────────────
          Row(
            children: [
              _GreetingStat(isBuyer ? '30+' : '₹99', isBuyer ? 'Fraud checks' : 'Start listing'),
              const SizedBox(width: 16),
              _GreetingStat('3 min', 'AI report'),
              const SizedBox(width: 16),
              _GreetingStat('All India', 'Coverage'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeToggleChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF1B5E20) : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _GreetingStat extends StatelessWidget {
  final String value;
  final String label;
  const _GreetingStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

// ─── Property Tax Estimator ────────────────────────────────────────────────────
class _PropertyTaxEstimator extends StatefulWidget {
  const _PropertyTaxEstimator();
  @override
  State<_PropertyTaxEstimator> createState() => _PropertyTaxEstimatorState();
}

class _PropertyTaxEstimatorState extends State<_PropertyTaxEstimator> {
  String _city = 'Bengaluru';
  final _valueCtrl = TextEditingController();
  int? _taxResult;

  static const _cities = [
    'Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi',
    'Chennai', 'Hyderabad', 'Mumbai', 'Pune', 'Delhi', 'Kolkata',
    'Ahmedabad', 'Jaipur', 'Lucknow', 'Surat',
  ];

  void _estimate() {
    final raw = _valueCtrl.text.replaceAll(',', '').replaceAll(' ', '');
    final value = int.tryParse(raw);
    if (value == null || value <= 0) { setState(() => _taxResult = null); return; }
    // Karnataka: ~0.5% of guidance value. Other cities: ~0.4%–0.6%.
    final rate = _city == 'Bengaluru' ? 0.005 : 0.004;
    setState(() => _taxResult = (value * rate).round());
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() { _valueCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('Property Tax Estimator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
            const Spacer(),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('How is this calculated?'),
                  content: const Text(
                    'Annual property tax ≈ 0.5% of the government guidance value '
                    'for Bengaluru (BBMP formula). Other cities use 0.4%–0.6% depending '
                    'on location and property type. Actual tax may vary based on floor, '
                    'age, and usage of the property.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.textLight, size: 16),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _city,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) { setState(() => _city = v!); _estimate(); },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _valueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Property Value (₹)',
                  hintText: 'e.g. 8000000',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (_) => _estimate(),
              ),
            ),
          ]),
          if (_taxResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated Annual Tax for $_city: ₹${_fmt(_taxResult!)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Know Your Documents ───────────────────────────────────────────────────────
class _KnowYourDocuments extends StatefulWidget {
  const _KnowYourDocuments();
  @override
  State<_KnowYourDocuments> createState() => _KnowYourDocumentsState();
}

class _KnowYourDocumentsState extends State<_KnowYourDocuments> {
  bool _expanded = false;

  static const _docs = [
    _DocItem('RTC (Record of Rights, Tenancy & Crops)',
        'Ownership · Khata type · Survey number', Icons.article_outlined, true),
    _DocItem('Encumbrance Certificate (EC)',
        'Loans · Mortgages · All past sales (last 30 yrs)', Icons.account_balance_outlined, true),
    _DocItem('Sale Deed', 'Legal ownership transfer document', Icons.description_outlined, true),
    _DocItem('Khata Certificate',
        'BBMP / Panchayat registration. A Khata = safe.', Icons.home_outlined, true),
    _DocItem('RERA Certificate',
        'Required for apartments. Check expiry.', Icons.business_outlined, false),
    _DocItem('Occupancy Certificate (OC)',
        'Confirms building was constructed as approved', Icons.apartment_outlined, false),
    _DocItem('Building Plan Approval',
        'BBMP / BDA sanctioned plan — mandatory', Icons.maps_home_work_outlined, false),
    _DocItem('Property Tax Receipts',
        'Last 3 years receipts — confirms ownership', Icons.receipt_outlined, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(children: [
                const Icon(Icons.folder_open_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Know Your Documents',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                    Text('What to check before buying · Tap to expand',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _expanded ? 'Hide' : '${_docs.length} docs',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary, size: 18),
              ]),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...(_docs.map((d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(d.icon,
                    color: d.isCritical ? AppColors.primary : AppColors.textLight,
                    size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(d.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: d.isCritical ? AppColors.textDark : AppColors.textMedium)),
                      ),
                      if (d.isCritical)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Must Have',
                              style: TextStyle(fontSize: 9, color: AppColors.danger,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(d.desc,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.3)),
                  ]),
                ),
              ]),
            ))),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Never pay advance without verifying RTC + EC + Khata. '
                      'Arth ID checks all 7 portals before you commit.',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocItem {
  final String name;
  final String desc;
  final IconData icon;
  final bool isCritical;
  const _DocItem(this.name, this.desc, this.icon, this.isCritical);
}

// ─── 5 Quick-Access Tool Boxes ─────────────────────────────────────────────────
class _QuickToolsGrid extends StatelessWidget {
  const _QuickToolsGrid();

  static const _tools = [
    _QuickTool(Icons.people_outline,    'Expert\nHelp',     Color(0xFFD97706), '/partners'),
    _QuickTool(Icons.fingerprint,       'FinSelf\nLite',    Color(0xFF1565C0), '/arth-id'),
    _QuickTool(Icons.flight,            'NRI\nMode',        Color(0xFF6366F1), '/nri'),
    _QuickTool(Icons.people,            'Broker\nZone',     Color(0xFF7C3AED), '/broker'),
    _QuickTool(Icons.home_outlined,     'Post\nPurchase',   Color(0xFF0891B2), '/post-purchase'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Access',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Row(
          children: _tools.map((t) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: t != _tools.last ? 8 : 0),
              child: _QuickToolBox(tool: t),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _QuickTool {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickTool(this.icon, this.label, this.color, this.route);
}

class _QuickToolBox extends StatelessWidget {
  final _QuickTool tool;
  const _QuickToolBox({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tool.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(tool.icon, color: tool.color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Two Action Blocks ─────────────────────────────────────────────────────────
// Two side-by-side cards placed above the buyer/seller toggle area.
// Left: Property Estimate & Finance → /tools
// Right: Browse Verified Listings → /property-search
class _TwoActionBlocks extends StatelessWidget {
  const _TwoActionBlocks();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/tools'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text('Property Estimate\n& Finance',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3)),
                  const SizedBox(height: 4),
                  const Text('EMI · Stamp Duty\nGuidance Value',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 10, height: 1.3)),
                  const SizedBox(height: 10),
                  const Text('Explore →',
                      style: TextStyle(
                          color: Color(0xFF52B788),
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/property-search'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text('Browse Verified\nListings',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3)),
                  const SizedBox(height: 4),
                  const Text('Seller-uploaded docs\n1BHK · 2BHK · Plot',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 10, height: 1.3)),
                  const SizedBox(height: 10),
                  const Text('Search →',
                      style: TextStyle(
                          color: Color(0xFF74C0FC),
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Know Your Property ────────────────────────────────────────────────────────
// Interactive: user selects property type → gets state-specific info.
// Replaces the old _KnowYourDocuments static list.
class _KnowYourProperty extends ConsumerStatefulWidget {
  const _KnowYourProperty();

  @override
  ConsumerState<_KnowYourProperty> createState() => _KnowYourPropertyState();
}

class _KnowYourPropertyState extends ConsumerState<_KnowYourProperty> {
  String? _selected;

  static const _types = [
    _PropType('site', Icons.crop_square, 'Site / Plot', Color(0xFF2E7D32)),
    _PropType('apartment', Icons.apartment, 'Apartment / Flat', Color(0xFF1565C0)),
    _PropType('house', Icons.home, 'Independent House', Color(0xFF6A1B9A)),
    _PropType('farm', Icons.agriculture, 'Farm Land', Color(0xFFBF360C)),
    _PropType('commercial', Icons.store, 'Commercial', Color(0xFF00695C)),
  ];

  static const _info = {
    'site': _PropInfo(
      mustHave: ['RTC (survey number, owner name)', 'DC Conversion Order', 'BDA/BBMP Layout Approval', 'Khata (A Khata only)', 'EC – last 30 years'],
      risks: ['Revenue site without DC conversion', 'B Khata or no Khata', 'Raja Kaluve / lake bed buffer', 'BDA acquisition notification'],
      portals: ['Bhoomi (RTC)', 'BBMP e-Aasthi (Khata)', 'Kaveri (EC)', 'BDA / BMRDA layout'],
      tip: 'Never pay advance on a site without DC conversion. Banks don\'t give home loans on revenue sites.',
    ),
    'apartment': _PropInfo(
      mustHave: ['RERA Registration Certificate', 'Occupancy Certificate (OC)', 'Building Plan Approval (BBMP/BDA)', 'Khata in seller\'s name', 'EC for the flat'],
      risks: ['No OC — building is technically illegal', 'No RERA — no buyer protection', 'Builder court cases or NCLT proceedings', 'Missing UDS (land share) in deed'],
      portals: ['RERA Karnataka', 'BBMP e-Aasthi', 'Kaveri (EC)', 'eCourts (builder disputes)'],
      tip: 'Always check RERA expiry date. If builder registration is cancelled, don\'t book.',
    ),
    'house': _PropInfo(
      mustHave: ['Sale Deed / Title Deed', 'Building Plan Approval', 'Khata Certificate (A Khata)', 'EC – 30 years', 'Tax Paid Receipts (last 3 yrs)'],
      risks: ['Unauthorised additions not in approved plan', 'Encroachment on neighbouring land', 'Unpaid BBMP property tax dues', 'Old mortgage not released'],
      portals: ['Bhoomi / BBMP e-Aasthi', 'Kaveri (EC)', 'BDA building plan records'],
      tip: 'Verify boundaries physically. Common fraud: selling 1,200 sq ft but built 1,500 sq ft — unauthorised area has no legal protection.',
    ),
    'farm': _PropInfo(
      mustHave: ['RTC showing agricultural use', 'Patta / Pahani document', 'Mutation entries', 'Caste certificate (if 79-A applies)', 'DC permission if non-agriculturist'],
      risks: ['Karnataka Land Reforms Act Section 79-A/79-B — non-agriculturists cannot buy farmland', 'Ceiling land — government can reclaim', 'Disputed boundaries with neighbouring farmers', 'Under KIADB / BDA acquisition'],
      portals: ['Bhoomi (RTC + mutations)', 'Revenue department (Patta)', 'KIADB notification check'],
      tip: 'Most NRIs and urban buyers CANNOT buy farm land in Karnataka without being agriculturists. High risk — always consult a lawyer first.',
    ),
    'commercial': _PropInfo(
      mustHave: ['Sale Deed / Lease Deed', 'Commercial building approval (BBMP/BDA)', 'Trade License / Occupancy Certificate', 'RERA (if multi-unit commercial project)', 'EC – 30 years'],
      risks: ['Residential area zoning — commercial use may be illegal', 'Floor Area Ratio (FAR) violation', 'Unpaid BBMP commercial tax', 'Fire NOC missing — occupancy risk'],
      portals: ['BBMP e-Aasthi', 'Kaveri (EC)', 'RERA (if applicable)', 'BDA zoning maps'],
      tip: 'Check that the locality zoning (Master Plan) allows commercial use. BBMP can seal premises if zoning is violated.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _selected != null ? _info[_selected] : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              Icon(Icons.explore_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Know Your Property',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Select property type → get what to verify',
                style: TextStyle(fontSize: 11, color: AppColors.textLight)),
          ),
          // Type selector chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _types[i];
                final active = _selected == t.key;
                return GestureDetector(
                  onTap: () => setState(() =>
                      _selected = active ? null : t.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? t.color : t.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: t.color.withValues(alpha: active ? 0 : 0.3)),
                    ),
                    child: Row(children: [
                      Icon(t.icon,
                          color: active ? Colors.white : t.color, size: 14),
                      const SizedBox(width: 5),
                      Text(t.label,
                          style: TextStyle(
                              color: active ? Colors.white : t.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (info != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KypSection(
                    icon: Icons.checklist,
                    color: AppColors.primary,
                    title: 'Must-Have Documents',
                    items: info.mustHave,
                  ),
                  const SizedBox(height: 10),
                  _KypSection(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    title: 'Key Risks to Check',
                    items: info.risks,
                  ),
                  const SizedBox(height: 10),
                  _KypSection(
                    icon: Icons.open_in_new,
                    color: AppColors.info,
                    title: 'Portals to Verify',
                    items: info.portals,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(info.tip,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _KypSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
  const _KypSection(
      {required this.icon,
      required this.color,
      required this.title,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ]),
        const SizedBox(height: 5),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium,
                            height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _PropType {
  final String key;
  final IconData icon;
  final String label;
  final Color color;
  const _PropType(this.key, this.icon, this.label, this.color);
}

class _PropInfo {
  final List<String> mustHave;
  final List<String> risks;
  final List<String> portals;
  final String tip;
  const _PropInfo(
      {required this.mustHave,
      required this.risks,
      required this.portals,
      required this.tip});
}

// ─── Escrow & Agreement Flow Banner ───────────────────────────────────────────
// Shows the end-to-end transaction flow so users understand how money moves.
class _EscrowFlowBanner extends StatelessWidget {
  const _EscrowFlowBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/escrow'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2137), Color(0xFF1A3A6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D2137).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.lock_clock, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('Safe Transaction — How It Works',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 4),
            const Text('Your advance is held safely until both parties agree',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 14),
            // Step row — 5 steps
            Row(
              children: [
                _EscrowStep(
                    icon: Icons.search,
                    label: 'Find',
                    sub: 'Browse\nlistings',
                    color: const Color(0xFF52B788)),
                _EscrowArrow(),
                _EscrowStep(
                    icon: Icons.psychology_outlined,
                    label: 'Verify',
                    sub: 'AI checks\ndocuments',
                    color: const Color(0xFF74C0FC)),
                _EscrowArrow(),
                _EscrowStep(
                    icon: Icons.location_on_outlined,
                    label: 'Inspect',
                    sub: 'Visit &\nconfirm',
                    color: Colors.amber),
                _EscrowArrow(),
                _EscrowStep(
                    icon: Icons.draw_outlined,
                    label: 'Advance',
                    sub: 'Escrow +\ne-Sign',
                    color: const Color(0xFFFF8A65)),
                _EscrowArrow(),
                _EscrowStep(
                    icon: Icons.home,
                    label: 'Register',
                    sub: 'Full pay\n+ SRO',
                    color: const Color(0xFFFF6B6B)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.account_balance_outlined,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Advance paid only after you verify docs & inspect the property · Full payment within 3 months · Escrow releases funds at registration',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        height: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('See Flow →',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _EscrowStep(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 9, height: 1.3)),
        ],
      ),
    );
  }
}

class _EscrowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Icon(Icons.arrow_forward_ios,
          size: 10, color: Colors.white30),
    );
  }
}
