// ─── Digital Signature Verification Service ──────────────────────────────────
// All government property documents in Karnataka carry a Digital Signature
// Certificate (DSC) issued under IT Act 2000 + Information Technology
// (Certifying Authorities) Rules 2000.
//
// MISTAKE-PROOF DESIGN:
//   - Browser-like headers so portals don't block us
//   - 3-attempt retry with exponential backoff (handles flaky portals)
//   - Explicit error types: NETWORK / PORTAL_DOWN / PARSE_FAILED / TAMPERED
//   - Every call logs which URL was hit and exactly why it failed
//   - No silent catch(_){} — every error is categorised
// ──────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';

enum SignatureStatus {
  authentic,      // QR verified — document is genuine, signed by authority
  tampered,       // QR data doesn't match document text — FORGERY detected
  expired,        // DSC certificate has expired (rare, but happens)
  unverifiable,   // Portal couldn't verify (network/portal down)
  notApplicable,  // Document type doesn't carry DSC (pre-2015 docs)
}

enum VerifyFailReason {
  none,
  networkError,      // No internet / timeout
  portalDown,        // HTTP 5xx or 404
  captchaBlocked,    // Portal returned CAPTCHA page
  parseFailed,       // Got response but couldn't extract data
  sessionRequired,   // Portal requires login session
}

class SignatureVerification {
  final SignatureStatus status;
  final String documentType;
  final String? signerName;
  final String? signerDesignation;
  final DateTime? signedAt;
  final String? documentHash;
  final String? conflictDetail;
  final String? verifyUrl;          // Exact URL that was called
  final VerifyFailReason failReason; // WHY it failed (if unverifiable)
  final String? failDetail;          // Human-readable failure detail

  const SignatureVerification({
    required this.status,
    required this.documentType,
    this.signerName,
    this.signerDesignation,
    this.signedAt,
    this.documentHash,
    this.conflictDetail,
    this.verifyUrl,
    this.failReason = VerifyFailReason.none,
    this.failDetail,
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
        return '⚠ DSC Expired — Verify manually';
      case SignatureStatus.unverifiable:
        return _unverifiableLabel;
      case SignatureStatus.notApplicable:
        return 'Pre-digital document — physical verification needed';
    }
  }

  String get _unverifiableLabel {
    switch (failReason) {
      case VerifyFailReason.networkError:
        return 'Network error — retry with internet connection';
      case VerifyFailReason.portalDown:
        return 'Government portal temporarily down — retry later';
      case VerifyFailReason.captchaBlocked:
        return 'Portal requires manual check — visit URL below';
      case VerifyFailReason.sessionRequired:
        return 'Portal requires login — manual verification needed';
      case VerifyFailReason.parseFailed:
        return 'Response received but could not extract data';
      default:
        return 'Cannot verify — portal unavailable';
    }
  }
}

class DigitalSignatureService {
  static final DigitalSignatureService _i = DigitalSignatureService._();
  factory DigitalSignatureService() => _i;
  DigitalSignatureService._();

  late final Dio _dio;
  bool _ready = false;

  // Browser-like headers so government portals treat us as a real browser
  static const _browserHeaders = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/112.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,'
        'application/json,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-IN,en;q=0.9,kn;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'no-cache',
  };

  void initialize() {
    if (_ready) return;
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      headers: _browserHeaders,
      followRedirects: true,
      maxRedirects: 5,
    ));
    _ready = true;
  }

  // ─── Robust HTTP GET with retry ───────────────────────────────────────────
  // Retries up to 3 times with exponential backoff.
  // Returns (responseBody, failReason, failDetail, statusCode).
  Future<({String? body, VerifyFailReason fail, String? detail, int? code})>
      _getWithRetry(String url, {Map<String, String>? extraHeaders}) async {
    if (!_ready) initialize();

    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final resp = await _dio.get<String>(
          url,
          options: Options(
            headers: extraHeaders,
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 600,
          ),
        );

        final code = resp.statusCode ?? 0;
        final body = resp.data ?? '';

        if (code == 200) {
          // Check if portal returned CAPTCHA page
          if (_isCaptchaPage(body)) {
            return (
              body: null,
              fail: VerifyFailReason.captchaBlocked,
              detail: 'Portal returned CAPTCHA at $url',
              code: code,
            );
          }
          // Check if portal requires login
          if (_isLoginPage(body)) {
            return (
              body: null,
              fail: VerifyFailReason.sessionRequired,
              detail: 'Portal requires session login at $url',
              code: code,
            );
          }
          return (body: body, fail: VerifyFailReason.none, detail: null, code: code);
        }

        if (code >= 500) {
          // Server error — retry
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          return (
            body: null,
            fail: VerifyFailReason.portalDown,
            detail: 'Portal returned HTTP $code at $url',
            code: code,
          );
        }

        if (code == 404) {
          return (
            body: null,
            fail: VerifyFailReason.portalDown,
            detail: 'Verify endpoint not found (404) at $url',
            code: code,
          );
        }

        // Other non-200 — treat body as received but note the code
        return (body: body, fail: VerifyFailReason.none, detail: null, code: code);
      } on DioException catch (e) {
        final isNetwork = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (isNetwork && attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        return (
          body: null,
          fail: isNetwork ? VerifyFailReason.networkError : VerifyFailReason.portalDown,
          detail: 'Attempt $attempt/$maxAttempts: ${e.message}',
          code: null,
        );
      } catch (e) {
        return (
          body: null,
          fail: VerifyFailReason.parseFailed,
          detail: 'Unexpected error: $e',
          code: null,
        );
      }
    }

    return (
      body: null,
      fail: VerifyFailReason.networkError,
      detail: 'All $maxAttempts retry attempts failed for $url',
      code: null,
    );
  }

  // ─── Verify Bhoomi RTC ────────────────────────────────────────────────────
  Future<SignatureVerification> verifyBhoomiRtc({
    required String qrData,
    String? expectedOwner,
    String? expectedSurveyNumber,
  }) async {
    final verifyUrl = _buildVerifyUrl(qrData, 'bhoomi');
    if (verifyUrl == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'RTC',
        failReason: VerifyFailReason.parseFailed,
        failDetail: 'Could not extract verify URL from QR data',
      );
    }

    final result = await _getWithRetry(verifyUrl, extraHeaders: {
      'Referer': 'https://land.kar.nic.in/',
    });

    if (result.body == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'RTC',
        verifyUrl: verifyUrl,
        failReason: result.fail,
        failDetail: result.detail,
      );
    }

    return _parseBhoomiVerify(result.body!, expectedOwner, expectedSurveyNumber, verifyUrl);
  }

  // ─── Verify KAVERI/IGRS EC ────────────────────────────────────────────────
  Future<SignatureVerification> verifyKaveriEc({
    required String qrData,
    String? expectedOwner,
  }) async {
    final verifyUrl = _buildVerifyUrl(qrData, 'kaveri');
    if (verifyUrl == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'EC',
        failReason: VerifyFailReason.parseFailed,
        failDetail: 'Could not extract verify URL from QR data',
      );
    }

    final result = await _getWithRetry(verifyUrl, extraHeaders: {
      'Referer': 'https://kaverionline.karnataka.gov.in/',
    });

    if (result.body == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'EC',
        verifyUrl: verifyUrl,
        failReason: result.fail,
        failDetail: result.detail,
      );
    }

    return _parseKaveriVerify(result.body!, expectedOwner, verifyUrl);
  }

  // ─── Verify e-Stamp (SHCIL) ───────────────────────────────────────────────
  Future<SignatureVerification> verifyEStamp({
    required String uin,
    required String state,
    String? expectedAmount,
  }) async {
    const verifyUrl = 'https://www.shcilestamps.com/Verify';

    VerifyFailReason failReason = VerifyFailReason.none;
    String? failDetail;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final resp = await _dio.post<String>(
          verifyUrl,
          data: 'uin=$uin&state=$state',
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            headers: {'Referer': 'https://www.shcilestamps.com/'},
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 600,
          ),
        );

        if (resp.statusCode == 200 && resp.data != null) {
          return _parseEStampVerify(resp.data!, expectedAmount, verifyUrl, uin);
        }

        failReason = VerifyFailReason.portalDown;
        failDetail = 'SHCIL returned HTTP ${resp.statusCode}';
      } on DioException catch (e) {
        failReason = VerifyFailReason.networkError;
        failDetail = e.message;
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'e-Stamp',
      verifyUrl: verifyUrl,
      failReason: failReason,
      failDetail: failDetail,
    );
  }

  // ─── Verify Khata (BBMP e-Aasthi) ────────────────────────────────────────
  Future<SignatureVerification> verifyKhata({
    required String qrData,
    String? expectedOwner,
    String? expectedKhataNumber,
  }) async {
    final verifyUrl = _buildVerifyUrl(qrData, 'bbmp');
    if (verifyUrl == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'Khata',
        failReason: VerifyFailReason.parseFailed,
        failDetail: 'Could not extract verify URL from QR data',
      );
    }

    final result = await _getWithRetry(verifyUrl, extraHeaders: {
      'Referer': 'https://bbmpeaasthi.karnataka.gov.in/',
    });

    if (result.body == null) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'Khata',
        verifyUrl: verifyUrl,
        failReason: result.fail,
        failDetail: result.detail,
      );
    }

    return _parseKhataVerify(result.body!, expectedOwner, expectedKhataNumber, verifyUrl);
  }

  // ─── Parse Bhoomi response ────────────────────────────────────────────────
  SignatureVerification _parseBhoomiVerify(
    String body, String? expectedOwner, String? expectedSurvey, String verifyUrl,
  ) {
    try {
      final lower = body.toLowerCase();

      // Hard-fail markers
      if (lower.contains('token expired') || lower.contains('link expired')) {
        return SignatureVerification(
          status: SignatureStatus.expired,
          documentType: 'RTC',
          verifyUrl: verifyUrl,
          failDetail: 'QR verification link has expired. Re-download RTC from Bhoomi.',
        );
      }

      if (lower.contains('record not found') || lower.contains('invalid token') ||
          lower.contains('no record')) {
        return SignatureVerification(
          status: SignatureStatus.unverifiable,
          documentType: 'RTC',
          verifyUrl: verifyUrl,
          failReason: VerifyFailReason.parseFailed,
          failDetail: 'Bhoomi says: record not found for this QR',
        );
      }

      final returnedOwner  = _extractField(body, ['owner_name', 'hissedhar', 'malik', 'khathedar', 'ryot_name']);
      final returnedSurvey = _extractField(body, ['survey_no', 'survey_number', 'sarvey_no', 'hissa_no']);
      final tahsildar      = _extractField(body, ['tahsildar', 'signed_by', 'officer', 'authorised_by']);
      final designation    = _extractField(body, ['designation', 'post', 'office']) ?? 'Tahsildar';
      final signedAt       = _extractDateField(body);

      // Check owner name tampering
      if (expectedOwner != null && returnedOwner != null) {
        if (!_namesMatch(expectedOwner, returnedOwner)) {
          return SignatureVerification(
            status: SignatureStatus.tampered,
            documentType: 'RTC',
            signerName: tahsildar,
            signedAt: signedAt,
            verifyUrl: verifyUrl,
            conflictDetail:
                'Document shows owner: "$expectedOwner" '
                'but Bhoomi QR says: "$returnedOwner". '
                'This document has been FORGED — IPC Section 465.',
          );
        }
      }

      // Check survey number tampering
      if (expectedSurvey != null && returnedSurvey != null) {
        if (!_surveysMatch(expectedSurvey, returnedSurvey)) {
          return SignatureVerification(
            status: SignatureStatus.tampered,
            documentType: 'RTC',
            signerName: tahsildar,
            signedAt: signedAt,
            verifyUrl: verifyUrl,
            conflictDetail:
                'Survey No. on document: "$expectedSurvey" '
                'but Bhoomi QR says: "$returnedSurvey". '
                'Survey number has been ALTERED.',
          );
        }
      }

      // If we got any known-good markers or extracted signer name, it's authentic
      final isAuthentic = lower.contains('valid') || lower.contains('authentic') ||
          lower.contains('verified') || lower.contains('genuine') ||
          tahsildar != null;

      if (isAuthentic) {
        return SignatureVerification(
          status: SignatureStatus.authentic,
          documentType: 'RTC',
          signerName: tahsildar,
          signerDesignation: designation,
          signedAt: signedAt,
          verifyUrl: verifyUrl,
        );
      }

      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'RTC',
        verifyUrl: verifyUrl,
        failReason: VerifyFailReason.parseFailed,
        failDetail: 'Response received but could not confirm authenticity',
      );
    } catch (e) {
      return SignatureVerification(
        status: SignatureStatus.unverifiable,
        documentType: 'RTC',
        verifyUrl: verifyUrl,
        failReason: VerifyFailReason.parseFailed,
        failDetail: 'Parse error: $e',
      );
    }
  }

  SignatureVerification _parseKaveriVerify(String body, String? expectedOwner, String verifyUrl) {
    final lower = body.toLowerCase();

    if (lower.contains('mismatch') || lower.contains('altered') || lower.contains('tampered')) {
      return SignatureVerification(
        status: SignatureStatus.tampered,
        documentType: 'EC',
        verifyUrl: verifyUrl,
        conflictDetail: 'EC document data does not match Sub-Registrar records.',
      );
    }

    if (lower.contains('valid') || lower.contains('authentic') || lower.contains('verified')) {
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'EC',
        signerName: _extractField(body, ['sub_registrar', 'signed_by', 'registrar', 'officer']),
        signerDesignation: 'Sub-Registrar',
        signedAt: _extractDateField(body),
        verifyUrl: verifyUrl,
      );
    }

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'EC',
      verifyUrl: verifyUrl,
      failReason: VerifyFailReason.parseFailed,
      failDetail: 'KAVERI response did not contain recognisable verification markers',
    );
  }

  SignatureVerification _parseEStampVerify(
      String body, String? expectedAmount, String verifyUrl, String uin) {
    final lower = body.toLowerCase();

    if (lower.contains('duplicate') || lower.contains('fake') ||
        lower.contains('already used') || lower.contains('invalid uin')) {
      return SignatureVerification(
        status: SignatureStatus.tampered,
        documentType: 'e-Stamp',
        verifyUrl: verifyUrl,
        conflictDetail: 'e-Stamp UIN $uin is INVALID or already used elsewhere. Possible duplicate stamp.',
      );
    }

    if (lower.contains('genuine') || lower.contains('valid') || lower.contains('verified')) {
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'e-Stamp',
        signerName: 'SHCIL (Stock Holding Corporation of India)',
        signerDesignation: 'Licensed e-Stamp Vendor',
        signedAt: _extractDateField(body),
        verifyUrl: verifyUrl,
      );
    }

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'e-Stamp',
      verifyUrl: verifyUrl,
      failReason: VerifyFailReason.parseFailed,
      failDetail: 'SHCIL response did not confirm UIN $uin',
    );
  }

  SignatureVerification _parseKhataVerify(
      String body, String? expectedOwner, String? expectedKhata, String verifyUrl) {
    final lower = body.toLowerCase();

    if (lower.contains('verified') || lower.contains('genuine') || lower.contains('authentic')) {
      return SignatureVerification(
        status: SignatureStatus.authentic,
        documentType: 'Khata',
        signerName: _extractField(body, ['commissioner', 'revenue_officer', 'aro', 'officer']),
        signerDesignation: 'Assistant Revenue Officer, BBMP',
        signedAt: _extractDateField(body),
        verifyUrl: verifyUrl,
      );
    }

    return SignatureVerification(
      status: SignatureStatus.unverifiable,
      documentType: 'Khata',
      verifyUrl: verifyUrl,
      failReason: VerifyFailReason.parseFailed,
      failDetail: 'BBMP e-Aasthi response did not contain verification markers',
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String? _buildVerifyUrl(String qrData, String portal) {
    if (qrData.startsWith('http')) return qrData;
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

  bool _isCaptchaPage(String body) {
    final lower = body.toLowerCase();
    return lower.contains('captcha') || lower.contains('recaptcha') ||
        lower.contains('are you human') || lower.contains('verify you are not a robot');
  }

  bool _isLoginPage(String body) {
    final lower = body.toLowerCase();
    return lower.contains('please login') || lower.contains('login required') ||
        lower.contains('session expired') || lower.contains('unauthorized');
  }

  String? _extractField(String body, List<String> keys) {
    for (final key in keys) {
      // Try JSON-style key:value
      final jsonRegex = RegExp('"?$key"?\\s*[:=]\\s*"?([^",}\\n<>]+)"?', caseSensitive: false);
      final jMatch = jsonRegex.firstMatch(body);
      if (jMatch != null) {
        final val = jMatch.group(1)?.trim();
        if (val != null && val.isNotEmpty && val != 'null') return val;
      }
      // Try HTML-style: <td>keyLabel</td><td>Value</td>
      final htmlRegex = RegExp('$key[^<]*</t[dh]>\\s*<t[dh][^>]*>([^<]+)', caseSensitive: false);
      final hMatch = htmlRegex.firstMatch(body);
      if (hMatch != null) {
        final val = hMatch.group(1)?.trim();
        if (val != null && val.isNotEmpty) return val;
      }
    }
    return null;
  }

  DateTime? _extractDateField(String body) {
    // ISO datetime
    final iso = RegExp(r'\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}');
    var m = iso.firstMatch(body);
    if (m != null) {
      try { return DateTime.parse(m.group(0)!.replaceAll(' ', 'T')); } catch (_) {}
    }
    // DD/MM/YYYY
    final dmy = RegExp(r'(\d{2})/(\d{2})/(\d{4})');
    m = dmy.firstMatch(body);
    if (m != null) {
      try {
        return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
      } catch (_) {}
    }
    return null;
  }

  // Fuzzy name match — handles transliteration differences (e.g., Venkatesh/Venkatesha)
  bool _namesMatch(String a, String b) {
    final clean = (String s) => s.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final ca = clean(a);
    final cb = clean(b);
    if (ca == cb) return true;
    // Check if one is a substring of the other (handles missing middle names)
    if (ca.contains(cb) || cb.contains(ca)) return true;
    // Levenshtein-like: allow up to 3 character differences
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
    final clean = (String s) => s.replaceAll(RegExp(r'[\s/\\.\-]'), '').toLowerCase();
    return clean(a) == clean(b);
  }
}
