import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B5E20);       // Deep forest green
  static const Color primaryLight = Color(0xFF4CAF50);  // Medium green
  static const Color primaryDark = Color(0xFF0A3D0A);   // Dark green
  static const Color accent = Color(0xFFFF6D00);        // Orange accent

  // ─── Semantic Colors ───────────────────────────────────────────────────────
  static const Color safe = Color(0xFF2E7D32);          // Green - safe to buy
  static const Color warning = Color(0xFFF57F17);       // Amber - moderate risk
  static const Color danger = Color(0xFFC62828);        // Red - high risk
  static const Color info = Color(0xFF1565C0);          // Blue - informational
  static const Color caution = Color(0xFFF57F17);       // Amber - caution

  // ─── Background Colors ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceGreen = Color(0xFFE8F5E9);  // Light green surface

  // ─── Text Colors ───────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF5C5C5C);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Border & Divider ──────────────────────────────────────────────────────
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFF0F0F0);

  // ─── Risk Score Gradient ───────────────────────────────────────────────────
  static const List<Color> riskGradientLow = [
    Color(0xFF2E7D32), Color(0xFF66BB6A),
  ];
  static const List<Color> riskGradientMedium = [
    Color(0xFFF57F17), Color(0xFFFFCA28),
  ];
  static const List<Color> riskGradientHigh = [
    Color(0xFFC62828), Color(0xFFEF5350),
  ];

  // ─── Status Tag Colors ─────────────────────────────────────────────────────
  static const Color statusClearBg = Color(0xFFE8F5E9);
  static const Color statusClearText = Color(0xFF1B5E20);
  static const Color statusWarningBg = Color(0xFFFFF8E1);
  static const Color statusWarningText = Color(0xFFE65100);
  static const Color statusDangerBg = Color(0xFFFFEBEE);
  static const Color statusDangerText = Color(0xFFB71C1C);

  // ─── Shimmer Colors ────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
