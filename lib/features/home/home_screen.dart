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
import 'package:digi_sampatti/widgets/common_widgets.dart';
import 'package:digi_sampatti/core/widgets/ds_logo.dart';

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

  // 6 sections: banner, demo, actions, more-tools, why, recent
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAskSheet(context),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(l.askQuestion),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: Row(
          children: [
            const DSLogo(size: 32),
            const SizedBox(width: 10),
            Text(l.homeTitle),
          ],
        ),
        actions: [
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
            // ── Buyer / Seller Mode Toggle  ─────────────────────────────
            _animated(0, _BuyerSellerToggle()),
            const SizedBox(height: 20),

            // ── Mode-aware primary actions ──────────────────────────────
            _animated(1, _ModeActions()),
            const SizedBox(height: 20),

            // ── Transaction tools (core revenue features) ───────────────
            _animated(2, _CoreTools()),
            const SizedBox(height: 16),

            // ── Secondary tools (collapsed, "More") ─────────────────────
            _animated(3, _MoreToolsSection()),
            const SizedBox(height: 24),

            // ── Recent Reports
            _animated(5, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.recentReports,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                  ...recentReports.take(5).map((r) => _RecentReportCard(report: r)),
              ],
            )),
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
          _Step('4', Icons.fingerprint, 'Know Your Buying Power (ARTH ID)',
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
              onPressed: () => context.push('/scan/camera'),
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
class _ModeActions extends ConsumerWidget {
  const _ModeActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuyer = ref.watch(userModeProvider) == UserMode.buyer;

    if (isBuyer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary CTA — Upload documents
          GestureDetector(
            onTap: () => context.push('/scan/camera'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.safe]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.upload_file, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text('Upload Property Documents',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 17)),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                    'Photograph any RTC, EC, sale deed, or agreement.\n'
                    'AI reads it instantly — any state, any language.',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Scan Document →',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary — manual search
          Row(children: [
            Expanded(child: _ActionCard(
              icon: Icons.search,
              title: 'Enter Survey No.',
              subtitle: 'Know the survey number',
              color: AppColors.arthBlue,
              onTap: () => context.push('/scan/manual'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionCard(
              icon: Icons.history,
              title: 'Past Reports',
              subtitle: 'Your checked properties',
              color: const Color(0xFF6366F1),
              onTap: () => context.push('/history'),
            )),
          ]),
        ],
      );
    }

    // Seller mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/seller-kyc'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.seller, Color(0xFFAD1457)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.verified_user_outlined,
                      color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('Get Your Property Verified',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Verified sellers attract more buyers and get faster deals.\n'
                  'Complete KYC → get Verified Badge → list with confidence.',
                  style: TextStyle(color: Colors.white70,
                      fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Start Seller KYC →',
                      style: TextStyle(color: AppColors.seller,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
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

// ─── Core Transaction Tools (revenue-generating, mode-aware) ─────────────────
class _CoreTools extends ConsumerWidget {
  const _CoreTools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuyer = ref.watch(userModeProvider) == UserMode.buyer;

    final buyerTools = [
      _Tool(Icons.fingerprint, 'ARTH ID — Loan Check', 'Know your buying power first',
          AppColors.arthBlue, '/loan-eligibility'),
      _Tool(Icons.how_to_reg_outlined, 'Verify Seller', 'KYC + Trust Score',
          AppColors.seller, '/seller-kyc'),
      _Tool(Icons.location_searching, 'Book Inspection', 'On-ground GPS visit',
          AppColors.slate, '/field-inspection'),
      _Tool(Icons.draw_outlined, 'e-Sign Agreement', 'Aadhaar-based signing',
          AppColors.esign, '/esign'),
      _Tool(Icons.people_outline, 'Expert Help', 'Lawyer · Bank · Insurance',
          AppColors.warning, '/partners'),
      _Tool(Icons.attach_money, 'Guidance Value', 'Min price per sqft',
          AppColors.teal, '/guidance-value'),
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
      _Tool(Icons.attach_money, 'Guidance Value', 'Know your property price',
          AppColors.teal, '/guidance-value'),
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
          _ToolRow(Icons.account_balance_wallet, 'Financial Tools',
              'EMI · Total Cost · Loan',
              AppColors.primary, () => context.push('/tools')),
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
