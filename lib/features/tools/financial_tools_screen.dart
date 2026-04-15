import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Financial Tools')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            const Text('Calculators', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _buildCard(context, Icons.calculate, 'EMI Calculator',
              'Monthly EMI for any loan amount & interest rate', AppColors.primary,
              () => context.push('/tools/emi')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.receipt_long, 'Total Cost Calculator',
              'Property price + stamp duty + registration + interior', AppColors.violet,
              () => context.push('/tools/total-cost')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.account_balance, 'Property Tax Estimator',
              'Estimate annual BBMP/Panchayat property tax', AppColors.info,
              () => context.push('/tools/property-tax')),
            const SizedBox(height: 10),
            _buildCard(context, Icons.trending_up, 'Home Loan Eligibility',
              'Your salary → how much loan you can get', AppColors.safe,
              () => context.push('/tools/loan-eligibility')),
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
          colors: [AppColors.primary, AppColors.safe],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Financial Planning', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          SizedBox(height: 8),
          Text('Know the True Cost', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('EMI, taxes, hidden costs — all calculated before you buy', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
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
