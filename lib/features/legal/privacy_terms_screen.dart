import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class PrivacyTermsScreen extends StatefulWidget {
  final bool showTerms; // true = Terms, false = Privacy Policy
  const PrivacyTermsScreen({super.key, this.showTerms = false});

  @override
  State<PrivacyTermsScreen> createState() => _PrivacyTermsScreenState();
}

class _PrivacyTermsScreenState extends State<PrivacyTermsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: widget.showTerms ? 1 : 0);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Legal'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Service'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildPrivacyPolicy(),
          _buildTermsOfService(),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Effective: April 1, 2026 · Last updated: April 3, 2026'),
        _buildSection('1. What We Collect',
          'We collect your mobile number (for OTP login) and property details you enter (survey number, district, taluk) to generate reports. Documents you upload for AI analysis are deleted from our servers within 24 hours. We never collect your full Aadhaar number — only the last 4 digits after OTP verification.'),
        _buildSection('2. How We Use Your Data',
          'Your data is used to generate property verification reports, process government service applications on your behalf, send property alert notifications, and process payments. We do not sell or share your data with any third party for commercial purposes.'),
        _buildSection('3. Government Portal Access',
          'DigiSampatti accesses Bhoomi, KAVERI/IGRS, CERSAI, eCourts, BBMP, RERA, and Benami IT Portal on your behalf as a public citizen right. No data licensing or government MOU is required. All retrieved data is displayed as-is — we do not modify any government records.'),
        _buildSection('4. Payment Information',
          'All payments are processed by Cashfree Payments. DigiSampatti does not store your card number, UPI ID, or any payment credentials. All payment data is handled entirely by Cashfree\'s PCI-DSS certified infrastructure.'),
        _buildSection('5. Location Data',
          'GPS location is accessed only when you explicitly use the land scan feature. Location is never tracked in the background. You can deny location permission and use manual survey number entry instead.'),
        _buildSection('6. Data Security',
          'All data in transit is encrypted using TLS 1.3. Documents are deleted within 24 hours. Payment data is never stored on our servers. Digital signatures use SHA-256 hashing and are tamper-evident.'),
        _buildSection('7. Your Rights (DPDP Act 2023)',
          'You have the right to access, correct, or delete your personal data. To exercise any right, email: privacy@digisampatti.in. We will respond within 30 days as required by the Digital Personal Data Protection Act 2023.'),
        _buildSection('8. Children\'s Privacy',
          'DigiSampatti is intended for users 18 years and older. We do not knowingly collect data from minors.'),
        _buildSection('9. Changes to This Policy',
          'We will notify you of material changes via push notification at least 7 days before they take effect. Continued use after that date means you accept the updated policy.'),
        _buildSection('10. Contact',
          'Data Protection Officer: privacy@digisampatti.in · Response within 30 days'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTermsOfService() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Effective: April 1, 2026'),
        _buildSection('1. Acceptance of Terms',
          'By downloading and using DigiSampatti, you agree to these Terms of Service. If you do not agree, do not use the app.'),
        _buildSection('2. Nature of Service',
          'DigiSampatti is a private PropTech SaaS platform that accesses publicly available government databases on your behalf as a citizen right. Our reports reflect the state of public records at the time of query.\n\nDIGISAMPATTI REPORTS ARE NOT LEGAL ADVICE AND DO NOT REPLACE A REGISTERED ADVOCATE\'S OPINION. Always consult a licensed property lawyer before making any purchase decision.'),
        _buildSection('3. Payment Terms',
          'Fees: ₹9 basic scan, ₹199 full verification, ₹499 legal expert, ₹2,999 mutation service. Payments processed by Cashfree. Payments are non-refundable once a report is generated. Government service fees are passed through at cost.'),
        _buildSection('4. Permitted Use',
          'You may use DigiSampatti for your personal property research. You may not: (a) use the app for commercial data scraping, (b) resell or redistribute our reports without permission, (c) attempt to reverse-engineer the app, or (d) use the app for any illegal purpose.'),
        _buildSection('5. Limitation of Liability',
          'DigiSampatti is not liable for any financial loss, property dispute, or legal complication arising from decisions made based on our reports. We strongly recommend independent legal verification before any property transaction.'),
        _buildSection('7. Intellectual Property',
          'All content, design, and code in DigiSampatti is the property of DigiSampatti (registered under Indian law). You may not copy, reproduce, or distribute our content without written permission.'),
        _buildSection('8. Account Termination',
          'We reserve the right to suspend or terminate accounts that violate these terms. You may delete your account at any time by contacting support.'),
        _buildSection('9. Governing Law',
          'These terms are governed by the laws of India, specifically Karnataka state laws. Any disputes shall be resolved in courts of jurisdiction in Bengaluru, Karnataka.'),
        _buildSection('10. Contact',
          'For questions about these terms: support@digisampatti.com'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(String title, [String? body]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(
              fontSize: 13, color: AppColors.textMedium, height: 1.6)),
          ],
        ],
      ),
    );
  }
}
