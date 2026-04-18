import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Arth ID Brand ────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1B5E20); // Deep forest green
  static const Color primaryLight = Color(0xFF4CAF50); // Medium green
  static const Color primaryDark  = Color(0xFF0A3D0A); // Dark green
  static const Color accent       = Color(0xFFFF6D00); // Orange accent

  // ─── ARTH ID / FinSelf Brand ───────────────────────────────────────────────
  static const Color arthGold      = Color(0xFFc8922a); // ARTH ID gold
  static const Color arthGoldLight = Color(0xFFf5c842); // Lighter gold
  static const Color arthNavy      = Color(0xFF0D2137); // ARTH ID dark navy
  static const Color arthBlue      = Color(0xFF0D47A1); // ARTH ID blue
  static const Color arthSurface   = Color(0xFF0d1b3e); // Dark card bg for ARTH ID

  // ─── Arth ID Gradients ────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF1B5E20), Color(0xFF2E7D32),
  ];
  static const List<Color> heroGradient = [
    Color(0xFF0a1628), Color(0xFF0b3d8e), Color(0xFF0a2a6a),
  ];

  // ─── ARTH ID Gradients ─────────────────────────────────────────────────────
  static const List<Color> arthGradient = [
    Color(0xFF0D2137), Color(0xFF0D47A1),
  ];
  static const List<Color> arthGoldGradient = [
    Color(0xFFc8922a), Color(0xFFf5c842),
  ];

  // ─── Semantic Colors ───────────────────────────────────────────────────────
  static const Color safe    = Color(0xFF2E7D32); // Green — safe to buy
  static const Color warning = Color(0xFFF57F17); // Amber — moderate risk
  static const Color danger  = Color(0xFFC62828); // Red — high risk
  static const Color info    = Color(0xFF1565C0); // Blue — informational
  static const Color caution = Color(0xFFF57F17); // Amber — caution
  static const Color critical = Color(0xFF7B0000); // Dark red — critical

  // ─── Interactive States ────────────────────────────────────────────────────
  static const Color pressed   = Color(0xFF145214); // Darker green on press
  static const Color selected  = Color(0xFFE8F5E9); // Light green selected
  static const Color highlight = Color(0xFFc8922a); // Gold highlight

  // ─── Background Colors ─────────────────────────────────────────────────────
  static const Color background   = Color(0xFFF5F7F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceGreen = Color(0xFFE8F5E9); // Light green surface
  static const Color surfaceDark  = Color(0xFF141927); // Dark card bg

  // ─── Text Colors ───────────────────────────────────────────────────────────
  static const Color textDark      = Color(0xFF1A1A1A);
  static const Color textMedium    = Color(0xFF5C5C5C);
  static const Color textLight     = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark    = Color(0xFFe8eaf6);

  // ─── Border & Divider ──────────────────────────────────────────────────────
  static const Color borderColor  = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFF0F0F0);
  static const Color borderDark   = Color(0x14FFFFFF); // 8% white on dark bg

  // ─── Risk Score Gradients ──────────────────────────────────────────────────
  static const List<Color> riskGradientLow = [
    Color(0xFF1B5E20), Color(0xFF00c48c),
  ];
  static const List<Color> riskGradientMedium = [
    Color(0xFFF57F17), Color(0xFFFFCA28),
  ];
  static const List<Color> riskGradientHigh = [
    Color(0xFF7B0000), Color(0xFFC62828),
  ];

  // ─── Score Color helper ────────────────────────────────────────────────────
  static Color scoreColor(int score) {
    if (score >= 75) return safe;
    if (score >= 50) return warning;
    if (score >= 30) return danger;
    return critical;
  }

  static List<Color> scoreGradient(int score) {
    if (score >= 75) return riskGradientLow;
    if (score >= 50) return riskGradientMedium;
    return riskGradientHigh;
  }

  // ─── Status Tag Colors ─────────────────────────────────────────────────────
  static const Color statusClearBg     = Color(0xFFE8F5E9);
  static const Color statusClearText   = Color(0xFF1B5E20);
  static const Color statusWarningBg   = Color(0xFFFFF8E1);
  static const Color statusWarningText = Color(0xFFE65100);
  static const Color statusDangerBg    = Color(0xFFFFEBEE);
  static const Color statusDangerText  = Color(0xFFB71C1C);

  // ─── Feature / Section Colors (replaces scattered hardcoded hex) ─────────
  static const Color seller    = Color(0xFF880E4F); // Seller mode — deep pink
  static const Color esign     = Color(0xFF4A148C); // e-Sign — deep purple
  static const Color slate     = Color(0xFF37474F); // Inspection / tracking — blue-grey
  static const Color teal      = Color(0xFF006064); // Guidance Value / teal
  static const Color indigo    = Color(0xFF1A237E); // BDA / government — deep indigo
  static const Color deepOrange = Color(0xFFBF360C); // Risk step 4 / deep orange
  static const Color violet    = Color(0xFF7C3AED); // Reports / history — violet
  static const Color emerald   = Color(0xFF00a878); // Success / verified — emerald
  static const Color navy      = Color(0xFF004D40); // BBMP / tax — dark teal

  // ─── Portal Brand Colors ──────────────────────────────────────────────────
  static const Color kaveri     = Color(0xFF7B1FA2); // Kaveri EC — purple
  static const Color bdaColor   = Color(0xFF1A3A6B); // BDA — dark blue
  static const Color reraColor  = Color(0xFF006064); // RERA — teal
  static const Color bbmpColor  = Color(0xFF37474F); // BBMP — blue-grey
  static const Color cersaiColor = Color(0xFFBF360C); // CERSAI — deep orange

  // ─── Surface Colors ────────────────────────────────────────────────────────
  static const Color surfaceGrey = Color(0xFFF5F5F5); // Light grey card background

  // ─── Shimmer Colors ────────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
