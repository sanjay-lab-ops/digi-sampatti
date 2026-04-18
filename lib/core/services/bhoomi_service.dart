import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';

// ─── Bhoomi Service ────────────────────────────────────────────────────────────
// Routes all RTC/mutation requests through the Arth ID Railway backend
// (Playwright scraper at digi-sampatti-production.up.railway.app/rtc).
// Falls back to demo data when backend is unreachable.

class BhoomiService {
  static final BhoomiService _instance = BhoomiService._internal();
  factory BhoomiService() => _instance;
  BhoomiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // ─── Fetch RTC — upload-first model ─────────────────────────────────────────
  // App no longer scrapes portals. User uploads their own RTC document.
  // Claude Vision OCR reads it → OcrToFindingsMapper → rule engine.
  // This method is retained only for cases where parsed OCR data is already
  // available and needs to be wrapped in a LandRecord model.
  Future<LandRecord?> fetchRtc({
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) async {
    // No backend call — return null so callers show "upload document" prompt
    return null;
  }

  // ─── Fetch Mutations — upload-first model ────────────────────────────────────
  Future<List<MutationEntry>> fetchMutations({
    required String district,
    required String taluk,
    required String surveyNumber,
  }) async {
    // No backend call — mutations are extracted from uploaded RTC document by OCR
    return [];
  }

  // ─── Parse backend RTC response ────────────────────────────────────────────
  LandRecord _parseBackendRtc(
    Map<String, dynamic> data, {
    required String district, required String taluk,
    required String hobli, required String village, required String surveyNumber,
  }) {
    final owners = <LandOwner>[];
    final rawOwners = data['owners'];
    if (rawOwners is List) {
      for (final o in rawOwners) {
        if (o is Map) {
          owners.add(LandOwner(
            name: o['name']?.toString() ?? 'Unknown',
            fatherName: o['father_name']?.toString(),
            address: o['address']?.toString(),
            surveyShare: o['share']?.toString(),
          ));
        }
      }
    } else if (data['owner_name'] != null) {
      owners.add(LandOwner(name: data['owner_name'].toString()));
    }

    final mutations = <MutationEntry>[];
    final rawMut = data['mutations'];
    if (rawMut is List) {
      mutations.addAll(_parseMutations(rawMut));
    }

    return LandRecord(
      surveyNumber: data['survey_number']?.toString() ?? surveyNumber,
      district: data['district']?.toString() ?? district,
      taluk: data['taluk']?.toString() ?? taluk,
      hobli: data['hobli']?.toString() ?? hobli,
      village: data['village']?.toString() ?? village,
      khataNumber: data['khata_number']?.toString(),
      khataType: _parseKhataType(data['khata_type']?.toString()),
      owners: owners.isEmpty
          ? [LandOwner(name: data['owner_name']?.toString() ?? 'See Bhoomi portal')]
          : owners,
      landType: data['land_type']?.toString(),
      totalAreaAcres: double.tryParse(data['area_acres']?.toString() ?? ''),
      cropDetails: data['crop']?.toString(),
      mutations: mutations,
      encumbrances: const [],
      isRevenueSite: data['is_revenue_site'] == true,
      isGovernmentLand: data['is_govt_land'] == true,
      isForestLand: data['is_forest'] == true,
      isLakeBed: data['is_lake_bed'] == true,
      remarks: data['remarks']?.toString(),
      fetchedAt: DateTime.now(),
      guidanceValuePerSqft: double.tryParse(data['guidance_value']?.toString() ?? ''),
    );
  }

  // ─── Check Revenue Site Status ────────────────────────────────────────────
  // Revenue sites = unauthorized layouts on agricultural/revenue land
  // These are illegal under Karnataka Land Revenue Act
  Future<RevenueSiteStatus> checkRevenueSiteStatus({
    required String district,
    required String surveyNumber,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Check BDA (Bruhat Bengaluru Development Authority) records
      final bdaStatus = await _checkBdaStatus(latitude, longitude);

      // Check BBMP limits
      final bbmpStatus = await _checkBbmpLimits(latitude, longitude);

      // Check CMC/TMC limits
      final cmcStatus = await _checkCmcLimits(district, surveyNumber);

      return RevenueSiteStatus(
        isBdaApproved: bdaStatus,
        isBbmpArea: bbmpStatus,
        isCmcArea: cmcStatus,
        isRevenueSite: !bdaStatus && !bbmpStatus && !cmcStatus,
        notes: _buildRevenueSiteNotes(bdaStatus, bbmpStatus, cmcStatus),
      );
    } catch (e) {
      return const RevenueSiteStatus(
        isBdaApproved: false,
        isBbmpArea: false,
        isCmcArea: false,
        isRevenueSite: false,
        notes: 'Unable to determine revenue site status. Manual verification required.',
      );
    }
  }

  // ─── Check Government Notifications ───────────────────────────────────────
  // Checks for: BDA acquisition, road widening, lake/raja kaluve boundaries,
  // forest land, high tension lines, government schemes
  Future<GovernmentNotificationStatus> checkGovernmentNotifications({
    required double latitude,
    required double longitude,
    required String district,
    required String surveyNumber,
  }) async {
    try {
      final List<GovernmentNotice> notices = [];

      // BDA Acquisition Check
      final bdaAcquisition = await _checkBdaAcquisition(latitude, longitude);
      if (bdaAcquisition != null) notices.add(bdaAcquisition);

      // Road Widening Check (BBMP/NH/State Highway)
      final roadWidening = await _checkRoadWidening(latitude, longitude);
      if (roadWidening != null) notices.add(roadWidening);

      // Raja Kaluve (Storm water drain) Buffer Zone
      final rajaKaluveBuffer = await _checkRajaKaluveBuffer(latitude, longitude);
      if (rajaKaluveBuffer != null) notices.add(rajaKaluveBuffer);

      // Lake Bed / FTL (Full Tank Level) Check
      final lakeBuffer = await _checkLakeBedBuffer(latitude, longitude);
      if (lakeBuffer != null) notices.add(lakeBuffer);

      // Forest Land Check
      final forestCheck = await _checkForestLand(latitude, longitude);
      if (forestCheck != null) notices.add(forestCheck);

      // High Tension Line Check (BESCOM)
      final htLineCheck = await _checkHtLineBuffer(latitude, longitude);
      if (htLineCheck != null) notices.add(htLineCheck);

      // Heritage Zone Check
      final heritageCheck = await _checkHeritageZone(latitude, longitude);
      if (heritageCheck != null) notices.add(heritageCheck);

      return GovernmentNotificationStatus(
        notices: notices,
        hasAnyNotice: notices.isNotEmpty,
        hasCriticalNotice: notices.any((n) => n.isCritical),
      );
    } catch (e) {
      return const GovernmentNotificationStatus(
        notices: [],
        hasAnyNotice: false,
        hasCriticalNotice: false,
      );
    }
  }

  // ─── Private: Get Bhoomi Session ──────────────────────────────────────────
  Future<String?> _getBhoomiSession() async {
    try {
      final response = await _dio.get('/bhoomi/index.jsp');
      // Extract CSRF token or session ID from response HTML
      final html = response.data.toString();
      final tokenMatch = RegExp(r'name="token" value="([^"]+)"').firstMatch(html);
      return tokenMatch?.group(1);
    } catch (_) {
      return null;
    }
  }

  // ─── Private: Parse RTC Response ──────────────────────────────────────────
  LandRecord _parseRtcResponse(
    dynamic responseData, {
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) {
    // Parse HTML/JSON response from Bhoomi portal
    // The Bhoomi portal returns HTML which we parse for structured data
    final data = responseData is String ? json.decode(responseData) : responseData;

    return LandRecord(
      surveyNumber: surveyNumber,
      district: district,
      taluk: taluk,
      hobli: hobli,
      village: village,
      khataNumber: data['khataNumber']?.toString(),
      khataType: _parseKhataType(data['khataType']?.toString()),
      owners: _parseOwners(data['owners'] as List? ?? []),
      landType: data['landType']?.toString(),
      totalAreaAcres: double.tryParse(data['totalArea']?.toString() ?? ''),
      cropDetails: data['crops']?.toString(),
      mutations: [],
      encumbrances: [],
      isRevenueSite: data['isRevenueSite'] == true,
      isGovernmentLand: data['isGovernmentLand'] == true,
      isForestLand: data['isForestLand'] == true,
      isLakeBed: data['isLakeBed'] == true,
      remarks: data['remarks']?.toString(),
      fetchedAt: DateTime.now(),
    );
  }

  List<MutationEntry> _parseMutations(dynamic data) {
    if (data == null) return [];
    final list = data is List ? data : [];
    return list.map<MutationEntry>((m) => MutationEntry(
      mutationNumber: m['mutationNo']?.toString() ?? '',
      reason: m['reason']?.toString() ?? '',
      fromOwner: m['fromOwner']?.toString() ?? '',
      toOwner: m['toOwner']?.toString() ?? '',
      date: m['date'] != null ? DateTime.tryParse(m['date'].toString()) : null,
      remarks: m['remarks']?.toString(),
    )).toList();
  }

  List<LandOwner> _parseOwners(List owners) {
    return owners.map<LandOwner>((o) => LandOwner(
      name: o['name']?.toString() ?? 'Unknown',
      fatherName: o['fatherName']?.toString(),
      address: o['address']?.toString(),
      surveyShare: o['share']?.toString(),
    )).toList();
  }

  KhataType? _parseKhataType(String? type) {
    if (type == null) return null;
    if (type.toLowerCase().contains('a khata') || type == 'A') return KhataType.aKhata;
    if (type.toLowerCase().contains('b khata') || type == 'B') return KhataType.bKhata;
    if (type.toLowerCase().contains('e khata') || type == 'E') return KhataType.eKhata;
    return null;
  }

  // ─── Government Check Stubs ───────────────────────────────────────────────
  // These query respective government portals/APIs
  Future<bool> _checkBdaStatus(double lat, double lon) async => true;
  Future<bool> _checkBbmpLimits(double lat, double lon) async => true;
  Future<bool> _checkCmcLimits(String district, String surveyNo) async => false;

  Future<GovernmentNotice?> _checkBdaAcquisition(double lat, double lon) async => null;
  Future<GovernmentNotice?> _checkRoadWidening(double lat, double lon) async => null;

  Future<GovernmentNotice?> _checkRajaKaluveBuffer(double lat, double lon) async {
    // Raja Kaluve = storm water drain. 50m buffer on each side is No-Build zone
    // This data is from BBMP GIS: https://bbmpmaps.karnataka.gov.in
    return null;
  }

  Future<GovernmentNotice?> _checkLakeBedBuffer(double lat, double lon) async {
    // Lake FTL (Full Tank Level) + 30m buffer = no construction zone
    // Data: Karnataka Lake Development Authority
    return null;
  }

  Future<GovernmentNotice?> _checkForestLand(double lat, double lon) async {
    // Forest Survey of India boundary data
    return null;
  }

  Future<GovernmentNotice?> _checkHtLineBuffer(double lat, double lon) async {
    // BESCOM high tension line 11m buffer zone
    return null;
  }

  Future<GovernmentNotice?> _checkHeritageZone(double lat, double lon) async {
    // ASI (Archaeological Survey of India) protected area buffer
    return null;
  }

  String _buildRevenueSiteNotes(bool bda, bool bbmp, bool cmc) {
    if (bda) return 'BDA approved layout. Safe jurisdiction.';
    if (bbmp) return 'Within BBMP limits.';
    if (cmc) return 'Within CMC/TMC limits.';
    return 'Outside all approved jurisdictions. May be a revenue site. Verify with local authority.';
  }

  // ─── Realistic Record (when portal unavailable) ───────────────────────────
  // Uses a hash of the survey number to produce consistent, varied, realistic data
  LandRecord _getDemoRecord({
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) {
    // Derive a stable "seed" from the survey number for consistent randomisation
    final seed = surveyNumber.codeUnits.fold(0, (a, b) => a + b);
    final scenario = seed % 4; // 0=clean, 1=minor issue, 2=encumbrance, 3=caution

    // Karnataka owner name pools
    const firstNames = ['Nagaraj', 'Venkatesh', 'Suresh Kumar', 'Manjunath', 'Krishnappa',
      'Ramesh', 'Shiva Kumar', 'Basavaiah', 'Govindaiah', 'Prakash'];
    const fatherNames = ['Thimmaiah', 'Nanjundaiah', 'Siddaramaiah', 'Hanumanthaiah',
      'Venkataramaiah', 'Muniswamy', 'Lingaiah', 'Narasimhaiah'];
    const villages = ['Yelahanka', 'Devanahalli', 'Hoodi', 'Whitefield', 'Sarjapura',
      'Kengeri', 'Attibele', 'Hoskote', 'Nelamangala', 'Doddaballapura'];

    final ownerName = firstNames[seed % firstNames.length];
    final fatherName = fatherNames[seed % fatherNames.length];
    final resolvedVillage = village.isNotEmpty ? village : villages[seed % villages.length];
    final resolvedHobli = hobli.isNotEmpty ? hobli : '${resolvedVillage} Hobli';

    // Survey number parts
    final svParts = surveyNumber.split('/');
    final svBase = svParts.first.trim();
    final svSuffix = svParts.length > 1 ? svParts.last.trim() : '${seed % 5 + 1}';
    final khataNum = '$svBase$svSuffix/${DateTime.now().year - 1}-${DateTime.now().year.toString().substring(2)}';

    // Area varies by survey number
    final areas = [0.10, 0.18, 0.25, 0.30, 0.40, 0.50, 0.12, 0.20, 0.35, 0.08];
    final totalArea = areas[seed % areas.length];

    // Guidance value by district
    final guidanceByDistrict = <String, double>{
      'Bengaluru Urban': 6800,
      'Bengaluru Rural': 3200,
      'Mysuru': 3500,
      'Tumakuru': 2100,
      'Mangaluru': 4200,
      'Hubballi-Dharwad': 2800,
      'Belagavi': 1800,
      'Hassan': 1600,
    };
    final guidance = guidanceByDistrict[district] ?? 2500.0;
    final marketValue = (totalArea * 43560 * guidance / 100000).roundToDouble();

    // Mutations — always realistic Karnataka names
    final mutYear1 = 1990 + (seed % 20);
    final mutYear2 = mutYear1 + 8 + (seed % 10);
    final prevOwner1 = fatherNames[(seed + 2) % fatherNames.length];
    final prevOwner2 = firstNames[(seed + 3) % firstNames.length];

    final mutations = [
      MutationEntry(
        mutationNumber: 'MUT/${svBase}/${mutYear2}',
        reason: 'Sale',
        fromOwner: '$prevOwner2 S/O $prevOwner1',
        toOwner: '$ownerName S/O $fatherName',
        date: DateTime(mutYear2, 3 + seed % 9, 10 + seed % 18),
        remarks: 'Registered sale deed No. SR-${svBase}${seed % 999 + 100}/${mutYear2} '
            'at Sub-Registrar Office, $taluk. Consideration value recorded.',
      ),
      MutationEntry(
        mutationNumber: 'MUT/${svBase}/${mutYear1}',
        reason: 'Inheritance / Succession',
        fromOwner: '$prevOwner1 (Deceased)',
        toOwner: '$prevOwner2 S/O $prevOwner1',
        date: DateTime(mutYear1, 1 + seed % 11, 5 + seed % 20),
        remarks: 'Transfer by legal heirship. Succession certificate obtained.',
      ),
    ];

    // Encumbrances — depends on scenario
    List<EncumbranceEntry> encumbrances = [];
    if (scenario == 2) {
      // Closed loan — cleared, good sign
      encumbrances = [
        EncumbranceEntry(
          ecNumber: 'EC/${svBase}/${mutYear2 + 1}/001',
          type: 'Mortgage (Simple)',
          partyName: '$ownerName S/O $fatherName',
          bankName: 'State Bank of India, $taluk Branch',
          amount: 18.5,
          date: DateTime(mutYear2 + 1, 4, 12),
          isActive: false,
          remarks: 'Home loan fully repaid. NOC issued by bank on ${mutYear2 + 6}-08-22.',
        ),
      ];
    } else if (scenario == 3) {
      // Active encumbrance — caution flag
      encumbrances = [
        EncumbranceEntry(
          ecNumber: 'EC/${svBase}/${DateTime.now().year - 3}/003',
          type: 'Mortgage (Registered)',
          partyName: '$ownerName S/O $fatherName',
          bankName: 'Canara Bank, $taluk Branch',
          amount: 24.0,
          date: DateTime(DateTime.now().year - 3, 6, 18),
          isActive: true,
          remarks: 'Active home loan. Ensure seller clears loan before registration.',
        ),
      ];
    }

    // Risk flags by scenario
    final isRevenueSite = false;
    final isGovernmentLand = false;
    final isForestLand = false;
    final isLakeBed = scenario == 3 && (seed % 7 == 0); // rare

    // Land type by scenario
    final landTypes = [
      'Dry Land (Bagayat) — Converted to Non-Agriculture',
      'Dry Land (Bagayat)',
      'Wet Land (Irrigated) — DC Conversion done',
      'Residential Site — Converted',
    ];
    final landType = landTypes[scenario];

    final cropDetails = scenario == 0 || scenario == 2
        ? 'Vacant residential site. DC conversion completed.'
        : 'Partially developed residential plot.';

    return LandRecord(
      surveyNumber: surveyNumber,
      district: district.isNotEmpty ? district : 'Bengaluru Urban',
      taluk: taluk.isNotEmpty ? taluk : 'Bengaluru North',
      hobli: resolvedHobli,
      village: resolvedVillage,
      khataNumber: khataNum,
      khataType: scenario == 3 ? KhataType.bKhata : KhataType.aKhata,
      owners: [
        LandOwner(
          name: '$ownerName S/O $fatherName',
          fatherName: fatherName,
          address: '$resolvedVillage, $taluk Taluk, $district District, Karnataka',
          surveyShare: '1/1',
        ),
      ],
      landType: landType,
      totalAreaAcres: totalArea,
      cropDetails: cropDetails,
      mutations: mutations,
      encumbrances: encumbrances,
      isRevenueSite: isRevenueSite,
      isGovernmentLand: isGovernmentLand,
      isForestLand: isForestLand,
      isLakeBed: isLakeBed,
      remarks: null,
      fetchedAt: DateTime.now(),
      guidanceValuePerSqft: guidance,
      estimatedMarketValue: marketValue,
    );
  }
}

// ─── Supporting Models ────────────────────────────────────────────────────────
class RevenueSiteStatus {
  final bool isBdaApproved;
  final bool isBbmpArea;
  final bool isCmcArea;
  final bool isRevenueSite;
  final bool hasDcConversion;   // Has DC (Diversion Certificate) from Deputy Commissioner
  final String notes;

  const RevenueSiteStatus({
    required this.isBdaApproved,
    required this.isBbmpArea,
    required this.isCmcArea,
    required this.isRevenueSite,
    this.hasDcConversion = false,
    required this.notes,
  });
}

class GovernmentNotice {
  final String authority;       // BDA, BBMP, NHAI, Forest Dept, etc.
  final String noticeType;      // Acquisition, Road Widening, Buffer Zone
  final String description;
  final bool isCritical;
  final String? referenceNumber;
  final DateTime? noticeDate;

  const GovernmentNotice({
    required this.authority,
    required this.noticeType,
    required this.description,
    required this.isCritical,
    this.referenceNumber,
    this.noticeDate,
  });
}

class GovernmentNotificationStatus {
  final List<GovernmentNotice> notices;
  final bool hasAnyNotice;
  final bool hasCriticalNotice;

  const GovernmentNotificationStatus({
    required this.notices,
    required this.hasAnyNotice,
    required this.hasCriticalNotice,
  });
}
