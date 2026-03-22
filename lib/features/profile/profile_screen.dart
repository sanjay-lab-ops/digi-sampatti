import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final reports = ref.watch(recentReportsProvider);
    final lang = ref.watch(languageProvider);
    final l = AppL10n(lang);
    final phone = user?.phoneNumber ?? 'Unknown';
    final maskedPhone = phone.length > 5
        ? '${phone.substring(0, phone.length - 4)}****'
        : phone;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.myProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(maskedPhone,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l.memberSince,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(child: _StatBox(
                  value: '${reports.length}',
                  label: l.reportsGenerated,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(
                  value: reports.isEmpty ? '—' : _safeScore(reports.first.riskAssessment.score),
                  label: l.lastSafetyScore,
                  color: AppColors.safe,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(
                  value: 'Beta',
                  label: l.appVersion,
                  color: AppColors.warning,
                )),
              ],
            ),
            const SizedBox(height: 16),

            // Menu
            _buildMenuCard([
              _MenuItem(Icons.subscriptions_outlined, l.plansPricing,
                '₹99/report · ₹999/month', AppColors.primary,
                () => context.push('/subscription')),
              _MenuItem(Icons.history, l.myReports,
                'View all past reports', AppColors.info,
                () => context.push('/history')),
              _MenuItem(Icons.people_outline, l.expertHelp,
                'Lawyers, banks, developers', AppColors.warning,
                () => context.push('/partners')),
            ]),
            const SizedBox(height: 12),
            _buildMenuCard([
              _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy',
                'How we protect your data', AppColors.textMedium,
                () => context.push('/privacy')),
              _MenuItem(Icons.description_outlined, 'Terms of Service',
                'Usage terms', AppColors.textMedium,
                () => context.push('/terms')),
              _MenuItem(Icons.info_outline, l.aboutApp,
                'v1.0 Beta · Property Verification Platform', AppColors.textMedium,
                () => _showAbout(context)),
            ]),
            const SizedBox(height: 12),
            // Language toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: AppColors.info, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.language,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('English / ಕನ್ನಡ',
                          style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Switch(
                    value: lang == 'kn',
                    activeColor: AppColors.primary,
                    onChanged: (v) => ref.read(languageProvider.notifier)
                        .setLanguage(v ? 'kn' : 'en'),
                  ),
                  Text(lang == 'kn' ? 'ಕನ್ನಡ' : 'EN',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard([
              _MenuItem(Icons.logout, l.signOut,
                'Log out of your account', AppColors.danger,
                () => _signOut(context)),
            ]),
            const SizedBox(height: 24),
            const Text('DigiSampatti v1.0 Beta',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const Text('Property Verification Platform',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _safeScore(int score) {
    if (score >= 70) return '$score ✓';
    if (score >= 40) return '$score !';
    return '$score ✗';
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: items.asMap().entries.map((e) => Column(
          children: [
            InkWell(
              onTap: e.value.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: e.value.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(e.value.icon, color: e.value.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.title,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                              color: e.value.color == AppColors.danger ? AppColors.danger : AppColors.textDark)),
                          Text(e.value.subtitle,
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            if (e.key < items.length - 1) const Divider(height: 1, indent: 64),
          ],
        )).toList(),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: AppColors.surfaceGreen, shape: BoxShape.circle),
              child: const Icon(Icons.verified_user, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('DigiSampatti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('v1.0 Beta', style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 12),
            const Text(
              'DigiSampatti verifies properties so you can buy with confidence.\nCheck land records, get AI analysis, download report.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
            const SizedBox(height: 12),
            const Text('support@digisampatti.com',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/auth');
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, this.color, this.onTap);
}
