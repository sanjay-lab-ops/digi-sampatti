import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

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
  String? _locality;

  // Step 2
  String? _propertyType;

  static const _districts = [
    'Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru',
    'Belagavi', 'Kalaburagi', 'Ballari', 'Dharwad', 'Shivamogga',
    'Hassan', 'Tumakuru', 'Udupi', 'Haveri', 'Davanagere',
  ];

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
      case 0: return _Step1Search(key: const ValueKey(0), onNext: (d, l) {
        setState(() { _district = d; _locality = l; _step = 1; });
      });
      case 1: return _Step2PropertyType(key: const ValueKey(1), onNext: (t) {
        setState(() { _propertyType = t; _step = 2; });
      });
      case 2: return _Step3Listings(key: const ValueKey(2),
        district: _district ?? 'Bengaluru Urban',
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
  final void Function(String district, String? locality) onNext;
  const _Step1Search({super.key, required this.onNext});
  @override
  State<_Step1Search> createState() => _Step1SearchState();
}

class _Step1SearchState extends State<_Step1Search> {
  String? _district;
  final _localityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _budget;
  String? _bhk;
  bool _showFilters = false;

  static const _budgets = ['Under ₹30L', '₹30L–60L', '₹60L–1Cr', '₹1Cr–2Cr', 'Above ₹2Cr'];
  static const _bhkOpts = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '4+ BHK', 'Any'];

  @override
  void dispose() { _localityCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 1 of 4', 'Where do you want to buy?', Icons.location_on_outlined, AppColors.primary),
        const SizedBox(height: 20),
        // Search by description
        TextFormField(
          controller: _descCtrl,
          decoration: _inputDeco('Search by description (e.g. "3BHK near metro")').copyWith(
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        // State (fixed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor)),
          child: const Row(children: [
            Icon(Icons.map_outlined, size: 16, color: AppColors.textLight),
            SizedBox(width: 8),
            Text('State: Karnataka', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _district,
          hint: const Text('Select District *'),
          decoration: _inputDeco('District'),
          items: _BuyerHomeScreenState._districts.map((d) =>
            DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _district = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _localityCtrl,
          decoration: _inputDeco('Locality / Area (optional)'),
        ),
        const SizedBox(height: 12),
        // Filters toggle
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
            onPressed: _district == null ? null : () => widget.onNext(
              _district!, _localityCtrl.text.trim().isEmpty ? null : _localityCtrl.text.trim()),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text('Next: Choose Property Type →', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
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
  final String? locality;
  final VoidCallback onViewDocs;
  const _Step3Listings({super.key, required this.district, required this.propertyType,
    this.locality, required this.onViewDocs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader('Step 3 of 4', 'Available Listings', Icons.home_work_outlined, AppColors.safe),
        const SizedBox(height: 8),
        // Location chip
        Wrap(spacing: 8, children: [
          _Chip(Icons.location_on_outlined, district, AppColors.primary),
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
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pay ₹99 to contact seller securely'))),
            icon: const Icon(Icons.chat_outlined, size: 14),
            label: const Text('Contact — ₹99', style: TextStyle(fontSize: 12)),
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
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 24),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('All documents checked!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.safe)),
                Text('Now upload them for AI verification (0–100 score)', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/upload'),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Upload & Verify with AI →'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.safe),
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
