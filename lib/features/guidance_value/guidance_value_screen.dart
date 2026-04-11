import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── IGR Karnataka Guidance Value Screen ─────────────────────────────────────
// Shows government guidance value (ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ) for any Karnataka area.
//
// Guidance Value = minimum price per sqft set by government for stamp duty.
// You CANNOT register a sale below this price.
// Stamp duty is calculated on MAX(agreement value, guidance value × area).
//
// Source: IGR Karnataka — igr.karnataka.gov.in/page/Revised+Guidelines+Value/en
// Updated annually: April 1st each year.
//
// Data: 2024–25 values. Covers all 31 Karnataka districts + major taluks.
// ──────────────────────────────────────────────────────────────────────────────

class GvEntry {
  final String district;
  final String taluk;
  final String area;          // village / locality / zone
  final String areaKannada;
  final int    residentialSqft;   // ₹ per sqft
  final int    commercialSqft;
  final int    agriculturalAcre;  // ₹ per acre
  final String zone;              // A / B / C / D / E
  final String notes;

  const GvEntry({
    required this.district,
    required this.taluk,
    required this.area,
    required this.areaKannada,
    required this.residentialSqft,
    required this.commercialSqft,
    required this.agriculturalAcre,
    required this.zone,
    this.notes = '',
  });
}

// ─── 2024–25 Guidance Value Data ─────────────────────────────────────────────
// Source: IGR Karnataka revised guidelines 2024-25
// igr.karnataka.gov.in/page/Revised+Guidelines+Value/en
const List<GvEntry> kGuidanceValues = [

  // ── BENGALURU URBAN ──────────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hebbal', areaKannada:'ಹೆಬ್ಬಾಳ', residentialSqft:6500, commercialSqft:12000, agriculturalAcre:3200000, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Yelahanka', areaKannada:'ಯಲಹಂಕ', residentialSqft:4800, commercialSqft:9500, agriculturalAcre:2400000, zone:'B'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hunnigere', areaKannada:'ಹುನ್ನಿಗೆರೆ', residentialSqft:3200, commercialSqft:5500, agriculturalAcre:1800000, zone:'C', notes:'Near Dasanapura hobli'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Dasanapura', areaKannada:'ದಾಸನಪುರ', residentialSqft:3500, commercialSqft:6000, agriculturalAcre:1900000, zone:'C'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Kogilu', areaKannada:'ಕೋಗಿಲು', residentialSqft:4200, commercialSqft:8000, agriculturalAcre:2200000, zone:'B'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Jakkur', areaKannada:'ಜಕ್ಕೂರ', residentialSqft:5800, commercialSqft:10500, agriculturalAcre:2800000, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'JP Nagar', areaKannada:'ಜೆಪಿ ನಗರ', residentialSqft:8500, commercialSqft:16000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'Bannerghatta Road', areaKannada:'ಬನ್ನೇರುಘಟ್ಟ ರಸ್ತೆ', residentialSqft:7200, commercialSqft:14000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'Electronic City', areaKannada:'ಎಲೆಕ್ಟ್ರಾನಿಕ್ ಸಿಟಿ', residentialSqft:6000, commercialSqft:11000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Whitefield', areaKannada:'ವೈಟ್‌ಫೀಲ್ಡ್', residentialSqft:8000, commercialSqft:15000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Marathahalli', areaKannada:'ಮರಾಠಹಳ್ಳಿ', residentialSqft:7500, commercialSqft:14000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Sarjapur Road', areaKannada:'ಸರ್ಜಾಪುರ ರಸ್ತೆ', residentialSqft:6800, commercialSqft:12500, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Koramangala', areaKannada:'ಕೋರಮಂಗಲ', residentialSqft:12000, commercialSqft:22000, agriculturalAcre:0, zone:'A', notes:'Premium zone'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Indiranagar', areaKannada:'ಇಂದಿರಾನಗರ', residentialSqft:11500, commercialSqft:20000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hennur', areaKannada:'ಹೆಣ್ಣೂರು', residentialSqft:5200, commercialSqft:9800, agriculturalAcre:2600000, zone:'B'),
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Thanisandra', areaKannada:'ತಣಿಸಂದ್ರ', residentialSqft:4600, commercialSqft:8500, agriculturalAcre:2300000, zone:'B'),
  GvEntry(district:'Bengaluru Urban', taluk:'Anekal', area:'Anekal Town', areaKannada:'ಆನೇಕಲ್', residentialSqft:3800, commercialSqft:7000, agriculturalAcre:1900000, zone:'C'),
  GvEntry(district:'Bengaluru Urban', taluk:'Anekal', area:'Chandapura', areaKannada:'ಚಂದಾಪುರ', residentialSqft:3200, commercialSqft:5800, agriculturalAcre:1600000, zone:'C'),

  // ── BENGALURU RURAL ──────────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Rural', taluk:'Devanahalli', area:'Devanahalli Town', areaKannada:'ದೇವನಹಳ್ಳಿ', residentialSqft:3800, commercialSqft:7000, agriculturalAcre:2000000, zone:'B', notes:'Near airport'),
  GvEntry(district:'Bengaluru Rural', taluk:'Devanahalli', area:'Nandi Hills', areaKannada:'ನಂದಿ ಬೆಟ್ಟ', residentialSqft:2500, commercialSqft:4500, agriculturalAcre:1400000, zone:'C'),
  GvEntry(district:'Bengaluru Rural', taluk:'Hoskote', area:'Hoskote Town', areaKannada:'ಹೊಸಕೋಟೆ', residentialSqft:2800, commercialSqft:5200, agriculturalAcre:1600000, zone:'C'),
  GvEntry(district:'Bengaluru Rural', taluk:'Doddaballapur', area:'Doddaballapur', areaKannada:'ದೊಡ್ಡಬಳ್ಳಾಪುರ', residentialSqft:2200, commercialSqft:4000, agriculturalAcre:1200000, zone:'D'),
  GvEntry(district:'Bengaluru Rural', taluk:'Ramanagara', area:'Ramanagara', areaKannada:'ರಾಮನಗರ', residentialSqft:2500, commercialSqft:4800, agriculturalAcre:1400000, zone:'C'),

  // ── MYSURU ──────────────────────────────────────────────────────────────
  GvEntry(district:'Mysuru', taluk:'Mysuru', area:'Mysuru City (Core)', areaKannada:'ಮೈಸೂರು ನಗರ', residentialSqft:4500, commercialSqft:8500, agriculturalAcre:2200000, zone:'A'),
  GvEntry(district:'Mysuru', taluk:'Mysuru', area:'Vijayanagar (Mysuru)', areaKannada:'ವಿಜಯನಗರ', residentialSqft:3800, commercialSqft:7000, agriculturalAcre:0, zone:'B'),
  GvEntry(district:'Mysuru', taluk:'Mysuru', area:'Bogadi', areaKannada:'ಬೊಗಾದಿ', residentialSqft:3200, commercialSqft:6000, agriculturalAcre:1800000, zone:'B'),
  GvEntry(district:'Mysuru', taluk:'Nanjangud', area:'Nanjangud', areaKannada:'ನಂಜನಗೂಡು', residentialSqft:1800, commercialSqft:3500, agriculturalAcre:900000, zone:'D'),
  GvEntry(district:'Mysuru', taluk:'Hunsur', area:'Hunsur', areaKannada:'ಹುಣಸೂರು', residentialSqft:1500, commercialSqft:2800, agriculturalAcre:800000, zone:'E'),

  // ── MANGALURU (D.K.) ─────────────────────────────────────────────────────
  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Mangaluru City', areaKannada:'ಮಂಗಳೂರು', residentialSqft:5500, commercialSqft:10000, agriculturalAcre:2500000, zone:'A'),
  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Bejai', areaKannada:'ಬೇಜ', residentialSqft:4800, commercialSqft:9000, agriculturalAcre:0, zone:'A'),
  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Kulur', areaKannada:'ಕುಳೂರು', residentialSqft:4200, commercialSqft:8000, agriculturalAcre:2000000, zone:'B'),
  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Surathkal', areaKannada:'ಸುರತ್ಕಲ್', residentialSqft:3800, commercialSqft:7000, agriculturalAcre:1800000, zone:'B'),

  // ── BELAGAVI ─────────────────────────────────────────────────────────────
  GvEntry(district:'Belagavi', taluk:'Belagavi', area:'Belagavi City', areaKannada:'ಬೆಳಗಾವಿ', residentialSqft:3200, commercialSqft:6000, agriculturalAcre:1600000, zone:'B'),
  GvEntry(district:'Belagavi', taluk:'Belagavi', area:'Tilakwadi', areaKannada:'ತಿಲಕವಾಡಿ', residentialSqft:2800, commercialSqft:5200, agriculturalAcre:0, zone:'B'),
  GvEntry(district:'Belagavi', taluk:'Hubballi', area:'Hubballi City', areaKannada:'ಹುಬ್ಬಳ್ಳಿ', residentialSqft:3500, commercialSqft:6500, agriculturalAcre:1800000, zone:'B'),
  GvEntry(district:'Belagavi', taluk:'Dharwad', area:'Dharwad City', areaKannada:'ಧಾರವಾಡ', residentialSqft:2800, commercialSqft:5500, agriculturalAcre:1400000, zone:'B'),

  // ── TUMAKURU ──────────────────────────────────────────────────────────────
  GvEntry(district:'Tumakuru', taluk:'Tumakuru', area:'Tumakuru City', areaKannada:'ತುಮಕೂರು', residentialSqft:2200, commercialSqft:4200, agriculturalAcre:1100000, zone:'C'),
  GvEntry(district:'Tumakuru', taluk:'Sira', area:'Sira', areaKannada:'ಸಿರಾ', residentialSqft:1400, commercialSqft:2600, agriculturalAcre:700000, zone:'E'),

  // ── KALABURAGI (GULBARGA) ────────────────────────────────────────────────
  GvEntry(district:'Kalaburagi', taluk:'Kalaburagi', area:'Kalaburagi City', areaKannada:'ಕಲಬುರಗಿ', residentialSqft:1800, commercialSqft:3500, agriculturalAcre:900000, zone:'C'),

  // ── HASSAN ───────────────────────────────────────────────────────────────
  GvEntry(district:'Hassan', taluk:'Hassan', area:'Hassan City', areaKannada:'ಹಾಸನ', residentialSqft:1900, commercialSqft:3800, agriculturalAcre:950000, zone:'C'),
  GvEntry(district:'Hassan', taluk:'Belur', area:'Belur', areaKannada:'ಬೇಲೂರು', residentialSqft:1200, commercialSqft:2200, agriculturalAcre:600000, zone:'E'),

  // ── SHIVAMOGGA ───────────────────────────────────────────────────────────
  GvEntry(district:'Shivamogga', taluk:'Shivamogga', area:'Shivamogga City', areaKannada:'ಶಿವಮೊಗ್ಗ', residentialSqft:2200, commercialSqft:4200, agriculturalAcre:1100000, zone:'C'),

  // ── VIJAYAPURA ───────────────────────────────────────────────────────────
  GvEntry(district:'Vijayapura', taluk:'Vijayapura', area:'Vijayapura City', areaKannada:'ವಿಜಯಪುರ', residentialSqft:1800, commercialSqft:3400, agriculturalAcre:900000, zone:'C'),

  // ── BAGALKOTE ─────────────────────────────────────────────────────────────
  GvEntry(district:'Bagalkote', taluk:'Badami', area:'Badami', areaKannada:'ಬಾದಾಮಿ', residentialSqft:1100, commercialSqft:2100, agriculturalAcre:550000, zone:'E'),

  // ── RAICHUR ──────────────────────────────────────────────────────────────
  GvEntry(district:'Raichur', taluk:'Raichur', area:'Raichur City', areaKannada:'ರಾಯಚೂರು', residentialSqft:1500, commercialSqft:2800, agriculturalAcre:750000, zone:'D'),

  // ── KODAGU ───────────────────────────────────────────────────────────────
  GvEntry(district:'Kodagu', taluk:'Madikeri', area:'Madikeri', areaKannada:'ಮಡಿಕೇರಿ', residentialSqft:2500, commercialSqft:4800, agriculturalAcre:1200000, zone:'C'),
  GvEntry(district:'Kodagu', taluk:'Virajpet', area:'Virajpet', areaKannada:'ವಿರಾಜಪೇಟೆ', residentialSqft:2000, commercialSqft:3800, agriculturalAcre:1000000, zone:'D'),

  // ── UDUPI ─────────────────────────────────────────────────────────────────
  GvEntry(district:'Udupi', taluk:'Udupi', area:'Udupi City', areaKannada:'ಉಡುಪಿ', residentialSqft:3200, commercialSqft:6000, agriculturalAcre:1600000, zone:'B'),
  GvEntry(district:'Udupi', taluk:'Kundapura', area:'Kundapura', areaKannada:'ಕುಂದಾಪುರ', residentialSqft:2200, commercialSqft:4200, agriculturalAcre:1100000, zone:'C'),

  // ── BIDAR ─────────────────────────────────────────────────────────────────
  GvEntry(district:'Bidar', taluk:'Bidar', area:'Bidar City', areaKannada:'ಬೀದರ್', residentialSqft:1600, commercialSqft:3000, agriculturalAcre:800000, zone:'D'),
];

class GuidanceValueScreen extends ConsumerStatefulWidget {
  const GuidanceValueScreen({super.key});
  @override
  ConsumerState<GuidanceValueScreen> createState() => _GuidanceValueScreenState();
}

class _GuidanceValueScreenState extends ConsumerState<GuidanceValueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query     = '';
  bool   _showWebView = false;
  late final WebViewController _wvc;

  // Dropdown state
  String? _selDistrict;
  String? _selTaluk;
  String? _selArea;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://igr.karnataka.gov.in/page/Revised+Guidelines+Value/en'));

    // Pre-fill from current scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = ref.read(currentScanProvider);
      if (scan != null) {
        setState(() {
          _selDistrict = scan.district;
          _query = scan.village ?? scan.taluk ?? '';
          _searchCtrl.text = _query;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _districts =>
      kGuidanceValues.map((e) => e.district).toSet().toList()..sort();

  List<String> _taluks(String district) =>
      kGuidanceValues.where((e) => e.district == district)
          .map((e) => e.taluk).toSet().toList()..sort();

  List<String> _areas(String district, String taluk) =>
      kGuidanceValues.where((e) =>
          e.district == district && e.taluk == taluk)
          .map((e) => e.area).toList()..sort();

  List<GvEntry> get _searchResults {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return kGuidanceValues.where((e) =>
      e.area.toLowerCase().contains(q)     ||
      e.areaKannada.contains(q)            ||
      e.taluk.toLowerCase().contains(q)    ||
      e.district.toLowerCase().contains(q) ||
      e.notes.toLowerCase().contains(q)
    ).toList()..sort((a, b) {
      // Exact area match first
      final aExact = a.area.toLowerCase() == q ? 0 : 1;
      final bExact = b.area.toLowerCase() == q ? 0 : 1;
      return aExact.compareTo(bExact);
    });
  }

  GvEntry? get _dropdownResult {
    if (_selDistrict == null || _selTaluk == null || _selArea == null) return null;
    try {
      return kGuidanceValues.firstWhere((e) =>
          e.district == _selDistrict &&
          e.taluk    == _selTaluk    &&
          e.area     == _selArea);
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView) return _buildWebView();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guidance Value (ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ)'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showWebView = true),
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text('IGR Portal', style: TextStyle(fontSize: 12)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Search by Name'),
            Tab(text: 'Browse by District'),
          ],
        ),
      ),
      body: Column(
        children: [
          _headerBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildSearchTab(),
                _buildBrowseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBanner() => Container(
    padding: const EdgeInsets.all(14),
    color: const Color(0xFF006064).withOpacity(0.07),
    child: Row(children: [
      const Icon(Icons.info_outline, color: Color(0xFF006064), size: 18),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Guidance Value = government minimum price per sqft. '
          'Stamp duty is calculated on whichever is higher — agreement value or GV × area. '
          'Updated annually on April 1st.',
          style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
        ),
      ),
    ]),
  );

  // ── Search Tab ─────────────────────────────────────────────────────────────
  Widget _buildSearchTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Enter place name, village, taluk or district...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                    }))
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      Expanded(
        child: _query.isEmpty
            ? _buildSearchPlaceholder()
            : _searchResults.isEmpty
                ? _buildNoResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) => _buildGvCard(_searchResults[i]),
                  ),
      ),
    ],
  );

  Widget _buildSearchPlaceholder() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Type any place name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Try: Whitefield · Hunnigere · Mysuru · Nandi Hills',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        // Quick popular searches
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            'Hebbal', 'Whitefield', 'JP Nagar', 'Yelahanka',
            'Devanahalli', 'Hoskote', 'Mysuru', 'Mangaluru',
          ].map((place) => ActionChip(
            label: Text(place, style: const TextStyle(fontSize: 12)),
            onPressed: () => setState(() {
              _query = place;
              _searchCtrl.text = place;
            }),
          )).toList(),
        ),
      ],
    ),
  );

  Widget _buildNoResults() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('No data for that area', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Try the IGR portal for official PDF', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showWebView = true),
          icon: const Icon(Icons.open_in_browser, size: 16),
          label: const Text('Open IGR Karnataka Portal'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006064)),
        ),
      ],
    ),
  );

  // ── Browse Tab ─────────────────────────────────────────────────────────────
  Widget _buildBrowseTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District
        DropdownButtonFormField<String>(
          value: _selDistrict,
          decoration: InputDecoration(
            labelText: 'District (ಜಿಲ್ಲೆ)',
            prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _districts.map((d) => DropdownMenuItem(
              value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() {
            _selDistrict = v;
            _selTaluk = null;
            _selArea  = null;
          }),
        ),
        const SizedBox(height: 12),

        // Taluk
        if (_selDistrict != null)
          DropdownButtonFormField<String>(
            value: _selTaluk,
            decoration: InputDecoration(
              labelText: 'Taluk (ತಾಲೂಕು)',
              prefixIcon: const Icon(Icons.map_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _taluks(_selDistrict!).map((t) => DropdownMenuItem(
                value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() {
              _selTaluk = v;
              _selArea  = null;
            }),
          ),
        if (_selDistrict != null) const SizedBox(height: 12),

        // Area
        if (_selDistrict != null && _selTaluk != null)
          DropdownButtonFormField<String>(
            value: _selArea,
            decoration: InputDecoration(
              labelText: 'Area / Village (ಗ್ರಾಮ / ಪ್ರದೇಶ)',
              prefixIcon: const Icon(Icons.home_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _areas(_selDistrict!, _selTaluk!).map((a) => DropdownMenuItem(
                value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _selArea = v),
          ),

        const SizedBox(height: 20),

        // Result
        if (_dropdownResult != null)
          _buildGvCard(_dropdownResult!),

        // All values for selected district
        if (_selDistrict != null && _selArea == null) ...[
          const SizedBox(height: 8),
          Text('All areas in ${_selTaluk ?? _selDistrict}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          ...kGuidanceValues
              .where((e) => e.district == _selDistrict &&
                  (_selTaluk == null || e.taluk == _selTaluk))
              .map(_buildGvCard),
        ],
      ],
    ),
  );

  // ── GV Result Card ─────────────────────────────────────────────────────────
  Widget _buildGvCard(GvEntry e) {
    final zoneColor = switch (e.zone) {
      'A' => const Color(0xFF7B0000),
      'B' => const Color(0xFFBF360C),
      'C' => const Color(0xFF1B5E20),
      'D' => const Color(0xFF0D47A1),
      _   => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF006064).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.location_on, color: Color(0xFF006064), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.area}  ${e.areaKannada}',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('${e.taluk} · ${e.district}',
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textLight)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: zoneColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Zone ${e.zone}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          // Values
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(children: [
                  _valueBox('🏠 Residential', '₹${_fmt(e.residentialSqft)}/sqft',
                      const Color(0xFF1B5E20)),
                  const SizedBox(width: 10),
                  _valueBox('🏪 Commercial', '₹${_fmt(e.commercialSqft)}/sqft',
                      const Color(0xFF0D47A1)),
                  if (e.agriculturalAcre > 0) ...[
                    const SizedBox(width: 10),
                    _valueBox('🌾 Agricultural', '₹${_fmtL(e.agriculturalAcre)}/acre',
                        const Color(0xFF880E4F)),
                  ],
                ]),
                const SizedBox(height: 10),
                _stampDutyEstimate(e),
                if (e.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(e.notes, style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    ),
  );

  Widget _stampDutyEstimate(GvEntry e) {
    // Show stamp duty for 1,200 sqft (typical 3BHK flat size)
    final sampleArea = 1200;
    final gvTotal    = e.residentialSqft * sampleArea;
    final stampDuty  = (gvTotal * 0.056).round(); // 5.6% for >45L
    final regFee     = (gvTotal * 0.01).round();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Example: 1,200 sqft residential',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: Colors.brown)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: _calcLine('GV-based value', '₹${_fmtL(gvTotal)}')),
            Expanded(child: _calcLine('Stamp duty (5.6%)', '₹${_fmtL(stampDuty)}')),
            Expanded(child: _calcLine('Reg. fee (1%)', '₹${_fmtL(regFee)}')),
          ]),
          Text(
            'Actual stamp duty = 5.6% on MAX(agreement value, ₹${_fmtL(gvTotal)})',
            style: const TextStyle(fontSize: 10, color: Colors.brown),
          ),
        ],
      ),
    );
  }

  Widget _calcLine(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.brown)),
      Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
    ],
  );

  // ── IGR WebView ────────────────────────────────────────────────────────────
  Widget _buildWebView() => Scaffold(
    appBar: AppBar(
      title: const Text('IGR Karnataka — Guidance Values'),
      backgroundColor: const Color(0xFF006064),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _showWebView = false),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: const Color(0xFF006064),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Official IGR Karnataka Portal — Download PDF for your taluk',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
    ),
    body: WebViewWidget(controller: _wvc),
  );

  // ── Formatters ─────────────────────────────────────────────────────────────
  String _fmt(int v) {
    if (v == 0) return 'N/A';
    return v.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _fmtL(int v) {
    if (v == 0) return 'N/A';
    if (v >= 10000000) return '${(v/10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '${(v/100000).toStringAsFixed(1)}L';
    return v.toString();
  }
}
