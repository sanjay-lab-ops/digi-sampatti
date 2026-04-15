import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── BBMP Property Tax Arrears Check ──────────────────────────────────────────
// Checks if the seller has any unpaid BBMP property tax on this property.
// If seller has arrears, Sub-Registrar can refuse registration OR the
// arrears become buyer's liability after purchase.
//
// BBMP e-Aasthi API endpoint:
//   GET https://bbmpeaasthi.karnataka.gov.in/api/... (WebView scrape fallback)
//
// Two modes:
//   1. PID search — if user has BBMP Property ID (PID)
//   2. Owner name search — search by seller name + ward
//   3. WebView fallback — open e-Aasthi in WebView, user searches manually
// ──────────────────────────────────────────────────────────────────────────────

enum _BbmpStep { idle, searching, found, notFound, error, webview }

class BbmpTaxCheckScreen extends ConsumerStatefulWidget {
  const BbmpTaxCheckScreen({super.key});
  @override
  ConsumerState<BbmpTaxCheckScreen> createState() => _BbmpTaxCheckScreenState();
}

class _BbmpTaxCheckScreenState extends ConsumerState<BbmpTaxCheckScreen> {
  final _pidCtrl       = TextEditingController();
  final _ownerCtrl     = TextEditingController();
  final _wardCtrl      = TextEditingController();

  _BbmpStep _step = _BbmpStep.idle;
  Map<String, dynamic>? _result;
  String? _errorMsg;
  bool _showWebView = false;
  late final WebViewController _wvc;

  @override
  void initState() {
    super.initState();
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://bbmpeaasthi.karnataka.gov.in/EAasthi/'));

    // Pre-fill owner from scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = ref.read(currentScanProvider);
      // Owner not stored directly — user fills from RTC
    });
  }

  @override
  void dispose() {
    _pidCtrl.dispose();
    _ownerCtrl.dispose();
    _wardCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchByPid() async {
    final pid = _pidCtrl.text.trim();
    if (pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter BBMP PID number')));
      return;
    }
    setState(() { _step = _BbmpStep.searching; _result = null; });

    try {
      // BBMP e-Aasthi public search endpoint
      final resp = await http.get(
        Uri.parse(
          'https://bbmpeaasthi.karnataka.gov.in/EAasthi/SearchController'
          '?searchType=pid&pid=$pid',
        ),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _result = data is Map<String, dynamic> ? data : {'raw': resp.body};
          _step = _BbmpStep.found;
        });
      } else {
        _fallbackToWebView();
      }
    } catch (_) {
      _fallbackToWebView();
    }
  }

  void _fallbackToWebView() {
    setState(() { _step = _BbmpStep.webview; _showWebView = true; });
  }

  bool get _hasArrears {
    if (_result == null) return false;
    final arrears = _result!['arrears'] ?? _result!['due_amount'] ?? 0;
    return (arrears is num && arrears > 0) ||
           (arrears is String && double.tryParse(arrears) != null &&
            double.parse(arrears) > 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView) return _buildWebViewFallback();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('BBMP Property Tax Check'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _fallbackToWebView,
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('Manual', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _warningBanner(),
            const SizedBox(height: 20),

            // ── Search by PID ─────────────────────────────────────────────
            _card(
              title: 'Search by BBMP PID',
              subtitle: 'PID = Property Identification Number. Found on BBMP '
                  'tax receipt or e-Aasthi portal. Best for exact match.',
              color: AppColors.navy,
              child: Column(children: [
                TextField(
                  controller: _pidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. PID-0012345678',
                    prefixIcon: const Icon(Icons.tag, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _step == _BbmpStep.searching ? null : _searchByPid,
                    icon: _step == _BbmpStep.searching
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: Text(_step == _BbmpStep.searching
                        ? 'Searching...' : 'Check Tax Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Search by owner name ──────────────────────────────────────
            _card(
              title: 'Search by Owner Name',
              subtitle: 'Enter seller\'s name exactly as it appears in BBMP records.',
              color: AppColors.info,
              child: Column(children: [
                TextField(
                  controller: _ownerCtrl,
                  decoration: InputDecoration(
                    hintText: 'Owner name (e.g. Vinod Mahadevaiah)',
                    prefixIcon: const Icon(Icons.person, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _wardCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ward name or number (optional)',
                    prefixIcon: const Icon(Icons.location_city, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _fallbackToWebView,
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text('Search on BBMP e-Aasthi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Result ────────────────────────────────────────────────────
            if (_step == _BbmpStep.found && _result != null) ...[
              const SizedBox(height: 16),
              _buildResult(),
            ],

            const SizedBox(height: 20),

            // ── What to look for ──────────────────────────────────────────
            _buildWhatToLookFor(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final arrears = _result!['arrears'] ?? _result!['due_amount'] ?? 0;
    final owner   = _result!['owner_name'] ?? _result!['ownerName'] ?? '';
    final pid     = _result!['pid'] ?? _result!['propertyId'] ?? '';
    final ward    = _result!['ward'] ?? '';
    final area    = _result!['built_up_area'] ?? '';
    final usage   = _result!['usage'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasArrears ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasArrears ? Colors.red.shade300 : Colors.green.shade300,
          width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              _hasArrears ? Icons.warning_amber_rounded : Icons.check_circle,
              color: _hasArrears ? Colors.red : Colors.green,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _hasArrears
                    ? 'TAX ARREARS FOUND — Seller has unpaid BBMP tax'
                    : 'Tax Paid — No outstanding BBMP dues',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _hasArrears ? Colors.red.shade800 : Colors.green.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (owner.isNotEmpty) _resultRow('Owner', owner),
          if (pid.isNotEmpty)   _resultRow('PID', pid),
          if (ward.isNotEmpty)  _resultRow('Ward', ward),
          if (area.isNotEmpty)  _resultRow('Built-up Area', area),
          if (usage.isNotEmpty) _resultRow('Usage Type', usage),
          _resultRow('Tax Due', '₹$arrears',
              color: _hasArrears ? Colors.red.shade800 : Colors.green.shade800),
          if (_hasArrears) ...[
            const SizedBox(height: 12),
            const Text(
              'What to do:\n'
              '• Do NOT pay seller the full amount until tax is cleared\n'
              '• Deduct arrears from sale price and pay BBMP directly\n'
              '• Get BBMP clearance certificate after payment\n'
              '• Sub-Registrar may ask for clearance before registration',
              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 120,
          child: Text(label, style: const TextStyle(
              fontSize: 12, color: AppColors.textLight))),
      Expanded(child: Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: color))),
    ]),
  );

  Widget _buildWhatToLookFor() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What to check on BBMP e-Aasthi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        ...[
          ('Tax arrears (ಬಾಕಿ)',
           'Any unpaid years of property tax. Can be charged to new owner after purchase.',
           true),
          ('Owner name matches RTC',
           'BBMP owner name should match the Bhoomi RTC owner exactly. Mismatch = name transfer not done.',
           true),
          ('Property usage type',
           'Residential / commercial / vacant site. Misuse = penalty + higher tax rate.',
           false),
          ('Built-up area',
           'Area on BBMP record vs actual built area. If more built than recorded = violation.',
           false),
          ('Khata type (A or B)',
           'A-Khata = approved layout, bank loan eligible. B-Khata = revenue site, most banks refuse.',
           true),
          ('Any BBMP notices',
           'Demolition notices, encroachment orders, building violation notices.',
           true),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              item.$3 ? Icons.warning_amber : Icons.info_outline,
              size: 16,
              color: item.$3 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
                Text(item.$2, style: const TextStyle(
                    fontSize: 11, color: Colors.black54, height: 1.3)),
              ],
            )),
          ]),
        )),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _fallbackToWebView,
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('Open BBMP e-Aasthi to Check'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildWebViewFallback() => Scaffold(
    appBar: AppBar(
      title: const Text('BBMP e-Aasthi'),
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _showWebView = false),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          color: AppColors.navy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Search owner name → check Tax Due (ಬಾಕಿ) column',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
    ),
    body: WebViewWidget(controller: _wvc),
  );

  Widget _warningBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withOpacity(0.4)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.location_city, color: Colors.deepOrange, size: 20),
          SizedBox(width: 8),
          Text('Why BBMP Tax Check Matters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                  color: Colors.deepOrange)),
        ]),
        SizedBox(height: 8),
        Text(
          'If the seller has unpaid BBMP property tax:\n'
          '• BBMP can attach/auction the property for dues recovery\n'
          '• Outstanding tax becomes the NEW OWNER\'s liability\n'
          '• Sub-Registrar in some cases asks for tax clearance\n'
          '• Khata transfer will be blocked until dues are cleared\n\n'
          'Only applicable for urban properties inside BBMP limits. '
          'Agricultural land (Bhoomi RTC) uses a different system.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _card({
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(subtitle, style: const TextStyle(
              fontSize: 11, color: AppColors.textLight)),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(12), child: child),
    ]),
  );
}
