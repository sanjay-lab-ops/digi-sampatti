import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Property Marketplace — Amazon-style listing by locality ────────────────
// Buyers browse verified listings by city / locality / property type.
// Seller lists property → buyers see it → contact popup → escrow initiated.
// ────────────────────────────────────────────────────────────────────────────

// ─── Data models ─────────────────────────────────────────────────────────────
class PropertyListing {
  final String id;
  final String title;
  final String locality;
  final String city;
  final String state;
  final String propertyType; // 'Apartment', 'Villa', 'Plot', 'Commercial'
  final int    priceInLakhs;
  final double areaSqft;
  final int    bedrooms;
  final bool   isVerified;   // has Arth ID report
  final String sellerName;
  final String sellerPhone;
  final String sellerEmail;
  final List<String> highlights;
  final String postedDaysAgo;
  final int    views;

  const PropertyListing({
    required this.id,
    required this.title,
    required this.locality,
    required this.city,
    required this.state,
    required this.propertyType,
    required this.priceInLakhs,
    required this.areaSqft,
    required this.bedrooms,
    required this.isVerified,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerEmail,
    required this.highlights,
    required this.postedDaysAgo,
    required this.views,
  });
}

// ─── Mock listings (real data from database in production) ───────────────────
const List<PropertyListing> kMockListings = [
  PropertyListing(
    id: 'L001',
    title: '3BHK in Whitefield — Gated Community',
    locality: 'Whitefield',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Apartment',
    priceInLakhs: 95,
    areaSqft: 1450,
    bedrooms: 3,
    isVerified: true,
    sellerName: 'Rajesh Kumar',
    sellerPhone: '+91 98765 43210',
    sellerEmail: 'rajesh@example.com',
    highlights: ['A Khata', 'RERA registered', 'OC received', 'No encumbrance'],
    postedDaysAgo: '2 days ago',
    views: 148,
  ),
  PropertyListing(
    id: 'L002',
    title: '30×40 BDA Site — Yelahanka New Town',
    locality: 'Yelahanka',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Plot',
    priceInLakhs: 68,
    areaSqft: 1200,
    bedrooms: 0,
    isVerified: true,
    sellerName: 'Anitha Shetty',
    sellerPhone: '+91 97654 32109',
    sellerEmail: 'anitha@example.com',
    highlights: ['BDA approved layout', 'A Khata', 'DC conversion done', 'Clear title'],
    postedDaysAgo: '5 days ago',
    views: 92,
  ),
  PropertyListing(
    id: 'L003',
    title: '2BHK Apartment — JP Nagar 7th Phase',
    locality: 'JP Nagar',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Apartment',
    priceInLakhs: 72,
    areaSqft: 1100,
    bedrooms: 2,
    isVerified: false,
    sellerName: 'Mohammed Irfan',
    sellerPhone: '+91 96543 21098',
    sellerEmail: 'irfan@example.com',
    highlights: ['Ready to move', 'Near metro', '2 parking'],
    postedDaysAgo: '1 week ago',
    views: 67,
  ),
  PropertyListing(
    id: 'L004',
    title: '4BHK Villa — Electronic City Phase 1',
    locality: 'Electronic City',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Villa',
    priceInLakhs: 165,
    areaSqft: 2800,
    bedrooms: 4,
    isVerified: true,
    sellerName: 'Priya Nair',
    sellerPhone: '+91 95432 10987',
    sellerEmail: 'priya@example.com',
    highlights: ['Independent villa', 'A Khata', 'RERA compliant', 'Vastu compliant'],
    postedDaysAgo: '3 days ago',
    views: 203,
  ),
  PropertyListing(
    id: 'L005',
    title: '1BHK Flat — Sarjapur Road',
    locality: 'Sarjapur Road',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Apartment',
    priceInLakhs: 42,
    areaSqft: 650,
    bedrooms: 1,
    isVerified: false,
    sellerName: 'Suresh Reddy',
    sellerPhone: '+91 94321 09876',
    sellerEmail: 'suresh@example.com',
    highlights: ['First resale', 'No broker', 'Direct seller'],
    postedDaysAgo: '2 weeks ago',
    views: 34,
  ),
  PropertyListing(
    id: 'L006',
    title: 'Commercial Shop — Koramangala 5th Block',
    locality: 'Koramangala',
    city: 'Bengaluru',
    state: 'Karnataka',
    propertyType: 'Commercial',
    priceInLakhs: 120,
    areaSqft: 800,
    bedrooms: 0,
    isVerified: true,
    sellerName: 'Deepa Sharma',
    sellerPhone: '+91 93210 98765',
    sellerEmail: 'deepa@example.com',
    highlights: ['Prime location', 'Running business possible', 'BBMP registered'],
    postedDaysAgo: '4 days ago',
    views: 177,
  ),
  PropertyListing(
    id: 'L007',
    title: '3BHK Independent House — Mysuru',
    locality: 'Vijayanagar',
    city: 'Mysuru',
    state: 'Karnataka',
    propertyType: 'Villa',
    priceInLakhs: 85,
    areaSqft: 2200,
    bedrooms: 3,
    isVerified: true,
    sellerName: 'Venkatesh Gowda',
    sellerPhone: '+91 92109 87654',
    sellerEmail: 'venkatesh@example.com',
    highlights: ['Independent house', 'Large garden', 'Clear title 30 years', 'EC clean'],
    postedDaysAgo: '1 week ago',
    views: 81,
  ),
];

// ─── Providers ────────────────────────────────────────────────────────────────
final _selectedCityProvider    = StateProvider<String>((ref) => 'All');
final _selectedTypeProvider    = StateProvider<String>((ref) => 'All');
final _searchQueryProvider     = StateProvider<String>((ref) => '');
final _verifiedOnlyProvider    = StateProvider<bool>((ref) => false);

// ─── Screen ────────────────────────────────────────────────────────────────────
class PropertyListingScreen extends ConsumerStatefulWidget {
  const PropertyListingScreen({super.key});

  @override
  ConsumerState<PropertyListingScreen> createState() =>
      _PropertyListingScreenState();
}

class _PropertyListingScreenState extends ConsumerState<PropertyListingScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PropertyListing> get _filtered {
    final city    = ref.read(_selectedCityProvider);
    final type    = ref.read(_selectedTypeProvider);
    final query   = ref.read(_searchQueryProvider).toLowerCase();
    final verOnly = ref.read(_verifiedOnlyProvider);

    return kMockListings.where((l) {
      if (city != 'All' && l.city != city) return false;
      if (type != 'All' && l.propertyType != type) return false;
      if (verOnly && !l.isVerified) return false;
      if (query.isNotEmpty) {
        return l.title.toLowerCase().contains(query) ||
            l.locality.toLowerCase().contains(query) ||
            l.city.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final city    = ref.watch(_selectedCityProvider);
    final type    = ref.watch(_selectedTypeProvider);
    final verOnly = ref.watch(_verifiedOnlyProvider);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Property Listings'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _showListPropertySheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('List My Property', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search by locality, city...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                        })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // ── Filter bar ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('All Cities', city == 'All',
                    () => ref.read(_selectedCityProvider.notifier).state = 'All'),
                _filterChip('Bengaluru', city == 'Bengaluru',
                    () => ref.read(_selectedCityProvider.notifier).state = 'Bengaluru'),
                _filterChip('Mysuru', city == 'Mysuru',
                    () => ref.read(_selectedCityProvider.notifier).state = 'Mysuru'),
                _filterChip('Mangaluru', city == 'Mangaluru',
                    () => ref.read(_selectedCityProvider.notifier).state = 'Mangaluru'),
                const SizedBox(width: 12),
                _filterChip('All Types', type == 'All',
                    () => ref.read(_selectedTypeProvider.notifier).state = 'All'),
                _filterChip('Apartment', type == 'Apartment',
                    () => ref.read(_selectedTypeProvider.notifier).state = 'Apartment'),
                _filterChip('Plot', type == 'Plot',
                    () => ref.read(_selectedTypeProvider.notifier).state = 'Plot'),
                _filterChip('Villa', type == 'Villa',
                    () => ref.read(_selectedTypeProvider.notifier).state = 'Villa'),
                _filterChip('Commercial', type == 'Commercial',
                    () => ref.read(_selectedTypeProvider.notifier).state = 'Commercial'),
                const SizedBox(width: 12),
                _verifiedChip(verOnly,
                    () => ref.read(_verifiedOnlyProvider.notifier).state = !verOnly),
              ]),
            ),
          ),
          // ── Results count ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Text('${filtered.length} properties found',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
              const Spacer(),
              const Text('Sorted by: Newest',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            ]),
          ),
          // ── Listings ─────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ListingCard(
                      listing: filtered[i],
                      onContact: () => _showContactSheet(context, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListPropertySheet(context),
        icon: const Icon(Icons.add_home),
        label: const Text('List Property'),
        backgroundColor: AppColors.seller,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700)),
        ),
      );

  Widget _verifiedChip(bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.safe : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(Icons.verified, size: 12,
            color: active ? Colors.white : Colors.grey.shade700),
        const SizedBox(width: 4),
        Text('Verified Only',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey.shade700)),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.home_work_outlined, size: 56, color: AppColors.textLight),
      const SizedBox(height: 12),
      const Text('No listings found',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Try a different city or property type',
          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
    ]),
  );

  void _showContactSheet(BuildContext context, PropertyListing listing) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSellerSheet(listing: listing),
    );
  }

  void _showListPropertySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ListPropertySheet(),
    );
  }
}

// ─── Listing Card ──────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final PropertyListing listing;
  final VoidCallback onContact;
  const _ListingCard({required this.listing, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final priceStr = listing.priceInLakhs >= 100
        ? '₹${(listing.priceInLakhs / 100).toStringAsFixed(2)} Cr'
        : '₹${listing.priceInLakhs} L';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Property image placeholder ──────────────────────────────────
        Stack(children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              color: _typeColor(listing.propertyType).withOpacity(0.12),
            ),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_typeIcon(listing.propertyType),
                    color: _typeColor(listing.propertyType), size: 44),
                const SizedBox(height: 6),
                Text(listing.propertyType,
                    style: TextStyle(color: _typeColor(listing.propertyType),
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),
          if (listing.isVerified)
            Positioned(top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.safe,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('DS Verified',
                      style: TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          Positioned(top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(listing.postedDaysAgo,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ]),
        // ── Content ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(listing.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Text(priceStr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, color: AppColors.primary)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('${listing.locality}, ${listing.city}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const Spacer(),
              const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('${listing.views} views',
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              if (listing.bedrooms > 0) ...[
                _spec(Icons.king_bed_outlined, '${listing.bedrooms} BHK'),
                const SizedBox(width: 12),
              ],
              _spec(Icons.square_foot, '${listing.areaSqft.toInt()} sqft'),
              const SizedBox(width: 12),
              _spec(Icons.map_outlined,
                  '₹${((listing.priceInLakhs * 100000) / listing.areaSqft).round()}/sqft'),
            ]),
            const SizedBox(height: 8),
            // Highlights
            Wrap(spacing: 6, runSpacing: 4,
              children: listing.highlights.take(3).map((h) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.safe.withOpacity(0.3)),
                  ),
                  child: Text(h,
                      style: const TextStyle(fontSize: 10, color: AppColors.safe,
                          fontWeight: FontWeight.w600)),
                ),
              ).toList()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Contact Seller', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.lock_outlined, size: 16),
                  label: const Text('Initiate Escrow', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.seller,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _spec(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.textMedium),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
    ],
  );

  Color _typeColor(String type) => switch (type) {
    'Apartment'  => AppColors.primary,
    'Villa'      => AppColors.seller,
    'Plot'       => AppColors.teal,
    'Commercial' => AppColors.arthBlue,
    _            => Colors.grey,
  };

  IconData _typeIcon(String type) => switch (type) {
    'Apartment'  => Icons.apartment,
    'Villa'      => Icons.home,
    'Plot'       => Icons.landscape,
    'Commercial' => Icons.store,
    _            => Icons.house,
  };
}

// ─── Contact Seller Sheet — with escrow calculator + buyer search guide ────────
class _ContactSellerSheet extends StatefulWidget {
  final PropertyListing listing;
  const _ContactSellerSheet({required this.listing});

  @override
  State<_ContactSellerSheet> createState() => _ContactSellerSheetState();
}

class _ContactSellerSheetState extends State<_ContactSellerSheet> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitted  = false;
  bool _escrow     = false;
  bool _showGuide  = false;

  // Escrow calc
  // Standard in India: token = max(₹1L, 1% of deal), advance = 10% of deal
  // Arth ID fee: 0.25% of escrow held (advance amount)
  int get _priceLakhs  => widget.listing.priceInLakhs;
  int get _priceRs     => _priceLakhs * 100000;
  int get _token       => (_priceRs * 0.01).round().clamp(100000, 500000);
  int get _advance     => (_priceRs * 0.10).round();  // 10% standard, negotiable
  int get _dsFee       => (_advance * 0.0025).round(); // 0.25% of advance
  int get _balance     => _priceRs - _advance;        // balance at registration

  String _fmt(int v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(1)} L';
    return '₹$v';
  }

  // Buyer search guide by property type
  Map<String, List<String>> get _searchGuide => {
    'Apartment': [
      'Ask seller for: Flat No. + Building Name + Floor',
      'Search on BBMP e-Aasthi: Khata number',
      'Check RERA: Builder + project registration no.',
      'Verify on Kaveri EC: Apartment name + survey no.',
      'Ask for: OC (Occupancy Certificate) copy',
    ],
    'Villa': [
      'Ask seller for: Site No. + Layout Name',
      'Search Bhoomi: Survey No. + Village + Taluk + District',
      'Verify BDA/BBMP layout approval number',
      'Check Kaveri EC: All transactions for 30 years',
      'Ask for: DC Conversion + Layout approval order',
    ],
    'Plot': [
      'Ask seller for: Survey No. + Hissa No. + Village name',
      'Search Bhoomi RTC: survey number shows owner + land type',
      'Verify DC Conversion (agricultural→residential)',
      'Check if layout is BDA/BBMP/BMRDA/BIAAPA approved',
      'Never buy without seeing the RTC in your own name after sale',
    ],
    'Commercial': [
      'Ask seller for: Property Tax Account No. + Khata No.',
      'Search on BBMP e-Aasthi or municipality portal',
      'Verify RERA (if residential component inside)',
      'Check Kaveri EC: all loans/mortgages on property',
      'Ask for: Trade licence if running business',
    ],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _submitted ? _buildSuccess() : _buildForm(sc),
      ),
    );
  }

  Widget _buildForm(ScrollController sc) => SingleChildScrollView(
    controller: sc,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Handle
      Center(child: Container(width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2)))),

      // Property summary
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(_typeIcon(widget.listing.propertyType),
              color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.listing.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('${widget.listing.locality}, ${widget.listing.city}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          )),
          Text(_priceLakhs >= 100
              ? '₹${(_priceLakhs / 100).toStringAsFixed(1)} Cr'
              : '₹$_priceLakhs L',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  color: AppColors.primary, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Buyer's What-to-Search Guide ───────────────────────────────────
      GestureDetector(
        onTap: () => setState(() => _showGuide = !_showGuide),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.arthBlue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.arthBlue.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.arthBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'What to ask the seller / what to search',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13, color: AppColors.arthBlue),
            )),
            Icon(_showGuide ? Icons.expand_less : Icons.expand_more,
                color: AppColors.arthBlue, size: 18),
          ]),
        ),
      ),
      if (_showGuide) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.arthBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For ${widget.listing.propertyType}:',
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 12, color: AppColors.arthBlue)),
              const SizedBox(height: 8),
              ...(_searchGuide[widget.listing.propertyType] ??
                  _searchGuide['Plot']!).map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.arrow_right, size: 16,
                      color: AppColors.arthBlue),
                  const SizedBox(width: 4),
                  Expanded(child: Text(step,
                      style: const TextStyle(fontSize: 11, height: 1.4,
                          color: Colors.black87))),
                ]),
              )),
              const Divider(height: 12),
              const Text('If you already know the seller:',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 11, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text(
                '1. Get the Survey No. / Flat No. from seller\n'
                '2. Search Bhoomi or Kaveri EC yourself to verify\n'
                '3. Confirm owner name matches seller\'s Aadhaar/PAN\n'
                '4. Cross-check with Arth ID document scan',
                style: TextStyle(fontSize: 11, height: 1.5,
                    color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),

      // ── Escrow Calculator ───────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.seller.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.seller.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.lock_outlined, color: AppColors.seller, size: 18),
            SizedBox(width: 8),
            Text('Arth ID Escrow — How It Works',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 13, color: AppColors.seller)),
          ]),
          const SizedBox(height: 12),
          _escrowRow('Token Amount (non-negotiable min)',
              _fmt(_token), Colors.orange,
              'Paid immediately on agreement to reserve property'),
          _escrowRow('Advance (standard 10%, negotiable)',
              _fmt(_advance), AppColors.seller,
              'Held in DS escrow — released only after doc verification'),
          _escrowRow('Balance on registration',
              _fmt(_balance), AppColors.primary,
              'Paid at SRO on actual registration day'),
          const Divider(height: 12),
          _escrowRow('DS Escrow Fee (0.25% of advance)',
              _fmt(_dsFee), AppColors.textMedium,
              'One-time service fee — split 50/50 between buyer & seller'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🔒 Escrow is powered by NBFC/RazorpayX. Your advance is '
              'held safely — seller cannot access it until documents are '
              'verified. If deal falls through due to bad documents, '
              'advance is returned within 7 business days.',
              style: TextStyle(fontSize: 11, height: 1.5,
                  color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Switch(
              value: _escrow,
              onChanged: (v) => setState(() => _escrow = v),
              activeColor: AppColors.seller,
            ),
            const SizedBox(width: 4),
            const Expanded(child: Text('Enable escrow for this transaction',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Your Details ────────────────────────────────────────────────────
      const Text('Your Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      const Text('Seller sees your contact only after you submit.',
          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
      const SizedBox(height: 12),
      _field(_nameCtrl, 'Your Full Name', Icons.person_outline),
      const SizedBox(height: 10),
      _field(_emailCtrl, 'Email Address', Icons.email_outlined,
          type: TextInputType.emailAddress),
      const SizedBox(height: 10),
      _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
          type: TextInputType.phone),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _escrow ? AppColors.seller : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _escrow
                ? 'Submit & Initiate Escrow (Token: ${_fmt(_token)})'
                : 'Submit Contact Request',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        '🔒 Encrypted. We never share your data without your consent.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.textLight),
      ),
    ]),
  );

  Widget _escrowRow(String label, String value, Color color, String hint) =>
    Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: color))),
          Text(value, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.bold, color: color)),
        ]),
        Text(hint, style: const TextStyle(fontSize: 10,
            color: AppColors.textLight, height: 1.3)),
      ],
    ));

  Widget _buildSuccess() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.safe.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.safe, size: 48)),
        const SizedBox(height: 20),
        const Text('Request Sent!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Your details have been shared with ${widget.listing.sellerName}.\n'
          'Expect a call within 24 hours.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMedium,
              height: 1.5),
        ),
        if (_escrow) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.seller.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              const Text('Escrow Initiated',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: AppColors.seller)),
              const SizedBox(height: 4),
              Text(
                'Token: ${_fmt(_token)} · Advance: ${_fmt(_advance)}\n'
                'DS team will contact you within 2 business days.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textLight,
                    height: 1.4)),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Done'))),
      ],
    ),
  );

  void _submit() {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and phone')));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
    TextField(
      controller: ctrl, keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

  IconData _typeIcon(String type) => switch (type) {
    'Apartment'  => Icons.apartment,
    'Villa'      => Icons.home,
    'Plot'       => Icons.landscape,
    'Commercial' => Icons.store,
    _            => Icons.house,
  };
}

// ─── List Property Sheet ──────────────────────────────────────────────────────
class _ListPropertySheet extends StatefulWidget {
  const _ListPropertySheet();

  @override
  State<_ListPropertySheet> createState() => _ListPropertySheetState();
}

class _ListPropertySheetState extends State<_ListPropertySheet> {
  final _titleCtrl    = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _areaCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  String _type = 'Apartment';
  bool _submitted = false;

  static const _types = ['Apartment', 'Villa', 'Plot', 'Commercial'];

  @override
  void dispose() {
    for (final c in [_titleCtrl, _localityCtrl, _priceCtrl, _areaCtrl, _phoneCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _submitted ? _buildSuccess() : _buildForm(sc),
      ),
    );
  }

  Widget _buildForm(ScrollController sc) => SingleChildScrollView(
    controller: sc,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Container(width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2))),
      ),
      const Text('List Your Property',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Reach verified buyers — free listing',
          style: TextStyle(fontSize: 12, color: AppColors.safe)),
      const SizedBox(height: 16),
      // Type selector
      const Text('Property Type',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      Row(children: _types.map((t) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _type = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _type == t ? AppColors.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _type == t ? Colors.white : Colors.grey.shade700)),
          ),
        ),
      )).toList()),
      const SizedBox(height: 14),
      _field(_titleCtrl, 'Property Title (e.g. 3BHK in Whitefield)',
          Icons.home_outlined),
      const SizedBox(height: 12),
      _field(_localityCtrl, 'Locality & City', Icons.location_on_outlined),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field(_priceCtrl, 'Price (₹ Lakhs)',
            Icons.currency_rupee, type: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _field(_areaCtrl, 'Area (sqft)',
            Icons.square_foot, type: TextInputType.number)),
      ]),
      const SizedBox(height: 12),
      _field(_phoneCtrl, 'Your Contact Number', Icons.phone_outlined,
          type: TextInputType.phone),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: const Text(
          '💡 Tip: Properties with a Arth ID verification report get 3× '
          'more buyer inquiries. Upload your documents first to get verified.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.seller,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('List My Property (Free)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ]),
  );

  Widget _buildSuccess() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.seller.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.seller, size: 48),
        ),
        const SizedBox(height: 20),
        const Text('Property Listed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Your listing is under review and will go live within 24 hours.\n'
          'Serious buyers will contact you directly.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.seller,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    ),
  );

  void _submit() {
    if (_titleCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and phone')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
}
