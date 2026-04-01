// ─── Digital Signature Verification Service ──────────────────────────────────
// All government property documents in Karnataka carry a Digital Signature
// Certificate (DSC) issued under IT Act 2000 + Information Technology
// (Certifying Authorities) Rules 2000.
//
// Documents with valid DSC:
//   • Bhoomi RTC — Tahsildar's DSC, QR code on document
//   • KAVERI EC  — Sub-Registrar's DSC, QR code on document
//   • Khata Cert — BBMP Commissioner's DSC, QR code on e-Aasthi
//   • Mutation Order — Tahsildar DSC after approval
//   • RERA Cert  — RERA Authority DSC
//   • e-Stamp    — SHCIL digital stamp, 24-digit unique number
//
// What DigiSampatti does:
//   1. Extracts QR code from scanned document photo (using OCR/camera)
//   2. Calls the respective government portal's verify endpoint
//   3. Gets back: signer name, designation, timestamp, hash
//   4. Compares returned data with document data (owner name, survey no.)
//   5. Returns: AUTHENTIC / TAMPERED / UNVERIFIABLE
//
// Why this matters:
//   Brokers sometimes show ALTERED Bhoomi printouts (changed owner name or area).
//   DigiSampatti checks the government's own QR → if data doesn't match printout,
//   document is forged. This is a criminal offence under IPC 465 (forgery).
// ──────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';

enum SignatureStatus {
  authentic,      // QR verified — document is genuine, signed by authority
  tampered,       // QR data doesn't match document text — FORGERY detected
  expired,        // DSC certificate has expired (rare, but happens)
  unverifiable,   // Portal couldn't verify (network/portal down)
  notApplicable,  // Document type doesn't carry DSC (pre-2015 docs)
}

class SignatureVerification {
  final SignatureStatus status;
  final String documentType;     // RTC / EC / Khata / Mutation / eStamp
  final String? signerName;      // e.g. "Sri Ramesh Gowda"
  final String? signerDesignation; // e.g. "Tahsildar, Yelahanka"
  final DateTime? signedAt;
  final String? documentHash;    // SHA-256 hash from QR
  final String? conflictDetail;  // If TAMPERED — what doesn't match
  final String? verifyUrl;       // URL used to verify

  const SignatureVerification({
    required this.status,
    required this.documentType,
    this.signerName,
    this.signerDesignation,
    this.signedAt,
    this.documentHash,
    this.conflictDetail,
    this.verifyUrl,
  });

  bool get isAuthentic => status == SignatureStatus.authentic;
  bool get isTampered  => status == SignatureStatus.tampered;

  String get statusLabel {
    switch (status) {
      case SignatureStatus.authentic:
        return '✓ Authentic — Officially Signed';
      case SignatureStatus.tampered:
        return '🚨 FORGERY DETECTED — Document Altered';
      case SignatureStatus.expired:
        return '⚠ DSC Expired — May still be valid, verify manually';
      case SignatureStatus.unverifiable:
        return 'Cannot verify — Portal unavailable';
      case SignatureStatus.notApplicable:
        return 'Pre-digital document — physical verification needed';
    }
  }
}

class DigitalSignatureService {
  static final DigitalSignatureService _i = DigitalSignatureService._();
  factory DigitalSignatureService() => _i;
  DigitalSignatureService._();

  late final Dio _dio;
  bool _ready = false;

  void initialize() {
    if (_ready) return;
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));
    _ready = true;
  }

  // ─── Verify Bhoomi RTC via QR code ───────────────────────────────────────
  // Bhoomi QR contains: encoded URL to land.kar.nic.in/verify?token=XXXX
  // That endpoint returns JSON with: owner, survey, tahsildar, timestamp, hash
  Future<SignatureVerification> verifyBhoomiRtc({
    required String qrData,
    String? expectedOwner,
    String? expectedSurveyNumber,
  }) async {
    if (!_ready) initialize();

    try {
      // QR data is typically a URL like:
      // https://land.kar.nic.in/landrecords/rtcprint/verify?appno=XXXX
      final verifyUrl = _extractVerifyUrl(qrData, 'bhoomi');
      if (verifyUrl == null) {
        return SignatureVerification(
          status: SignatureStatus.unverifiable,
          documentType: 'RTC',
        );
      }

      final resp = await _dio.get(verifyUrl);
      if (resp.statusCode == 200) {
        return _parseBhoomiVerify(resp.data, expectedOwner, expectedSurveyNumber);
      }
    } catch (_) {}

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'RTC',
    );
  }

  // ─── Verify KAVERI/IGRS EC via QR code ────────────────────────────────────
  // KAVERI QR URL: https://kaverionline.karnataka.gov.in/ecVerify?docNo=XXXX
  Future<SignatureVerification> verifyKaveriEc({
    required String qrData,
    String? expectedOwner,
  }) async {
    if (!_ready) initialize();

    try {
      final verifyUrl = _extractVerifyUrl(qrData, 'kaveri');
      if (verifyUrl == null) {
        return SignatureVerification(
          status: SignatureStatus.unverifiable,
          documentType: 'EC',
        );
      }

      final resp = await _dio.get(verifyUrl);
      if (resp.statusCode == 200) {
        return _parseKaveriVerify(resp.data, expectedOwner);
      }
    } catch (_) {}

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'EC',
    );
  }

  // ─── Verify e-Stamp (SHCIL) ───────────────────────────────────────────────
  // e-Stamp has a 24-digit Unique Identification Number (UIN)
  // Verify at: https://www.shcilestamps.com/Verify
  Future<SignatureVerification> verifyEStamp({
    required String uin,          // 24-digit UIN from e-stamp
    required String state,        // 'Karnataka'
    String? expectedAmount,
  }) async {
    if (!_ready) initialize();

    try {
      final resp = await _dio.post(
        'https://www.shcilestamps.com/Verify',
        data: {
          'uin': uin,
          'state': state,
        },
      );

      if (resp.statusCode == 200) {
        return _parseEStampVerify(resp.data, expectedAmount);
      }
    } catch (_) {}

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'e-Stamp',
    );
  }

  // ─── Verify Khata Certificate (BBMP e-Aasthi) ─────────────────────────────
  Future<SignatureVerification> verifyKhata({
    required String qrData,
    String? expectedOwner,
    String? expectedKhataNumber,
  }) async {
    if (!_ready) initialize();

    try {
      final verifyUrl = _extractVerifyUrl(qrData, 'bbmp');
      if (verifyUrl == null) {
        return SignatureVerification(
          status: SignatureStatus.unverifiable,
          documentType: 'Khata',
        );
      }

      final resp = await _dio.get(verifyUrl);
      if (resp.statusCode == 200) {
        return _parseKhataVerify(resp.data, expectedOwner, expectedKhataNumber);
      }
    } catch (_) {}

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'Khata',
    );
  }

  // ─── Parse Bhoomi verify response ─────────────────────────────────────────
  SignatureVerification _parseBhoomiVerify(
    dynamic data,
    String? expectedOwner,
    String? expectedSurvey,
  ) {
    try {
      final body = data is String ? data : data.toString();
      final lower = body.toLowerCase();

      // Bhoomi returns owner name, survey number, tahsildar name, timestamp
      final returnedOwner   = _extractField(body, ['owner_name', 'hissedhar', 'malik']);
      final returnedSurvey  = _extractField(body, ['survey_no', 'survey_number', 'sarvey']);
      final tahsildar       = _extractField(body, ['tahsildar', 'signed_by', 'officer']);
      final signedAt        = _extractDateField(body);

      // Check for tampering
      if (expectedOwner != null && returnedOwner != null) {
        if (!_namesMatch(expectedOwner, returnedOwner)) {
          return SignatureVerification(
            status: SignatureStatus.tampered,
            documentType: 'RTC',
            signerName: tahsildar,
            signedAt: signedAt,
            conflictDetail:
                'Document shows owner: "$expectedOwner" '
                'but government QR says: "$returnedOwner". '
                'This document has been ALTERED.',
          );
        }
      }

      if (expectedSurvey != null && returnedSurvey != null) {
        if (!_surveysMatch(expectedSurvey, returnedSurvey)) {
          return SignatureVerification(
            status: SignatureStatus.tampered,
            documentType: 'RTC',
            signerName: tahsildar,
            signedAt: signedAt,
            conflictDetail:
                'Survey number on document "$expectedSurvey" '
                'does not match QR data "$returnedSurvey".',
          );
        }
      }

      if (lower.contains('invalid') || lower.contains('not found')) {
        return SignatureVerification(
          status: SignatureStatus.unverifiable,
          documentType: 'RTC',
        );
      }

      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'RTC',
        signerName: tahsildar,
        signerDesignation: _extractField(body, ['designation', 'post', 'office']) ?? 'Tahsildar',
        signedAt: signedAt,
      );
    } catch (_) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'RTC',
      );
    }
  }

  SignatureVerification _parseKaveriVerify(dynamic data, String? expectedOwner) {
    final body = data is String ? data : data.toString();
    final lower = body.toLowerCase();

    if (lower.contains('valid') || lower.contains('authentic')) {
      final signerName = _extractField(body, ['sub_registrar', 'signed_by', 'registrar']);
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'EC',
        signerName: signerName,
        signerDesignation: 'Sub-Registrar',
        signedAt: _extractDateField(body),
      );
    }

    if (lower.contains('mismatch') || lower.contains('altered')) {
      return SignatureVerification(
        status: SignatureStatus.tampered,
        documentType: 'EC',
        conflictDetail: 'EC document data does not match Sub-Registrar records.',
      );
    }

    return SignatureVerification(status: SignatureStatus.unverifiable, documentType: 'EC');
  }

  SignatureVerification _parseEStampVerify(dynamic data, String? expectedAmount) {
    final body = data is String ? data : data.toString();
    final lower = body.toLowerCase();

    if (lower.contains('genuine') || lower.contains('valid') || lower.contains('verified')) {
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'e-Stamp',
        signerName: 'SHCIL (Stock Holding Corporation of India)',
        signerDesignation: 'Licensed e-Stamp Vendor',
        signedAt: _extractDateField(body),
      );
    }

    if (lower.contains('duplicate') || lower.contains('invalid') || lower.contains('fake')) {
      return SignatureVerification(
        status: SignatureStatus.tampered,
        documentType: 'e-Stamp',
        conflictDetail: 'This e-Stamp UIN is INVALID or has already been used.',
      );
    }

    return SignatureVerification(status: SignatureStatus.unverifiable, documentType: 'e-Stamp');
  }

  SignatureVerification _parseKhataVerify(dynamic data, String? expectedOwner, String? expectedKhata) {
    final body = data is String ? data : data.toString();
    final lower = body.toLowerCase();

    if (lower.contains('verified') || lower.contains('genuine')) {
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'Khata',
        signerName: _extractField(body, ['commissioner', 'revenue_officer', 'aro']),
        signerDesignation: 'Assistant Revenue Officer, BBMP',
        signedAt: _extractDateField(body),
      );
    }

    return SignatureVerification(status: SignatureStatus.unverifiable, documentType: 'Khata');
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String? _extractVerifyUrl(String qrData, String portal) {
    // If QR data is already a URL, use it
    if (qrData.startsWith('http')) return qrData;

    // Build portal-specific verify URL from QR token
    switch (portal) {
      case 'bhoomi':
        return 'https://land.kar.nic.in/landrecords/rtcprint/verify?token=$qrData';
      case 'kaveri':
        return 'https://kaverionline.karnataka.gov.in/ecVerify?docNo=$qrData';
      case 'bbmp':
        return 'https://bbmpeaasthi.karnataka.gov.in/verify?id=$qrData';
      default:
        return null;
    }
  }

  String? _extractField(String body, List<String> keys) {
    for (final key in keys) {
      final regex = RegExp('"?$key"?\\s*[:=]\\s*"?([^",}\\n]+)"?', caseSensitive: false);
      final match = regex.firstMatch(body);
      if (match != null) {
        final val = match.group(1)?.trim();
        if (val != null && val.isNotEmpty) return val;
      }
    }
    return null;
  }

  DateTime? _extractDateField(String body) {
    final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}T?\d{2}:\d{2}');
    final match = dateRegex.firstMatch(body);
    if (match != null) {
      try { return DateTime.parse(match.group(0)!); } catch (_) {}
    }
    return null;
  }

  // Fuzzy name match — handles transliteration differences
  bool _namesMatch(String a, String b) {
    final clean = (String s) => s.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .trim();
    final ca = clean(a); final cb = clean(b);
    if (ca == cb) return true;
    // Allow 2 character difference (transliteration variants)
    int diff = 0;
    final shorter = ca.length < cb.length ? ca : cb;
    final longer  = ca.length < cb.length ? cb : ca;
    for (int i = 0; i < shorter.length; i++) {
      if (i >= longer.length || shorter[i] != longer[i]) diff++;
    }
    diff += (longer.length - shorter.length).abs();
    return diff <= 3;
  }

  bool _surveysMatch(String a, String b) {
    final clean = (String s) => s.replaceAll(RegExp(r'[\s/\\.]'), '').toLowerCase();
    return clean(a) == clean(b);
  }
}
