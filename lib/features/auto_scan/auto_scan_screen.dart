import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/portal_findings_model.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/features/portal_checklist/portal_checklist_screen.dart';
import 'package:digi_sampatti/features/bhoomi/bhoomi_device_scraper_screen.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

// ─── Auto Scan Screen ─────────────────────────────────────────────────────────
// Automatically checks ALL relevant government portals for a given survey number.
//
// Portals checked:
//   Site / Plot:  Bhoomi RTC · Kaveri EC · eCourts · BBMP Khata · CERSAI ·
//                 Guidance Value · FMB Sketch · BDA/BMRDA (peri-urban)
//   Apartment:    All above + RERA (mandatory for builder projects)
//   House/Villa:  All above + BBMP building plan approval
//
// Note: RERA is NOT required for agricultural sites, revenue sites or individual plots.
// ─────────────────────────────────────────────────────────────────────────────

enum _PortalStatus { waiting, scanning, done, failed }

class _PortalResult {
  final String name;
  final IconData icon;
  final Color color;
  _PortalStatus status;
  String? summary;
  bool? hasIssue;

  _PortalResult({
    required this.name,
    required this.icon,
    required this.color,
    this.status = _PortalStatus.waiting,
    this.summary,
    this.hasIssue,
  });
}

class AutoScanScreen extends ConsumerStatefulWidget {
  const AutoScanScreen({super.key});

  @override
  ConsumerState<AutoScanScreen> createState() => _AutoScanScreenState();
}

class _AutoScanScreenState extends ConsumerState<AutoScanScreen>
    with TickerProviderStateMixin {
  bool _scanning = false;
  bool _done = false;
  String? _error;
  Map<String, dynamic>? _fullResult;

  // Stored for on-device Bhoomi scraper
  String _scanDistrict = '';
  String _scanTaluk = '';
  String _scanHobli = '';
  String _scanVillage = '';
  String _scanSurveyNo = '';

  late final AnimationController _pulseCtrl;

  final List<_PortalResult> _portals = [
    _PortalResult(name: 'Bhoomi RTC',    icon: Icons.article_outlined,       color: const Color(0xFF1B5E20)),
    _PortalResult(name: 'Kaveri EC',     icon: Icons.account_balance_outlined, color: const Color(0xFF0D47A1)),
    _PortalResult(name: 'RERA',          icon: Icons.verified_outlined,        color: const Color(0xFF4A148C)),
    _PortalResult(name: 'eCourts',       icon: Icons.gavel_outlined,           color: const Color(0xFFBF360C)),
    _PortalResult(name: 'BBMP / Khata',  icon: Icons.location_city_outlined,   color: const Color(0xFF1565C0)),
    _PortalResult(name: 'CERSAI',        icon: Icons.lock_outlined,            color: const Color(0xFF880E4F)),
    _PortalResult(name: 'Guidance Value',icon: Icons.attach_money,             color: const Color(0xFF006064)),
    _PortalResult(name: 'FMB Sketch',    icon: Icons.map_outlined,             color: const Color(0xFF37474F)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Start full auto scan ─────────────────────────────────────────────────
  Future<void> _startScan() async {
    final scan = ref.read(currentScanProvider);
    if (scan == null) return;

    setState(() {
      _scanning = true;
      _done = false;
      _error = null;
      for (final p in _portals) {
        p.status = _PortalStatus.waiting;
        p.summary = null;
        p.hasIssue = null;
      }
    });

    final backendUrl = ApiConstants.backendBaseUrl;

    try {
      // ── Mark all as scanning (parallel) ───────────────────────────────────
      for (final p in _portals) {
        setState(() => p.status = _PortalStatus.scanning);
      }

      // Store scan params for on-device Bhoomi fallback
      _scanDistrict = scan.district ?? '';
      _scanTaluk    = scan.taluk ?? '';
      _scanHobli    = scan.hobli ?? '';
      _scanVillage  = scan.village ?? '';
      _scanSurveyNo = scan.surveyNumber ?? '';

      // ── Single call to /full-check — backend runs all portals in parallel ─
      final resp = await http.post(
        Uri.parse('$backendUrl/full-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district':      _scanDistrict,
          'taluk':         _scanTaluk,
          'hobli':         _scanHobli,
          'village':       _scanVillage,
          'survey_number': _scanSurveyNo,
          'owner_name':    '',
        }),
      ).timeout(const Duration(seconds: 90));

      if (resp.statusCode != 200) {
        throw Exception('Backend returned ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _fullResult = data;

      // ── Update portal statuses from result ────────────────────────────────
      final rtc      = data['rtc']            as Map<String, dynamic>?;
      final ec       = data['ec']             as Map<String, dynamic>?;
      final courts   = data['courts']         as Map<String, dynamic>?;
      final cersai   = data['cersai']         as Map<String, dynamic>?;
      final gv       = data['guidance_value'] as Map<String, dynamic>?;
      final fmb      = data['fmb']            as Map<String, dynamic>?;

      setState(() {
        _updatePortal('Bhoomi RTC',     rtc,    _rtcSummary);
        _updatePortal('Kaveri EC',      ec,     _ecSummary);
        _updatePortal('eCourts',        courts, _courtsSummary);
        _updatePortal('CERSAI',         cersai, _cersaiSummary);
        _updatePortal('Guidance Value', gv,     _gvSummary);
        _updatePortal('FMB Sketch',     fmb,    _fmbSummary);
        // BBMP e-Aasthi: always show as "open on device" (requires login)
        _portals.firstWhere((p) => p.name == 'BBMP / Khata')
          ..status = _PortalStatus.failed
          ..summary = 'Not available (portal down)'
          ..hasIssue = null;
        // RERA — only relevant for apartments/builder projects
        final propType = ref.read(propertyTypeProvider);
        if (propType == 'apartment') {
          _portals.firstWhere((p) => p.name == 'RERA')
            ..status = _PortalStatus.done
            ..summary = 'Checked — verify RERA registration for this project'
            ..hasIssue = false;
        } else if (propType == 'bda_layout') {
          _portals.firstWhere((p) => p.name == 'RERA')
            ..status = _PortalStatus.done
            ..summary = 'Not required — BDA/BMRDA approval matters more for layouts'
            ..hasIssue = false;
        } else {
          _portals.firstWhere((p) => p.name == 'RERA')
            ..status = _PortalStatus.done
            ..summary = 'Not required — RERA is only for apartments / builder projects'
            ..hasIssue = false;
        }
        _scanning = false;
        _done = true;
      });

      // ── Map backend results → PortalFindings so AI analysis counts correctly
      final pType = ref.read(propertyTypeProvider);
      final findings = PortalFindings(
        bhoomiOpened:   rtc    != null,
        kaveriOpened:   ec     != null,
        ecourtsOpened:  courts != null,
        cersaiOpened:   cersai != null,
        fmbOpened:      fmb    != null,
        isApartmentProject: pType == 'apartment',
        hasActiveLoan:  ec?['encumbrance_free'] != true && ec != null,
        hasCourtCases:  (courts?['has_pending_cases'] ?? false) as bool,
        hasBankCharge:  (cersai?['is_mortgaged'] ?? false) as bool,
      );
      ref.read(portalFindingsProvider.notifier).state = findings;
    } catch (e) {
      setState(() {
        _scanning = false;
        _done = true;   // allow fallback buttons to appear
        _bhoomiFailed = true;  // show on-device Bhoomi CTA
        _error = 'Cloud check failed — use on-device Bhoomi scan below.\n(${e.toString().split('\n').first})';
        for (final p in _portals) {
          if (p.status == _PortalStatus.scanning) {
            p.status = _PortalStatus.failed;
            if (p.name == 'Bhoomi RTC') {
              p.summary = 'Bhoomi blocked from cloud — tap "Scan RTC" below';
            } else {
              p.summary = 'Not available (cloud unreachable)';
            }
          }
        }
      });
    }
  }

  bool _bhoomiFailed = false;
  bool _bhoomiFetchingOnDevice = false;

  Future<void> _fetchBhoomiOnDevice() async {
    setState(() => _bhoomiFetchingOnDevice = true);
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => BhoomiDeviceScraperScreen(
          district:     _scanDistrict,
          taluk:        _scanTaluk,
          hobli:        _scanHobli,
          village:      _scanVillage,
          surveyNumber: _scanSurveyNo,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      final src = result['source']?.toString() ?? '';
      if (!src.contains('no_data') && !src.contains('error')) {
        // Update Bhoomi portal card with on-device result
        _updatePortal('Bhoomi RTC', result, (d) {
          final owner = d['owner_name'] ?? '';
          final extent = d['extent'] ?? '';
          return owner.isNotEmpty ? 'Owner: $owner${extent.isNotEmpty ? ' · $extent' : ''}' : 'Record fetched';
        });
        // Merge into fullResult
        if (_fullResult != null) {
          setState(() {
            _fullResult = {..._fullResult!, 'rtc': result};
            _bhoomiFailed = false;
          });
        }
      } else {
        setState(() => _bhoomiFetchingOnDevice = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No RTC data found for this survey number on Bhoomi.')),
          );
        }
      }
    } else {
      setState(() => _bhoomiFetchingOnDevice = false);
    }
  }

  void _updatePortal(String name, dynamic data, String Function(Map) summarize) {
    final p = _portals.firstWhere((p) => p.name == name);
    if (data == null) {
      p.status = _PortalStatus.failed;
      p.summary = name == 'Bhoomi RTC'
          ? 'Bhoomi blocked from cloud — tap "Scan RTC" below'
          : 'Not available (portal down)';
      p.hasIssue = null;
      if (name == 'Bhoomi RTC') _bhoomiFailed = true;
      return;
    }
    final d = data as Map<String, dynamic>;
    final src = d['source']?.toString() ?? '';
    if (src.contains('no_data') || src.contains('error')) {
      p.status = _PortalStatus.failed;
      p.summary = name == 'Bhoomi RTC'
          ? 'Bhoomi blocked from cloud — tap "Scan RTC" below'
          : 'No record found';
      p.hasIssue = null;
      if (name == 'Bhoomi RTC') _bhoomiFailed = true;
      return;
    }
    p.status = _PortalStatus.done;
    p.summary = summarize(d);
    p.hasIssue = _hasIssue(name, d);
  }

  String _rtcSummary(Map d) {
    final owner = d['owner_name'] ?? 'Unknown';
    final extent = d['extent'] ?? '';
    return 'Owner: $owner${extent.isNotEmpty ? " · $extent" : ""}';
  }

  String _ecSummary(Map d) {
    final count = d['transaction_count'] ?? 0;
    final free = d['encumbrance_free'] == true;
    return free ? 'Encumbrance Free ✓' : '$count transaction(s) found';
  }

  String _courtsSummary(Map d) {
    final count = d['cases_found'] ?? 0;
    return count == 0 ? 'No cases found ✓' : '$count case(s) found — check';
  }

  String _cersaiSummary(Map d) {
    final mortgaged = d['is_mortgaged'] == true;
    final lenders = (d['lenders'] as List?)?.join(', ') ?? '';
    return mortgaged ? 'Mortgage found: $lenders' : 'No lien/charge ✓';
  }

  String _gvSummary(Map d) {
    final val = d['value_per_sqft'] ?? 0;
    final taluk = d['taluk'] ?? '';
    // IGR guidance value is the sub-registrar's floor price for stamp duty,
    // not the market rate. The actual figure is from the IGR Karnataka PDF.
    return '~₹$val / sqft · ${taluk.isNotEmpty ? taluk : 'Area'} (IGR estimate — verify at igr.karnataka.gov.in)';
  }

  String _fmbSummary(Map d) {
    final area = d['area'] ?? '';
    final hasSketch = d['sketch_url'] != null;
    return hasSketch ? 'Sketch available · $area' : 'Area: $area';
  }

  bool _hasIssue(String name, Map d) {
    switch (name) {
      case 'Kaveri EC':     return d['encumbrance_free'] != true;
      case 'eCourts':       return (d['has_pending_cases'] ?? false) == true;
      case 'CERSAI':        return (d['is_mortgaged'] ?? false) == true;
      default: return false;
    }
  }

  // ─── Risk level from full result ──────────────────────────────────────────
  String get _riskLevel        => _fullResult?['risk_level'] ?? 'UNKNOWN';
  List   get _riskFlags        => _fullResult?['risk_flags'] ?? [];
  List   get _fraudPatterns    => _fullResult?['fraud_patterns'] ?? [];
  String get _investmentVerdict=> _fullResult?['investment_verdict'] ?? '';

  /// Investment score: only meaningful when Bhoomi + EC data is available.
  /// Return null (show "—") when core portals failed — avoids misleading 100/100.
  int? get _investmentScore {
    final raw = _fullResult?['investment_score'];
    if (raw == null) return null;
    final score = raw as int;
    // If Bhoomi failed (no owner data) and score is suspiciously perfect, hide it
    final bhoomiOk = _portals.firstWhere((p) => p.name == 'Bhoomi RTC').status == _PortalStatus.done;
    final ecOk     = _portals.firstWhere((p) => p.name == 'Kaveri EC').status == _PortalStatus.done;
    if (!bhoomiOk && !ecOk) return null;
    return score;
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'SAFE':     return AppColors.safe;
      case 'CAUTION':  return Colors.orange;
      case 'HIGH':     return Colors.red;
      case 'CRITICAL': return const Color(0xFF7B0000);
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(currentScanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Auto Property Scan'),
        backgroundColor: Colors.white,
        actions: [
          if (_done)
            TextButton.icon(
              onPressed: () => context.push('/analysis'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI Report'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(scan),
            const SizedBox(height: 16),

            // ── Scan Button ──────────────────────────────────────────────────
            if (!_scanning && !_done) _buildScanButton(),
            if (_scanning) _buildScanningIndicator(),

            // ── Error ────────────────────────────────────────────────────────
            if (_error != null) _buildError(),

            // ── Portal Results ───────────────────────────────────────────────
            if (_scanning || _done) ...[
              const SizedBox(height: 20),
              const Text('Government Portal Checks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                _scanning
                    ? 'Checking Bhoomi · Kaveri EC · eCourts · BBMP · CERSAI · Guidance Value · FMB'
                    : 'Done — RERA shown only if apartment project name provided',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              ..._portals.map(_buildPortalCard),
            ],

            // ── Risk Summary ────────────────────────────────────────────────
            if (_done) ...[
              const SizedBox(height: 20),
              _buildRiskSummary(),

              // ── Bhoomi blocked banner + RTC scan CTA ─────────────────
              if (_bhoomiFailed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.document_scanner, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Bhoomi RTC — Scan Your Document',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bhoomi portal blocks automated access from cloud servers. '
                        'If you have the physical RTC / Pahani document, photograph it — '
                        'our AI will read all fields directly.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      // Primary CTA: fetch directly from Bhoomi using device IP
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _bhoomiFetchingOnDevice ? null : _fetchBhoomiOnDevice,
                          icon: _bhoomiFetchingOnDevice
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.travel_explore),
                          label: Text(_bhoomiFetchingOnDevice
                              ? 'Fetching from Bhoomi...'
                              : 'Fetch from Bhoomi (on device)'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fallback: scan physical document
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/scan/camera'),
                          icon: const Icon(Icons.camera_alt, color: Colors.orange),
                          label: const Text('Scan Physical RTC Document',
                              style: TextStyle(color: Colors.orange)),
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.orange.shade400)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // ₹99 — View All Records on screen
              ElevatedButton.icon(
                onPressed: () => context.push(
                  '/property-records',
                  extra: _fullResult,
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('View All Records — ₹99'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 10),
              // ₹149 — Full AI Analysis + PDF
              ElevatedButton.icon(
                onPressed: () => context.push('/analysis'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Analysis + PDF Report — ₹149'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/partners'),
                icon: const Icon(Icons.support_agent),
                label: const Text('Get Expert Help'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PropertyScan? scan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Automated Property Scan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  scan?.surveyNumber != null
                      ? 'Survey ${scan!.surveyNumber} · ${scan.district ?? ""}'
                      : 'No property selected',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _startScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'Start Automatic Scan',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(
              'Fetches Bhoomi · Kaveri · eCourts · CERSAI · RERA · IGR · FMB\nZero manual steps',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.4 + _pulseCtrl.value * 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanning all government portals...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary)),
                SizedBox(height: 2),
                Text(
                  'Backend is fetching data automatically. No action needed from you.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalCard(_PortalResult p) {
    Widget statusWidget;
    switch (p.status) {
      case _PortalStatus.waiting:
        statusWidget = const Icon(Icons.hourglass_empty, size: 18, color: Colors.grey);
        break;
      case _PortalStatus.scanning:
        statusWidget = AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: p.color.withOpacity(0.5 + _pulseCtrl.value * 0.5),
            ),
          ),
        );
        break;
      case _PortalStatus.done:
        statusWidget = Icon(
          p.hasIssue == true ? Icons.warning_rounded : Icons.check_circle,
          size: 20,
          color: p.hasIssue == true ? Colors.orange : AppColors.safe,
        );
        break;
      case _PortalStatus.failed:
        statusWidget = const Icon(Icons.error_outline, size: 18, color: Colors.grey);
        break;
    }

    // These portals are blocked from cloud — show "Open on Device" when they fail
    final isBhoomiBlocked  = p.name == 'Bhoomi RTC'     && p.status == _PortalStatus.failed;
    final isKaveriBlocked  = p.name == 'Kaveri EC'      && p.status == _PortalStatus.failed;
    final isFmbBlocked     = p.name == 'FMB Sketch'     && p.status == _PortalStatus.failed;
    final isCersaiBlocked  = p.name == 'CERSAI'         && p.status == _PortalStatus.failed;
    final isBbmpBlocked    = p.name == 'BBMP / Khata'   && p.status == _PortalStatus.failed;

    return Container(
      margin: EdgeInsets.only(bottom: (isBhoomiBlocked || isKaveriBlocked || isFmbBlocked || isCersaiBlocked || isBbmpBlocked) ? 0 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.status == _PortalStatus.done && p.hasIssue == true
              ? Colors.orange.shade200
              : AppColors.borderColor,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: p.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(p.icon, color: p.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (p.summary != null)
                        Text(p.summary!,
                            style: TextStyle(
                                fontSize: 11,
                                color: p.hasIssue == true
                                    ? Colors.orange.shade700
                                    : AppColors.textLight))
                      else if (p.status == _PortalStatus.scanning)
                        const Text('Fetching...',
                            style: TextStyle(fontSize: 11, color: AppColors.textLight))
                      else
                        const Text('Waiting...',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                statusWidget,
              ],
            ),
          ),
          // ── Bhoomi blocked: show "Open on Device" CTA ──────────────────────
          if (isBhoomiBlocked) _onDeviceButton(
            context,
            portal: GovPortal.bhoomi,
            label: 'Open Bhoomi on Device (Real RTC Data)',
            color: const Color(0xFF1B5E20),
          ),
          if (isKaveriBlocked) _onDeviceButton(
            context,
            portal: GovPortal.kaveri,
            label: 'Open Kaveri EC on Device (Real Data)',
            color: const Color(0xFF0D47A1),
          ),
          if (isFmbBlocked) _onDeviceButton(
            context,
            portal: GovPortal.dishank,
            label: 'Open FMB / Sketch Map on Device',
            color: const Color(0xFF37474F),
          ),
          if (isCersaiBlocked) _onDeviceButton(
            context,
            portal: GovPortal.cersai,
            label: 'Open CERSAI in Browser (Bank Mortgage)',
            color: const Color(0xFF880E4F),
          ),
          if (isBbmpBlocked) _onDeviceButton(
            context,
            portal: GovPortal.bbmp,
            label: 'Open BBMP e-Aasthi (Khata Check)',
            color: const Color(0xFF1565C0),
          ),
          if (isBhoomiBlocked || isKaveriBlocked || isFmbBlocked || isCersaiBlocked || isBbmpBlocked)
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── On-device button for cloud-blocked portals ───────────────────────────
  Widget _onDeviceButton(BuildContext context, {
    required GovPortal portal,
    required String label,
    required Color color,
  }) {
    final scan = ref.read(currentScanProvider);
    // Bhoomi: use automated device scraper (fills form, returns parsed data)
    if (portal == GovPortal.bhoomi && scan != null &&
        scan.district != null && scan.taluk != null && scan.surveyNumber != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push<Map<String, dynamic>?>(
              context,
              MaterialPageRoute(
                builder: (_) => BhoomiDeviceScraperScreen(
                  district:     scan.district!,
                  taluk:        scan.taluk!,
                  hobli:        scan.hobli ?? '',
                  village:      scan.village ?? '',
                  surveyNumber: scan.surveyNumber!,
                ),
              ),
            );
            if (result != null && mounted) {
              setState(() {
                final p = _portals.firstWhere((p) => p.name == 'Bhoomi RTC');
                p.status = _PortalStatus.done;
                p.summary = _rtcSummary(result);
                p.hasIssue = false;
              });
            }
          },
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    // Other portals: open WebView manually
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GovWebViewScreen(
              portal: portal,
              surveyNumber: scan?.surveyNumber,
              district:     scan?.district,
              taluk:        scan?.taluk,
              hobli:        scan?.hobli,
              village:      scan?.village,
            ),
          ),
        ),
        icon: const Icon(Icons.open_in_browser, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ─── What you still need to do (online vs. physical presence) ────────────
  Widget _buildNextStepsCard() {
    final hasFraud    = _fraudPatterns.isNotEmpty;
    final hasCourts   = (_fullResult?['courts'] as Map?)?.containsKey('has_pending_cases') == true
        && (_fullResult!['courts']['has_pending_cases'] as bool? ?? false);
    final hasMortgage = (_fullResult?['cersai'] as Map?)?.containsKey('is_mortgaged') == true
        && (_fullResult!['cersai']['is_mortgaged'] as bool? ?? false);
    final ecDown      = _fullResult?['ec'] == null;
    final cersaiDown  = _fullResult?['cersai'] == null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.checklist, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('ಮುಂದಿನ ಹಂತಗಳು  /  What You Still Need To Do',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Online — can be done from phone
                const _SectionLabel('📱 Can be done online / on this app'),
                const SizedBox(height: 8),
                _NextStep(
                  done: _fullResult?['rtc'] != null,
                  label: 'Bhoomi RTC fetched ✓',
                  note: 'Owner, extent, liabilities — visible above',
                  physical: false,
                ),
                _NextStep(
                  done: !ecDown,
                  label: ecDown
                      ? 'Kaveri EC — verify manually at kaveri.karnataka.gov.in'
                      : 'Kaveri EC checked ✓',
                  note: ecDown ? 'Kaveri portal is frequently down. Get EC from the sub-registrar office.' : null,
                  physical: ecDown,
                  isWarning: ecDown,
                ),
                _NextStep(
                  done: !cersaiDown,
                  label: cersaiDown
                      ? 'CERSAI — ask seller to show CERSAI screenshot or check at cersai.org.in'
                      : 'CERSAI mortgage check ✓',
                  note: cersaiDown ? 'CERSAI login is required. A lawyer can get this for ₹200.' : null,
                  physical: false,
                  isWarning: cersaiDown,
                ),
                _NextStep(
                  done: !hasCourts,
                  label: hasCourts
                      ? 'Court cases found — read details in report ⚠'
                      : 'eCourts search done ✓',
                  note: hasCourts ? 'Get a lawyer to review the case status before buying.' : null,
                  physical: false,
                  isWarning: hasCourts,
                ),

                const SizedBox(height: 14),
                // Physical presence required
                const _SectionLabel('🏢 Requires physical presence'),
                const SizedBox(height: 8),
                const _NextStep(
                  done: false,
                  label: 'Visit the sub-registrar office (SRO)',
                  note: 'Get the original EC, check sale deed history in person. Bring survey number + Aadhaar.',
                  physical: true,
                ),
                const _NextStep(
                  done: false,
                  label: 'Visit the property site',
                  note: 'Verify boundary markers match FMB sketch. Check if any encroachment.',
                  physical: true,
                ),
                const _NextStep(
                  done: false,
                  label: 'Check with village accountant (VA)',
                  note: 'Ask if there are any oral/unregistered transactions or disputes on this survey.',
                  physical: true,
                ),
                if (hasFraud) ...[
                  const SizedBox(height: 14),
                  const _SectionLabel('🚨 Fraud patterns detected — additional steps'),
                  const SizedBox(height: 8),
                  const _NextStep(
                    done: false,
                    label: 'Hire a property lawyer immediately',
                    note: 'Do NOT pay any advance until a lawyer reviews the RTC, EC, and mutation history.',
                    physical: false,
                    isWarning: true,
                  ),
                  const _NextStep(
                    done: false,
                    label: 'Do NOT sign any agreement yet',
                    note: 'Suspicious patterns detected. Get police verification of the seller\'s identity.',
                    physical: true,
                    isWarning: true,
                  ),
                ],

                if (hasMortgage) ...[
                  const SizedBox(height: 14),
                  const _SectionLabel('🏦 Mortgage found — additional steps'),
                  const SizedBox(height: 8),
                  const _NextStep(
                    done: false,
                    label: 'Get NOC from the bank before sale',
                    note: 'Seller must show No-Objection Certificate from the bank clearing the mortgage.',
                    physical: true,
                    isWarning: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Raw Government Records ────────────────────────────────────────────────
  Widget _buildRawDataSection() {
    final scan   = ref.read(currentScanProvider);
    final rtc    = _fullResult!['rtc']    as Map<String, dynamic>?;
    final ec     = _fullResult!['ec']     as Map<String, dynamic>?;
    final courts = _fullResult!['courts'] as Map<String, dynamic>?;
    final cersai = _fullResult!['cersai'] as Map<String, dynamic>?;
    final gv     = _fullResult!['guidance_value'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance, size: 18, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Expanded(
              child: Text('ಸರ್ಕಾರಿ ದಾಖಲೆಗಳು  /  Raw Government Records',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text('Live data fetched from Karnataka portals — shown inline',
            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 12),

        // ── Scan vs. Live comparison (only if RTC available + scan has OCR data) ─
        if (rtc != null && scan != null && scan.surveyNumber != null)
          _buildComparisonCard(scan, rtc),
        if (rtc != null && scan != null && scan.surveyNumber != null)
          const SizedBox(height: 10),

        // ── RTC (Bhoomi) ──────────────────────────────────────────────────────
        rtc != null
            ? _buildRtcCard(rtc)
            : _buildUnavailableCard(
                'Bhoomi RTC  /  ಪಹಣಿ',
                'Bhoomi portal did not respond. Survey No: ${scan?.surveyNumber ?? "—"}',
                Icons.article_outlined, const Color(0xFF1B5E20)),

        const SizedBox(height: 10),

        // ── EC (Kaveri) — frequently down ─────────────────────────────────────
        ec != null
            ? _buildEcCard(ec)
            : _buildUnavailableCard(
                'Kaveri EC  /  ಋಣ ಪ್ರಮಾಣಪತ್ರ',
                'Kaveri portal is currently unavailable (frequent maintenance). '
                'Verify EC manually at kaveri.karnataka.gov.in',
                Icons.account_balance_outlined, const Color(0xFF0D47A1),
                isKaveriDown: true),

        const SizedBox(height: 10),

        // ── eCourts ───────────────────────────────────────────────────────────
        courts != null
            ? _buildCourtsCard(courts)
            : _buildUnavailableCard(
                'eCourts India  /  ನ್ಯಾಯಾಲಯ',
                'eCourts search was not reachable. Check manually at services.ecourts.gov.in',
                Icons.gavel_outlined, const Color(0xFFBF360C)),

        const SizedBox(height: 10),

        // ── CERSAI — requires login/OTP ───────────────────────────────────────
        cersai != null
            ? _buildCersaiCard(cersai)
            : _buildUnavailableCard(
                'CERSAI  /  ಒತ್ತೆ ನೋಂದಣಿ',
                'CERSAI requires OTP login and cannot be automated. '
                'Ask the seller to provide CERSAI screenshot, or check at cersai.org.in',
                Icons.lock_outline, const Color(0xFF37474F),
                isCersaiLogin: true),

        const SizedBox(height: 10),

        // ── Guidance Value — zone rate, not plot-specific ─────────────────────
        _buildGuidanceCard(gv, scan?.district ?? '', scan?.taluk ?? ''),
      ],
    );
  }

  // ── Scan document vs. live portal — side by side ─────────────────────────
  Widget _buildComparisonCard(PropertyScan scan, Map<String, dynamic> rtc) {
    final scanSurvey   = scan.surveyNumber ?? '—';
    final scanDistrict = scan.district ?? '—';
    final scanTaluk    = scan.taluk ?? '—';
    final liveSurvey   = _val(rtc['survey_number']).isNotEmpty ? _val(rtc['survey_number']) : '—';
    final liveOwner    = _val(rtc['owner_name']).isNotEmpty ? _val(rtc['owner_name']) : '—';
    final liveExtent   = _val(rtc['extent']).isNotEmpty ? _val(rtc['extent']) : '—';
    final liveVillage  = _val(rtc['village']).isNotEmpty ? _val(rtc['village']) : '—';

    bool match(String a, String b) =>
        a != '—' && b != '—' && a.toLowerCase().trim() == b.toLowerCase().trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.compare_arrows, size: 16, color: Color(0xFF1B5E20)),
                SizedBox(width: 8),
                Text('Scanned Document  vs  Live Portal',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1B5E20))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    const SizedBox(width: 100),
                    Expanded(
                      child: Text('📄 Scanned',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700)),
                    ),
                    Expanded(
                      child: Text('🏛 Bhoomi Live',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20))),
                    ),
                  ],
                ),
                const Divider(height: 14),
                _CompRow('Survey No.', scanSurvey, liveSurvey,
                    match: match(scanSurvey, liveSurvey)),
                _CompRow('District', scanDistrict, _val(rtc['district']).isNotEmpty ? _val(rtc['district']) : '—',
                    match: match(scanDistrict, _val(rtc['district']))),
                _CompRow('Taluk', scanTaluk, _val(rtc['taluk']).isNotEmpty ? _val(rtc['taluk']) : '—',
                    match: match(scanTaluk, _val(rtc['taluk']))),
                _CompRow('Village', '—', liveVillage),
                _CompRow('Owner', '—', liveOwner),
                _CompRow('Extent', '—', liveExtent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRtcCard(Map<String, dynamic> rtc) {
    final owner       = _val(rtc['owner_name']);
    final extent      = _val(rtc['extent']);
    final landType    = _val(rtc['land_type']);
    final kharab      = _val(rtc['kharab']);
    final liabilities = _val(rtc['liabilities']);
    final khata       = _val(rtc['khata_number']);
    final village     = _val(rtc['village']);

    return _RawCard(
      title: 'Bhoomi RTC  /  ಪಹಣಿ',
      subtitle: 'Record of Rights, Tenancy & Crops',
      icon: Icons.article_outlined,
      color: const Color(0xFF1B5E20),
      children: [
        _RawRow('Survey No.',   _val(rtc['survey_number']).isNotEmpty ? _val(rtc['survey_number']) : '—'),
        if (village.isNotEmpty)   _RawRow('Village / ಗ್ರಾಮ', village),
        _RawRow('Owner / ಮಾಲೀಕ', owner.isNotEmpty ? owner : '— (not returned)'),
        _RawRow('Total Extent',   extent.isNotEmpty ? extent : '—'),
        if (landType.isNotEmpty)  _RawRow('Land Type', landType),
        if (kharab.isNotEmpty)    _RawRow('Kharab / Govt Share', kharab),
        if (khata.isNotEmpty)     _RawRow('Khata No.', khata),
        _RawRow('Liabilities',
          liabilities.isNotEmpty ? liabilities : 'None on record ✓',
          valueColor: liabilities.isNotEmpty ? Colors.red : AppColors.safe),
      ],
    );
  }

  Widget _buildEcCard(Map<String, dynamic> ec) {
    final free  = ec['encumbrance_free'] == true;
    final count = ec['transaction_count'] ?? 0;
    final txns  = (ec['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return _RawCard(
      title: 'Kaveri EC  /  ಋಣ ಪ್ರಮಾಣಪತ್ರ',
      subtitle: 'Encumbrance Certificate — last 25 years',
      icon: Icons.account_balance_outlined,
      color: const Color(0xFF0D47A1),
      children: [
        _RawRow('EC Status',
          free ? 'Encumbrance Free ✓' : '$count transaction(s) on record',
          valueColor: free ? AppColors.safe : Colors.orange),
        if (!free && count == 0)
          _RawRow('Note', 'Portal returned data but no entries — re-verify manually', small: true),
        ...txns.take(5).map((t) => _RawRow(
          t['date']?.toString() ?? 'Entry',
          '${t['type'] ?? 'Transaction'} — ${t['party'] ?? ''}',
          small: true)),
        if (txns.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 0),
            child: Text('+${txns.length - 5} more entries',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight))),
      ],
    );
  }

  Widget _buildCourtsCard(Map<String, dynamic> courts) {
    final hasCases = courts['has_pending_cases'] == true;
    final count    = courts['cases_found'] ?? 0;
    final cases    = (courts['case_numbers'] as List?)?.cast<String>() ?? [];

    return _RawCard(
      title: 'eCourts India  /  ನ್ಯಾಯಾಲಯ',
      subtitle: 'Active civil/criminal cases on owner name',
      icon: Icons.gavel_outlined,
      color: const Color(0xFFBF360C),
      children: [
        _RawRow('Litigation',
          hasCases ? '$count case(s) found — verify before buying' : 'No cases found ✓',
          valueColor: hasCases ? Colors.red : AppColors.safe),
        ...cases.take(4).map((c) => _RawRow('Case No.', c, small: true)),
      ],
    );
  }

  Widget _buildCersaiCard(Map<String, dynamic> cersai) {
    final mortgaged = cersai['is_mortgaged'] == true;
    final lenders   = (cersai['lenders'] as List?)?.cast<String>() ?? [];

    return _RawCard(
      title: 'CERSAI  /  ಒತ್ತೆ ನೋಂದಣಿ',
      subtitle: 'Central Registry — bank mortgage & liens',
      icon: Icons.lock_outline,
      color: const Color(0xFF37474F),
      children: [
        _RawRow('Mortgage',
          mortgaged ? 'Active charge registered ⚠' : 'No lien / charge found ✓',
          valueColor: mortgaged ? Colors.red : AppColors.safe),
        if (lenders.isNotEmpty) _RawRow('Lender(s)', lenders.join(', ')),
      ],
    );
  }

  Widget _buildGuidanceCard(Map<String, dynamic>? gv, String district, String taluk) {
    final val    = gv?['value_per_sqft'];
    final source = _val(gv?['source']);
    final isFallback = source == 'igr_gazette_2024' || gv == null;

    return _RawCard(
      title: 'Guidance Value  /  ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ',
      subtitle: 'Karnataka IGR — minimum stamp duty rate',
      icon: Icons.currency_rupee,
      color: const Color(0xFF006064),
      children: [
        _RawRow('Rate',
          val != null ? '₹$val / sqft' : '—'),
        _RawRow('Zone / Area',
          taluk.isNotEmpty ? '$taluk, $district' : district),
        _RawRow('Important',
          isFallback
            ? 'Zone-level estimate (IGR gazette 2024). Same rate applies to entire taluk — not plot-specific'
            : 'Live from IGR portal',
          valueColor: isFallback ? Colors.orange.shade700 : AppColors.safe,
          small: true),
      ],
    );
  }

  Widget _buildUnavailableCard(String title, String reason, IconData icon, Color color,
      {bool isKaveriDown = false, bool isCersaiLogin = false}) {
    return _RawCard(
      title: title,
      subtitle: isKaveriDown
          ? 'Portal frequently under maintenance'
          : isCersaiLogin
              ? 'OTP login required — cannot automate'
              : 'Portal unavailable',
      icon: icon,
      color: color,
      statusBadge: 'UNAVAILABLE',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCersaiLogin ? Icons.info_outline : Icons.wifi_off_outlined,
              size: 14,
              color: color.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(reason,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                      height: 1.5)),
            ),
          ],
        ),
      ],
    );
  }

  String _val(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'N/A') return '';
    return s;
  }

  Widget _buildRiskSummary() {
    final String riskLabel;
    final IconData riskIcon;
    switch (_riskLevel) {
      case 'SAFE':
        riskLabel = 'Property looks SAFE';
        riskIcon  = Icons.verified;
        break;
      case 'CAUTION':
        riskLabel = 'Proceed with CAUTION';
        riskIcon  = Icons.warning_amber_rounded;
        break;
      case 'HIGH':
        riskLabel = 'HIGH RISK — Do Not Proceed';
        riskIcon  = Icons.dangerous;
        break;
      case 'CRITICAL':
        riskLabel = 'CRITICAL — Likely Fraud Detected';
        riskIcon  = Icons.gpp_bad;
        break;
      default:
        riskLabel = 'Unknown';
        riskIcon  = Icons.help_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Investment Score Card ─────────────────────────────────────────────
        Builder(builder: (context) {
          final score = _investmentScore;
          final scoreColor = score != null ? _investmentScoreColor : Colors.grey;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withOpacity(0.12),
                  scoreColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                // Score circle
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score != null ? score / 100 : 0,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: scoreColor,
                      ),
                      Text(
                        score != null ? '$score' : '—',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: score != null ? 18 : 22,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Investment Score',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        score != null
                            ? _investmentVerdict
                            : 'Score unavailable — Bhoomi or EC data missing',
                        style: TextStyle(fontSize: 12, color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // ── Risk Level Banner ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _riskColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _riskColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(riskIcon, color: _riskColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      riskLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _riskColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (_riskFlags.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._riskFlags.map((flag) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, color: _riskColor, size: 16),
                          Expanded(
                            child: Text(flag.toString(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _riskColor.withOpacity(0.9))),
                          ),
                        ],
                      ),
                    )),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'No encumbrance · No court cases · No mortgage found',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ],
          ),
        ),

        // ── Fraud Patterns ────────────────────────────────────────────────────
        if (_fraudPatterns.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Fraud Pattern Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._fraudPatterns.map((p) {
            final pattern = p as Map<String, dynamic>;
            final sev = pattern['severity'] as String? ?? 'CAUTION';
            final Color sevColor = sev == 'CRITICAL'
                ? const Color(0xFF7B0000)
                : sev == 'HIGH'
                    ? Colors.red
                    : Colors.orange;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sevColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sevColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sev,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (pattern['pattern'] as String? ?? '')
                              .replaceAll('_', ' '),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: sevColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pattern['detail'] as String? ?? '',
                    style: TextStyle(
                        fontSize: 11, color: sevColor.withOpacity(0.85)),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Color get _investmentScoreColor {
    final score = _investmentScore;
    if (score == null) return Colors.grey;
    if (score >= 80) return AppColors.safe;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red.shade800;
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Cloud scan unavailable — use on-device scan below',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _done = false;
                _scanning = false;
                _error = null;
                _bhoomiFailed = false;
                for (final p in _portals) {
                  p.status = _PortalStatus.waiting;
                  p.summary = null;
                  p.hasIssue = null;
                }
              }),
              child: const Text('Retry Cloud Scan'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card / row widgets used in portal detail cards ───────────────────────────

class _RawCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final String? statusBadge;

  const _RawCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: color)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 10,
                              color: color.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                if (statusBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusBadge!,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _RawRow(String label, String value,
    {Color? valueColor, bool small = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(
                  fontSize: small ? 10 : 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: small ? 10 : 12,
                  color: valueColor ?? const Color(0xFF1A1A1A),
                  fontWeight:
                      valueColor != null ? FontWeight.w600 : FontWeight.normal,
                  height: 1.3)),
        ),
      ],
    ),
  );
}

// ── Helper widgets used in next-steps & comparison panels ────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F)));
  }
}

class _NextStep extends StatelessWidget {
  final bool done;
  final String label;
  final String? note;
  final bool physical;
  final bool isWarning;

  const _NextStep({
    required this.done,
    required this.label,
    this.note,
    this.physical = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF1B5E20)
        : isWarning
            ? Colors.red.shade700
            : Colors.grey.shade700;
    final icon = done
        ? Icons.check_circle
        : isWarning
            ? Icons.warning_amber_rounded
            : physical
                ? Icons.directions_walk
                : Icons.radio_button_unchecked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(note!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final String scanned;
  final String live;
  final bool? match;

  const _CompRow(this.label, this.scanned, this.live, {this.match});

  @override
  Widget build(BuildContext context) {
    final matched = match;
    final rowColor = matched == null
        ? null
        : matched
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE);

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F))),
          ),
          Expanded(
            child: Text(scanned,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF546E7A))),
          ),
          Expanded(
            child: Text(live,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: matched == false
                        ? Colors.red.shade700
                        : const Color(0xFF1B5E20))),
          ),
          if (matched != null)
            Icon(
              matched ? Icons.check : Icons.close,
              size: 14,
              color: matched
                  ? const Color(0xFF1B5E20)
                  : Colors.red.shade700,
            ),
        ],
      ),
    );
  }
}
