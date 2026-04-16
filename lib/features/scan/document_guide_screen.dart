import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

// ─── Document Guide Screen ────────────────────────────────────────────────────
// Shows which documents are required for the selected property type, which
// government portal to get each one from, step-by-step instructions, and
// lets the user open that portal in-app before uploading.
//
// Flow:  Home → /scan/guide → user picks property type
//        → sees doc checklist → opens portal in-app → downloads doc
//        → taps "Upload this document" → /scan/camera (or gallery)
//        → OCR → /auto-scan → Legal Report

class DocumentGuideScreen extends ConsumerStatefulWidget {
  const DocumentGuideScreen({super.key});

  @override
  ConsumerState<DocumentGuideScreen> createState() => _DocumentGuideScreenState();
}

class _DocumentGuideScreenState extends ConsumerState<DocumentGuideScreen> {
  final Set<int> _expanded = {};
  String _selectedState = 'Karnataka';

  @override
  Widget build(BuildContext context) {
    final propType = ref.watch(propertyTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Get Your Documents'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/scan/camera'),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            label: const Text('Skip — I Have Docs',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStateSelector(),
          _buildPropertyTypeSelector(propType),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_selectedState != 'Karnataka') _buildOtherStateNotice(),
                _buildWhySection(propType),
                const SizedBox(height: 12),
                ..._buildDocCards(propType),
                const SizedBox(height: 16),
                _buildScanNowButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── State selector ───────────────────────────────────────────────────────
  Widget _buildStateSelector() {
    const states = [
      'Karnataka', 'Tamil Nadu', 'Maharashtra', 'Telangana',
      'Andhra Pradesh', 'Kerala', 'UP', 'Other',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textLight),
        const SizedBox(width: 6),
        const Text('State:', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: states.map((s) {
                final sel = _selectedState == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedState = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(s, style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? Colors.white : AppColors.textMedium)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildOtherStateNotice() {
    final stateDocNames = switch (_selectedState) {
      'Tamil Nadu'       => 'Patta & Chitta (tnreginet.gov.in), EC (tnreginet)',
      'Maharashtra'      => '7/12 Utara (bhulekh.mahabhumi.gov.in), EC (igrmaharashtra.gov.in)',
      'Telangana'        => 'Pahani / Pattadar Passbook (dharani.telangana.gov.in)',
      'Andhra Pradesh'   => 'ROR-1B / Pattadar (meebhoomi.ap.gov.in)',
      'Kerala'           => 'Thandaper / Pokkuvaravu (erekha.kerala.gov.in)',
      'UP'               => 'Khatauni / B1 (upbhulekh.gov.in)',
      _                  => 'Check your state land records portal for RTC/Patta equivalent',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, size: 15, color: Colors.amber),
          const SizedBox(width: 6),
          Text('$_selectedState — Key Documents',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 12, color: Colors.brown)),
        ]),
        const SizedBox(height: 6),
        Text(stateDocNames,
            style: const TextStyle(fontSize: 12, color: Colors.brown, height: 1.4)),
        const SizedBox(height: 6),
        const Text(
          'Portal names differ by state. The document purpose is the same — '
          'upload the equivalent document and our AI will read it.',
          style: TextStyle(fontSize: 11, color: Colors.brown, height: 1.4),
        ),
      ]),
    );
  }

  // ── Property type chip selector ──────────────────────────────────────────
  Widget _buildPropertyTypeSelector(String current) {
    final types = [
      ('site',        Icons.landscape_outlined,    'Plot / Site'),
      ('bda_layout',  Icons.holiday_village_outlined, 'BDA Layout'),
      ('apartment',   Icons.apartment,             'Apartment'),
      ('house',       Icons.home_outlined,         'House'),
      ('farm',        Icons.agriculture_outlined,  'Farm Land'),
      ('commercial',  Icons.store_outlined,        'Commercial'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: types.map((t) {
                final selected = current == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Row(children: [
                      Icon(t.$2, size: 14,
                          color: selected ? Colors.white : AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(t.$3,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : AppColors.textMedium,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ]),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceGrey,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    onSelected: (_) {
                      ref.read(propertyTypeProvider.notifier).state = t.$1;
                      setState(() => _expanded.clear());
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Why section ──────────────────────────────────────────────────────────
  Widget _buildWhySection(String propType) {
    final text = switch (propType) {
      'apartment'  => 'For a flat/apartment you need: RERA registration, Encumbrance Certificate (EC), and CC/OC certificates. The bank will NOT give a loan without all three.',
      'farm'       => 'For agricultural land you need: RTC (Pahani), EC for 30 years, and Mutation Register. If the land is "converted", you also need the DC Conversion order.',
      'house'      => 'For an independent house you need: RTC, EC (30 years), Building Plan Approval, and Completion Certificate (CC) from your local authority.',
      'bda_layout' => 'For a BDA layout plot you need: RTC, EC, and the BDA Layout Approval document. Verify the plot is in BDA\'s approved list before paying.',
      'commercial' => 'For commercial property you need: RTC, EC, Building Plan Approval, and RERA registration if it is a commercial complex.',
      _            => 'For a residential plot / site you need: RTC, EC (30 years), and layout approval from BDA / BIAAPA / BBMP depending on location.',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium,
                  height: 1.5))),
        ],
      ),
    );
  }

  // ── Document cards ───────────────────────────────────────────────────────
  List<Widget> _buildDocCards(String propType) {
    final docs = _docsFor(propType);
    return docs.asMap().entries.map((e) {
      final i = e.key;
      final doc = e.value;
      final isExpanded = _expanded.contains(i);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            // Header row
            InkWell(
              onTap: () => setState(() {
                if (isExpanded) _expanded.remove(i); else _expanded.add(i);
              }),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: doc.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(doc.icon, color: doc.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(doc.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 14, color: AppColors.textDark)),
                            ),
                            const SizedBox(width: 6),
                            if (doc.required)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('REQUIRED',
                                    style: TextStyle(fontSize: 9,
                                        color: AppColors.danger, fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('REC',
                                    style: TextStyle(fontSize: 9,
                                        color: AppColors.info, fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3)),
                              ),
                          ]),
                          const SizedBox(height: 3),
                          Text(doc.subtitle,
                              style: const TextStyle(fontSize: 11,
                                  color: AppColors.textLight, height: 1.3)),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textLight),
                  ],
                ),
              ),
            ),

            // Expanded: How to get it + portal button
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 16),
                    const Text('How to get this document',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...doc.steps.asMap().entries.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: doc.color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${s.key + 1}',
                                style: TextStyle(fontSize: 10,
                                    color: doc.color, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.value,
                              style: const TextStyle(fontSize: 12,
                                  color: AppColors.textMedium, height: 1.4))),
                        ],
                      ),
                    )),
                    if (doc.portal != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                GovWebViewScreen(portal: doc.portal!))),
                            icon: Icon(Icons.open_in_browser, size: 16, color: doc.color),
                            label: Text('Open ${doc.portalLabel ?? 'Portal'} in App',
                                style: TextStyle(color: doc.color, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: doc.color.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/scan/camera'),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Upload Doc', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: doc.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ] else ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/scan/camera'),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload This Document',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: doc.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  // ── Scan Now CTA ─────────────────────────────────────────────────────────
  Widget _buildScanNowButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/document-check'),
            icon: const Icon(Icons.document_scanner, size: 20),
            label: const Text('I Have My Documents — Scan Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Point camera at document or pick from gallery.\nAI reads it automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4),
        ),
      ],
    );
  }

  // ── Document definitions per property type ───────────────────────────────
  List<_DocInfo> _docsFor(String propType) {
    // Non-Karnataka states get state-specific doc lists
    if (_selectedState != 'Karnataka') {
      return _otherStateDocs(_selectedState, propType);
    }
    return switch (propType) {
      'apartment'  => _apartmentDocs(),
      'farm'       => _farmDocs(),
      'house'      => _houseDocs(),
      'bda_layout' => _bdaLayoutDocs(),
      'commercial' => _commercialDocs(),
      _            => _siteDocs(),
    };
  }

  // ── State-specific document lists ─────────────────────────────────────────
  List<_DocInfo> _otherStateDocs(String state, String propType) {
    return switch (state) {
      'Tamil Nadu'     => _tamilNaduDocs(propType),
      'Maharashtra'    => _maharashtraDocs(propType),
      'Telangana'      => _telanganaDocs(propType),
      'Andhra Pradesh' => _andhrapadeshDocs(propType),
      'Kerala'         => _keralaDocs(propType),
      'UP'             => _upDocs(propType),
      _                => _genericStateDocs(state, propType),
    };
  }

  List<_DocInfo> _tamilNaduDocs(String propType) => [
    _DocInfo(
      name: 'Patta & Chitta',
      subtitle: 'Ownership record — equivalent of RTC/Pahani in Tamil Nadu',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to eservices.tn.gov.in → "View Patta & FMB / Chitta / TSLR Extract"',
        'Select District → Taluk → Village',
        'Enter Survey Number',
        'View and screenshot the Patta document',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions — mortgages, sales, leases (tnreginet)',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to tnreginet.gov.in → "Encumbrance Certificate"',
        'Select Sub-Registrar Office → enter survey/doc number',
        'Choose period (last 30 years)',
        'Pay ₹50 online and download the EC',
        'Upload here',
      ],
    ),
    if (propType == 'apartment') _DocInfo(
      name: 'RERA Tamil Nadu Certificate',
      subtitle: 'Project registration — mandatory for apartments above 500 sqm',
      icon: Icons.apartment, color: AppColors.reraColor, required: true,
      steps: [
        'Go to rera.tn.gov.in → "Registered Projects"',
        'Search by project name or promoter name',
        'Download the RERA certificate',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'CERSAI Check',
      subtitle: 'Confirms no bank mortgage on this property',
      icon: Icons.account_balance_outlined, color: AppColors.cersaiColor, required: false,
      steps: [
        'Go to cersai.org.in → "Search for Security Interest"',
        'Enter property details or owner name',
        'Screenshot result and upload',
      ],
    ),
  ];

  List<_DocInfo> _maharashtraDocs(String propType) => [
    _DocInfo(
      name: '7/12 Utara (Satbara)',
      subtitle: 'Land ownership record — equivalent of RTC in Maharashtra',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to bhulekh.mahabhumi.gov.in',
        'Select District → Taluka → Village',
        'Enter Gat/Survey number',
        'View and download the 7/12 extract',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Property Card / 8-A',
      subtitle: 'Municipal ownership record for urban properties',
      icon: Icons.credit_card_outlined, color: Colors.teal, required: propType != 'farm',
      steps: [
        'Go to mahabhulekh.maharashtra.gov.in for rural',
        'For Mumbai: go to mcgm.gov.in → Property Tax → Property Card',
        'Enter property / CTS number',
        'Download or screenshot the card',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions — from IGR Maharashtra',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to igrmaharashtra.gov.in → "e-Search"',
        'Enter village, survey, or document number',
        'Choose date range (last 30 years)',
        'Download the EC and upload here',
      ],
    ),
    if (propType == 'apartment') _DocInfo(
      name: 'MahaRERA Certificate',
      subtitle: 'Maharashtra RERA — mandatory for residential projects',
      icon: Icons.apartment, color: AppColors.reraColor, required: true,
      steps: [
        'Go to maharera.mahaonline.gov.in',
        'Search project by name or registration number',
        'Download the MahaRERA certificate',
        'Upload here',
      ],
    ),
  ];

  List<_DocInfo> _telanganaDocs(String propType) => [
    _DocInfo(
      name: 'Pahani / Pattadar Passbook',
      subtitle: 'Land ownership — Telangana Dharani portal',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to dharani.telangana.gov.in',
        'Tap "Encumbrance Search" or "Pahani"',
        'Enter District, Mandal, Village, Survey Number',
        'View and screenshot the Pahani',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions on this property',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to dharani.telangana.gov.in → "Encumbrance Search"',
        'Or visit registration.telangana.gov.in → EC search',
        'Enter property details and date range',
        'Download and upload here',
      ],
    ),
    if (propType == 'apartment') _DocInfo(
      name: 'TSRERA Certificate',
      subtitle: 'Telangana RERA registration for apartment projects',
      icon: Icons.apartment, color: AppColors.reraColor, required: true,
      steps: [
        'Go to rera.telangana.gov.in',
        'Search registered projects by name',
        'Download the TSRERA certificate and upload',
      ],
    ),
  ];

  List<_DocInfo> _andhrapadeshDocs(String propType) => [
    _DocInfo(
      name: 'ROR-1B / Adangal',
      subtitle: 'Land rights record — MeeBhoomi portal Andhra Pradesh',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to meebhoomi.ap.gov.in',
        'Select "Adangal" (land details)',
        'Enter District, Mandal, Village, Survey Number',
        'View and screenshot the ROR-1B',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions from AP Registration Dept',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to registration.ap.gov.in → "Encumbrance Certificate"',
        'Enter SRO, village, survey number and date range',
        'Pay fee and download EC',
        'Upload here',
      ],
    ),
  ];

  List<_DocInfo> _keralaDocs(String propType) => [
    _DocInfo(
      name: 'Thandaper / Pokkuvaravu',
      subtitle: 'Property ownership certificate — Kerala erekha portal',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to erekha.kerala.gov.in',
        'Select District, Taluk, Village',
        'Enter Survey Number / Re-survey number',
        'Download Thandaper document and upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered encumbrances — Kerala Registration Dept',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to keralaregistration.gov.in → "Online EC"',
        'Select SRO, enter property details',
        'Choose period and download EC',
        'Upload here',
      ],
    ),
  ];

  List<_DocInfo> _upDocs(String propType) => [
    _DocInfo(
      name: 'Khatauni / B1 Extract',
      subtitle: 'Land ownership record — UP Bhulekh portal',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Go to upbhulekh.gov.in',
        'Select District, Tehsil, Village',
        'Search by Khata/Khasra or owner name',
        'View and print the Khatauni',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions — IGRSUP portal',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Go to igrsup.gov.in → "Property Search"',
        'Enter district, tehsil, property details',
        'Download EC / property history',
        'Upload here',
      ],
    ),
    if (propType == 'apartment') _DocInfo(
      name: 'UP RERA Certificate',
      subtitle: 'UP RERA registration — mandatory for residential projects',
      icon: Icons.apartment, color: AppColors.reraColor, required: true,
      steps: [
        'Go to up-rera.in',
        'Search project by name or promoter',
        'Download the UP RERA certificate and upload',
      ],
    ),
  ];

  List<_DocInfo> _genericStateDocs(String state, String propType) => [
    _DocInfo(
      name: 'Land Ownership Record (RTC / Patta / Pahani)',
      subtitle: 'Check your state\'s official land records portal for the equivalent',
      icon: Icons.description_outlined, color: AppColors.primary, required: true,
      steps: [
        'Search Google: "$state land records portal"',
        'Select your district, taluk/tehsil, village',
        'Enter survey/khasra number',
        'Download or screenshot the ownership record',
        'Upload here — AI reads all Indian state formats',
      ],
    ),
    _DocInfo(
      name: 'Encumbrance Certificate (EC)',
      subtitle: 'All registered transactions — from your state\'s registration dept',
      icon: Icons.verified_outlined, color: AppColors.kaveri, required: true,
      steps: [
        'Search Google: "$state encumbrance certificate online"',
        'Log in to the state registration portal',
        'Enter property and date range details',
        'Download EC and upload here',
      ],
    ),
    if (propType == 'apartment') _DocInfo(
      name: 'RERA Certificate',
      subtitle: 'State RERA registration — mandatory for apartments',
      icon: Icons.apartment, color: AppColors.reraColor, required: true,
      steps: [
        'Search Google: "$state RERA portal"',
        'Search project by name or promoter',
        'Download RERA certificate and upload here',
      ],
    ),
    _DocInfo(
      name: 'CERSAI Check',
      subtitle: 'National portal — confirms no bank mortgage on property',
      icon: Icons.account_balance_outlined, color: AppColors.cersaiColor, required: false,
      steps: [
        'Go to cersai.org.in → "Search for Security Interest"',
        'Enter property or owner details',
        'Screenshot result and upload',
      ],
    ),
  ];

  List<_DocInfo> _siteDocs() => [
    _DocInfo(
      name: 'RTC (Pahani)',
      subtitle: 'Record of Rights, Tenancy & Crops — owner, area, khata type',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Open Bhoomi portal (landrecords.karnataka.gov.in)',
        'Tap "View RTC / Pahani"',
        'Select District → Taluk → Hobli → Village',
        'Enter Survey Number and tap Search',
        'Screenshot or download the RTC page',
        'Come back here and tap Upload',
      ],
    ),
    _DocInfo(
      name: 'EC (Encumbrance Certificate)',
      subtitle: 'Shows all registered sales, mortgages, leases on this land — 30 years',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Open Kaveri portal (kaverionline.karnataka.gov.in)',
        'Tap "Encumbrance Certificate"',
        'Select your Sub-Registrar Office (SRO)',
        'Enter survey/khata number and date range (past 30 years)',
        'Download or screenshot the EC',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Layout Approval',
      subtitle: 'BDA / BIAAPA / BBMP approval — confirms plot is in legal layout',
      icon: Icons.map_outlined,
      color: AppColors.bdaColor,
      required: true,
      portal: GovPortal.bdaLayout,
      portalLabel: 'BDA',
      steps: [
        'Ask the seller for the layout approval copy',
        'Check if the layout name is listed on BDA portal (bdabengaluru.gov.in)',
        'If near Devanahalli / Hoskote airport area: check BIAAPA portal instead',
        'If within BBMP city limits: check BBMP plan approval',
        'Upload the layout document',
      ],
    ),
    _DocInfo(
      name: 'DC Conversion Order',
      subtitle: 'Deputy Commissioner order converting agricultural land to residential use',
      icon: Icons.swap_horiz_outlined,
      color: Colors.deepOrange,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Land Conversion Portal',
      steps: [
        'Go to landconversion.karnataka.gov.in',
        'Tap "Final Orders" → search by Survey Number or Request ID',
        'Enter District, Taluk, Hobli, Village + Survey Number',
        'Download or screenshot the conversion order',
        'If not online: visit the Tahsildar office with survey number — they issue a certified copy',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'CERSAI — Mortgage Check',
      subtitle: 'Confirms no bank has a registered charge or mortgage on this land',
      icon: Icons.account_balance_outlined,
      color: AppColors.cersaiColor,
      required: false,
      portal: GovPortal.cersai,
      portalLabel: 'CERSAI',
      steps: [
        'Open CERSAI portal (cersai.org.in)',
        'Tap "Search for Security Interest"',
        'Enter property details or owner name',
        'Check if any active charge/mortgage is shown',
        'Screenshot the result and upload',
      ],
    ),
  ];

  List<_DocInfo> _farmDocs() => [
    _DocInfo(
      name: 'RTC (Pahani)',
      subtitle: 'Record of Rights, Tenancy & Crops — owner name, land type, area, khata',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Open Bhoomi portal (landrecords.karnataka.gov.in)',
        'Tap "View RTC / Pahani"',
        'Select District → Taluk → Hobli → Village',
        'Enter Survey Number → tap Search',
        'Screenshot or download the RTC',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Mutation Register',
      subtitle: 'History of all ownership changes — inheritance, sales, court orders',
      icon: Icons.history_edu_outlined,
      color: AppColors.arthBlue,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'On the Bhoomi portal, search for the survey number',
        'Tap "Mutation History" on the RTC result page',
        'Review all past mutations — especially recent ones',
        'Screenshot each mutation page',
        'Upload the mutation register',
      ],
    ),
    _DocInfo(
      name: 'EC (Encumbrance Certificate, 30 years)',
      subtitle: 'Shows registered transactions — any loan or mortgage against this land',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Open Kaveri portal',
        'Select "Encumbrance Certificate"',
        'Enter SRO office, survey number, date range (30 years back)',
        'Download EC report',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'DC Conversion Order (if applicable)',
      subtitle: 'If land was converted from agricultural to non-ag use — this is critical',
      icon: Icons.swap_horiz_outlined,
      color: AppColors.warning,
      required: false,
      portal: GovPortal.dcConversion,
      portalLabel: 'DC Conversion',
      steps: [
        'Ask the seller for the DC (Diversion Certificate) copy',
        'Verify on Bhoomi: the RTC "Land Type" field should say "DC Converted"',
        'If not converted but land is being sold for construction — RED FLAG',
        'Upload the DC order document',
      ],
    ),
    _DocInfo(
      name: 'Court Injunction Check',
      subtitle: 'Checks if any court has put a stay on sale or transfer of this land',
      icon: Icons.gavel_outlined,
      color: AppColors.danger,
      required: true,
      portal: GovPortal.eCourts,
      portalLabel: 'eCourts',
      steps: [
        'Open eCourts portal (ecourts.gov.in)',
        'Search by party name (owner) or property details',
        'Look for any civil suit, injunction, or OS case against this survey number',
        'Screenshot result (even "no cases found" is useful)',
        'Upload here',
      ],
    ),
  ];

  List<_DocInfo> _apartmentDocs() => [
    _DocInfo(
      name: 'RERA Registration',
      subtitle: 'Confirms project is registered — builder details, delivery date, complaints',
      icon: Icons.domain_verification_outlined,
      color: AppColors.reraColor,
      required: true,
      portal: GovPortal.rera,
      portalLabel: 'RERA',
      steps: [
        'Open RERA Karnataka portal (rera.karnataka.gov.in)',
        'Tap "Project Registration Search"',
        'Search by project name or builder/promoter name',
        'Download the RERA certificate page',
        'Check: registration active? delivery date? complaints filed?',
        'Upload the RERA page',
      ],
    ),
    _DocInfo(
      name: 'EC on Flat (Encumbrance Certificate)',
      subtitle: 'Shows if the flat is mortgaged or has any bank charge',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Open Kaveri portal',
        'Search EC by flat / schedule number or builder name',
        'Download EC for the specific unit',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'CC / OC Certificate',
      subtitle: 'Completion Certificate + Occupancy Certificate — mandatory for bank loan',
      icon: Icons.verified_user_outlined,
      color: AppColors.navy,
      required: true,
      portal: GovPortal.bbmpPlan,
      portalLabel: 'BBMP Plan',
      steps: [
        'Ask the builder for CC and OC copy',
        'CC = Completion Certificate issued by BBMP / BDA when building is complete',
        'OC = Occupancy Certificate — allows people to legally occupy the flat',
        'Banks WILL NOT give home loan without both CC and OC',
        'Upload the CC/OC document',
      ],
    ),
    _DocInfo(
      name: 'CERSAI — Mortgage Check',
      subtitle: 'Confirms no bank has a registered charge on this flat',
      icon: Icons.account_balance_outlined,
      color: AppColors.cersaiColor,
      required: false,
      portal: GovPortal.cersai,
      portalLabel: 'CERSAI',
      steps: [
        'Open CERSAI portal (cersai.org.in)',
        'Search by property address or flat number',
        'Check for any active mortgage or charge',
        'Screenshot and upload',
      ],
    ),
    _DocInfo(
      name: 'Parent Land RTC (Builder\'s Land)',
      subtitle: 'Confirms builder had valid title over the land where apartments are built',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: false,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Ask builder for the "Sale Deed of Parent Land" or "Title document"',
        'Note the survey number of the parent land',
        'Check that land\'s RTC on Bhoomi portal',
        'Upload the parent land RTC',
      ],
    ),
  ];

  List<_DocInfo> _houseDocs() => [
    _DocInfo(
      name: 'RTC (Pahani)',
      subtitle: 'Shows land ownership, khata type, and survey number',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Open Bhoomi portal (landrecords.karnataka.gov.in)',
        'Tap "View RTC"',
        'Enter District, Taluk, Hobli, Village, Survey Number',
        'Screenshot or download RTC',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'EC (Encumbrance Certificate, 30 years)',
      subtitle: 'Shows all registered transactions on this property — loans, sales, mortgages',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Open Kaveri portal',
        'Select Encumbrance Certificate',
        'Enter your SRO, survey/khata number, 30-year range',
        'Download and upload',
      ],
    ),
    _DocInfo(
      name: 'Building Plan Approval',
      subtitle: 'Confirms house construction was approved by local authority (BBMP/BDA/CMC)',
      icon: Icons.architecture_outlined,
      color: AppColors.bbmpColor,
      required: true,
      portal: GovPortal.bbmpPlan,
      portalLabel: 'BBMP Plan',
      steps: [
        'Ask the seller for the Building Plan Approval copy',
        'The plan is approved by BBMP (city), BDA (layout), or CMC/TMC (smaller towns)',
        'Upload the plan approval document',
      ],
    ),
    _DocInfo(
      name: 'Completion Certificate (CC)',
      subtitle: 'Proof that construction matches the approved plan — needed for loan',
      icon: Icons.verified_user_outlined,
      color: AppColors.navy,
      required: true,
      portal: null,
      portalLabel: null,
      steps: [
        'CC is issued by BBMP/BDA/CMC after construction',
        'Ask seller for CC copy',
        'If no CC: the house is "unauthorized" — bank will not give loan',
        'Upload the CC document',
      ],
    ),
    _DocInfo(
      name: 'Khata Certificate',
      subtitle: 'Property tax account — A-Khata is regular, B-Khata is irregular',
      icon: Icons.receipt_long_outlined,
      color: AppColors.bbmpColor,
      required: false,
      portal: GovPortal.bbmp,
      portalLabel: 'BBMP',
      steps: [
        'Open BBMP Aasthi portal (bbmpeaasthi.karnataka.gov.in)',
        'Search by PID number or owner name',
        'Download the Khata Certificate',
        'Note: A-Khata = approved site. B-Khata = irregular, harder to get loan',
        'Upload here',
      ],
    ),
  ];

  List<_DocInfo> _bdaLayoutDocs() => [
    _DocInfo(
      name: 'RTC (Pahani)',
      subtitle: 'Land record — owner, area, survey number, khata',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Open Bhoomi portal',
        'View RTC → enter your plot\'s parent survey number',
        'Screenshot and upload',
      ],
    ),
    _DocInfo(
      name: 'EC (Encumbrance Certificate)',
      subtitle: 'Checks for registered loans or mortgages — 30 years',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Open Kaveri portal',
        'EC Search → SRO → survey/khata number → 30 years',
        'Download and upload',
      ],
    ),
    _DocInfo(
      name: 'BDA Layout Approval',
      subtitle: 'Confirms this layout is approved by BDA — the most important check',
      icon: Icons.map_outlined,
      color: AppColors.bdaColor,
      required: true,
      portal: GovPortal.bdaLayout,
      portalLabel: 'BDA Layout',
      steps: [
        'Open BDA portal (bdabengaluru.gov.in)',
        'Go to "Approved Layouts" list',
        'Search by layout name or survey number',
        'Download the approval page showing scheme name and year',
        'Upload here — any "unapproved BDA layout" is illegal',
      ],
    ),
    _DocInfo(
      name: 'BBMP A-Khata (after possession)',
      subtitle: 'BBMP property tax account — required to register the plot in your name',
      icon: Icons.receipt_long_outlined,
      color: AppColors.bbmpColor,
      required: false,
      portal: GovPortal.bbmp,
      portalLabel: 'BBMP',
      steps: [
        'After BDA releases the plot and you get possession letter',
        'Apply for BBMP Khata conversion',
        'This converts the site from BDA record to BBMP record',
        'A-Khata enables home loan and building plan approval later',
      ],
    ),
  ];

  List<_DocInfo> _commercialDocs() => [
    _DocInfo(
      name: 'RTC (Pahani)',
      subtitle: 'Land ownership record — survey number, owner, land type, area',
      icon: Icons.description_outlined,
      color: AppColors.primary,
      required: true,
      portal: GovPortal.bhoomi,
      portalLabel: 'Bhoomi',
      steps: [
        'Open Bhoomi portal',
        'View RTC → enter survey number',
        'Screenshot and upload',
      ],
    ),
    _DocInfo(
      name: 'EC (Encumbrance Certificate)',
      subtitle: 'All registered transactions on this property — essential for due diligence',
      icon: Icons.verified_outlined,
      color: AppColors.kaveri,
      required: true,
      portal: GovPortal.kaveri,
      portalLabel: 'Kaveri',
      steps: [
        'Kaveri portal → EC Search',
        'Enter SRO, survey/khata, 30-year range',
        'Download and upload',
      ],
    ),
    _DocInfo(
      name: 'RERA (if commercial complex)',
      subtitle: 'RERA registration required for commercial RERA projects',
      icon: Icons.domain_verification_outlined,
      color: AppColors.reraColor,
      required: false,
      portal: GovPortal.rera,
      portalLabel: 'RERA',
      steps: [
        'Check if this is a registered RERA commercial project',
        'RERA Karnataka portal → search by project or promoter',
        'Download RERA certificate page',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'Building Plan Approval',
      subtitle: 'Commercial use approval from BBMP / BDA / planning authority',
      icon: Icons.architecture_outlined,
      color: AppColors.bbmpColor,
      required: true,
      portal: GovPortal.bbmpPlan,
      portalLabel: 'BBMP Plan',
      steps: [
        'Get building plan approval copy from seller / builder',
        'Confirm the plan allows commercial use (not residential)',
        'Upload here',
      ],
    ),
    _DocInfo(
      name: 'CERSAI — Mortgage Check',
      subtitle: 'Checks for any bank charge or mortgage on this property',
      icon: Icons.account_balance_outlined,
      color: AppColors.cersaiColor,
      required: false,
      portal: GovPortal.cersai,
      portalLabel: 'CERSAI',
      steps: [
        'Open CERSAI portal',
        'Search by property or owner',
        'Screenshot result and upload',
      ],
    ),
  ];
}

// ─── Doc Info Model ────────────────────────────────────────────────────────────
class _DocInfo {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool required;
  final GovPortal? portal;
  final String? portalLabel;
  final List<String> steps;

  const _DocInfo({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.required,
    required this.portal,
    required this.portalLabel,
    required this.steps,
  });
}
