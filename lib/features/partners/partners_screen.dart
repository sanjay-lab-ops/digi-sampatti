import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';

// ─── Partners Screen ───────────────────────────────────────────────────────────
// Commission-based referral screen shown after legal report.
// DigiSampatti earns referral fee from each partner.
// User pays the partner directly — transparent model.

class PartnersScreen extends StatelessWidget {
  final Map<String, dynamic>? reportData;
  const PartnersScreen({super.key, this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Get Expert Help'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSectionTitle('Legal Help'),
            const SizedBox(height: 12),
            _buildPartnerCard(
              context: context,
              icon: Icons.gavel,
              iconColor: const Color(0xFF1A237E),
              title: AppStrings.partnerLawyerTitle,
              description: AppStrings.partnerLawyerDesc,
              cta: AppStrings.partnerLawyerCta,
              badge: 'Most Popular',
              badgeColor: AppColors.primary,
              commissionNote: 'Physical verification + court checks + title search',
              onTap: () => _showContactDialog(
                context,
                title: 'Connect with Property Advocate',
                message: 'We will connect you with a verified property advocate in your district within 2 hours.',
                phone: '+91-XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),
            _buildPartnerCard(
              context: context,
              icon: Icons.straighten,
              iconColor: const Color(0xFF1B5E20),
              title: AppStrings.partnerSurveyorTitle,
              description: AppStrings.partnerSurveyorDesc,
              cta: AppStrings.partnerSurveyorCta,
              badge: null,
              badgeColor: null,
              commissionNote: 'Physical boundary measurement + survey sketch comparison',
              onTap: () => _showContactDialog(
                context,
                title: 'Book Licensed Surveyor',
                message: 'A government-licensed surveyor will visit the property and verify boundaries.',
                phone: '+91-XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Home Loan'),
            const SizedBox(height: 12),
            _buildPartnerCard(
              context: context,
              icon: Icons.account_balance,
              iconColor: const Color(0xFF0D47A1),
              title: AppStrings.partnerBankTitle,
              description: AppStrings.partnerBankDesc,
              cta: AppStrings.partnerBankCta,
              badge: 'Free Check',
              badgeColor: AppColors.safe,
              commissionNote: 'Pre-verified property = faster approval + better rate',
              onTap: () => _showLoanDialog(context),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Property Protection'),
            const SizedBox(height: 12),
            _buildPartnerCard(
              context: context,
              icon: Icons.shield,
              iconColor: const Color(0xFF4A148C),
              title: AppStrings.partnerInsuranceTitle,
              description: AppStrings.partnerInsuranceDesc,
              cta: AppStrings.partnerInsuranceCta,
              badge: 'Recommended',
              badgeColor: const Color(0xFF4A148C),
              commissionNote: 'Protects against future ownership disputes and hidden claims',
              onTap: () => _showContactDialog(
                context,
                title: 'Get Title Insurance Quote',
                message: 'One-time premium protects your property forever from undiscovered legal disputes.',
                phone: '+91-XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Verified Developers'),
            const SizedBox(height: 4),
            const Text('DigiSampatti verified projects — legally checked before listing',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 12),
            _buildDeveloperCard(
              context,
              name: 'Brigade Group',
              tagline: 'RERA registered · 35+ years · Bengaluru',
              projects: ['Brigade Orchards', 'Brigade Utopia', 'Brigade Omega'],
              color: const Color(0xFF1A237E),
              badge: 'MOU Partner',
            ),
            const SizedBox(height: 10),
            _buildDeveloperCard(
              context,
              name: 'Century Real Estate',
              tagline: 'Premium plots & villas · Bengaluru',
              projects: ['Century Indus', 'Century Ethos', 'Century Horizon'],
              color: const Color(0xFF4A148C),
              badge: 'Verified',
            ),
            const SizedBox(height: 10),
            _buildDeveloperCard(
              context,
              name: 'Prestige Group',
              tagline: 'RERA · Apartments, villas, commercial',
              projects: ['Prestige Lakeside', 'Prestige Primrose Hills'],
              color: const Color(0xFF1B5E20),
              badge: 'Verified',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Are you a Developer or Builder?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        SizedBox(height: 2),
                        Text('List your project — reach verified, serious buyers', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDisclaimerCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Property is Digitally Verified ✓',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your due diligence with verified experts. '
            'All partners pre-screened by DigiSampatti.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildPartnerCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String cta,
    required String? badge,
    required Color? badgeColor,
    required String commissionNote,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: badgeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        commissionNote,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, {
    required String name, required String tagline,
    required List<String> projects, required Color color, required String badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(badge, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(tagline, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: projects.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderColor)),
                          child: Text(p, style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderColor))),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showContactDialog(context,
                  title: 'Enquire about $name',
                  message: 'Our team will share verified project details and connect you with $name sales team. DigiSampatti verified buyers get priority response.',
                  phone: '+91-XXXXXXXXXX'),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Enquire about projects', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                      Icon(Icons.arrow_forward_ios, size: 13, color: color),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textLight),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              AppStrings.partnerDisclaimer,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String phone,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone),
                label: const Text('Request Callback'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apply for Home Loan',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.safe.withOpacity(0.2)),
              ),
              child: const Text(
                '✅ This property has passed DigiSampatti legal verification. '
                'This gives you a stronger case for faster loan approval.',
                style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select your preferred lender:',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _buildLenderOption('HDFC Bank', '8.5% p.a. onwards'),
            _buildLenderOption('SBI Home Loans', '8.4% p.a. onwards'),
            _buildLenderOption('ICICI Bank', '8.75% p.a. onwards'),
            _buildLenderOption('Bajaj Finserv', '8.6% p.a. onwards'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Check My Eligibility — Free'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLenderOption(String name, String rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          Text(rate,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}
