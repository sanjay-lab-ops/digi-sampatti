import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ── Entry Screen — shown before OTP login ─────────────────────────────────────
// Single entry point for all users: buyers, sellers, brokers, banks, lawyers.
// Everyone is a customer. No separate login types.
// ─────────────────────────────────────────────────────────────────────────────

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('DigiSampatti',
                style: TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.w900, letterSpacing: .5)),
            const Text('ಡಿಜಿ ಸಂಪತ್ತಿ',
                style: TextStyle(color: Colors.amber, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('India\'s Property Intelligence Platform',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 32),

            // Bottom sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Verify any property in 90 seconds',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.primary)),
                    const SizedBox(height: 6),
                    const Text(
                        'For buyers, sellers, brokers, banks and lawyers — '
                        'one platform, one login.',
                        style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
                    const SizedBox(height: 24),

                    // Feature chips
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: const [
                        _Chip('7 Govt Portals'),
                        _Chip('8 Fraud Types Blocked'),
                        _Chip('90 Seconds'),
                        _Chip('Zero Office Visits'),
                        _Chip('DPDP Act 2023'),
                        _Chip('Patent Pending'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main CTA
                    ElevatedButton(
                      onPressed: () => context.go('/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Get Started — Enter Phone Number',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),

                    // Demo
                    OutlinedButton.icon(
                      onPressed: () => context.push('/demo'),
                      icon: const Icon(Icons.play_circle_outline,
                          color: AppColors.primary, size: 18),
                      label: const Text('View Demo Report',
                          style: TextStyle(color: AppColors.primary, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Spacer(),
                    const Center(
                      child: Text(
                        'Startup India: IN-0326-9427JD · Patent Provisional Filed',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}
