import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/features/splash/splash_screen.dart';
import 'package:digi_sampatti/features/onboarding/onboarding_screen.dart';
import 'package:digi_sampatti/features/auth/auth_screen.dart';
import 'package:digi_sampatti/features/home/home_screen.dart';
import 'package:digi_sampatti/features/scan/camera_scan_screen.dart';
import 'package:digi_sampatti/features/scan/manual_search_screen.dart';
import 'package:digi_sampatti/features/records/land_records_screen.dart';
import 'package:digi_sampatti/features/analysis/ai_analysis_screen.dart';
import 'package:digi_sampatti/features/report/legal_report_screen.dart';
import 'package:digi_sampatti/features/map/map_view_screen.dart';
import 'package:digi_sampatti/features/verification/physical_verification_screen.dart';
import 'package:digi_sampatti/features/partners/partners_screen.dart';

// ─── Router ───────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan/camera',
      name: 'camera-scan',
      builder: (context, state) => const CameraScanScreen(),
    ),
    GoRoute(
      path: '/scan/manual',
      name: 'manual-search',
      builder: (context, state) => const ManualSearchScreen(),
    ),
    GoRoute(
      path: '/records',
      name: 'land-records',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LandRecordsScreen(scanData: extra);
      },
    ),
    GoRoute(
      path: '/analysis',
      name: 'ai-analysis',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AiAnalysisScreen(recordData: extra);
      },
    ),
    GoRoute(
      path: '/report',
      name: 'legal-report',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LegalReportScreen(reportData: extra);
      },
    ),
    GoRoute(
      path: '/map',
      name: 'map-view',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MapViewScreen(locationData: extra);
      },
    ),
    GoRoute(
      path: '/verification',
      name: 'physical-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PhysicalVerificationScreen(reportData: extra);
      },
    ),
    GoRoute(
      path: '/partners',
      name: 'partners',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PartnersScreen(reportData: extra);
      },
    ),
  ],
);

// ─── App Root ─────────────────────────────────────────────────────────────────
class DigiSampattiApp extends ConsumerWidget {
  const DigiSampattiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'DigiSampatti',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
    );
  }
}
