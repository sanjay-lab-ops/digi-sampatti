import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class BuyerGuidesScreen extends StatelessWidget {
  const BuyerGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buyer Guides')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            const Text('Property Type Guides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildCard(context, Icons.apartment, 'Apartment Buyer Guide',
              'OC, CC, RERA, UDS — what to check before buying a flat',
              AppColors.primary, () => context.push('/guides/apartment')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.landscape, 'DC Conversion Guide',
              'Agricultural → Residential/Commercial/Industrial',
              AppColors.violet, () => context.push('/guides/dc-conversion')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.warning_amber, 'Red Flags Guide',
              '15 warning signs of a fraudulent property deal',
              AppColors.danger, () => context.push('/guides/red-flags')),
            const SizedBox(height: 20),
            const Text('Learn the Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildCard(context, Icons.menu_book, 'Legal Glossary',
              'RTC, EC, Khata, UDS, OC, CC — explained simply',
              AppColors.info, () => context.push('/guides/glossary')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.quiz, 'FAQ — Common Questions',
              'Answers to 20 most asked property questions',
              AppColors.safe, () => context.push('/guides/faq')),
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
          colors: [Color(0xFF4A1942), Color(0xFF6B2D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.school, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Education & Guides', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          SizedBox(height: 8),
          Text('Know Before You Sign', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Understand every document, term, and red flag', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
