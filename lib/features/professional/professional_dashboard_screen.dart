import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/professional_model.dart';
import 'package:digi_sampatti/core/services/professional_service.dart';

// ─── Dashboard for a registered professional ──────────────────────────────────
// Shows: verification status, incoming buyer leads, profile stats, quick actions.

class ProfessionalDashboardScreen extends ConsumerWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStream = ProfessionalService().watchMyProfile();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/professional/register'),
            tooltip: 'Update Profile',
          ),
        ],
      ),
      body: StreamBuilder<ProfessionalProfile?>(
        stream: profileStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snap.data;
          if (profile == null) {
            return _buildNotRegistered(context);
          }

          return _buildDashboard(context, profile);
        },
      ),
    );
  }

  Widget _buildNotRegistered(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_center_outlined, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('Not Registered as Partner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Register as a property professional to receive leads from verified buyers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/professional/register'),
              child: const Text('Register as Partner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ProfessionalProfile profile) {
    final leadsStream = ProfessionalService().watchMyLeads();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(profile),
          const SizedBox(height: 16),
          _buildStatsRow(profile),
          const SizedBox(height: 20),
          const Text('Buyer Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),
          StreamBuilder<List<ProfessionalLead>>(
            stream: leadsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final leads = snap.data ?? [];
              if (leads.isEmpty) {
                return _buildNoLeads();
              }
              return Column(
                children: leads.map((l) => _buildLeadCard(context, l)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTipsCard(profile.status),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ProfessionalProfile profile) {
    final status = profile.status;
    Color bgColor, textColor, borderColor;
    IconData icon;

    switch (status) {
      case VerificationStatus.pending:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFF7B5800);
        borderColor = const Color(0xFFFFD54F);
        icon = Icons.hourglass_empty;
        break;
      case VerificationStatus.verified:
        bgColor = AppColors.surfaceGreen;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        icon = Icons.verified;
        break;
      case VerificationStatus.rejected:
        bgColor = AppColors.statusDangerBg;
        textColor = AppColors.statusDangerText;
        borderColor = AppColors.danger;
        icon = Icons.cancel_outlined;
        break;
      case VerificationStatus.suspended:
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
        borderColor = const Color(0xFF9C27B0);
        icon = Icons.pause_circle_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (profile.profilePhotoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(profile.profilePhotoUrl!,
                      width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 48, color: AppColors.textLight)),
                )
              else
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.3), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: textColor),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                    Text(profile.type.label,
                        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: textColor),
                    const SizedBox(width: 5),
                    Text(status.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(status.description,
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8), height: 1.4)),
          if (status == VerificationStatus.rejected && profile.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text('Reason: ${profile.rejectionReason}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.statusDangerText)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProfessionalProfile profile) {
    return Row(
      children: [
        _statCard('${profile.leadCount}', 'Leads', Icons.person_pin_outlined, AppColors.primary),
        const SizedBox(width: 10),
        _statCard(profile.rating.toStringAsFixed(1), 'Rating', Icons.star_outlined, const Color(0xFFF57C00)),
        const SizedBox(width: 10),
        _statCard('${profile.reviewCount}', 'Reviews', Icons.reviews_outlined, AppColors.arthBlue),
        const SizedBox(width: 10),
        _statCard('${profile.yearsExperience}y', 'Exp', Icons.timeline_outlined, AppColors.esign),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, ProfessionalLead lead) {
    final isNew = lead.status == 'new';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? AppColors.primary.withOpacity(0.4) : AppColors.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isNew ? AppColors.primary.withOpacity(0.1) : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline,
                color: isNew ? AppColors.primary : AppColors.textLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(lead.buyerPhone,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (lead.surveyNumber != null || lead.district != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (lead.district != null) lead.district!,
                      if (lead.surveyNumber != null) 'Sy No: ${lead.surveyNumber}',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
                if (lead.message != null) ...[
                  const SizedBox(height: 4),
                  Text(lead.message!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _actionBtn(
                      'Call',
                      Icons.phone,
                      () async {
                        final url = Uri.parse('tel:${lead.buyerPhone}');
                        if (await canLaunchUrl(url)) launchUrl(url);
                        ProfessionalService().markLeadContacted(lead.id);
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      'WhatsApp',
                      Icons.chat,
                      () async {
                        final num = lead.buyerPhone.replaceAll('+', '');
                        final url = Uri.parse('https://wa.me/$num');
                        if (await canLaunchUrl(url)) launchUrl(url);
                        ProfessionalService().markLeadContacted(lead.id);
                      },
                      primary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap, {bool primary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: primary ? Colors.white : AppColors.primary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: primary ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLeads() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
          SizedBox(height: 12),
          Text('No leads yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text(
            'Once your profile is verified and live, buyers in your district will see you and send requests here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(VerificationStatus status) {
    if (status != VerificationStatus.verified) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2))),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tips to get more leads',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
          SizedBox(height: 8),
          _Tip('Add a clear profile photo — it increases trust'),
          _Tip('Write a detailed bio about your specialisation'),
          _Tip('Keep your WhatsApp number updated for instant response'),
          _Tip('Respond to leads within 1 hour — faster response = higher ranking'),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textDark, height: 1.4))),
        ],
      ),
    );
  }
}
