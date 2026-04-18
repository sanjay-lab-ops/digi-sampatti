import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/widgets/ds_logo.dart';
import 'package:digi_sampatti/core/widgets/language_picker.dart';

// ── Entry Screen — shown before OTP login ─────────────────────────────────────
// Single entry point for all users: buyers, sellers, brokers, banks, lawyers.
// Everyone is a customer. No separate login types.
// ─────────────────────────────────────────────────────────────────────────────

class UserTypeScreen extends ConsumerWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Language picker top-right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: const LanguagePickerButton(dark: true),
              ),
            ),
            const SizedBox(height: 16),
            // Arth ID Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/images/arth_id_logo.png', fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const DSLogo(size: 64)),
            ),
            const SizedBox(height: 16),
            const Text('DigiSampatti',
                style: TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.w900, letterSpacing: .5)),
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
                    // AI Score highlight banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.safe],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(children: [
                        Icon(Icons.psychology_outlined, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Property Score',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 2),
                            Text('Upload any property document — get a 0–100 safety score in 90 seconds',
                                style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        )),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                        'Upload RTC, EC, Sale Deed, or RERA certificate. '
                        'Our AI reads the document and tells you if the property is safe to buy — '
                        'with 30+ fraud checks and a downloadable report.',
                        style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6)),
                    const SizedBox(height: 16),

                    // Feature chips — same as number entry screen
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: const [
                        _Chip(icon: Icons.upload_file_outlined, label: 'Upload Any Doc'),
                        _Chip(icon: Icons.shield_outlined,      label: '30+ Fraud Checks'),
                        _Chip(icon: Icons.timer_outlined,       label: '90 Seconds'),
                        _Chip(icon: Icons.location_off_outlined,label: 'Zero Office Visits'),
                        _Chip(icon: Icons.lock_clock_outlined,  label: 'Digital Escrow'),
                        _Chip(icon: Icons.workspace_premium_outlined, label: 'Patent Pending'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Risk callout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          '₹30–50 Lakh at risk in every property deal — know before you pay.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 24),

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

                    const Spacer(),
                    Center(
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 12, color: Colors.white54),
                            const SizedBox(width: 5),
                            const Text('Powered by Claude AI',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Startup India: IN-0326-9427JD · Patent Provisional Filed',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: Colors.white38),
                        ),
                      ]),
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
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8D8B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.safe),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
