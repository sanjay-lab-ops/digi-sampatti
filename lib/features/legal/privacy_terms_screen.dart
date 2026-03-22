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
        _buildSection('Last updated: March 2026'),
        _buildSection('1. Information We Collect',
          'DigiSampatti collects your mobile phone number for authentication via OTP. We also collect property search data (survey numbers, districts, GPS coordinates) that you voluntarily enter to generate reports. We do not collect your name, email, or any financial information.'),
        _buildSection('2. How We Use Your Information',
          'Your phone number is used only for login verification via Firebase Authentication. Property search data is used to generate your legal report and store your report history. We do not sell, share, or trade your personal information with any third party.'),
        _buildSection('3. Report Storage',
          'Your property reports are stored securely on Google Firebase servers. Reports are linked to your phone number and are only accessible by you. You can delete your account and all associated data by contacting us.'),
        _buildSection('4. Payment Information',
          'Payments for PDF reports (₹99) are processed by Razorpay. DigiSampatti does not store your card number, UPI ID, or any payment credentials. All payment data is handled directly by Razorpay\'s secure servers.'),
        _buildSection('5. Location Data',
          'GPS location is accessed only when you use the Camera Scan feature to attach coordinates to a property scan. Location data is not tracked in the background. You can deny location permission and use Manual Search instead.'),
        _buildSection('6. Third-Party Services',
          'We use Google Firebase (authentication and storage), Razorpay (payments), Google Maps (map view), and Claude AI (legal analysis). Each service has its own privacy policy.'),
        _buildSection('7. Data Security',
          'All data is transmitted over HTTPS. Firebase security rules ensure only authenticated users can access their own data. We regularly review our security practices.'),
        _buildSection('8. Children\'s Privacy',
          'DigiSampatti is not intended for users under 18 years of age. We do not knowingly collect personal information from minors.'),
        _buildSection('9. Changes to This Policy',
          'We may update this Privacy Policy from time to time. We will notify you of significant changes via the app. Continued use of the app after changes means you accept the updated policy.'),
        _buildSection('10. Contact Us',
          'For any privacy concerns, data deletion requests, or questions, contact us at: support@digisampatti.com'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTermsOfService() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Last updated: March 2026'),
        _buildSection('1. Acceptance of Terms',
          'By downloading and using DigiSampatti, you agree to these Terms of Service. If you do not agree, do not use the app.'),
        _buildSection('2. Nature of Service — Important Disclaimer',
          'DigiSampatti provides property information for educational and reference purposes only. Our reports are based on publicly available data, AI analysis, and demo data (while real API integration is pending).\n\nDIGISAMPATTI REPORTS ARE NOT LEGAL ADVICE AND DO NOT REPLACE A REGISTERED ADVOCATE\'S LEGAL OPINION. Always consult a licensed property lawyer before making any purchase decision.'),
        _buildSection('3. Demo Data Notice',
          'Currently, DigiSampatti uses realistic demo data based on Karnataka land records formats. Real-time Bhoomi API integration is in progress. Reports generated currently are for demonstration purposes. We clearly indicate when data is demo vs real.'),
        _buildSection('4. Payment Terms',
          'PDF report download costs ₹99 per report (one-time). Subscription plan of ₹999/month gives unlimited reports. Payments are non-refundable once a report is generated and downloaded. Razorpay\'s payment terms also apply.'),
        _buildSection('5. Permitted Use',
          'You may use DigiSampatti for your personal property research. You may not: (a) use the app for commercial data scraping, (b) resell or redistribute our reports without permission, (c) attempt to reverse-engineer the app, or (d) use the app for any illegal purpose.'),
        _buildSection('6. Limitation of Liability',
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
