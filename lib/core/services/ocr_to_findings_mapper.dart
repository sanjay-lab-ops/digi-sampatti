import 'package:digi_sampatti/core/models/portal_findings_model.dart';
import 'package:digi_sampatti/core/services/ocr_service.dart';

// ─── OcrResult → PortalFindings Mapper ────────────────────────────────────────
// This is the CRITICAL missing piece of the private model pipeline.
//
// OLD flow (Bhoomi scraper):
//   Bhoomi portal → user checks manually → PortalFindings → AI analysis
//
// NEW flow (document upload):
//   Photo → Claude Vision → OcrResult → THIS MAPPER → PortalFindings → AI analysis
//
// The mapper converts Claude's structured extraction into the same PortalFindings
// format that the rule engine uses — enabling identical risk scoring for both flows.
// ──────────────────────────────────────────────────────────────────────────────

class OcrToFindingsMapper {
  /// Maps Claude Vision extracted data → PortalFindings for rule engine.
  /// Also accepts the raw backend response Map (from /rtc-from-image).
  static PortalFindings fromOcrResult(OcrResult ocr, {
    Map<String, dynamic>? rawBackendData,
  }) {
    final raw = rawBackendData ?? {};

    // Determine Khata type from extracted data
    KhataFound? khataFound;
    final khataRaw = (raw['khata_type'] ?? raw['khataType'] ?? '').toString().toLowerCase();
    if (khataRaw.contains('a-khata') || khataRaw.contains('a khata')) {
      khataFound = KhataFound.aKhata;
    } else if (khataRaw.contains('b-khata') || khataRaw.contains('b khata')) {
      khataFound = KhataFound.bKhata;
    } else if (khataRaw.contains('no khata') || khataRaw.contains('not found')) {
      khataFound = KhataFound.noKhata;
    }

    // Detect injunction / court order in extracted text
    final allText = [
      raw['raw_text'] ?? '',
      raw['remarks'] ?? '',
      raw['mutations']?.toString() ?? '',
      raw['notes'] ?? '',
    ].join(' ').toLowerCase();

    final hasCourtCases = _detectInjunction(allText);
    final hasActiveLoan = _detectLoan(allText);
    final hasRemarks    = _detectRemarks(allText);
    final multipleSales = _detectMultipleSales(allText);

    // Land type → check if revenue/government/forest
    final landType = (raw['land_type'] ?? raw['landType'] ?? '').toString().toLowerCase();
    final isRevenueSite = landType.contains('revenue') || landType.contains('b khata');

    // Property type from document
    final docType = (raw['document_type'] ?? ocr.documentType ?? '').toString().toLowerCase();
    final isApartment = docType.contains('apartment') || docType.contains('flat') ||
        docType.contains('rera');

    return PortalFindings(
      // Bhoomi RTC
      bhoomiOpened:      true,                     // document was uploaded = checked
      khataFound:        khataFound,
      bhoomiHasRemarks:  hasRemarks || hasCourtCases,
      isRevenueSite:     isRevenueSite,

      // Kaveri EC — if EC data is in the same upload
      kaveriOpened:      raw['ec_data'] != null || raw['transactions'] != null,
      hasActiveLoan:     hasActiveLoan,
      multipleSales:     multipleSales,

      // RERA
      isApartmentProject: isApartment,
      reraRegistered:    isApartment
          ? (raw['rera_registered'] as bool?) : null,

      // eCourts
      ecourtsOpened:     hasCourtCases, // auto-detected from document
      hasCourtCases:     hasCourtCases,

      // BBMP — cannot detect from document alone
      bbmpOpened:        null,
      propertyTaxPaid:   null,

      // CERSAI — cannot detect from document alone
      cersaiOpened:      null,
      hasBankCharge:     hasActiveLoan, // cross-reference from EC text

      // FMB — if sketch found in document
      fmbOpened:         raw['fmb_found'] as bool? ?? false,
      boundariesCorrect: null,
    );
  }

  /// Maps full backend response (from /rtc-from-image or /full-check)
  static PortalFindings fromBackendFullCheck(Map<String, dynamic> data) {
    final rtc    = data['rtc']    as Map<String, dynamic>?;
    final ec     = data['ec']     as Map<String, dynamic>?;
    final courts = data['courts'] as Map<String, dynamic>?;
    final cersai = data['cersai'] as Map<String, dynamic>?;

    // Build from OcrResult first using rtc data
    final ocrResult = OcrResult(
      scanType:     ScanType.document,
      surveyNumber: rtc?['survey_number']?.toString(),
      ownerName:    rtc?['owner_name']?.toString(),
      district:     rtc?['district']?.toString(),
      taluk:        rtc?['taluk']?.toString(),
      documentType: 'RTC',
    );

    final base = fromOcrResult(ocrResult, rawBackendData: rtc ?? {});

    // Override with actual portal data where available
    return base.copyWith(
      kaveriOpened:  ec != null,
      hasActiveLoan: ec?['encumbrance_free'] == false,
      multipleSales: (ec?['transaction_count'] as int? ?? 0) > 3,
      ecourtsOpened: courts != null,
      hasCourtCases: (courts?['has_pending_cases'] as bool?) ?? base.hasCourtCases,
      cersaiOpened:  cersai != null,
      hasBankCharge: (cersai?['is_mortgaged'] as bool?) ?? false,
    );
  }

  // ── Text detectors ──────────────────────────────────────────────────────────

  static bool _detectInjunction(String text) =>
      text.contains('injunction')      ||
      text.contains('ತಡೆಯಾಜ್ಞೆ')       ||
      text.contains('thadeyajne')       ||
      text.contains('court order')      ||
      text.contains('temporary stay')   ||
      text.contains('os ')             ||
      text.contains('rabn')            ||
      text.contains('trgn');

  static bool _detectLoan(String text) =>
      text.contains('mortgage')        ||
      text.contains('hypothecation')   ||
      text.contains('loan')            ||
      text.contains('charge')          ||
      text.contains('encumbrance')     ||
      text.contains('otti')            ||
      text.contains('ಒತ್ತೆ');

  static bool _detectRemarks(String text) =>
      text.contains('remark')          ||
      text.contains('notice')          ||
      text.contains('dispute')         ||
      text.contains('acquisition')     ||
      text.contains('objection');

  static bool _detectMultipleSales(String text) {
    final saleCount = RegExp(r'sale deed').allMatches(text).length;
    return saleCount > 1;
  }
}
