import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/location_service.dart';
import 'package:digi_sampatti/core/widgets/searchable_picker.dart';

// ─── Documents required per property type ─────────────────────────────────────
const _docsMap = {
  'Apartment / Flat': [
    ('Sale Deed / Agreement to Sell', 'Primary ownership proof'),
    ('Encumbrance Certificate (EC)', 'No loan/mortgage on property'),
    ('Khata Certificate + Extract', 'BBMP/BDA registration status'),
    ('Occupancy Certificate (OC)', 'Construction is legal & complete'),
    ('RERA Registration', 'Project is RERA approved'),
    ('Share Certificate', 'Flat ownership in society'),
    ('Building Plan Approval', 'Sanctioned layout from authority'),
    ('Property Tax Receipts', 'Last 3 years paid'),
  ],
  'House / Independent Villa': [
    ('Sale Deed', 'Primary ownership proof'),
    ('RTC (Pahani)', 'Revenue record for land'),
    ('Encumbrance Certificate', 'No pending loans/mortgages'),
    ('Khata Certificate + Extract', 'Municipal body registration'),
    ('Building Plan Sanction', 'Construction approval from BDA/BBMP'),
    ('DC Conversion Certificate', 'Agricultural → non-agricultural'),
    ('Property Tax Receipts', 'Last 3 years paid'),
    ('Mutation Records', 'Title transfer history'),
  ],
  'Plot / Land': [
    ('Sale Deed / Title Deed', 'Ownership proof'),
    ('RTC (Record of Rights)', 'Revenue dept. land record'),
    ('Encumbrance Certificate', 'Free from loans/mortgages'),
    ('Survey Sketch (FMB)', 'Boundary map from Survey Dept.'),
    ('DC Conversion Certificate', 'If non-agricultural use intended'),
    ('Mutation Records', 'Previous owner chain'),
    ('Katha Certificate', 'BBMP/Panchayat record'),
    ('Betterment Charges Receipt', 'BDA / BBMP dues cleared'),
  ],
  'Commercial Property': [
    ('Sale Deed', 'Ownership proof'),
    ('Encumbrance Certificate', 'No pending charges'),
    ('Occupancy Certificate', 'Building is legally habitable'),
    ('Fire NOC', 'Fire safety clearance'),
    ('Building Plan Sanction', 'Approved layout'),
    ('GST Registration of Seller', 'For commercial transactions'),
    ('Property Tax Receipts', 'Current & up to date'),
    ('Lease Agreement (if any)', 'Existing tenant details'),
  ],
  'Agricultural Land': [
    ('RTC (Pahani)', 'Primary land record'),
    ('Mutation Records', 'Ownership history'),
    ('Survey Sketch (FMB)', 'Boundary & measurement'),
    ('Land Use Certificate', 'Confirms agricultural zoning'),
    ('Encumbrance Certificate', 'No loans/mortgages'),
    ('Aakara Banda', 'Land revenue assessment'),
    ('Nil-Tenancy Certificate', 'No tenant occupying land'),
  ],
};

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});
  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  int _step = 0; // 0=search, 1=property type, 2=listings, 3=documents

  // Step 1
  String? _district;
  String? _taluk;
  String? _locality;

  // Step 2
  String? _propertyType;

  // Location data loaded from JSON — no hardcoded lists here

  static const _propertyTypes = [
    'Apartment / Flat',
    'House / Independent Villa',
    'Plot / Land',
    'Commercial Property',
    'Agricultural Land',
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_step > 0) setState(() => _step--);
          else context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("I'm a Buyer"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_step > 0) setState(() => _step--);
              else context.go('/home');
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: _StepProgressBar(current: _step, total: 4),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _Step1Search(key: const ValueKey(0), onNext: (d, t, l) {
        setState(() { _district = d; _taluk = t; _locality = l; _step = 1; });
      });
      case 1: return _Step2PropertyType(key: const ValueKey(1), onNext: (t) {
        setState(() { _propertyType = t; _step = 2; });
      });
      case 2: return _Step3Listings(key: const ValueKey(2),
        district: _district ?? 'Bengaluru Urban',
        taluk: _taluk,
        locality: _locality,
        propertyType: _propertyType ?? 'Apartment / Flat',
        onViewDocs: () => setState(() => _step = 3),
      );
      case 3: return _Step4Documents(key: const ValueKey(3),
        propertyType: _propertyType ?? 'Apartment / Flat',
        district: _district ?? 'Bengaluru Urban',
      );
      default: return const SizedBox.shrink();
    }
  }
}

class _StepProgressBar extends StatelessWidget {
  final int current, total;
  const _StepProgressBar({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          height: 3,
          margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
          color: i <= current ? AppColors.primary : AppColors.borderColor,
        ),
      )),
    );
  }
}

// ─── Step 1: Location Search ──────────────────────────────────────────────────
class _Step1Search extends StatefulWidget {
  final void Function(String district, String? taluk, String? locality) onNext;
  const _Step1Search({super.key, required this.onNext});
  @override
  State<_Step1Search> createState() => _Step1SearchState();
}

class _Step1SearchState extends State<_Step1Search> {
  // All district data loaded from JSON asset
  List<KaDistrict> _allDistricts = [];
  bool _loaded = false;

  KaDistrict? _district;
  KaTaluk? _taluk;
  String? _village;
  SroOffice? _sro;

  String? _budget;
  String? _bhk;
  bool _showFilters = false;

  static const _budgets = ['Under ₹30L', '₹30L–60L', '₹60L–1Cr', '₹1Cr–2Cr', 'Above ₹2Cr'];
  static const _bhkOpts = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '4+ BHK', 'Any'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final districts = await LocationService.instance.getDistricts();
    if (mounted) setState(() { _allDistricts = districts; _loaded = true; });
  }

  Future<void> _pickDistrict() async {
    final picked = await showSearchablePicker<KaDistrict>(
      context: context,
      title: 'Select District',
      items: _allDistricts,
      label: (d) => d.name,
      selected: _district,
      hint: 'Type district name...',
    );
    if (picked != null && picked.name != _district?.name) {
      final sros = await LocationService.instance.getSrosForDistrict(picked.name);
      setState(() { _district = picked; _taluk = null; _village = null; _sro = sros.isNotEmpty ? sros.first : null; });
    }
  }

  Future<void> _pickTaluk() async {
    if (_district == null) return;
    final picked = await showSearchablePicker<KaTaluk>(
      context: context,
      title: 'Select Taluk',
      items: _district!.taluks,
      label: (t) => t.name,
      selected: _taluk,
      hint: 'Type taluk name...',
    );
    if (picked != null) {
      final sro = await LocationService.instance.getSroForTaluk(picked.name);
      setState(() { _taluk = picked; _village = null; _sro = sro; });
    }
  }

  Future<void> _pickVillage() async {
    if (_taluk == null) return;
    final picked = await showSearchablePicker<String>(
      context: context,
      title: 'Select Village / Area',
      items: _taluk!.villages,
      label: (v) => v,
      selected: _village,
      hint: 'Type village name...',
    );
    if (picked != null) setState(() => _village = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 1 of 4', 'Where do you want to buy?', Icons.location_on_outlined, AppColors.primary),
        const SizedBox(height: 20),

        // ── State (fixed) ────────────────────────────────────────────────
        _PickerTile(
          icon: Icons.map_outlined,
          label: 'State',
          value: 'Karnataka',
          locked: true,
          onTap: null,
        ),
        const SizedBox(height: 10),

        // ── District picker ──────────────────────────────────────────────
        _PickerTile(
          icon: Icons.location_city_outlined,
          label: 'District *',
          value: _district?.name,
          placeholder: 'Tap to select district',
          onTap: _pickDistrict,
        ),

        // ── Taluk picker (shown after district) ──────────────────────────
        if (_district != null) ...[
          const SizedBox(height: 10),
          _PickerTile(
            icon: Icons.account_tree_outlined,
            label: 'Taluk *',
            value: _taluk?.name,
            placeholder: 'Tap to select taluk',
            onTap: _pickTaluk,
          ),
        ],

        // ── Village picker (shown after taluk) ───────────────────────────
        if (_taluk != null) ...[
          const SizedBox(height: 10),
          _PickerTile(
            icon: Icons.villa_outlined,
            label: 'Village / Area',
            value: _village,
            placeholder: 'Tap to select village (optional)',
            onTap: _pickVillage,
          ),
        ],

        const SizedBox(height: 14),
        // ── Filters toggle ───────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _showFilters = !_showFilters),
          child: Row(children: [
            const Icon(Icons.tune, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(_showFilters ? 'Hide Filters' : 'Add Filters (Budget, BHK)',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            Icon(_showFilters ? Icons.expand_less : Icons.expand_more, color: AppColors.primary, size: 18),
          ]),
        ),
        if (_showFilters) ...[
          const SizedBox(height: 12),
          const Text('Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: _budgets.map((b) => GestureDetector(
            onTap: () => setState(() => _budget = _budget == b ? null : b),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _budget == b ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _budget == b ? AppColors.primary : AppColors.borderColor),
              ),
              child: Text(b, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: _budget == b ? Colors.white : AppColors.textDark)),
            ),
          )).toList()),
          const SizedBox(height: 12),
          const Text('BHK / Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: _bhkOpts.map((b) => GestureDetector(
            onTap: () => setState(() => _bhk = _bhk == b ? null : b),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bhk == b ? AppColors.info : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _bhk == b ? AppColors.info : AppColors.borderColor),
              ),
              child: Text(b, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: _bhk == b ? Colors.white : AppColors.textDark)),
            ),
          )).toList()),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_district == null || _taluk == null) ? null : () => widget.onNext(
              _district!.name, _taluk!.name, _village),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text('Next: Choose Property Type →', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ── Picker tile widget ──────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final bool locked;
  final VoidCallback? onTap;
  const _PickerTile({required this.icon, required this.label, this.value,
    this.placeholder, this.locked = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? AppColors.primary.withOpacity(0.5) : AppColors.borderColor,
            width: hasValue ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: hasValue ? AppColors.primary : AppColors.textLight),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value ?? placeholder ?? '',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: hasValue ? AppColors.textDark : AppColors.textLight,
              )),
          ])),
          if (!locked)
            Icon(Icons.chevron_right, size: 18,
              color: hasValue ? AppColors.primary : AppColors.textLight),
        ]),
      ),
    );
  }
}

// ── Location intelligence panel ─────────────────────────────────────────────
class _LocationIntelPanel extends StatelessWidget {
  final KaDistrict district;
  final KaTaluk? taluk;
  final SroOffice? sro;
  const _LocationIntelPanel({required this.district, this.taluk, this.sro});

  // Static AI-style guidance per property research context
  static const _guidance = [
    'Check RTC (Bhoomi) for owner name, khata number, land type',
    'Obtain EC (Encumbrance Certificate) for last 30 years from Kaveri portal',
    'Verify DC Conversion if buying plot/land for residential use',
    'Confirm no court injunction or pending litigation on title',
  ];

  static const _risks = [
    'B Khata properties — banks will not give home loans',
    'Revenue sites without DC conversion — demolition risk',
    'Properties near Raja Kaluve (storm drain buffer zone)',
    'Lake bed / FTL encroachments — legally invalidated',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.insights_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('${district.name}${taluk != null ? ' · ${taluk!.name}' : ''} — Property Intelligence',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Guidance value
            _InfoRow(Icons.bar_chart_outlined, 'Guidance Value', district.guidance, AppColors.safe),
            const SizedBox(height: 10),

            // SRO info
            if (sro != null) ...[
              _InfoRow(Icons.business_outlined, 'SRO Office', sro!.name, AppColors.info),
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 2, bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sro!.address, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4)),
                  const SizedBox(height: 2),
                  Text('${sro!.phone}  ·  ${sro!.hours}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                ]),
              ),
            ],

            const Divider(height: 20),

            // AI Guidance bullets
            const Text('Key Checks for This Location',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            ..._guidance.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle_outline, size: 13, color: AppColors.safe),
                const SizedBox(width: 6),
                Expanded(child: Text(g, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4))),
              ]),
            )),

            const SizedBox(height: 10),
            const Text('Common Risks to Watch',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            ..._risks.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_outlined, size: 13, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4))),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
    ]);
  }
}

// ─── Step 2: Property Type ────────────────────────────────────────────────────
class _Step2PropertyType extends StatefulWidget {
  final void Function(String type) onNext;
  const _Step2PropertyType({super.key, required this.onNext});
  @override
  State<_Step2PropertyType> createState() => _Step2PropertyTypeState();
}

class _Step2PropertyTypeState extends State<_Step2PropertyType> {
  String? _selected;

  static const _types = [
    ('Apartment / Flat',         Icons.apartment_outlined,         '🏢', Color(0xFF1565C0)),
    ('House / Independent Villa',Icons.home_outlined,               '🏠', Color(0xFF2E7D32)),
    ('Plot / Land',              Icons.landscape_outlined,          '🌿', Color(0xFF5D4037)),
    ('Commercial Property',      Icons.business_outlined,           '🏬', Color(0xFF6A1B9A)),
    ('Agricultural Land',        Icons.agriculture_outlined,        '🌾', Color(0xFF558B2F)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 2 of 4', 'What type of property?', Icons.category_outlined, AppColors.info),
        const SizedBox(height: 20),
        ..._types.map((t) => _TypeCard(
          title: t.$1, icon: t.$2, emoji: t.$3, color: t.$4,
          selected: _selected == t.$1,
          onTap: () => setState(() => _selected = t.$1),
        )),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected == null ? null : () => widget.onNext(_selected!),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text('Next: View Listings →', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title, emoji;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({required this.title, required this.icon, required this.emoji,
    required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.borderColor, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: selected ? color : AppColors.textDark))),
          if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20)
          else const Icon(Icons.radio_button_unchecked, color: AppColors.textLight, size: 20),
        ]),
      ),
    );
  }
}

// ─── Step 3: Listings ─────────────────────────────────────────────────────────
class _Step3Listings extends StatelessWidget {
  final String district, propertyType;
  final String? taluk;
  final String? locality;
  final VoidCallback onViewDocs;
  const _Step3Listings({super.key, required this.district, required this.propertyType,
    this.taluk, this.locality, required this.onViewDocs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 3 of 4', 'Available Listings', Icons.home_work_outlined, AppColors.safe),
        const SizedBox(height: 8),
        // Location chip
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Chip(Icons.map_outlined, 'Karnataka', AppColors.primary),
          _Chip(Icons.location_city_outlined, district, AppColors.primary),
          if (taluk != null) _Chip(Icons.location_on_outlined, taluk!, AppColors.info),
          if (locality != null) _Chip(Icons.near_me_outlined, locality!, AppColors.info),
          _Chip(Icons.category_outlined, propertyType, AppColors.warning),
        ]),
        const SizedBox(height: 16),
        // Doc checklist reminder
        GestureDetector(
          onTap: onViewDocs,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.checklist_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Before viewing any property: know the ${_docsMap[propertyType]?.length ?? 7} documents you must check for $propertyType.',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              )),
              const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // Sample listings
        ..._buildListings(context),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/marketplace'),
          icon: const Icon(Icons.grid_view_outlined, size: 16),
          label: const Text('View All Listings'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        ),
      ]),
    );
  }

  List<Widget> _buildListings(BuildContext context) {
    final listings = _sampleListings(propertyType, district);
    return listings.map((l) => _ListingCard(listing: l, onViewDocs: onViewDocs)).toList();
  }

  List<_Listing> _sampleListings(String type, String district) => [
    _Listing('${type.split('/').first.trim()} in $district',
      '₹${type.contains('Plot') ? '45' : type.contains('Commercial') ? '1.2 Cr' : '85'} Lakhs',
      '${type.contains('Plot') ? '1200' : '1450'} sq.ft', '3 BHK', 'Verified Seller',
      Icons.verified_outlined, AppColors.safe),
    _Listing('Premium ${type.split('/').first.trim()}',
      '₹${type.contains('Plot') ? '62' : '1.1 Cr'} Lakhs',
      '${type.contains('Plot') ? '2400' : '2100'} sq.ft', '4 BHK', 'Document Pending',
      Icons.pending_outlined, AppColors.warning),
    _Listing('Budget ${type.split('/').first.trim()}',
      '₹${type.contains('Plot') ? '28' : '55'} Lakhs',
      '950 sq.ft', '2 BHK', 'Unverified',
      Icons.warning_amber_outlined, AppColors.danger),
  ];
}

class _Listing {
  final String title, price, area, config, status;
  final IconData statusIcon;
  final Color statusColor;
  const _Listing(this.title, this.price, this.area, this.config, this.status, this.statusIcon, this.statusColor);
}

class _ListingCard extends StatelessWidget {
  final _Listing listing;
  final VoidCallback onViewDocs;
  const _ListingCard({required this.listing, required this.onViewDocs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: listing.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(listing.statusIcon, size: 12, color: listing.statusColor),
              const SizedBox(width: 4),
              Text(listing.status, style: TextStyle(fontSize: 10, color: listing.statusColor, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text(listing.price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Spacer(),
          Text('${listing.area} · ${listing.config}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onViewDocs,
            icon: const Icon(Icons.checklist, size: 14),
            label: const Text('Check Docs', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8),
              foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => context.push('/deal-connect', extra: {
              'propertyTitle': listing.title,
              'sellerName': 'Seller',
              'price': listing.price,
            }),
            icon: const Icon(Icons.handshake_outlined, size: 14),
            label: const Text('Start Deal', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
          )),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Step 4: Document Checklist ───────────────────────────────────────────────
class _Step4Documents extends StatefulWidget {
  final String propertyType, district;
  const _Step4Documents({super.key, required this.propertyType, required this.district});
  @override
  State<_Step4Documents> createState() => _Step4DocumentsState();
}

class _Step4DocumentsState extends State<_Step4Documents> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final docs = _docsMap[widget.propertyType] ?? _docsMap['Apartment / Flat']!;
    final allChecked = _checked.length == docs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 4 of 4', 'Documents to Verify', Icons.checklist_outlined, AppColors.warning),
        const SizedBox(height: 4),
        Text('For ${widget.propertyType} in ${widget.district}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 16),
        // Progress
        LinearProgressIndicator(
          value: docs.isEmpty ? 0 : _checked.length / docs.length,
          backgroundColor: AppColors.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(allChecked ? AppColors.safe : AppColors.primary),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 6),
        Text('${_checked.length} of ${docs.length} verified',
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 16),
        ...docs.asMap().entries.map((e) => _DocCheckItem(
          index: e.key,
          title: e.value.$1,
          subtitle: e.value.$2,
          checked: _checked.contains(e.key),
          onToggle: () => setState(() {
            if (_checked.contains(e.key)) _checked.remove(e.key);
            else _checked.add(e.key);
          }),
        )),
        const SizedBox(height: 20),
        if (allChecked) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.safe.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.safe.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 24),
                SizedBox(width: 10),
                Text('Checklist complete!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.safe)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'You have reviewed all required documents. The seller\'s listing has been AI-verified by DigiSampatti.',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _VerifyChip(Icons.verified, 'EC Checked', AppColors.safe),
                const SizedBox(width: 6),
                _VerifyChip(Icons.verified, 'RERA Valid', AppColors.safe),
                const SizedBox(width: 6),
                _VerifyChip(Icons.verified, 'No Disputes', AppColors.safe),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/deal-connect'),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Connect with Seller — Pay ₹99 →'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary),
          ),
        ] else
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: Text('Check all ${docs.length - _checked.length} remaining items to proceed'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/partners'),
          icon: const Icon(Icons.people_outline, size: 16),
          label: const Text('Need help? Talk to a lawyer'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _VerifyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _VerifyChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DocCheckItem extends StatelessWidget {
  final int index;
  final String title, subtitle;
  final bool checked;
  final VoidCallback onToggle;
  const _DocCheckItem({required this.index, required this.title, required this.subtitle,
    required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: checked ? AppColors.safe.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: checked ? AppColors.safe.withOpacity(0.4) : AppColors.borderColor),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: checked ? AppColors.safe : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: checked ? AppColors.safe : AppColors.textLight, width: 1.5),
            ),
            child: checked ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: checked ? AppColors.textDark : AppColors.textDark,
              decoration: checked ? TextDecoration.none : null)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
        ]),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final String step, title;
  final IconData icon;
  final Color color;
  const _StepHeader(this.step, this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
      ]),
    ]);
  }
}

InputDecoration _inputDeco(String label) => InputDecoration(
  labelText: label,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.borderColor)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);
