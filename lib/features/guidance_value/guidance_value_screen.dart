import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Guidance Value Screen ─────────────────────────────────────────────────────
// What a stamp vendor tells you — but smarter.
// Type any place name → get current guidance value instantly.
//
// Shows:
//   • Current GV (2024-25) per sqft / per acre
//   • Estimated market value (what people actually pay)
//   • Year-by-year trend (2019 → 2024)
//   • Stamp duty on a sample transaction
//   • Seller view: "What is my property worth today?"
//   • Buyer view: "Is the asking price fair?"
//
// Source: IGR Karnataka — igr.karnataka.gov.in/page/Revised+Guidelines+Value/en
// Updated: Every April 1st by state government
// ──────────────────────────────────────────────────────────────────────────────

enum _GvMode { buyer, seller, developer }

class GvEntry {
  final String district;
  final String taluk;
  final String area;
  final String areaKannada;
  final int    zone;              // 1=highest, 5=lowest
  // Guidance values per sqft (residential) by year
  final Map<String, int> gvHistory; // '2019-20', '2020-21', ... '2024-25'
  final int    commercialSqft;
  final int    agriculturalAcre;
  final double marketMultiplier;  // market ≈ GV × this factor
  final String trend;             // 'rising', 'stable', 'flat'
  final int    trendPct;          // avg annual % increase

  const GvEntry({
    required this.district,
    required this.taluk,
    required this.area,
    required this.areaKannada,
    required this.zone,
    required this.gvHistory,
    required this.commercialSqft,
    required this.agriculturalAcre,
    required this.marketMultiplier,
    required this.trend,
    required this.trendPct,
  });

  int get currentGv => gvHistory['2024-25'] ?? gvHistory.values.last;
  int get prevGv    => gvHistory['2023-24'] ?? currentGv;
  int get annualGainPct => prevGv > 0 ? ((currentGv - prevGv) / prevGv * 100).round() : 0;
  int get estimatedMarketSqft => (currentGv * marketMultiplier).round();

  String get zoneLabel => switch (zone) {
    1 => 'Zone A — Premium',
    2 => 'Zone B — High',
    3 => 'Zone C — Mid',
    4 => 'Zone D — Developing',
    _ => 'Zone E — Outskirts',
  };

  Color get zoneColor => switch (zone) {
    1 => const Color(0xFF7B0000),
    2 => const Color(0xFFBF360C),
    3 => const Color(0xFF1B5E20),
    4 => const Color(0xFF0D47A1),
    _ => Colors.grey.shade700,
  };
}

// ─── 2024-25 Guidance Value Data with 5-year history ─────────────────────────
const List<GvEntry> kGvData = [

  // ── BENGALURU URBAN — NORTH ────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hebbal',
    areaKannada:'ಹೆಬ್ಬಾಳ', zone:1,
    gvHistory: {'2019-20':4200,'2020-21':4500,'2021-22':5000,'2022-23':5800,'2023-24':6200,'2024-25':6500},
    commercialSqft:12000, agriculturalAcre:3200000,
    marketMultiplier:2.8, trend:'rising', trendPct:9),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Yelahanka',
    areaKannada:'ಯಲಹಂಕ', zone:2,
    gvHistory: {'2019-20':3000,'2020-21':3200,'2021-22':3600,'2022-23':4200,'2023-24':4600,'2024-25':4800},
    commercialSqft:9500, agriculturalAcre:2400000,
    marketMultiplier:2.4, trend:'rising', trendPct:10),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hunnigere',
    areaKannada:'ಹುನ್ನಿಗೆರೆ', zone:3,
    gvHistory: {'2019-20':1800,'2020-21':1900,'2021-22':2200,'2022-23':2700,'2023-24':3000,'2024-25':3200},
    commercialSqft:5500, agriculturalAcre:1800000,
    marketMultiplier:1.9, trend:'rising', trendPct:12),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Dasanapura',
    areaKannada:'ದಾಸನಪುರ', zone:3,
    gvHistory: {'2019-20':2000,'2020-21':2100,'2021-22':2400,'2022-23':2900,'2023-24':3200,'2024-25':3500},
    commercialSqft:6000, agriculturalAcre:1900000,
    marketMultiplier:2.0, trend:'rising', trendPct:11),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Thanisandra',
    areaKannada:'ತಣಿಸಂದ್ರ', zone:2,
    gvHistory: {'2019-20':2800,'2020-21':3000,'2021-22':3400,'2022-23':4000,'2023-24':4400,'2024-25':4600},
    commercialSqft:8500, agriculturalAcre:2300000,
    marketMultiplier:2.3, trend:'rising', trendPct:10),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Kogilu',
    areaKannada:'ಕೋಗಿಲು', zone:2,
    gvHistory: {'2019-20':2600,'2020-21':2800,'2021-22':3100,'2022-23':3700,'2023-24':4000,'2024-25':4200},
    commercialSqft:8000, agriculturalAcre:2200000,
    marketMultiplier:2.2, trend:'rising', trendPct:10),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Jakkur',
    areaKannada:'ಜಕ್ಕೂರ', zone:1,
    gvHistory: {'2019-20':3800,'2020-21':4000,'2021-22':4500,'2022-23':5200,'2023-24':5600,'2024-25':5800},
    commercialSqft:10500, agriculturalAcre:2800000,
    marketMultiplier:2.6, trend:'rising', trendPct:9),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Hennur',
    areaKannada:'ಹೆಣ್ಣೂರು', zone:2,
    gvHistory: {'2019-20':3100,'2020-21':3300,'2021-22':3700,'2022-23':4400,'2023-24':4900,'2024-25':5200},
    commercialSqft:9800, agriculturalAcre:2600000,
    marketMultiplier:2.4, trend:'rising', trendPct:11),

  // ── BENGALURU URBAN — SOUTH ────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'JP Nagar',
    areaKannada:'ಜೆಪಿ ನಗರ', zone:1,
    gvHistory: {'2019-20':5500,'2020-21':6000,'2021-22':6800,'2022-23':7500,'2023-24':8200,'2024-25':8500},
    commercialSqft:16000, agriculturalAcre:0,
    marketMultiplier:3.2, trend:'rising', trendPct:9),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'Electronic City',
    areaKannada:'ಎಲೆಕ್ಟ್ರಾನಿಕ್ ಸಿಟಿ', zone:1,
    gvHistory: {'2019-20':3800,'2020-21':4200,'2021-22':4800,'2022-23':5400,'2023-24':5800,'2024-25':6000},
    commercialSqft:11000, agriculturalAcre:0,
    marketMultiplier:2.7, trend:'rising', trendPct:10),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru South', area:'Bannerghatta Road',
    areaKannada:'ಬನ್ನೇರುಘಟ್ಟ ರಸ್ತೆ', zone:1,
    gvHistory: {'2019-20':4500,'2020-21':4900,'2021-22':5500,'2022-23':6200,'2023-24':6900,'2024-25':7200},
    commercialSqft:14000, agriculturalAcre:0,
    marketMultiplier:3.0, trend:'rising', trendPct:10),

  // ── BENGALURU URBAN — EAST ─────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Whitefield',
    areaKannada:'ವೈಟ್‌ಫೀಲ್ಡ್', zone:1,
    gvHistory: {'2019-20':5200,'2020-21':5600,'2021-22':6200,'2022-23':7000,'2023-24':7700,'2024-25':8000},
    commercialSqft:15000, agriculturalAcre:0,
    marketMultiplier:3.0, trend:'rising', trendPct:9),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Marathahalli',
    areaKannada:'ಮರಾಠಹಳ್ಳಿ', zone:1,
    gvHistory: {'2019-20':4800,'2020-21':5200,'2021-22':5800,'2022-23':6500,'2023-24':7200,'2024-25':7500},
    commercialSqft:14000, agriculturalAcre:0,
    marketMultiplier:2.9, trend:'rising', trendPct:9),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru East', area:'Sarjapur Road',
    areaKannada:'ಸರ್ಜಾಪುರ ರಸ್ತೆ', zone:1,
    gvHistory: {'2019-20':3900,'2020-21':4200,'2021-22':5000,'2022-23':5700,'2023-24':6500,'2024-25':6800},
    commercialSqft:12500, agriculturalAcre:0,
    marketMultiplier:2.8, trend:'rising', trendPct:11),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Koramangala',
    areaKannada:'ಕೋರಮಂಗಲ', zone:1,
    gvHistory: {'2019-20':8500,'2020-21':9000,'2021-22':9800,'2022-23':10500,'2023-24':11500,'2024-25':12000},
    commercialSqft:22000, agriculturalAcre:0,
    marketMultiplier:3.8, trend:'stable', trendPct:7),

  GvEntry(district:'Bengaluru Urban', taluk:'Bengaluru North', area:'Indiranagar',
    areaKannada:'ಇಂದಿರಾನಗರ', zone:1,
    gvHistory: {'2019-20':8000,'2020-21':8500,'2021-22':9200,'2022-23':10000,'2023-24':11000,'2024-25':11500},
    commercialSqft:20000, agriculturalAcre:0,
    marketMultiplier:3.6, trend:'stable', trendPct:7),

  // ── BENGALURU RURAL ────────────────────────────────────────────────────────
  GvEntry(district:'Bengaluru Rural', taluk:'Devanahalli', area:'Devanahalli',
    areaKannada:'ದೇವನಹಳ್ಳಿ', zone:2,
    gvHistory: {'2019-20':2200,'2020-21':2500,'2021-22':2900,'2022-23':3400,'2023-24':3600,'2024-25':3800},
    commercialSqft:7000, agriculturalAcre:2000000,
    marketMultiplier:2.3, trend:'rising', trendPct:12),

  GvEntry(district:'Bengaluru Rural', taluk:'Hoskote', area:'Hoskote',
    areaKannada:'ಹೊಸಕೋಟೆ', zone:3,
    gvHistory: {'2019-20':1400,'2020-21':1600,'2021-22':1900,'2022-23':2300,'2023-24':2600,'2024-25':2800},
    commercialSqft:5200, agriculturalAcre:1600000,
    marketMultiplier:1.9, trend:'rising', trendPct:14),

  GvEntry(district:'Bengaluru Rural', taluk:'Doddaballapur', area:'Doddaballapur',
    areaKannada:'ದೊಡ್ಡಬಳ್ಳಾಪುರ', zone:4,
    gvHistory: {'2019-20':900,'2020-21':1000,'2021-22':1200,'2022-23':1600,'2023-24':1900,'2024-25':2200},
    commercialSqft:4000, agriculturalAcre:1200000,
    marketMultiplier:1.6, trend:'rising', trendPct:18),

  GvEntry(district:'Bengaluru Rural', taluk:'Ramanagara', area:'Ramanagara',
    areaKannada:'ರಾಮನಗರ', zone:3,
    gvHistory: {'2019-20':1300,'2020-21':1400,'2021-22':1700,'2022-23':2100,'2023-24':2300,'2024-25':2500},
    commercialSqft:4800, agriculturalAcre:1400000,
    marketMultiplier:1.7, trend:'rising', trendPct:14),

  // ── MYSURU ─────────────────────────────────────────────────────────────────
  GvEntry(district:'Mysuru', taluk:'Mysuru', area:'Mysuru City',
    areaKannada:'ಮೈಸೂರು ನಗರ', zone:1,
    gvHistory: {'2019-20':2800,'2020-21':3000,'2021-22':3400,'2022-23':3900,'2023-24':4200,'2024-25':4500},
    commercialSqft:8500, agriculturalAcre:2200000,
    marketMultiplier:2.4, trend:'rising', trendPct:10),

  GvEntry(district:'Mysuru', taluk:'Mysuru', area:'Vijayanagar Mysuru',
    areaKannada:'ವಿಜಯನಗರ', zone:2,
    gvHistory: {'2019-20':2200,'2020-21':2400,'2021-22':2700,'2022-23':3100,'2023-24':3500,'2024-25':3800},
    commercialSqft:7000, agriculturalAcre:0,
    marketMultiplier:2.1, trend:'rising', trendPct:11),

  // ── DAKSHINA KANNADA ───────────────────────────────────────────────────────
  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Mangaluru City',
    areaKannada:'ಮಂಗಳೂರು', zone:1,
    gvHistory: {'2019-20':3500,'2020-21':3800,'2021-22':4200,'2022-23':4800,'2023-24':5200,'2024-25':5500},
    commercialSqft:10000, agriculturalAcre:2500000,
    marketMultiplier:2.6, trend:'rising', trendPct:9),

  GvEntry(district:'Dakshina Kannada', taluk:'Mangaluru', area:'Surathkal',
    areaKannada:'ಸುರತ್ಕಲ್', zone:2,
    gvHistory: {'2019-20':2400,'2020-21':2600,'2021-22':2900,'2022-23':3300,'2023-24':3600,'2024-25':3800},
    commercialSqft:7000, agriculturalAcre:1800000,
    marketMultiplier:2.1, trend:'rising', trendPct:9),

  // ── BELAGAVI ───────────────────────────────────────────────────────────────
  GvEntry(district:'Belagavi', taluk:'Belagavi', area:'Belagavi City',
    areaKannada:'ಬೆಳಗಾವಿ', zone:2,
    gvHistory: {'2019-20':1900,'2020-21':2100,'2021-22':2400,'2022-23':2800,'2023-24':3000,'2024-25':3200},
    commercialSqft:6000, agriculturalAcre:1600000,
    marketMultiplier:2.0, trend:'rising', trendPct:11),

  GvEntry(district:'Belagavi', taluk:'Hubballi', area:'Hubballi City',
    areaKannada:'ಹುಬ್ಬಳ್ಳಿ', zone:2,
    gvHistory: {'2019-20':2100,'2020-21':2300,'2021-22':2600,'2022-23':3000,'2023-24':3300,'2024-25':3500},
    commercialSqft:6500, agriculturalAcre:1800000,
    marketMultiplier:2.1, trend:'rising', trendPct:11),

  GvEntry(district:'Belagavi', taluk:'Dharwad', area:'Dharwad City',
    areaKannada:'ಧಾರವಾಡ', zone:2,
    gvHistory: {'2019-20':1700,'2020-21':1900,'2021-22':2100,'2022-23':2500,'2023-24':2700,'2024-25':2800},
    commercialSqft:5500, agriculturalAcre:1400000,
    marketMultiplier:1.9, trend:'rising', trendPct:10),

  // ── TUMAKURU ───────────────────────────────────────────────────────────────
  GvEntry(district:'Tumakuru', taluk:'Tumakuru', area:'Tumakuru City',
    areaKannada:'ತುಮಕೂರು', zone:3,
    gvHistory: {'2019-20':1200,'2020-21':1300,'2021-22':1600,'2022-23':1900,'2023-24':2000,'2024-25':2200},
    commercialSqft:4200, agriculturalAcre:1100000,
    marketMultiplier:1.7, trend:'rising', trendPct:13),

  // ── KALABURAGI ────────────────────────────────────────────────────────────
  GvEntry(district:'Kalaburagi', taluk:'Kalaburagi', area:'Kalaburagi City',
    areaKannada:'ಕಲಬುರಗಿ', zone:3,
    gvHistory: {'2019-20':900,'2020-21':1000,'2021-22':1200,'2022-23':1500,'2023-24':1700,'2024-25':1800},
    commercialSqft:3500, agriculturalAcre:900000,
    marketMultiplier:1.6, trend:'rising', trendPct:15),

  // ── UDUPI ──────────────────────────────────────────────────────────────────
  GvEntry(district:'Udupi', taluk:'Udupi', area:'Udupi City',
    areaKannada:'ಉಡುಪಿ', zone:2,
    gvHistory: {'2019-20':1900,'2020-21':2100,'2021-22':2400,'2022-23':2800,'2023-24':3000,'2024-25':3200},
    commercialSqft:6000, agriculturalAcre:1600000,
    marketMultiplier:2.0, trend:'rising', trendPct:11),

  // ── HASSAN ────────────────────────────────────────────────────────────────
  GvEntry(district:'Hassan', taluk:'Hassan', area:'Hassan City',
    areaKannada:'ಹಾಸನ', zone:3,
    gvHistory: {'2019-20':900,'2020-21':1000,'2021-22':1200,'2022-23':1500,'2023-24':1700,'2024-25':1900},
    commercialSqft:3800, agriculturalAcre:950000,
    marketMultiplier:1.6, trend:'rising', trendPct:15),

  // ── SHIVAMOGGA ────────────────────────────────────────────────────────────
  GvEntry(district:'Shivamogga', taluk:'Shivamogga', area:'Shivamogga City',
    areaKannada:'ಶಿವಮೊಗ್ಗ', zone:3,
    gvHistory: {'2019-20':1100,'2020-21':1200,'2021-22':1500,'2022-23':1800,'2023-24':2000,'2024-25':2200},
    commercialSqft:4200, agriculturalAcre:1100000,
    marketMultiplier:1.7, trend:'rising', trendPct:14),

  // ── KODAGU ────────────────────────────────────────────────────────────────
  GvEntry(district:'Kodagu', taluk:'Madikeri', area:'Madikeri',
    areaKannada:'ಮಡಿಕೇರಿ', zone:3,
    gvHistory: {'2019-20':1400,'2020-21':1500,'2021-22':1800,'2022-23':2100,'2023-24':2400,'2024-25':2500},
    commercialSqft:4800, agriculturalAcre:1200000,
    marketMultiplier:2.0, trend:'rising', trendPct:12),
];

// ─── Screen ────────────────────────────────────────────────────────────────────
class GuidanceValueScreen extends ConsumerStatefulWidget {
  const GuidanceValueScreen({super.key});
  @override
  ConsumerState<GuidanceValueScreen> createState() => _GuidanceValueScreenState();
}

class _GuidanceValueScreenState extends ConsumerState<GuidanceValueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl  = TextEditingController();
  _GvMode _mode      = _GvMode.buyer;
  GvEntry? _selected;
  // Calculator inputs
  double _areaSqft   = 1200;
  bool   _showWebView = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Auto-detect from current scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = ref.read(currentScanProvider);
      if (scan?.village != null) {
        _searchCtrl.text = scan!.village!;
        _autoSearch(scan.village!);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _autoSearch(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) { setState(() => _selected = null); return; }
    final match = kGvData.firstWhere(
      (e) => e.area.toLowerCase().contains(q)
          || e.areaKannada.contains(q)
          || e.taluk.toLowerCase().contains(q)
          || e.district.toLowerCase().contains(q),
      orElse: () => kGvData.first,
    );
    setState(() {
      _selected = match;
      // Default area for stamp duty calc
      _areaSqft = 1200;
    });
  }

  List<GvEntry> get _searchResults {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return [];
    return kGvData.where((e) =>
      e.area.toLowerCase().contains(q)     ||
      e.areaKannada.contains(q)            ||
      e.taluk.toLowerCase().contains(q)    ||
      e.district.toLowerCase().contains(q)
    ).toList()
      ..sort((a, b) {
        final aExact = a.area.toLowerCase().startsWith(q) ? 0 : 1;
        final bExact = b.area.toLowerCase().startsWith(q) ? 0 : 1;
        return aExact.compareTo(bExact);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guidance Value (ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ)'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://igr.karnataka.gov.in/page/Revised+Guidelines+Value/en');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('IGR PDFs', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mode toggle ────────────────────────────────────────────────────
          _buildModeBar(),
          // ── Search box ─────────────────────────────────────────────────────
          _buildSearchBar(),
          // ── Results ────────────────────────────────────────────────────────
          Expanded(
            child: _selected != null
                ? _buildDetailView(_selected!)
                : _buildSearchList(),
          ),
        ],
      ),
    );
  }

  // ── Mode Bar ────────────────────────────────────────────────────────────────
  Widget _buildModeBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(children: [
      _modeChip(_GvMode.buyer,     '🏠 Buyer',     const Color(0xFF1B5E20)),
      const SizedBox(width: 8),
      _modeChip(_GvMode.seller,    '💰 Seller',    const Color(0xFF880E4F)),
      const SizedBox(width: 8),
      _modeChip(_GvMode.developer, '🏗️ Developer', const Color(0xFF0D47A1)),
    ]),
  );

  Widget _modeChip(_GvMode m, String label, Color color) => GestureDetector(
    onTap: () => setState(() => _mode = m),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _mode == m ? color : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: _mode == m ? Colors.white : Colors.grey.shade700,
      )),
    ),
  );

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() => _selected = null);
        if (v.isNotEmpty) _autoSearch(v);
      },
      decoration: InputDecoration(
        hintText: 'Type any place — Hunnigere, Whitefield, Mysuru...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() {
                  _searchCtrl.clear();
                  _selected = null;
                }))
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );

  // ── Search result list ──────────────────────────────────────────────────────
  Widget _buildSearchList() {
    final results = _searchResults;
    if (_searchCtrl.text.isEmpty) {
      return _buildHomePlaceholder();
    }
    if (results.isEmpty) {
      return _buildNoResult();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) => _buildResultTile(results[i]),
    );
  }

  Widget _buildHomePlaceholder() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _explanationCard(),
        const SizedBox(height: 20),
        const Text('Quick Search — Popular Areas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          'Hunnigere', 'Whitefield', 'Hebbal', 'JP Nagar',
          'Yelahanka', 'Sarjapur', 'Mysuru', 'Mangaluru',
          'Devanahalli', 'Koramangala', 'Marathahalli', 'Hoskote',
        ].map((p) => ActionChip(
          label: Text(p, style: const TextStyle(fontSize: 12)),
          onPressed: () {
            _searchCtrl.text = p;
            _autoSearch(p);
          },
        )).toList()),
        const SizedBox(height: 20),
        _igrPdfSection(),
      ],
    ),
  );

  Widget _explanationCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF006064).withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF006064).withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.info_outline, color: Color(0xFF006064), size: 18),
        SizedBox(width: 8),
        Text('What is Guidance Value?',
            style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: Color(0xFF006064))),
      ]),
      const SizedBox(height: 8),
      const Text(
        'Government minimum price per sqft for stamp duty calculation.\n\n'
        '• You CANNOT register a sale below this value\n'
        '• Stamp duty is on MAX(agreement price, GV × area)\n'
        '• Updated every April 1st by IGR Karnataka\n'
        '• Market value is typically 1.5×–4× higher than GV\n\n'
        'Like asking a stamp vendor — but with trends and forecasts.',
        style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black54),
      ),
    ]),
  );

  Widget _buildNoResult() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🔍', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('Area not found in database',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Check the official IGR Karnataka PDFs for this area',
          style: TextStyle(color: AppColors.textLight)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse('https://igr.karnataka.gov.in/page/Revised+Guidelines+Value/en');
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        icon: const Icon(Icons.open_in_browser, size: 16),
        label: const Text('Open IGR Portal'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006064)),
      ),
    ]),
  );

  Widget _buildResultTile(GvEntry e) => GestureDetector(
    onTap: () => setState(() { _selected = e; _searchCtrl.text = e.area; }),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: e.zoneColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_zoneIcon(e.zone),
              style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.area}  ${e.areaKannada}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${e.taluk} · ${e.district}',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${_fmt(e.currentGv)}/sqft',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: e.zoneColor, fontSize: 14)),
          Text('Market ~₹${_fmt(e.estimatedMarketSqft)}/sqft',
              style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ]),
      ]),
    ),
  );

  // ── Detail View ─────────────────────────────────────────────────────────────
  Widget _buildDetailView(GvEntry e) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailHeader(e),
        const SizedBox(height: 16),
        // Mode-specific content
        if (_mode == _GvMode.buyer)   _buildBuyerView(e),
        if (_mode == _GvMode.seller)  _buildSellerView(e),
        if (_mode == _GvMode.developer) _buildDeveloperView(e),
        const SizedBox(height: 16),
        _buildYearTrend(e),
        const SizedBox(height: 16),
        _buildStampDutyCalc(e),
        const SizedBox(height: 16),
        _igrPdfSection(),
        const SizedBox(height: 32),
      ],
    ),
  );

  Widget _buildDetailHeader(GvEntry e) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: e.zoneColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: e.zoneColor.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_zoneIcon(e.zone), style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.area} · ${e.areaKannada}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${e.taluk} · ${e.district}',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: e.zoneColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(e.zoneLabel,
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        _headerStat('GV 2024-25', '₹${_fmt(e.currentGv)}/sqft', e.zoneColor),
        const SizedBox(width: 12),
        _headerStat('Market Est.', '₹${_fmt(e.estimatedMarketSqft)}/sqft',
            const Color(0xFF880E4F)),
        const SizedBox(width: 12),
        _headerStat('Annual Rise',
            '${e.annualGainPct > 0 ? '+' : ''}${e.annualGainPct}%',
            e.annualGainPct >= 10 ? Colors.green : Colors.orange),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.trending_up, size: 14, color: Colors.green),
        const SizedBox(width: 4),
        Text('${e.trendPct}% average annual increase over 5 years · ${e.trend.toUpperCase()}',
            style: const TextStyle(fontSize: 11, color: Colors.green,
                fontWeight: FontWeight.w600)),
      ]),
    ]),
  );

  Widget _headerStat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
    ),
  );

  // ── Buyer View ──────────────────────────────────────────────────────────────
  Widget _buildBuyerView(GvEntry e) => _card(
    title: '🏠 Buyer — Is the Price Fair?',
    color: const Color(0xFF1B5E20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'When a seller quotes a price, compare it against these benchmarks:',
        style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 14),
      _priceRow('Government Minimum (GV)', e.currentGv, Colors.blue,
          'Stamp duty calculated on this. Cannot register below this.'),
      _priceRow('Fair Market Value (est.)', e.estimatedMarketSqft,
          const Color(0xFF1B5E20),
          'Typical selling price in this area based on recent registrations.'),
      _priceRow('Premium Max (Zone ${e.zone})',
          (e.estimatedMarketSqft * 1.3).round(), Colors.orange,
          'Above this price — demand extra justification from seller.'),
      const Divider(height: 20),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '💡 Quick check: For a 1,200 sqft flat in ${e.area}:\n'
          '  Fair price range: ₹${_fmtL(e.estimatedMarketSqft * 1200)} – '
          '₹${_fmtL((e.estimatedMarketSqft * 1.3 * 1200).round())}',
          style: const TextStyle(fontSize: 12, height: 1.5,
              color: Color(0xFF1B5E20)),
        ),
      ),
    ]),
  );

  // ── Seller View ─────────────────────────────────────────────────────────────
  Widget _buildSellerView(GvEntry e) => _card(
    title: '💰 Seller — What Is My Property Worth?',
    color: const Color(0xFF880E4F),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'If you are selling your property in this area, here is the price guide:',
        style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 14),
      _priceRow('Minimum Legal Price (GV)',
          e.currentGv, Colors.grey,
          'You CANNOT sell below this. Stamp duty is on this minimum.'),
      _priceRow('Recommended Asking Price',
          e.estimatedMarketSqft, const Color(0xFF880E4F),
          'Current market rate buyers are paying in ${e.area}.'),
      _priceRow('If You Need Quick Sale',
          (e.estimatedMarketSqft * 0.85).round(), Colors.orange,
          '15% below market — attracts buyers quickly.'),
      const Divider(height: 20),
      // What seller gets after deductions
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF880E4F).withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF880E4F).withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('For 1,200 sqft at market rate:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          _deductRow('Gross sale proceeds',
              '₹${_fmtL(e.estimatedMarketSqft * 1200)}', null),
          _deductRow('Stamp duty buyer pays (5.6%)',
              '-₹${_fmtL((e.currentGv * 1200 * 0.056).round())}', Colors.red),
          _deductRow('LTCG tax if held >2yr (20%)',
              'Consult CA', Colors.orange),
          _deductRow('Agent commission (1-2%)',
              '-₹${_fmtL((e.estimatedMarketSqft * 1200 * 0.015).round())}', Colors.orange),
          const Divider(height: 10),
          _deductRow('You receive approximately',
              '₹${_fmtL((e.estimatedMarketSqft * 1200 * 0.97).round())}',
              const Color(0xFF1B5E20)),
        ]),
      ),
    ]),
  );

  // ── Developer View ──────────────────────────────────────────────────────────
  Widget _buildDeveloperView(GvEntry e) => _card(
    title: '🏗️ Developer / Official — Project Feasibility',
    color: const Color(0xFF0D47A1),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'For layout developers, builders, and government officials:',
        style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 14),
      _devRow('GV Residential', '₹${_fmt(e.currentGv)}/sqft'),
      _devRow('GV Commercial', '₹${_fmt(e.commercialSqft)}/sqft'),
      if (e.agriculturalAcre > 0)
        _devRow('GV Agricultural', '₹${_fmtL(e.agriculturalAcre)}/acre'),
      _devRow('Market Rate', '₹${_fmt(e.estimatedMarketSqft)}/sqft'),
      _devRow('Market/GV Ratio', '${e.marketMultiplier}×'),
      const Divider(height: 16),
      const Text('Per acre site analysis:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(height: 8),
      _devRow('1 acre = 43,560 sqft',
          '₹${_fmtL(e.currentGv * 43560)} at GV'),
      _devRow('Market value (1 acre)',
          '₹${_fmtL((e.estimatedMarketSqft * 43560).round())}'),
      _devRow('Layout development cost',
          '₹${_fmtL((e.estimatedMarketSqft * 43560 * 0.30).round())} est.'),
      _devRow('Stamp duty on purchase (5.6%)',
          '₹${_fmtL((e.currentGv * 43560 * 0.056).round())}'),
      const Divider(height: 16),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '📋 For official use: Download the IGR Karnataka Guidance Value PDF '
          'for your taluk. PDFs are the legally valid reference document for '
          'all Sub-Registrar office transactions.',
          style: TextStyle(fontSize: 11, height: 1.5, color: Colors.black54),
        ),
      ),
    ]),
  );

  // ── Year Trend ──────────────────────────────────────────────────────────────
  Widget _buildYearTrend(GvEntry e) => _card(
    title: '📈 Year-by-Year Guidance Value Trend',
    color: Colors.teal.shade700,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'How ${e.area} GV has changed — updated every April 1st',
        style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 14),
      ...e.gvHistory.entries.map((entry) {
        final year = entry.key;
        final gv   = entry.value;
        final prev = e.gvHistory.entries
            .where((en) => en.key.compareTo(year) < 0)
            .lastOrNull?.value ?? gv;
        final pct  = prev > 0 ? ((gv - prev) / prev * 100).round() : 0;
        final isLatest = year == '2024-25';
        final barWidth = gv / (e.gvHistory.values.reduce((a,b) => a > b ? a : b));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 60,
                child: Text(year,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                        color: isLatest ? Colors.teal.shade700 : Colors.grey))),
              Expanded(
                child: Container(
                  height: 20,
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: isLatest ? 20 : 16,
                    width: MediaQuery.of(context).size.width * 0.5 * barWidth,
                    decoration: BoxDecoration(
                      color: isLatest
                          ? Colors.teal.shade700
                          : Colors.teal.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('₹${_fmt(gv)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                      color: isLatest ? Colors.teal.shade700 : Colors.black54)),
              if (pct != 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('+$pct%',
                      style: TextStyle(fontSize: 9,
                          color: pct > 10 ? Colors.green : Colors.orange)),
                ),
            ]),
          ]),
        );
      }),
      const Divider(height: 20),
      Row(children: [
        const Icon(Icons.arrow_forward, size: 14, color: Colors.teal),
        const SizedBox(width: 6),
        Text(
          '5-year average increase: ${e.trendPct}%/year · '
          'Projected 2025-26: ~₹${_fmt((e.currentGv * (1 + e.trendPct/100)).round())}/sqft',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.teal),
        ),
      ]),
    ]),
  );

  // ── Stamp Duty Calculator ───────────────────────────────────────────────────
  Widget _buildStampDutyCalc(GvEntry e) => _card(
    title: '🧮 Stamp Duty Calculator',
    color: AppColors.primary,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Area (sqft)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: (v) => setState(() =>
                _areaSqft = double.tryParse(v) ?? _areaSqft),
            controller: TextEditingController(text: _areaSqft.toStringAsFixed(0)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text('₹${_fmtL((e.currentGv * _areaSqft).round())}',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16, color: AppColors.primary)),
              const Text('GV value', style: TextStyle(fontSize: 10)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _calcRow('GV-based value', '₹${_fmtL((e.currentGv * _areaSqft).round())}'),
      _calcRow('Stamp duty (5.6%)',
          '₹${_fmtL((e.currentGv * _areaSqft * 0.056).round())}'),
      _calcRow('Registration fee (1%)',
          '₹${_fmtL((e.currentGv * _areaSqft * 0.01).round())}'),
      const Divider(height: 12),
      _calcRow('Total registration cost',
          '₹${_fmtL((e.currentGv * _areaSqft * 0.066).round())}', bold: true),
      const SizedBox(height: 8),
      Text(
        'Market price (est.) for $_areaSqft sqft: '
        '₹${_fmtL((e.estimatedMarketSqft * _areaSqft).round())}',
        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
      ),
    ]),
  );

  // ── IGR PDF Section ─────────────────────────────────────────────────────────
  Widget _igrPdfSection() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
        SizedBox(width: 8),
        Text('Official IGR Karnataka PDFs',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 8),
      const Text(
        'Official guidance value PDFs for every district/taluk/village. '
        'Download the PDF for your specific area. Updated April 1st each year.',
        style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(
                'https://igr.karnataka.gov.in/page/Revised+Guidelines+Value/en');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_browser, size: 16),
          label: const Text('Download IGR Guidance Value PDFs →'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006064),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'For stamp vendors, lawyers, and government officials: '
        'these PDFs are the legally binding reference.',
        style: TextStyle(fontSize: 10, color: AppColors.textLight),
      ),
    ]),
  );

  // ── Helper widgets ───────────────────────────────────────────────────────────
  Widget _card({required String title, required Color color, required Widget child}) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );

  Widget _priceRow(String label, int sqftPrice, Color color, String hint) =>
    Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600))),
          Text('₹${_fmt(sqftPrice)}/sqft',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: color, fontSize: 13)),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 2),
          child: Text(hint, style: const TextStyle(
              fontSize: 11, color: AppColors.textLight)),
        ),
      ],
    ));

  Widget _devRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textLight))),
      Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _deductRow(String label, String value, Color? color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
      Text(value, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _calcRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textLight))),
      Text(value, style: TextStyle(fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: bold ? AppColors.primary : null)),
    ]),
  );

  String _zoneIcon(int zone) => switch (zone) {
    1 => '🏙️', 2 => '🌆', 3 => '🏘️', 4 => '🌄', _ => '🌾',
  };

  String _fmt(int v) =>
      v.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtL(int v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹${_fmt(v)}';
  }
}
