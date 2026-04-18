import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class PropertyTransferScreen extends StatelessWidget {
  const PropertyTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Property Transfer Guide')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            const Text('Transfer Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildToolCard(
              context,
              icon: Icons.calculate,
              title: 'Stamp Duty Calculator',
              subtitle: 'Calculate stamp duty + registration charges',
              color: AppColors.primary,
              onTap: () => context.push('/transfer/stamp-duty'),
            ),
            const SizedBox(height: 10),
            _buildToolCard(
              context,
              icon: Icons.checklist,
              title: 'Document Checklist',
              subtitle: 'All documents needed for property transfer',
              color: AppColors.info,
              onTap: () => context.push('/transfer/documents'),
            ),
            const SizedBox(height: 10),
            _buildToolCard(
              context,
              icon: Icons.swap_horiz,
              title: 'Mutation Guide',
              subtitle: 'Step-by-step Bhoomi + Khata name transfer',
              color: AppColors.violet,
              onTap: () => context.push('/transfer/mutation'),
            ),
            const SizedBox(height: 10),
            _buildToolCard(
              context,
              icon: Icons.location_on,
              title: 'Sub-Registrar Office Locator',
              subtitle: 'Find your office, timings, documents',
              color: AppColors.safe,
              onTap: () => context.push('/transfer/sro'),
            ),
            const SizedBox(height: 10),
            _buildToolCard(
              context,
              icon: Icons.how_to_reg,
              title: 'Registration Day Guide',
              subtitle: 'Steps · Checklist · Tips for SRO visit',
              color: const Color(0xFFB45309),
              onTap: () => context.push('/transfer/registration'),
            ),
            const SizedBox(height: 20),
            _buildTimelineCard(),
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
          colors: [AppColors.indigo, Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.home_work, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Property Transfer', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          SizedBox(height: 8),
          Text('Complete Transfer Guide', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('From sale deed to mutation — everything in one place', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, {
    required IconData icon, required String title,
    required String subtitle, required Color color, required VoidCallback onTap,
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

  Widget _buildTimelineCard() {
    const steps = [
      ('1', 'Verify Property', 'Arth ID report — confirm legal status', true),
      ('2', 'Draft Sale Deed', 'Hire advocate to draft sale deed', true),
      ('3', 'Pay Stamp Duty', 'Pay at bank or franking center', true),
      ('4', 'Register at SRO', 'Both buyer + seller visit Sub-Registrar', true),
      ('5', 'Apply for Mutation', 'Submit mutation application in Bhoomi', false),
      ('6', 'Khata Transfer', 'Apply at BBMP/Panchayat for Khata', false),
      ('7', 'Property Tax Update', 'Update name in property tax records', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transfer Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: s.$4 ? AppColors.primary : AppColors.borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(s.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                  if (s.$1 != '7') Container(width: 2, height: 24, color: AppColors.borderColor),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(s.$3, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
