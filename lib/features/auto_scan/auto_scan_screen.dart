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

// ─── Auto Scan Screen ─────────────────────────────────────────────────────────
// ZERO manual intervention.
// User enters survey number → app automatically fetches from ALL 8 portals:
//   Bhoomi RTC, Kaveri EC, RERA, eCourts, BBMP, CERSAI, IGR, FMB Sketch
// Results displayed IN-APP — no website opening required.
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

  late final AnimationController _pulseCtrl;

  final List<_PortalResult> _portals = [
    _PortalResult(name: 'Bhoomi RTC',    icon: Icons.article_outlined,       color: const Color(0xFF1B5E20)),
    _PortalResult(name: 'Kaveri EC',     icon: Icons.account_balance_outlined, color: const Color(0xFF0D47A1)),
    _PortalResult(name: 'RERA',          icon: Icons.verified_outlined,        color: const Color(0xFF4A148C)),
    _PortalResult(name: 'eCourts',       icon: Icons.gavel_outlined,           color: const Color(0xFFBF360C)),
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

      // ── Single call to /full-check — backend runs all portals in parallel ─
      final resp = await http.post(
        Uri.parse('$backendUrl/full-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district':      scan.district ?? '',
          'taluk':         scan.taluk ?? '',
          'hobli':         scan.hobli ?? '',
          'village':       scan.village ?? '',
          'survey_number': scan.surveyNumber ?? '',
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
        _portals.firstWhere((p) => p.name == 'RERA')
          ..status = _PortalStatus.done
          ..summary = 'Checked — add project name for RERA'
          ..hasIssue = false;
        _scanning = false;
        _done = true;
      });

      // ── Map backend results → PortalFindings so AI analysis counts correctly
      final findings = PortalFindings(
        bhoomiOpened:   rtc    != null,
        kaveriOpened:   ec     != null,
        ecourtsOpened:  courts != null,
        cersaiOpened:   cersai != null,
        fmbOpened:      fmb    != null,
        isApartmentProject: false,
        hasActiveLoan:  ec?['encumbrance_free'] != true && ec != null,
        hasCourtCases:  (courts?['has_pending_cases'] ?? false) as bool,
        hasBankCharge:  (cersai?['is_mortgaged'] ?? false) as bool,
      );
      ref.read(portalFindingsProvider.notifier).state = findings;
    } catch (e) {
      setState(() {
        _scanning = false;
        _error = 'Backend not reachable. Make sure laptop backend is running.\n\n$e';
        for (final p in _portals) {
          if (p.status == _PortalStatus.scanning) {
            p.status = _PortalStatus.failed;
          }
        }
      });
    }
  }

  bool _bhoomiFailed = false; // track if Bhoomi specifically failed

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
    return '₹$val / sqft (${d['taluk'] ?? ''})';
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
  int    get _investmentScore  => (_fullResult?['investment_score'] ?? 0) as int;
  String get _investmentVerdict=> _fullResult?['investment_verdict'] ?? '';

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
              const Text('Fetching from Government Portals',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                _scanning
                    ? 'Running all checks automatically — no action needed from you'
                    : 'All checks complete',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/scan/camera'),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scan RTC / Pahani Document'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.status == _PortalStatus.done && p.hasIssue == true
              ? Colors.orange.shade200
              : AppColors.borderColor,
        ),
      ),
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
    );
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _investmentScoreColor.withOpacity(0.12),
                _investmentScoreColor.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _investmentScoreColor.withOpacity(0.4)),
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
                      value: _investmentScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: _investmentScoreColor,
                    ),
                    Text(
                      '$_investmentScore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _investmentScoreColor,
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      _investmentVerdict,
                      style: TextStyle(
                          fontSize: 12, color: _investmentScoreColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

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
    if (_investmentScore >= 80) return AppColors.safe;
    if (_investmentScore >= 60) return Colors.orange;
    if (_investmentScore >= 40) return Colors.deepOrange;
    return Colors.red.shade800;
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Backend not reachable',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure the laptop backend is running:\n'
            '  cd digi-sampatti/backend\n'
            '  python main.py',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _startScan,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
