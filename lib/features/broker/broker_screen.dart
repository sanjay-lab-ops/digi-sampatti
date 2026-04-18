import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class BrokerScreen extends StatelessWidget {
  const BrokerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Broker Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 20),
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              icon: Icons.search,
              title: 'Verify Property for Client',
              subtitle: 'Run instant legal check — share report with client',
              color: AppColors.primary,
              onTap: () => context.push('/scan/manual'),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              context,
              icon: Icons.history,
              title: 'My Past Reports',
              subtitle: 'View and share previously generated reports',
              color: AppColors.info,
              onTap: () => context.push('/history'),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              context,
              icon: Icons.share,
              title: 'Refer Arth ID',
              subtitle: 'Earn ₹50 for every client who buys a report',
              color: AppColors.safe,
              onTap: () => _showReferralDialog(context),
            ),
            const SizedBox(height: 20),
            _buildFreeTrialBanner(),
            const SizedBox(height: 20),
            _buildReferralCard(context),
            const SizedBox(height: 20),
            _buildBenefits(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Verified Broker Partner', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          SizedBox(height: 8),
          Text('Welcome, Partner!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Free reports available • Earn per referral', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '5', label: 'Free\nReports Left', color: AppColors.safe)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '0', label: 'Reports\nGenerated', color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '₹0', label: 'Referral\nEarnings', color: AppColors.warning)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free Trial Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('5 free reports for your first clients. After that ₹499/report or ₹1,999/month unlimited.', style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      ('Instant digital report', 'Share PDF with client in seconds', Icons.picture_as_pdf),
      ('AI risk score', 'Clear Safe / Caution / Danger rating', Icons.psychology),
      ('Khata A/B check', 'Loan eligibility shown instantly', Icons.account_balance),
      ('Commission income', '₹50 per referral to Arth ID', Icons.currency_rupee),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Why Arth ID for Brokers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...benefits.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.surfaceGreen, borderRadius: BorderRadius.circular(8)),
                child: Icon(b.$3, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(b.$2, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    const referralCode = 'BROKER001';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo, Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.card_giftcard, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Your Referral Code', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(referralCode, style: TextStyle(
                color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.bold, letterSpacing: 4,
              )),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: referralCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied!'), duration: Duration(seconds: 1)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.copy, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Share this code — earn ₹50 when someone pays for a report',
            style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    const referralCode = 'BROKER001';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your Referral Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(referralCode, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 4)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Share this code with clients. You earn ₹50 when they buy a report.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
