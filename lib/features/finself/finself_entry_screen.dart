import 'package:flutter/material.dart';
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
              AccountAggregatorScreen(propertyValue: widget.propertyValue),
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
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── LOGO PLACEHOLDER ────────────────────────────────────
                // Replace this Container with your logo image:
                // Image.asset('assets/images/finself_logo.png', height: 80)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      'FS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                // ── END LOGO PLACEHOLDER ─────────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'FinSelf Lite',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Financial Identity',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
    );
  }
}
