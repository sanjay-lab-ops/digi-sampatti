import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/features/finself/account_aggregator_screen.dart';

// ─── FinSelf Lite Entry — Branded Splash ─────────────────────────────────────
// Shows the FinSelf logo + tagline for 2 seconds, then transitions
// to the Account Aggregator consent screen.
//
// To add your logo:
//   1. Place logo file in assets/images/finself_logo.png
//   2. Add to pubspec.yaml under assets:
//      - assets/images/finself_logo.png
//   3. Replace the placeholder widget below with:
//      Image.asset('assets/images/finself_logo.png', height: 80)
// ──────────────────────────────────────────────────────────────────────────────

class FinselfEntryScreen extends StatefulWidget {
  final double? propertyValue;
  const FinselfEntryScreen({super.key, this.propertyValue});

  @override
  State<FinselfEntryScreen> createState() => _FinselfEntryScreenState();
}

class _FinselfEntryScreenState extends State<FinselfEntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();

    // Navigate to AA screen after 2.2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              const AccountAggregatorScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.arthGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ARTH ID Logo (fingerprint + ₹ hexagon)
                  // File: assets/images/arth_id_logo.png
                  Image.asset(
                    'assets/images/arth_id_logo.png',
                    height: 120,
                    width: 120,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.arthGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.arthGold, width: 2.5),
                      ),
                      child: const Center(child: Text('₹',
                          style: TextStyle(color: AppColors.arthGold,
                              fontSize: 48, fontWeight: FontWeight.w900))),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'ARTH ID',
                  style: TextStyle(
                    color: AppColors.arthGold,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'India\'s Financial Identity',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Powered by RBI Account Aggregator',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
