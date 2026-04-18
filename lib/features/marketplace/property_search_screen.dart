import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'property_listing_screen.dart';

// ─── Zomato-style Property Search Screen ─────────────────────────────────────
// Entry: Home → "Browse Verified Listings"
// Step 1: Search / choose location (typeahead like Zomato)
// Step 2: Choose property type (filter chips)
// Step 3: Browse listings with ₹99 basic / ₹499 full tiers
// ─────────────────────────────────────────────────────────────────────────────

class PropertySearchScreen extends StatefulWidget {
  const PropertySearchScreen({super.key});

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  final _searchCtrl   = TextEditingController();
  final _keywordCtrl  = TextEditingController();
  String? _selectedLocality;
  String? _selectedType;
  bool _searched = false;

  static const _popularLocalities = [
    'Whitefield', 'Koramangala', 'Indiranagar', 'HSR Layout', 'Yelahanka',
    'Sarjapur Road', 'Electronic City', 'Bannerghatta Road', 'JP Nagar',
    'Hebbal', 'Marathahalli', 'BTM Layout',
  ];

  static const _propertyTypes = [
    '🏠 All', '🏢 Apartment', '🏡 Villa', '🌳 Plot', '🏪 Commercial', '🌾 Farm Land',
  ];

  List<String> get _filteredLocalities {
    if (_searchCtrl.text.isEmpty) return _popularLocalities;
    final q = _searchCtrl.text.toLowerCase();
    return _popularLocalities.where((l) => l.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() { _searchCtrl.dispose(); _keywordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Your Property'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _searched ? _buildResults() : _buildSearch(),
    );
  }

  // ─── Step 1 & 2: Location + Type selection ──────────────────────────────────
  Widget _buildSearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location search bar (Zomato-style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search locality, area, or city...',
                    hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () { _searchCtrl.clear(); setState(() {}); },
                  child: const Icon(Icons.close, color: AppColors.textLight, size: 18),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Use current location chip
          GestureDetector(
            onTap: () => setState(() {
              _selectedLocality = 'Near Me';
              _searchCtrl.text = 'Near Me';
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.my_location, color: AppColors.primary, size: 14),
                SizedBox(width: 6),
                Text('Use Current Location',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Popular localities
          const Text('Popular in Bengaluru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filteredLocalities.map((loc) => GestureDetector(
              onTap: () => setState(() {
                _selectedLocality = loc;
                _searchCtrl.text = loc;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedLocality == loc
                      ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedLocality == loc
                        ? AppColors.primary : AppColors.borderColor,
                  ),
                ),
                child: Text(
                  loc,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _selectedLocality == loc ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Property type filter
          const Text('Property Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _propertyTypes.map((type) => GestureDetector(
              onTap: () => setState(() => _selectedType = type == '🏠 All' ? null : type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (_selectedType == type || (type == '🏠 All' && _selectedType == null))
                      ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_selectedType == type || (type == '🏠 All' && _selectedType == null))
                        ? AppColors.primary : AppColors.borderColor,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (_selectedType == type || (type == '🏠 All' && _selectedType == null))
                        ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 32),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedLocality != null || _searchCtrl.text.isNotEmpty
                  ? () => setState(() => _searched = true)
                  : null,
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                _selectedLocality != null
                    ? 'Search in $_selectedLocality'
                    : 'Choose a location first',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Results list with ₹99 / ₹499 tiers ────────────────────────────
  Widget _buildResults() {
    final locality = _selectedLocality ?? _searchCtrl.text;
    final keyword  = _keywordCtrl.text.toLowerCase();
    final filtered = kMockListings.where((l) {
      final matchLoc = locality.isEmpty || locality == 'Near Me' ||
          l.locality.toLowerCase().contains(locality.toLowerCase());
      final matchType = _selectedType == null ||
          l.propertyType == _selectedType!.split(' ').last;
      final matchKey = keyword.isEmpty ||
          l.title.toLowerCase().contains(keyword) ||
          l.locality.toLowerCase().contains(keyword) ||
          l.propertyType.toLowerCase().contains(keyword) ||
          l.highlights.any((h) => h.toLowerCase().contains(keyword));
      return matchLoc && matchType && matchKey;
    }).toList();

    return Column(
      children: [
        // Location row (tap to change)
        GestureDetector(
          onTap: () => setState(() => _searched = false),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(locality,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ]),
          ),
        ),
        // Keyword search bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.textLight, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _keywordCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search by keyword — 3BHK, near school, BMRDA...',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_keywordCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () { _keywordCtrl.clear(); setState(() {}); },
                child: const Icon(Icons.close, size: 16, color: AppColors.textLight),
              ),
          ]),
        ),

        // Filter chips (type)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _propertyTypes.map((type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type == '🏠 All' ? null : type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_selectedType == type || (type == '🏠 All' && _selectedType == null))
                        ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      color: (_selectedType == type || (type == '🏠 All' && _selectedType == null))
                          ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),

        // Result count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text('${filtered.length} properties in $locality',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const Spacer(),
            const Icon(Icons.tune, size: 16, color: AppColors.textLight),
            const SizedBox(width: 4),
            const Text('Sort', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ]),
        ),

        // Listings
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No listings in this area yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Check back soon or list yours!',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _ListingCard(listing: filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ─── Listing Card with ₹99 / ₹499 Tiers ──────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final PropertyListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo placeholder + verified badge
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Center(
                  child: Icon(
                    listing.propertyType == 'Apartment' ? Icons.apartment :
                    listing.propertyType == 'Plot' ? Icons.landscape :
                    Icons.villa,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              if (listing.isVerified)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safe,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.upload_file, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Docs Uploaded', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(listing.propertyType,
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text('${listing.locality}, ${listing.city}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const Spacer(),
                  const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 3),
                  Text('${listing.views} views', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('₹${listing.priceInLakhs}L',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  if (listing.bedrooms > 0)
                    _Chip('${listing.bedrooms} BHK', Icons.bed_outlined, AppColors.textMedium),
                  const SizedBox(width: 6),
                  _Chip('${listing.areaSqft.toInt()} sqft', Icons.square_foot, AppColors.textMedium),
                ]),
                const SizedBox(height: 8),
                // Highlights
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: listing.highlights.take(3).map((h) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.safe.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(h, style: const TextStyle(fontSize: 9, color: AppColors.safe, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                // ─── Two-tier pricing ───────────────────────────────────
                Row(children: [
                  // ₹99 — basic view
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showBasicDetails(context, listing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: const Column(children: [
                          Text('₹99', style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          Text('Basic Details', style: TextStyle(fontSize: 10, color: AppColors.textMedium)),
                          Text('Documents · Owner name', style: TextStyle(fontSize: 9, color: AppColors.textLight)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ₹499 — full service
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullService(context, listing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(children: [
                          Text('₹499', style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          Text('Full Report', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          Text('All 7 portals · AI verdict', style: TextStyle(fontSize: 9, color: Colors.white60)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Contact seller (moderated)
                  GestureDetector(
                    onTap: () => _contactSeller(context, listing),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ₹99 Basic — show seller name + doc summary (no phone/full docs)
  void _showBasicDetails(BuildContext context, PropertyListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Basic Property Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('₹99 · Unlocked for you',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
            const Divider(height: 24),
            _BasicRow('Property Title', listing.title),
            _BasicRow('Location', '${listing.locality}, ${listing.city}'),
            _BasicRow('Type', listing.propertyType),
            _BasicRow('Area', '${listing.areaSqft.toInt()} sqft'),
            _BasicRow('Price', '₹${listing.priceInLakhs} Lakhs'),
            _BasicRow('Seller', listing.sellerName),
            _BasicRow('Posted', listing.postedDaysAgo),
            const SizedBox(height: 8),
            const Text('Documents Available:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ...listing.highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.safe, size: 14),
                const SizedBox(width: 8),
                Text(h, style: const TextStyle(fontSize: 12)),
              ]),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Full documents, contact number, and AI verification report available with ₹499 Full Service.',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _showFullService(context, listing); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Upgrade to Full Report — ₹499'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ₹499 Full Service — AI report + all docs + contact
  void _showFullService(BuildContext context, PropertyListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Full Property Report — ₹499',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _ServiceItem('AI Legal Analysis', '30+ fraud checks, risk score 0–100', Icons.psychology_outlined, AppColors.primary),
            _ServiceItem('All 7 Government Portals', 'Bhoomi + Kaveri + eCourts + RERA + BBMP + CERSAI + IGR', Icons.account_balance_outlined, AppColors.arthBlue),
            _ServiceItem('Full Documents', 'All seller-uploaded docs unlocked', Icons.folder_outlined, AppColors.safe),
            _ServiceItem('Seller Contact', 'Direct phone + WhatsApp number', Icons.phone_outlined, const Color(0xFF25D366)),
            _ServiceItem('PDF Report', 'Shareable with lawyer / bank / family', Icons.picture_as_pdf_outlined, AppColors.deepOrange),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); },
                icon: const Icon(Icons.lock_open_outlined, size: 16),
                label: const Text('Pay ₹499 & Unlock Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Moderated seller contact
  void _contactSeller(BuildContext context, PropertyListing listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contact Seller',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For your safety, contact is only enabled after you view the ₹99 basic details. '
                      'Never share your bank details or pay outside Arth ID escrow.',
                      style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.chat, color: Colors.white, size: 18),
              ),
              title: const Text('Chat on WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Send a message — seller will see your enquiry'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.videocam_outlined, color: Colors.purple.shade700, size: 18),
              ),
              title: const Text('Schedule Video Call', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Pick a 30-minute slot with the seller'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            const Text(
              '🔒 Seller phone number unlocked only with ₹499 Full Report',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ],
  );
}

class _BasicRow extends StatelessWidget {
  final String k;
  final String v;
  const _BasicRow(this.k, this.v);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 90, child: Text(k,
          style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
      Expanded(child: Text(v,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
    ]),
  );
}

class _ServiceItem extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  const _ServiceItem(this.title, this.sub, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      )),
      const Icon(Icons.check_circle, color: AppColors.safe, size: 16),
    ]),
  );
}
