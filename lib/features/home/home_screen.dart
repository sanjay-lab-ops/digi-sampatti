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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text(l.homeTitle),
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
            _WelcomeBanner(
              userName: user?.phoneNumber ?? '',
              headline: l.knowBeforeYouBuy,
            ),
            const SizedBox(height: 20),

            // ── Quick Action Buttons
            Text(
              l.startPropertyCheck,
              style: const TextStyle(
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
                    title: l.scanProperty,
                    subtitle: 'Take photo + GPS',
                    color: AppColors.primary,
                    onTap: () => context.push('/scan/camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.search,
                    title: l.manualSearch,
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
                    title: l.myReports,
                    subtitle: 'Past searches',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push('/history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.people,
                    title: l.brokerZone,
                    subtitle: '5 free reports',
                    color: const Color(0xFFD97706),
                    onTap: () => context.push('/broker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
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
                    child: Text(l.moreTools, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  ),
                  const Divider(height: 1),
                  _ToolRow(Icons.home_work, 'Property Transfer', 'Stamp Duty · Mutation · SRO', const Color(0xFF1A237E), () => context.push('/transfer')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.account_balance_wallet, 'Financial Tools', 'EMI · Total Cost · Loan Eligibility', const Color(0xFF1B5E20), () => context.push('/tools')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.school, 'Buyer Guides', 'Apartment · DC Conversion · Glossary', const Color(0xFF4A1942), () => context.push('/guides')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.people_outline, 'Expert Help', 'Lawyer · Bank · Insurance · Developers', AppColors.warning, () => context.push('/partners')),
                  const Divider(height: 1, indent: 56),
                  _ToolRow(Icons.gavel, 'Court Case Check', 'eCourts · Disputes · Injunctions', const Color(0xFF1A237E), () => context.push('/ecourts')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Investor Confidence Banner
            const _InvestorBanner(),
            const SizedBox(height: 16),

            // ── Digital India Expansion
            const _DigitalIndiaSection(),
            const SizedBox(height: 16),

            // ── Rural & Tribal Access
            const _TribalInclusionCard(),
            const SizedBox(height: 16),

            // ── Property Price Ladder
            const _PriceLadderCard(),
            const SizedBox(height: 16),

            // ── Clean Governance
            const _CleanGovernanceCard(),
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
                Text(
                  l.recentReports,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (recentReports.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: const Text(AppStrings.viewAll),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentReports.isEmpty)
              _EmptyReportsCard(noReportsText: l.noReports)
            else
              ...recentReports.take(5).map((r) => _RecentReportCard(report: r)),
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
  const _WelcomeBanner({required this.userName, required this.headline});

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

// ─── Tribal & Rural Inclusion Card ───────────────────────────────────────────
class _TribalInclusionCard extends StatelessWidget {
  const _TribalInclusionCard();

  static const _rights = [
    _RightItem(Icons.forest,           '🌿 Forest Rights Act 2006',   'Tribal communities have legal rights over forest land they live on. FRA ensures every family\'s rights are properly recorded and protected.'),
    _RightItem(Icons.account_balance,  '⚖️ PESA Act 1996',            'Gram Sabha (village council) has authority over land in Scheduled Areas. No transfer without their consent.'),
    _RightItem(Icons.shield,           '🛡️ Anti-Alienation Laws',     'In Karnataka & most states, tribal land cannot be sold to non-tribals without government permission.'),
    _RightItem(Icons.agriculture,      '🌾 Agricultural Land Rights', 'Farmers and small landholders can verify if their RTC, Khata, and EC are correct — free of brokers.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🌍', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'For Every Indian',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'City flat · Village farm · Forest village · Tribal land — your land rights matter equally.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),

          // Rights list
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: _rights.asMap().entries.map((e) {
                final item = e.value;
                return Column(
                  children: [
                    _ExpandableRight(item: item),
                    if (e.key < _rights.length - 1)
                      const Divider(height: 16, color: Color(0xFFE8F5E9)),
                  ],
                );
              }).toList(),
            ),
          ),

          // Footer note
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 13)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DigiSampatti is designed for simple use — no legal knowledge needed. If you can read a phone, you can protect your land.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF5D4037), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightItem {
  final IconData icon;
  final String title;
  final String description;
  const _RightItem(this.icon, this.title, this.description);
}

class _ExpandableRight extends StatefulWidget {
  final _RightItem item;
  const _ExpandableRight({required this.item});

  @override
  State<_ExpandableRight> createState() => _ExpandableRightState();
}

class _ExpandableRightState extends State<_ExpandableRight> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.item.icon, size: 16, color: const Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 16, color: const Color(0xFF81C784),
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  widget.item.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF37474F), height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Property Price Ladder ────────────────────────────────────────────────────
class _PriceLadderCard extends StatelessWidget {
  const _PriceLadderCard();

  static const _zones = [
    _Zone('Gram\nPanchayat', '₹200–\n800/sqft',   '🌾', Color(0xFF795548)),
    _Zone('CMC/TMC\nTown',   '₹800–\n3,000/sqft', '🏘️', Color(0xFF607D8B)),
    _Zone('City\nOutskirts', '₹3k–\n8k/sqft',     '🏗️', Color(0xFF1976D2)),
    _Zone('BBMP\nBengaluru', '₹5k–\n20k/sqft',    '🏙️', Color(0xFF6A1B9A)),
    _Zone('Premium\nMetro',  '₹20k–\n80k/sqft',   '🏢', Color(0xFFB71C1C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: Color(0xFF1976D2)),
                SizedBox(width: 8),
                Text('Property Price Ranges — Village to Metro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF37474F))),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('Karnataka approximate rates. Always verify current market price.',
              style: TextStyle(fontSize: 10, color: Color(0xFF90A4AE))),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final z = _zones[i];
                final isLast = i == _zones.length - 1;
                return Row(
                  children: [
                    Container(
                      width: 88,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: z.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: z.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(z.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(z.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: z.color, fontWeight: FontWeight.bold, height: 1.2)),
                          const SizedBox(height: 3),
                          Text(z.price,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: z.color, height: 1.2)),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Icon(Icons.arrow_forward, size: 14, color: Colors.grey[300]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Zone {
  final String label, price, emoji;
  final Color color;
  const _Zone(this.label, this.price, this.emoji, this.color);
}

// ─── Clean Governance Card ────────────────────────────────────────────────────
class _CleanGovernanceCard extends StatelessWidget {
  const _CleanGovernanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Text('⚖️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Corruption-Free Land Records',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Karnataka Revenue Dept. Digital Mission',
                        style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: const Column(
              children: [
                _GovItem('🗂️', 'Bhoomi Portal',
                  'All Karnataka land records available online. Get your RTC copy instantly from home — fast, easy, and transparent.'),
                Divider(height: 16),
                _GovItem('📋', 'SAKALA Scheme',
                  'Government guarantees service delivery within fixed days. Delayed mutation or khata = compensation.'),
                Divider(height: 16),
                _GovItem('🔑', 'Kaveri 2.0',
                  'Online property registration. Stamp duty payment, deed booking, and EC — all from home.'),
                Divider(height: 16),
                _GovItem('📡', 'NLRMP / DILRMP',
                  'National programme to digitize every survey stone, village map, and land boundary in India.'),
                Divider(height: 16),
                _GovItem('🛡️', 'DigiSampatti Mission',
                  'Putting verified government data directly in your hands — so every citizen can make confident, informed property decisions.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GovItem extends StatelessWidget {
  final String emoji, title, description;
  const _GovItem(this.emoji, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A237E))),
              const SizedBox(height: 3),
              Text(description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Digital India Section ────────────────────────────────────────────────────
class _DigitalIndiaSection extends StatelessWidget {
  const _DigitalIndiaSection();

  // States grouped: Live → Metro priority → Southern → Northern → Eastern → NE → UTs
  static const _states = [
    // ── Live
    _StateItem('Karnataka',           true,  '🟢'),
    // ── Metros / High Priority
    _StateItem('Delhi',               false, '🔜'),
    _StateItem('Maharashtra',         false, '🔜'),
    _StateItem('Telangana',           false, '🔜'),
    _StateItem('Tamil Nadu',          false, '🔜'),
    _StateItem('Gujarat',             false, '🔜'),
    _StateItem('West Bengal',         false, '🔜'),
    // ── South
    _StateItem('Kerala',              false, '🔜'),
    _StateItem('Andhra Pradesh',      false, '🔜'),
    _StateItem('Goa',                 false, '🔜'),
    // ── North
    _StateItem('Uttar Pradesh',       false, '🔜'),
    _StateItem('Rajasthan',           false, '🔜'),
    _StateItem('Haryana',             false, '🔜'),
    _StateItem('Punjab',              false, '🔜'),
    _StateItem('Madhya Pradesh',      false, '🔜'),
    _StateItem('Himachal Pradesh',    false, '🔜'),
    _StateItem('Uttarakhand',         false, '🔜'),
    _StateItem('J & K',               false, '🔜'),
    // ── East & Central
    _StateItem('Bihar',               false, '🔜'),
    _StateItem('Jharkhand',           false, '🔜'),
    _StateItem('Odisha',              false, '🔜'),
    _StateItem('Chhattisgarh',        false, '🔜'),
    _StateItem('Assam',               false, '🔜'),
    // ── North-East
    _StateItem('Meghalaya',           false, '🔜'),
    _StateItem('Manipur',             false, '🔜'),
    _StateItem('Nagaland',            false, '🔜'),
    _StateItem('Mizoram',             false, '🔜'),
    _StateItem('Tripura',             false, '🔜'),
    _StateItem('Arunachal Pradesh',   false, '🔜'),
    _StateItem('Sikkim',              false, '🔜'),
    // ── UTs
    _StateItem('Chandigarh',          false, '🔜'),
    _StateItem('Puducherry',          false, '🔜'),
    _StateItem('Andaman & Nicobar',   false, '🔜'),
    _StateItem('Lakshadweep',         false, '🔜'),
    _StateItem('Ladakh',              false, '🔜'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar — tricolor accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFF4CAF50)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital India · Property Platform',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'PM Modi\'s vision: every citizen empowered with land data',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Expanding', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // States grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'State Coverage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF37474F)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _states.map((s) => _StateChip(s)).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Color(0xFF388E3C)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DILRMP — Digital India Land Records Modernisation Programme — is digitizing all 36 state & UT land records under PM Modi\'s Digital India mission. DigiSampatti integrates state-by-state as portals go live.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateItem {
  final String name;
  final bool live;
  final String emoji;
  const _StateItem(this.name, this.live, this.emoji);
}

class _StateChip extends StatelessWidget {
  final _StateItem state;
  const _StateChip(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: state.live ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: state.live ? const Color(0xFF66BB6A) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            state.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: state.live ? FontWeight.bold : FontWeight.normal,
              color: state.live ? const Color(0xFF2E7D32) : const Color(0xFF757575),
            ),
          ),
          if (state.live) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Investor Confidence Banner ───────────────────────────────────────────────
class _InvestorBanner extends StatelessWidget {
  const _InvestorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invest with Confidence',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  'Dubai, Singapore & UAE require full legal due diligence before every property deal. DigiSampatti brings the same standard to Karnataka.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
                SizedBox(height: 6),
                Text(
                  '🏙️  Property Expo Ready  ·  Investor Grade Reports',
                  style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
