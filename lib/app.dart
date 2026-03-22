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
import 'package:digi_sampatti/features/history/report_history_screen.dart';
import 'package:digi_sampatti/features/broker/broker_screen.dart';
import 'package:digi_sampatti/features/transfer/property_transfer_screen.dart';
import 'package:digi_sampatti/features/transfer/stamp_duty_screen.dart';
import 'package:digi_sampatti/features/transfer/document_checklist_screen.dart';
import 'package:digi_sampatti/features/transfer/mutation_guide_screen.dart';
import 'package:digi_sampatti/features/transfer/sro_locator_screen.dart';
import 'package:digi_sampatti/features/transfer/registration_guide_screen.dart';
import 'package:digi_sampatti/features/tools/financial_tools_screen.dart';
import 'package:digi_sampatti/features/tools/emi_calculator_screen.dart';
import 'package:digi_sampatti/features/tools/total_cost_screen.dart';
import 'package:digi_sampatti/features/tools/property_tax_screen.dart';
import 'package:digi_sampatti/features/tools/loan_eligibility_screen.dart';
import 'package:digi_sampatti/features/guides/buyer_guides_screen.dart';
import 'package:digi_sampatti/features/guides/apartment_guide_screen.dart';
import 'package:digi_sampatti/features/guides/dc_conversion_screen.dart';
import 'package:digi_sampatti/features/guides/legal_glossary_screen.dart';
import 'package:digi_sampatti/features/guides/red_flags_screen.dart';
import 'package:digi_sampatti/features/guides/faq_screen.dart';
import 'package:digi_sampatti/features/ecourts/ecourts_screen.dart';
import 'package:digi_sampatti/features/legal/privacy_terms_screen.dart';
import 'package:digi_sampatti/features/subscription/subscription_screen.dart';
import 'package:digi_sampatti/features/profile/profile_screen.dart';
import 'package:digi_sampatti/features/gov_services/gov_services_screen.dart';

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
    GoRoute(
      path: '/history',
      name: 'report-history',
      builder: (context, state) => const ReportHistoryScreen(),
    ),
    GoRoute(
      path: '/broker',
      name: 'broker',
      builder: (context, state) => const BrokerScreen(),
    ),
    GoRoute(
      path: '/transfer',
      name: 'transfer',
      builder: (context, state) => const PropertyTransferScreen(),
    ),
    GoRoute(
      path: '/transfer/stamp-duty',
      name: 'stamp-duty',
      builder: (context, state) => const StampDutyScreen(),
    ),
    GoRoute(
      path: '/transfer/documents',
      name: 'document-checklist',
      builder: (context, state) => const DocumentChecklistScreen(),
    ),
    GoRoute(
      path: '/transfer/mutation',
      name: 'mutation-guide',
      builder: (context, state) => const MutationGuideScreen(),
    ),
    GoRoute(
      path: '/transfer/sro',
      name: 'sro-locator',
      builder: (context, state) => const SroLocatorScreen(),
    ),
    GoRoute(
      path: '/transfer/registration',
      name: 'registration-guide',
      builder: (context, state) => const RegistrationGuideScreen(),
    ),
    GoRoute(
      path: '/tools',
      name: 'financial-tools',
      builder: (context, state) => const FinancialToolsScreen(),
    ),
    GoRoute(
      path: '/tools/emi',
      name: 'emi-calculator',
      builder: (context, state) => const EmiCalculatorScreen(),
    ),
    GoRoute(
      path: '/tools/total-cost',
      name: 'total-cost',
      builder: (context, state) => const TotalCostScreen(),
    ),
    GoRoute(
      path: '/tools/property-tax',
      name: 'property-tax',
      builder: (context, state) => const PropertyTaxScreen(),
    ),
    GoRoute(
      path: '/tools/loan-eligibility',
      name: 'loan-eligibility',
      builder: (context, state) => const LoanEligibilityScreen(),
    ),
    GoRoute(
      path: '/guides',
      name: 'buyer-guides',
      builder: (context, state) => const BuyerGuidesScreen(),
    ),
    GoRoute(
      path: '/guides/apartment',
      name: 'apartment-guide',
      builder: (context, state) => const ApartmentGuideScreen(),
    ),
    GoRoute(
      path: '/guides/dc-conversion',
      name: 'dc-conversion',
      builder: (context, state) => const DcConversionScreen(),
    ),
    GoRoute(
      path: '/guides/glossary',
      name: 'legal-glossary',
      builder: (context, state) => const LegalGlossaryScreen(),
    ),
    GoRoute(
      path: '/guides/red-flags',
      name: 'red-flags',
      builder: (context, state) => const RedFlagsScreen(),
    ),
    GoRoute(
      path: '/guides/faq',
      name: 'faq',
      builder: (context, state) => const FaqScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/subscription',
      name: 'subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyTermsScreen(showTerms: false),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const PrivacyTermsScreen(showTerms: true),
    ),
    GoRoute(
      path: '/gov-services',
      name: 'gov-services',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return GovServicesScreen(prefillData: extra);
      },
    ),
    GoRoute(
      path: '/ecourts',
      name: 'ecourts',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EcourtsScreen(
          ownerName: extra?['ownerName'] as String?,
          surveyNumber: extra?['surveyNumber'] as String?,
        );
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
