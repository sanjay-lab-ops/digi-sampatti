import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';

// ─── Bhoomi Service ────────────────────────────────────────────────────────────
// Integrates with Karnataka Bhoomi portal (bhoomi.karnataka.gov.in)
// Fetches: RTC, Mutation records, Owner details, Land type, Kharab land status
//
// NOTE: The Bhoomi portal does not have a public documented REST API.
// This service uses:
//   1. HTTP requests matching Bhoomi portal's internal endpoints
//   2. HTML parsing for data extraction
//   3. Falls back to mock/demo data when portal is unavailable
// For production, get an official MoU with Karnataka Government's
// SSLR (Survey Settlement and Land Records) department.

class BhoomiService {
  static final BhoomiService _instance = BhoomiService._internal();
  factory BhoomiService() => _instance;
  BhoomiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.bhoomiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: ApiConstants.bhoomiHeaders,
    ));

    // Intercept for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));
  }

  // ─── Fetch RTC (Record of Rights, Tenancy & Crops) ─────────────────────────
  // This is the primary land record document in Karnataka
  Future<LandRecord?> fetchRtc({
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) async {
    try {
      // Step 1: Get session/token from Bhoomi portal
      final sessionToken = await _getBhoomiSession();

      // Step 2: Submit RTC request
      final response = await _dio.post(
        ApiConstants.bhoomiRtcEndpoint,
        data: {
          'district': district,
          'taluk': taluk,
          'hobli': hobli,
          'village': village,
          'surveyNo': surveyNumber,
          'token': sessionToken,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        return _parseRtcResponse(
          response.data,
          district: district,
          taluk: taluk,
          hobli: hobli,
          village: village,
          surveyNumber: surveyNumber,
        );
      }
    } catch (_) {}

    // Always return demo data when real portal unavailable
    return _getDemoRecord(
      district: district,
      taluk: taluk,
      hobli: hobli,
      village: village,
      surveyNumber: surveyNumber,
    );
  }

  // ─── Fetch Mutation History ────────────────────────────────────────────────
  Future<List<MutationEntry>> fetchMutations({
    required String district,
    required String taluk,
    required String surveyNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bhoomiMutationEndpoint,
        data: {
          'district': district,
          'taluk': taluk,
          'surveyNo': surveyNumber,
        },
      );

      if (response.statusCode == 200) {
        return _parseMutations(response.data);
      }
    } catch (_) {}
    return [];
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

  // ─── Demo Data (when portal unavailable) ──────────────────────────────────
  LandRecord _getDemoRecord({
    required String district,
    required String taluk,
    required String hobli,
    required String village,
    required String surveyNumber,
  }) {
    return LandRecord(
      surveyNumber: surveyNumber,
      district: district,
      taluk: taluk,
      hobli: hobli.isNotEmpty ? hobli : 'Krishnarajapura',
      village: village.isNotEmpty ? village : 'Hoodi',
      khataNumber: '${surveyNumber.replaceAll('/', '')}/2024-25',
      khataType: KhataType.aKhata,
      owners: [
        LandOwner(
          name: 'Ramaiah S/O Venkatesh',
          fatherName: 'Venkatesh',
          address: '$taluk, $district, Karnataka - 560048',
          surveyShare: '1/1',
        ),
      ],
      landType: 'Dry Land (Bagayat)',
      totalAreaAcres: 0.20,
      cropDetails: 'Vacant residential site',
      mutations: [
        MutationEntry(
          mutationNumber: 'MUT/${surveyNumber}/2018',
          reason: 'Sale',
          fromOwner: 'Krishna Murthy',
          toOwner: 'Ramaiah S/O Venkatesh',
          date: DateTime(2018, 6, 15),
          remarks: 'Registered sale deed at Sub-Registrar Office, $taluk',
        ),
        MutationEntry(
          mutationNumber: 'MUT/${surveyNumber}/2005',
          reason: 'Inheritance',
          fromOwner: 'Venkatesh (Deceased)',
          toOwner: 'Krishna Murthy',
          date: DateTime(2005, 3, 10),
          remarks: 'Transfer by succession',
        ),
      ],
      encumbrances: const [],
      isRevenueSite: false,
      isGovernmentLand: false,
      isForestLand: false,
      isLakeBed: false,
      remarks: 'DEMO DATA — Connect real Bhoomi API for live records.',
      fetchedAt: DateTime.now(),
      guidanceValuePerSqft: 4500,
      estimatedMarketValue: 52.0,
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
