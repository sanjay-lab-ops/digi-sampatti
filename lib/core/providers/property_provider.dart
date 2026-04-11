import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/models/portal_findings_model.dart';
import 'package:digi_sampatti/core/services/bhoomi_service.dart';
import 'package:digi_sampatti/core/services/rera_service.dart';
import 'package:digi_sampatti/core/services/ai_analysis_service.dart';
import 'package:digi_sampatti/core/services/report_generator_service.dart';
import 'package:digi_sampatti/core/services/gps_service.dart';
import 'package:digi_sampatti/core/services/report_history_service.dart';

// ─── Services Providers ────────────────────────────────────────────────────────
final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());
final bhoomiServiceProvider = Provider<BhoomiService>((ref) {
  final service = BhoomiService();
  service.initialize();
  return service;
});
final reraServiceProvider = Provider<ReraService>((ref) {
  final service = ReraService();
  service.initialize();
  return service;
});
final encumbranceServiceProvider = Provider<EncumbranceService>((ref) {
  final service = EncumbranceService();
  service.initialize();
  return service;
});
final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  final service = AiAnalysisService();
  service.initialize();
  return service;
});
final reportGeneratorProvider = Provider<ReportGeneratorService>(
  (ref) => ReportGeneratorService(),
);

// ─── User Location + Property Profile ────────────────────────────────────────
// Set when user selects their area in the buyer/seller toggle.
// Drives: document checklist, AI personalization, risk engine rules.
class UserPropertyProfile {
  final String? state;
  final String? district;
  final String? taluk;
  final String? village;
  final String propertyType;   // site / apartment / house / villa / bda_layout / commercial / farm
  final bool isFirstTimeBuyer;
  final bool isSeller;

  const UserPropertyProfile({
    this.state,
    this.district,
    this.taluk,
    this.village,
    this.propertyType = 'site',
    this.isFirstTimeBuyer = true,
    this.isSeller = false,
  });

  String get locationLabel {
    final parts = [village, taluk, district, state]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    return parts.isNotEmpty ? parts : 'Location not set';
  }

  String get propertyTypeLabel => switch (propertyType) {
    'apartment'   => 'Apartment / Flat',
    'house'       => 'House / Villa',
    'site'        => 'Site / Plot',
    'bda_layout'  => 'BDA / BMRDA Layout Site',
    'commercial'  => 'Commercial Space',
    'farm'        => 'Farm / Agricultural Land',
    'industrial'  => 'Industrial Plot',
    _             => 'Site / Plot',
  };
}

final userProfileProvider =
    StateProvider<UserPropertyProfile>((ref) => const UserPropertyProfile());

// ─── User Mode: Buyer or Seller ──────────────────────────────────────────────
// Controls which features are shown on home screen and throughout the app.
// 'buyer'  → Upload docs, check property, verify seller, inspect, transact
// 'seller' → Register property, get verified badge, document locker
enum UserMode { buyer, seller }
final userModeProvider = StateProvider<UserMode>((ref) => UserMode.buyer);

// ─── Property Type (set at manual search, read by auto-scan) ─────────────────
// 'site'       — Agricultural / Revenue site / Plot
// 'house'      — Independent house / Villa
// 'apartment'  — Apartment / Flat (RERA mandatory)
// 'bda_layout' — BDA / BMRDA approved layout site
final propertyTypeProvider = StateProvider<String>((ref) => 'site');

// ─── Current Scan State ────────────────────────────────────────────────────────
final currentScanProvider = StateProvider<PropertyScan?>((ref) => null);
final currentLandRecordProvider = StateProvider<LandRecord?>((ref) => null);
final currentReraRecordProvider = StateProvider<ReraRecord?>((ref) => null);
final currentReportProvider = StateProvider<LegalReport?>((ref) => null);

// ─── Recent Reports List ───────────────────────────────────────────────────────
final recentReportsProvider = StateProvider<List<LegalReport>>((ref) => []);

// ─── Loading States ────────────────────────────────────────────────────────────
final isLoadingLandRecordsProvider = StateProvider<bool>((ref) => false);
final isLoadingAiAnalysisProvider = StateProvider<bool>((ref) => false);
final isGeneratingReportProvider = StateProvider<bool>((ref) => false);

// ─── Error State ───────────────────────────────────────────────────────────────
final errorMessageProvider = StateProvider<String?>((ref) => null);

// ─── GPS Location ──────────────────────────────────────────────────────────────
final currentLocationProvider = StateProvider<GpsLocation?>((ref) => null);

// ─── Full Property Check Flow ──────────────────────────────────────────────────
final propertyCheckNotifierProvider =
    AsyncNotifierProvider<PropertyCheckNotifier, LegalReport?>(
  PropertyCheckNotifier.new,
);

class PropertyCheckNotifier extends AsyncNotifier<LegalReport?> {
  @override
  Future<LegalReport?> build() async => null;

  // ─── Step 1: Save Scan ────────────────────────────────────────────────────
  void setScan(PropertyScan scan) {
    ref.read(currentScanProvider.notifier).state = scan;
  }

  // ─── Step 2: Fetch Land Records ───────────────────────────────────────────
  Future<void> fetchLandRecords({
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) async {
    ref.read(isLoadingLandRecordsProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    state = const AsyncLoading();

    try {
      final bhoomiService = ref.read(bhoomiServiceProvider);
      final reraService = ref.read(reraServiceProvider);
      final encumbranceService = ref.read(encumbranceServiceProvider);

      // Fetch RTC from Bhoomi
      final landRecord = await bhoomiService.fetchRtc(
        district: district,
        taluk: taluk,
        hobli: hobli,
        village: village,
        surveyNumber: surveyNumber,
      );

      // Fetch Encumbrances (EC - last 30 years)
      if (landRecord != null) {
        final currentYear = DateTime.now().year;
        final encumbrances = await encumbranceService.fetchEncumbranceCertificate(
          district: district,
          sroOffice: taluk,
          surveyNumber: surveyNumber,
          fromYear: currentYear - 30,
          toYear: currentYear,
        );

        // Mutations
        final mutations = await bhoomiService.fetchMutations(
          district: district,
          taluk: taluk,
          surveyNumber: surveyNumber,
        );

        // Merge into landRecord
        final updatedRecord = LandRecord(
          surveyNumber: landRecord.surveyNumber,
          district: landRecord.district,
          taluk: landRecord.taluk,
          hobli: landRecord.hobli,
          village: landRecord.village,
          khataNumber: landRecord.khataNumber,
          khataType: landRecord.khataType,
          owners: landRecord.owners,
          landType: landRecord.landType,
          totalAreaAcres: landRecord.totalAreaAcres,
          cropDetails: landRecord.cropDetails,
          mutations: mutations,
          encumbrances: encumbrances,
          isRevenueSite: landRecord.isRevenueSite,
          isGovernmentLand: landRecord.isGovernmentLand,
          isForestLand: landRecord.isForestLand,
          isLakeBed: landRecord.isLakeBed,
          remarks: landRecord.remarks,
          fetchedAt: DateTime.now(),
          guidanceValuePerSqft: landRecord.guidanceValuePerSqft,
          estimatedMarketValue: landRecord.estimatedMarketValue,
        );

        ref.read(currentLandRecordProvider.notifier).state = updatedRecord;
      }

      // Check RERA (for apartments/layouts)
      final reraResults = await reraService.searchByLocation(
        latitude: ref.read(currentLocationProvider)?.latitude ?? 12.9716,
        longitude: ref.read(currentLocationProvider)?.longitude ?? 77.5946,
      );

      if (reraResults.isNotEmpty) {
        ref.read(currentReraRecordProvider.notifier).state = reraResults.first;
      }

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      ref.read(isLoadingLandRecordsProvider.notifier).state = false;
    }
  }

  // ─── Step 3: Run AI Analysis + Generate Report ────────────────────────────
  // Uses real portal findings from the checklist — no simulated data.
  Future<LegalReport?> runAnalysisAndGenerateReport({
    PortalFindings? portalFindings,
  }) async {
    final scan = ref.read(currentScanProvider);
    if (scan == null) return null;

    ref.read(isLoadingAiAnalysisProvider.notifier).state = true;
    state = const AsyncLoading();

    try {
      final aiService = ref.read(aiAnalysisServiceProvider);

      // Build a land record from portal findings (what the user actually saw)
      // Only used for labelling in the report — AI uses portalFindings directly
      final landRecord = _buildRecordFromFindings(scan, portalFindings);

      // Build RERA record from findings
      final reraRecord = portalFindings != null
          ? _buildReraFromFindings(portalFindings)
          : null;

      // Run AI analysis using real user-verified findings
      final riskAssessment = await aiService.analyzePropertyFromFindings(
        scan: scan,
        findings: portalFindings ?? const PortalFindings(),
        landRecord: landRecord,
        reraRecord: reraRecord,
      );

      // Build report
      final report = LegalReport(
        reportId: const Uuid().v4().substring(0, 8).toUpperCase(),
        scan: scan,
        landRecord: landRecord,
        reraRecord: reraRecord,
        riskAssessment: riskAssessment,
        aiAnalysisSummary: riskAssessment.summary,
        generatedAt: DateTime.now(),
        isPaid: false,
      );

      ref.read(currentReportProvider.notifier).state = report;

      // Save to persistent history
      await ReportHistoryService().saveReport(report);

      // Add to recent reports list
      final reports = [...ref.read(recentReportsProvider)];
      reports.insert(0, report);
      if (reports.length > 20) reports.removeLast();
      ref.read(recentReportsProvider.notifier).state = reports;

      state = AsyncData(report);
      return report;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      ref.read(errorMessageProvider.notifier).state = e.toString();
      return null;
    } finally {
      ref.read(isLoadingAiAnalysisProvider.notifier).state = false;
    }
  }

  // ─── Step 4: Generate PDF ─────────────────────────────────────────────────
  Future<String?> generatePdf() async {
    final report = ref.read(currentReportProvider);
    if (report == null) return null;

    ref.read(isGeneratingReportProvider.notifier).state = true;
    try {
      final generator = ref.read(reportGeneratorProvider);
      return await generator.generatePdfReport(report);
    } finally {
      ref.read(isGeneratingReportProvider.notifier).state = false;
    }
  }

  // ─── Build minimal LandRecord from what user saw on Bhoomi ───────────────
  LandRecord? _buildRecordFromFindings(
      PropertyScan scan, PortalFindings? f) {
    if (f == null) return null;
    return LandRecord(
      surveyNumber: scan.surveyNumber ?? '',
      district: scan.district ?? '',
      taluk: scan.taluk ?? '',
      hobli: scan.hobli ?? '',
      village: scan.village ?? '',
      khataType: switch (f.khataFound) {
        KhataFound.aKhata => KhataType.aKhata,
        KhataFound.bKhata => KhataType.bKhata,
        _ => null,
      },
      owners: const [],
      mutations: const [],
      encumbrances: const [],
      isRevenueSite: false,
      isGovernmentLand: false,
      isForestLand: false,
      isLakeBed: false,
      remarks: f.bhoomiHasRemarks == true
          ? 'User found remarks/notices in RTC'
          : null,
    );
  }

  ReraRecord? _buildReraFromFindings(PortalFindings f) {
    if (f.isApartmentProject != true) return null;
    return ReraRecord(isRegistered: f.reraRegistered ?? false);
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  void reset() {
    ref.read(currentScanProvider.notifier).state = null;
    ref.read(currentLandRecordProvider.notifier).state = null;
    ref.read(currentReraRecordProvider.notifier).state = null;
    ref.read(currentReportProvider.notifier).state = null;
    ref.read(errorMessageProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}
