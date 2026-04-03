import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';
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
            // ── Welcome Banner
            _animated(0, _WelcomeBanner(
              userName: user?.phoneNumber ?? '',
              headline: l.knowBeforeYouBuy,
              subtitle: l.verifyInMinutes,
            )),
            const SizedBox(height: 20),

            // ── How It Works Banner
            _animated(2, GestureDetector(
              onTap: () => context.push('/demo'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_filled, color: Colors.amber, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('See a Sample Report',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('How DigiSampatti checks a real Karnataka property',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                  ],
                ),
              ),
            )),

            // ── Quick Action Buttons
            _animated(1, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.startPropertyCheck,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepChip(label: '1. Scan'),
                    const _StepArrow(),
                    _StepChip(label: '2. Analyse'),
                    const _StepArrow(),
                    _StepChip(label: '3. Report'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.camera_alt, title: l.scanProperty, subtitle: l.photoGps,
                    color: AppColors.primary, onTap: () => context.push('/scan/camera'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(
                    icon: Icons.search, title: l.manualSearch, subtitle: l.surveyNo,
                    color: AppColors.info, onTap: () => context.push('/scan/manual'),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.history, title: l.myReports, subtitle: l.pastSearches,
                    color: const Color(0xFF6366F1), onTap: () => context.push('/history'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(
                    icon: Icons.people, title: l.brokerZone, subtitle: l.freeReports,
                    color: const Color(0xFFD97706), onTap: () => context.push('/broker'),
                  )),
                ]),
              ],
            )),
            const SizedBox(height: 16),

            // ── More Tools
            _animated(3, Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(l.moreTools,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  ),
                  const Divider(height: 1),
                  _ToolRow(Icons.home_work, l.propertyTransfer, 'Stamp Duty · Mutation · SRO', const Color(0xFF1A237E), () => context.push('/transfer')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.account_balance_wallet, l.financialTools, 'EMI · Total Cost · Loan Eligibility', const Color(0xFF1B5E20), () => context.push('/tools')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.school, l.buyerGuides, 'Apartment · DC Conversion · Glossary', const Color(0xFF4A1942), () => context.push('/guides')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.people_outline, l.expertHelp, 'Lawyer · Bank · Developers', AppColors.warning, () => context.push('/partners')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.gavel, l.courtCaseCheck, 'eCourts · Disputes · Injunctions', const Color(0xFF1A237E), () => context.push('/ecourts')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.assignment_turned_in, l.applyAndTrack, 'EC · RTC · Mutation · RERA · Registration', const Color(0xFF004D40), () => context.push('/gov-services')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.route, l.buyingJourney, 'Advance · Agreement · Registration', const Color(0xFF1B5E20), () => context.push('/buying-journey')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.flight, l.nriMode, 'UAE · USA · UK · FEMA · Ground Verify', const Color(0xFF0D47A1), () => context.push('/nri')),
                ],
              ),
            )),
            const SizedBox(height: 16),

            // ── Why DigiSampatti — interactive card
            _animated(4, _WhyDigiSampattiCard(onTap: () => _showWhySheet(context))),
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

  void _showWhySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WhySheet(),
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
              subtitle: const Text('₹99/report · ₹999/month unlimited'),
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

// ─── Why DigiSampatti Card ────────────────────────────────────────────────────
class _WhyDigiSampattiCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WhyDigiSampattiCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🇮🇳  Why DigiSampatti?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text(
                    'For investors · Expo ready · All India · Every citizen',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _Pill('💼 Investor'),
                      SizedBox(width: 6),
                      _Pill('🌾 Rural'),
                      SizedBox(width: 6),
                      _Pill('🏙️ Metro'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}

// ─── Why Sheet ────────────────────────────────────────────────────────────────
class _WhySheet extends StatefulWidget {
  const _WhySheet();
  @override
  State<_WhySheet> createState() => _WhySheetState();
}

class _WhySheetState extends State<_WhySheet> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Why DigiSampatti?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '💼 Invest'),
                Tab(text: '🇮🇳 All India'),
                Tab(text: '🌾 Rural'),
                Tab(text: '📈 Prices'),
                Tab(text: '⚖️ Governance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _investTab(),
                  _indiaTab(),
                  _ruralTab(),
                  _pricesTab(),
                  _govTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _investTab() => _SheetPage(children: [
    _SheetHeader('💼', 'Invest with Confidence', 'Property expo ready · Investor grade reports'),
    _InfoTile('🏙️', 'International Standard',
      'Dubai, Singapore and UAE require full legal due diligence before every property deal. DigiSampatti brings the same standard to every Indian buyer.'),
    _InfoTile('📊', 'Investor-Grade Report',
      'Comprehensive safety score, legal flags, encumbrance history and AI analysis — everything an investor needs before committing funds.'),
    _InfoTile('🤝', 'Property Expo Ready',
      'Print your DigiSampatti report at a property expo and show buyers the property is clean. Builds instant trust.'),
    _InfoTile('🔒', 'Risk Before You Sign',
      'Know disputes, mortgages, government notices and layout violations before paying any advance — not after.'),
  ]);

  Widget _indiaTab() {
    final states = [
      ['Karnataka', true],  ['Delhi', false],     ['Maharashtra', false],
      ['Telangana', false], ['Tamil Nadu', false], ['Gujarat', false],
      ['West Bengal', false],['Kerala', false],    ['Andhra Pradesh', false],
      ['UP', false],        ['Rajasthan', false],  ['Haryana', false],
      ['Punjab', false],    ['MP', false],         ['Himachal', false],
      ['Uttarakhand', false],['J & K', false],     ['Bihar', false],
      ['Jharkhand', false], ['Odisha', false],     ['Chhattisgarh', false],
      ['Assam', false],     ['Goa', false],        ['Meghalaya', false],
      ['Manipur', false],   ['Nagaland', false],   ['Mizoram', false],
      ['Tripura', false],   ['Arunachal', false],  ['Sikkim', false],
      ['Chandigarh', false],['Puducherry', false], ['Ladakh', false],
      ['Andaman', false],   ['Lakshadweep', false],
    ];
    return _SheetPage(children: [
      _SheetHeader('🇮🇳', 'All India Coverage', 'State-by-state rollout under Digital India mission'),
      const _InfoTile('📡', 'DILRMP Programme',
        'Digital India Land Records Modernisation Programme is digitizing all state land records. DigiSampatti integrates each state as portals go live.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: states.map((s) {
          final live = s[1] as bool;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: live ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: live ? const Color(0xFF66BB6A) : const Color(0xFFE0E0E0)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(live ? '🟢' : '🔜', style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(s[0] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: live ? FontWeight.bold : FontWeight.normal,
                  color: live ? const Color(0xFF2E7D32) : const Color(0xFF757575),
                )),
              if (live) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(4)),
                  child: const Text('LIVE', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _ruralTab() => _SheetPage(children: [
    _SheetHeader('🌾', 'For Every Indian', 'City flat · Village farm · Tribal land'),
    _InfoTile('🌿', 'Forest Rights Act 2006',
      'Tribal communities have legal rights over forest land they live on. FRA ensures every family\'s rights are properly recorded and protected.'),
    _InfoTile('⚖️', 'PESA Act 1996',
      'Gram Sabha has authority over land in Scheduled Areas. No land transfer without village council consent.'),
    _InfoTile('🛡️', 'Tribal Land Protection',
      'In Karnataka and most states, tribal land cannot be sold to non-tribals without government permission — protecting ancestral land.'),
    _InfoTile('🌾', 'Farmer & Small Landholders',
      'Verify your RTC, Khata and EC yourself from any phone. No need for agents or middlemen.'),
    _InfoTile('💡', 'Simple for Everyone',
      'No legal knowledge needed. If you can read a phone, you can protect your land.'),
  ]);

  Widget _pricesTab() => _SheetPage(children: [
    _SheetHeader('📈', 'Property Price Ranges', 'Karnataka approximate rates — village to metro'),
    _PriceRow('🌾', 'Gram Panchayat', '₹200 – ₹800 / sqft',   'Agricultural land, village areas', const Color(0xFF795548)),
    _PriceRow('🏘️', 'CMC / TMC Town',  '₹800 – ₹3,000 / sqft', 'Smaller cities, taluk headquarters', const Color(0xFF607D8B)),
    _PriceRow('🏗️', 'City Outskirts',  '₹3,000 – ₹8,000 / sqft','BDA layouts, peripheral areas', const Color(0xFF1976D2)),
    _PriceRow('🏙️', 'BBMP Bengaluru',  '₹5,000 – ₹20,000 / sqft','City proper, approved layouts', const Color(0xFF6A1B9A)),
    _PriceRow('🏢', 'Premium Metro',   '₹20,000 – ₹80,000 / sqft','CBD, Whitefield, Indiranagar', const Color(0xFFB71C1C)),
    const Padding(
      padding: EdgeInsets.only(top: 16),
      child: Text('Always verify current market price independently. These are indicative ranges only.',
        style: TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.4)),
    ),
  ]);

  Widget _govTab() => _SheetPage(children: [
    _SheetHeader('⚖️', 'Digital Governance', 'Government\'s mission for transparent land records'),
    _InfoTile('🗂️', 'Bhoomi Portal',
      'All Karnataka land records available online. Get your RTC copy instantly from home — fast, easy, and transparent.'),
    _InfoTile('📋', 'SAKALA Scheme',
      'Government guarantees service delivery within fixed days. Mutation, Khata transfers — all time-bound.'),
    _InfoTile('🔑', 'Kaveri 2.0',
      'Online property registration. Stamp duty payment, deed booking and EC — all from home.'),
    _InfoTile('📡', 'NLRMP / DILRMP',
      'National programme to digitize every survey stone, village map and land boundary across India.'),
    _InfoTile('🛡️', 'DigiSampatti Mission',
      'Putting verified government data directly in your hands — so every citizen can make confident, informed property decisions.'),
  ]);
}

class _SheetPage extends StatelessWidget {
  final List<Widget> children;
  const _SheetPage({required this.children});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: children,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String emoji, title, subtitle;
  const _SheetHeader(this.emoji, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        )),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji, title, description;
  const _InfoTile(this.emoji, this.title, this.description);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
          ])),
        ]),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String emoji, zone, range, desc;
  final Color color;
  const _PriceRow(this.emoji, this.zone, this.range, this.desc, this.color);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
            Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ])),
          Text(range, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
        ]),
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
