// ─── Portal Findings — What the user actually saw on each government portal ────
// These are real user-verified inputs, NOT generated/simulated data.
// Each field is nullable: null = portal not checked / skipped.

enum KhataFound { aKhata, bKhata, noKhata, notShown }

class PortalFindings {
  // ── Bhoomi RTC ─────────────────────────────────────────────────────────────
  final bool? bhoomiOpened;       // Did user open Bhoomi?
  final KhataFound? khataFound;   // What Khata type did they see?
  final bool? bhoomiHasRemarks;   // Any red remarks / govt notices in RTC?
  final bool? isRevenueSite;      // B Khata: is this a revenue site (unapproved layout)?

  // ── Kaveri IGRS (EC) ───────────────────────────────────────────────────────
  final bool? kaveriOpened;
  final bool? hasActiveLoan;      // Loan/mortgage shown in EC?
  final bool? multipleSales;      // Multiple sale transactions recently?

  // ── RERA ──────────────────────────────────────────────────────────────────
  final bool? isApartmentProject; // Is this an apartment (not individual plot)?
  final bool? reraRegistered;     // Builder registered on RERA? (null = N/A)

  // ── eCourts ───────────────────────────────────────────────────────────────
  final bool? ecourtsOpened;
  final bool? hasCourtCases;      // Active litigation found?

  // ── BBMP Tax ──────────────────────────────────────────────────────────────
  final bool? bbmpOpened;
  final bool? propertyTaxPaid;    // Tax up to date?

  // ── CERSAI ────────────────────────────────────────────────────────────────
  final bool? cersaiOpened;
  final bool? hasBankCharge;      // Registered bank mortgage/charge?

  // ── Bhoomi FMB / Sketch Map ───────────────────────────────────────────────
  final bool? fmbOpened;
  final bool? boundariesCorrect;  // Physical plot matches map?

  // ── Document Gap Flags (from checklist status) ────────────────────────────
  // These represent what could NOT be verified — critical for risk scoring.
  final bool? dcConversionNotExists;  // Agricultural land, DC conversion absent = ILLEGAL to build
  final bool? ecNotProvided;           // EC not uploaded — encumbrance status unknown
  final bool? mutationPending;         // Mutation not approved = ownership chain gap
  final bool? taxDuesUnknown;          // Tax receipt missing — dues status unknown
  final bool? khataNotAvailable;       // Khata not provided — municipal status unknown
  final List<String> physicalVisitDocs; // Docs user says will get physically (pending)
  final List<String> notExistsDocs;     // Docs that the seller could not produce

  const PortalFindings({
    this.bhoomiOpened,
    this.khataFound,
    this.bhoomiHasRemarks,
    this.isRevenueSite,
    this.kaveriOpened,
    this.hasActiveLoan,
    this.multipleSales,
    this.isApartmentProject,
    this.reraRegistered,
    this.ecourtsOpened,
    this.hasCourtCases,
    this.bbmpOpened,
    this.propertyTaxPaid,
    this.cersaiOpened,
    this.hasBankCharge,
    this.fmbOpened,
    this.boundariesCorrect,
    this.dcConversionNotExists,
    this.ecNotProvided,
    this.mutationPending,
    this.taxDuesUnknown,
    this.khataNotAvailable,
    this.physicalVisitDocs = const [],
    this.notExistsDocs = const [],
  });

  PortalFindings copyWith({
    bool? bhoomiOpened,
    KhataFound? khataFound,
    bool? bhoomiHasRemarks,
    bool? isRevenueSite,
    bool? kaveriOpened,
    bool? hasActiveLoan,
    bool? multipleSales,
    bool? isApartmentProject,
    bool? reraRegistered,
    bool? ecourtsOpened,
    bool? hasCourtCases,
    bool? bbmpOpened,
    bool? propertyTaxPaid,
    bool? cersaiOpened,
    bool? hasBankCharge,
    bool? fmbOpened,
    bool? boundariesCorrect,
    bool? dcConversionNotExists,
    bool? ecNotProvided,
    bool? mutationPending,
    bool? taxDuesUnknown,
    bool? khataNotAvailable,
    List<String>? physicalVisitDocs,
    List<String>? notExistsDocs,
  }) =>
      PortalFindings(
        bhoomiOpened: bhoomiOpened ?? this.bhoomiOpened,
        khataFound: khataFound ?? this.khataFound,
        bhoomiHasRemarks: bhoomiHasRemarks ?? this.bhoomiHasRemarks,
        isRevenueSite: isRevenueSite ?? this.isRevenueSite,
        kaveriOpened: kaveriOpened ?? this.kaveriOpened,
        hasActiveLoan: hasActiveLoan ?? this.hasActiveLoan,
        multipleSales: multipleSales ?? this.multipleSales,
        isApartmentProject: isApartmentProject ?? this.isApartmentProject,
        reraRegistered: reraRegistered ?? this.reraRegistered,
        ecourtsOpened: ecourtsOpened ?? this.ecourtsOpened,
        hasCourtCases: hasCourtCases ?? this.hasCourtCases,
        bbmpOpened: bbmpOpened ?? this.bbmpOpened,
        propertyTaxPaid: propertyTaxPaid ?? this.propertyTaxPaid,
        cersaiOpened: cersaiOpened ?? this.cersaiOpened,
        hasBankCharge: hasBankCharge ?? this.hasBankCharge,
        fmbOpened: fmbOpened ?? this.fmbOpened,
        boundariesCorrect: boundariesCorrect ?? this.boundariesCorrect,
        dcConversionNotExists: dcConversionNotExists ?? this.dcConversionNotExists,
        ecNotProvided: ecNotProvided ?? this.ecNotProvided,
        mutationPending: mutationPending ?? this.mutationPending,
        taxDuesUnknown: taxDuesUnknown ?? this.taxDuesUnknown,
        khataNotAvailable: khataNotAvailable ?? this.khataNotAvailable,
        physicalVisitDocs: physicalVisitDocs ?? this.physicalVisitDocs,
        notExistsDocs: notExistsDocs ?? this.notExistsDocs,
      );

  // ── Risk summary for AI prompt ─────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'bhoomi': {
          'opened': bhoomiOpened,
          'khata': khataFound?.name,
          'hasRemarks': bhoomiHasRemarks,
        },
        'kaveri': {
          'opened': kaveriOpened,
          'activeLoan': hasActiveLoan,
          'multipleSales': multipleSales,
        },
        'rera': {
          'isApartment': isApartmentProject,
          'registered': reraRegistered,
        },
        'ecourts': {
          'opened': ecourtsOpened,
          'hasCases': hasCourtCases,
        },
        'bbmp': {
          'opened': bbmpOpened,
          'taxPaid': propertyTaxPaid,
        },
        'cersai': {
          'opened': cersaiOpened,
          'bankCharge': hasBankCharge,
        },
        'fmb': {
          'opened': fmbOpened,
          'boundariesCorrect': boundariesCorrect,
        },
        'document_gaps': {
          'dc_conversion_not_exists': dcConversionNotExists,
          'ec_not_provided': ecNotProvided,
          'mutation_pending': mutationPending,
          'tax_dues_unknown': taxDuesUnknown,
          'khata_not_available': khataNotAvailable,
          'physical_visit_pending': physicalVisitDocs,
          'docs_seller_could_not_produce': notExistsDocs,
        },
      };

  int get portalsChecked {
    int count = 0;
    if (bhoomiOpened == true) count++;
    if (kaveriOpened == true) count++;
    if (isApartmentProject != null) count++; // RERA answered
    if (ecourtsOpened == true) count++;
    if (bbmpOpened == true) count++;
    if (cersaiOpened == true) count++;
    if (fmbOpened == true) count++;
    return count;
  }
}
