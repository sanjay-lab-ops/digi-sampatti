import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Property Profile Sheet ───────────────────────────────────────────────────
// Bottom sheet shown when user taps Buyer or Seller toggle.
// Collects: State → District → Taluk → Village + Property Type
// This drives the AI personalization, document checklist, and risk checks.
// ─────────────────────────────────────────────────────────────────────────────

// All-India states + UTs
const kIndianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Puducherry', 'Chandigarh', 'Jammu & Kashmir', 'Ladakh',
];

// Documents named differently per state (same content, different local name)
const kStateDocumentNames = {
  'Karnataka':        {'title': 'RTC (ಆರ್‌ಟಿಸಿ)', 'ec': 'Encumbrance Certificate (Kaveri)', 'register': 'Bhoomi'},
  'Tamil Nadu':       {'title': 'Patta (பட்டா)', 'ec': 'Encumbrance Certificate (TNREGINET)', 'register': 'TNREGINET'},
  'Andhra Pradesh':   {'title': 'Pahani (పహాణీ)', 'ec': 'EC (Registration Dept)', 'register': 'Meebhoomi'},
  'Telangana':        {'title': 'Pahani (పహాణీ)', 'ec': 'EC (Registration Dept)', 'register': 'Dharani'},
  'Maharashtra':      {'title': '7/12 Extract (सात बारा)', 'ec': 'EC (IGR Maharashtra)', 'register': 'MahaBhoomi'},
  'Kerala':           {'title': 'Thandaper / Pattayam', 'ec': 'EC (Registration Dept)', 'register': 'E-Rekha'},
  'West Bengal':      {'title': 'Record of Rights (ROR / RS Khatian)', 'ec': 'EC', 'register': 'Banglarbhumi'},
  'Gujarat':          {'title': '8-A / Hak Patrak', 'ec': 'EC', 'register': 'AnyROR'},
  'Rajasthan':        {'title': 'Jamabandi / Nakal', 'ec': 'EC', 'register': 'Apna Khata'},
  'Uttar Pradesh':    {'title': 'Khatian / Khatauni', 'ec': 'EC', 'register': 'UP Bhulekh'},
  'Madhya Pradesh':   {'title': 'Khasra / B1 Extract', 'ec': 'EC', 'register': 'MP Bhulekh'},
  'Punjab':           {'title': 'Jamabandi', 'ec': 'EC', 'register': 'PLRS'},
  'Haryana':          {'title': 'Jamabandi / Nakal', 'ec': 'EC', 'register': 'Jamabandi Haryana'},
};

// Property types with their specific required documents
const kPropertyTypes = [
  _PropType('site',       '🌍', 'Site / Plot',
      'Agricultural or revenue site. Needs: RTC, EC, DC Conversion, FMB Sketch.'),
  _PropType('apartment',  '🏢', 'Apartment / Flat',
      'Builder project. Needs: RERA, OC, building plan, EC, NOC from builder + society.'),
  _PropType('house',      '🏠', 'House / Villa',
      'Independent house. Needs: Building plan, OC, Khata, EC, FMB, tax receipt.'),
  _PropType('bda_layout', '📐', 'BDA / BMRDA Layout',
      'Approved layout site. Needs: BDA approval, site plan, Khata, EC.'),
  _PropType('farm',       '🌾', 'Farm / Agricultural Land',
      'Agricultural land. Needs: RTC, FMB, EC. NRI cannot buy without RBI permission.'),
  _PropType('commercial', '🏪', 'Commercial Space',
      'Shop / office. Needs: Building plan, OC, EC, RERA (if new project).'),
];

class _PropType {
  final String id;
  final String emoji;
  final String label;
  final String hint;
  const _PropType(this.id, this.emoji, this.label, this.hint);
}

Future<UserPropertyProfile?> showPropertyProfileSheet(
  BuildContext context,
  WidgetRef ref,
  bool isSeller,
) async {
  return showModalBottomSheet<UserPropertyProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PropertyProfileSheet(
      initial: ref.read(userProfileProvider),
      isSeller: isSeller,
    ),
  );
}

class _PropertyProfileSheet extends ConsumerStatefulWidget {
  final UserPropertyProfile initial;
  final bool isSeller;
  const _PropertyProfileSheet({required this.initial, required this.isSeller});

  @override
  ConsumerState<_PropertyProfileSheet> createState() => _PropertyProfileSheetState();
}

class _PropertyProfileSheetState extends ConsumerState<_PropertyProfileSheet> {
  String? _state;
  String? _district;
  String? _taluk;
  String? _village;
  String _propType = 'site';
  bool _firstTimeBuyer = true;

  final _districtCtrl = TextEditingController();
  final _talukCtrl    = TextEditingController();
  final _villageCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _state        = p.state;
    _district     = p.district;
    _taluk        = p.taluk;
    _village      = p.village;
    _propType     = p.propertyType;
    _firstTimeBuyer = p.isFirstTimeBuyer;
    _districtCtrl.text = _district ?? '';
    _talukCtrl.text    = _taluk    ?? '';
    _villageCtrl.text  = _village  ?? '';
  }

  @override
  void dispose() {
    _districtCtrl.dispose();
    _talukCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final profile = UserPropertyProfile(
      state:          _state,
      district:       _districtCtrl.text.trim().isNotEmpty ? _districtCtrl.text.trim() : _district,
      taluk:          _talukCtrl.text.trim().isNotEmpty    ? _talukCtrl.text.trim()    : _taluk,
      village:        _villageCtrl.text.trim().isNotEmpty  ? _villageCtrl.text.trim()  : _village,
      propertyType:   _propType,
      isFirstTimeBuyer: _firstTimeBuyer,
      isSeller:       widget.isSeller,
    );
    ref.read(userProfileProvider.notifier).state = profile;
    ref.read(propertyTypeProvider.notifier).state = _propType;
    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final docNames = kStateDocumentNames[_state];
    final selectedProp = kPropertyTypes.firstWhere(
        (p) => p.id == _propType, orElse: () => kPropertyTypes.first);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF141927),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.isSeller
                          ? AppColors.seller
                          : AppColors.primary)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isSeller ? Icons.sell_outlined : Icons.search,
                  color: widget.isSeller ? const Color(0xFFAD1457) : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isSeller ? 'Tell us about your property' : 'Where are you looking to buy?',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 17, color: Colors.white)),
                  Text('This helps AI give you relevant guidance',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Location ────────────────────────────────────────────
                  _sectionLabel('📍 Location'),
                  const SizedBox(height: 12),

                  // State dropdown
                  DropdownButtonFormField<String>(
                    value: _state,
                    dropdownColor: const Color(0xFF1a2035),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDeco('State / UT', Icons.map_outlined),
                    items: kIndianStates.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _state = v;
                      _district = null;
                      _districtCtrl.clear();
                    }),
                    hint: const Text('Select state',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                  const SizedBox(height: 10),

                  // Document name info for selected state
                  if (docNames != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'In ${_state}: Land title = "${docNames['title']}" · '
                          'Transactions = "${docNames['ec']}" · Portal: ${docNames['register']}',
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        )),
                      ]),
                    ),
                  const SizedBox(height: 10),

                  // District (free text — all-India)
                  TextField(
                    controller: _districtCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('District (ಜಿಲ್ಲೆ / जिला)', Icons.location_city_outlined),
                    onChanged: (v) => _district = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _talukCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Taluk / Tehsil / Mandal', Icons.layers_outlined),
                    onChanged: (v) => _taluk = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _villageCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Village / Area / Locality', Icons.cottage_outlined),
                    onChanged: (v) => _village = v,
                  ),

                  const SizedBox(height: 24),

                  // ── Property Type ────────────────────────────────────────
                  _sectionLabel(widget.isSeller
                      ? '🏠 What type of property are you selling?'
                      : '🏠 What type of property are you looking for?'),
                  const SizedBox(height: 12),

                  ...kPropertyTypes.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _propType = p.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _propType == p.id
                              ? AppColors.primary.withOpacity(0.12)
                              : const Color(0xFF1a2035),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _propType == p.id
                                ? AppColors.primary
                                : Colors.white12,
                            width: _propType == p.id ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label, style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14,
                                  color: _propType == p.id
                                      ? Colors.white : Colors.white70)),
                              Text(p.hint, style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                            ],
                          )),
                          if (_propType == p.id)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 18),
                        ]),
                      ),
                    ),
                  )),

                  const SizedBox(height: 24),

                  // ── AI personalisation preview ────────────────────────────
                  if (_state != null || _propType.isNotEmpty) ...[
                    _sectionLabel('🤖 What AI will check for you'),
                    const SizedBox(height: 10),
                    _buildAiPreview(selectedProp),
                    const SizedBox(height: 16),
                  ],

                  // ── First time buyer ──────────────────────────────────────
                  if (!widget.isSeller) ...[
                    Row(children: [
                      Checkbox(
                        value: _firstTimeBuyer,
                        onChanged: (v) => setState(() => _firstTimeBuyer = v!),
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      const Expanded(
                        child: Text('First-time property buyer — explain everything in simple language',
                            style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Save & Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isSeller
                            ? AppColors.seller : AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreview(_PropType prop) {
    final checks = _checksForType(prop.id, _state);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_state != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text('For ${prop.label} in ${_state}:',
                    style: const TextStyle(fontSize: 12,
                        color: Colors.white54, fontWeight: FontWeight.w500)),
              ]),
            ),
          ...checks.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: c.startsWith('⚠') ? Colors.orange
                      : c.startsWith('🔴') ? Colors.red
                      : AppColors.safe,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: const TextStyle(
                  fontSize: 12, color: Colors.white70))),
            ]),
          )),
        ],
      ),
    );
  }

  List<String> _checksForType(String type, String? state) {
    final base = <String>[];
    final docName = kStateDocumentNames[state]?['title'] ?? 'Land Title Document';
    final ecName  = kStateDocumentNames[state]?['ec']    ?? 'Encumbrance Certificate';

    base.add('$docName — ownership, land type, mutations, injunctions');
    base.add('$ecName — all transactions for 30 years');
    base.add('Court cases (eCourts) — active litigation on this property');
    base.add('CERSAI — bank mortgages and charges');

    switch (type) {
      case 'site':
        base.add('DC Conversion — is agricultural land converted for residential use?');
        base.add('FMB Sketch — boundary verification');
        if (state == 'Karnataka') {
          base.add('BBMP/BMRDA limits — is it inside urban planning area?');
        }
        break;
      case 'apartment':
        base.add('⚠ RERA registration — is this project legally registered?');
        base.add('⚠ Occupancy Certificate (OC) — has building been approved as complete?');
        base.add('⚠ Builder NOC + Society NOC for resale');
        base.add('RERA escrow — are buyer funds protected during construction?');
        base.add('Building plan approval — does actual structure match approved plan?');
        break;
      case 'house':
        base.add('Building plan approval (BBMP/BDA/Panchayat)');
        base.add('Occupancy Certificate — legally completed structure');
        base.add('⚠ Khata type — A-Khata required for bank loans');
        base.add('Property tax status — any arrears become buyer\'s liability');
        break;
      case 'bda_layout':
        base.add('BDA/BMRDA layout approval — is this layout legally sanctioned?');
        base.add('Site allotment letter or sale deed from developer');
        base.add('⚠ Conversion status — panchayat or BDA jurisdiction?');
        break;
      case 'farm':
        base.add('🔴 Agricultural land restrictions — who can buy');
        base.add('🔴 NRI restriction — RBI permission required for NRI buyers');
        base.add('SC/ST land restrictions — separate rules apply');
        base.add('Ceiling limit check — does seller hold excess land?');
        break;
      case 'commercial':
        base.add('Building plan — commercial use permission');
        base.add('RERA — if new commercial project');
        base.add('GST implications — commercial property purchase has GST');
        break;
    }

    // State-specific additions
    if (state == 'Karnataka') {
      base.add('Guidance Value (IGR Karnataka 2024-25) — minimum stamp duty price');
    }
    if (state == 'Maharashtra') {
      base.add('Stamp duty ready reckoner — Maharashtra IGR rates');
    }

    return base;
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold,
          fontSize: 13, color: Colors.white70));

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: const Color(0xFF1a2035),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}
