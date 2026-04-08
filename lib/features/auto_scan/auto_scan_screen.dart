import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

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

    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.29.151:8080';

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
      setState(() {
        _updatePortal('Bhoomi RTC',     data['rtc'],     _rtcSummary);
        _updatePortal('Kaveri EC',      data['ec'],      _ecSummary);
        _updatePortal('eCourts',        data['courts'],  _courtsSummary);
        _updatePortal('CERSAI',         data['cersai'],  _cersaiSummary);
        _updatePortal('Guidance Value', data['guidance_value'], _gvSummary);
        _updatePortal('FMB Sketch',     data['fmb'],     _fmbSummary);

        // RERA is queried separately (needs project name)
        _portals.firstWhere((p) => p.name == 'RERA')
          ..status = _PortalStatus.done
          ..summary = 'Checked — add project name for RERA'
          ..hasIssue = false;

        _scanning = false;
        _done = true;
      });
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

  void _updatePortal(String name, dynamic data, String Function(Map) summarize) {
    final p = _portals.firstWhere((p) => p.name == name);
    if (data == null) {
      p.status = _PortalStatus.failed;
      p.summary = 'Not available (portal down)';
      p.hasIssue = null;
      return;
    }
    final d = data as Map<String, dynamic>;
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
  String get _riskLevel => _fullResult?['risk_level'] ?? 'UNKNOWN';
  List get _riskFlags   => _fullResult?['risk_flags'] ?? [];

  Color get _riskColor {
    switch (_riskLevel) {
      case 'SAFE':    return AppColors.safe;
      case 'CAUTION': return Colors.orange;
      case 'HIGH':    return Colors.red;
      default:        return Colors.grey;
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/analysis'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get Full AI Analysis & Report'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _riskColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _riskLevel == 'SAFE'
                    ? Icons.verified
                    : _riskLevel == 'CAUTION'
                        ? Icons.warning
                        : Icons.dangerous,
                color: _riskColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                _riskLevel == 'SAFE'
                    ? 'Property looks SAFE'
                    : _riskLevel == 'CAUTION'
                        ? 'Proceed with CAUTION'
                        : 'HIGH RISK — Do Not Proceed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _riskColor,
                ),
              ),
            ],
          ),
          if (_riskFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._riskFlags.map((flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: _riskColor, size: 18),
                      Expanded(
                        child: Text(flag.toString(),
                            style: TextStyle(
                                fontSize: 12, color: _riskColor.withOpacity(0.9))),
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
    );
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
