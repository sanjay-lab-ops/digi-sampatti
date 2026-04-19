import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/api_constants.dart';

// Documents per property type — aligned with DigiSampatti verification framework
const _sellerDocsMap = {

  // ════════════════════════════════════════════════════════════
  // APARTMENT / FLAT — approval-heavy, not land-heavy
  // Risks: No RERA, No OC, plan deviations, builder litigation
  // ════════════════════════════════════════════════════════════
  'Apartment / Flat': [
    // Ownership
    ('Sale Deed / Agreement to Sale', 'Registered ownership document from SRO', true),
    ('Possession Letter', 'From builder — confirms flat handed over to you', true),
    // Legal
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — no loans on flat', true),
    ('Khata Certificate + Extract', 'From BBMP/BDA — confirms property in your name in records', true),
    // Approvals (critical — no RERA = High Risk)
    ('RERA Registration Certificate', 'Mandatory — project/builder RERA no. from rera.karnataka.gov.in', true),
    ('Building Plan Approval', 'Sanctioned plan from BDA/BBMP — detects unauthorized construction', true),
    ('Commencement Certificate (CC)', 'Issued before construction begins — confirms legal start', true),
    ('Occupancy Certificate (OC)', 'Issued after completion — without OC, occupancy is illegal', true),
    // Supporting
    ('Property Tax Receipts', 'Last 3 years from BBMP — confirms active records', true),
    ('Share Certificate', 'From housing society — confirms membership', false),
    ('Allotment Letter', 'From builder — original allotment document (resale)', false),
  ],

  // ════════════════════════════════════════════════════════════
  // HOUSE / INDEPENDENT VILLA — hybrid: plot + building
  // Risks: Unauthorized floors, missing OC, no DC conversion
  // ════════════════════════════════════════════════════════════
  'House / Independent Villa': [
    // Ownership chain (plot component)
    ('Sale Deed (Current Owner)', 'Registered deed — current ownership proof', true),
    ('Mother Deed / Parent Documents', 'Title chain 15–30 years — detects duplicate sale fraud', true),
    ('RTC / Pahani (Bhoomi)', 'From landrecords.karnataka.gov.in — land type, owner, survey no.', true),
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — no loans/charges on land', true),
    ('Khata Certificate + Extract', 'From BBMP/BDA/Panchayat — A Khata safer, B Khata risky', true),
    // Layout + conversion (plot component)
    ('Layout Approval Letter', 'From BDA/BMRDA/BIAPPA/TMC — Panchayat approval = High Risk', true),
    ('DC Conversion Certificate', 'If land was agricultural — without this, building is illegal', true),
    // Building component
    ('Building Plan Sanction', 'BDA/BBMP approved plan — detects unauthorized floors/extensions', true),
    ('Occupancy Certificate (OC)', 'Confirms building legally complete as per approved plan', true),
    // Supporting
    ('Property Tax Receipts', 'Last 3 years — confirms municipal records', true),
    ('Survey Sketch (FMB)', 'From Survey Dept. — boundary map, prevents encroachment claims', false),
    ('Mutation Records', 'Ownership transfer history from revenue records', false),
  ],

  // ════════════════════════════════════════════════════════════
  // PLOT / LAND (RESIDENTIAL) — land-heavy
  // Risks: No layout approval, no DC conversion, Panchayat sites
  // ════════════════════════════════════════════════════════════
  'Plot / Land': [
    // Ownership
    ('Sale Deed (Current Owner)', 'Registered sale deed — current ownership proof', true),
    ('Mother Deed / Parent Documents', 'Title chain for last 15–30 years — detects duplicate sale fraud', true),
    // Land record
    ('RTC / Pahani (Bhoomi)', 'From landrecords.karnataka.gov.in — owner name, survey no., land type', true),
    // Encumbrance
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — all transactions & loans on this plot', true),
    // Khata
    ('Khata Certificate + Extract', 'From BBMP/BDA/Panchayat — A Khata preferred, B Khata is risky', true),
    // Approvals (critical)
    ('Layout Approval Letter', 'Issued by BDA/BMRDA/BIAPPA/TMC — Panchayat approval = High Risk for residential', true),
    ('DC Conversion Certificate', 'Mandatory if originally agricultural — without this, construction is illegal', true),
    // Supporting
    ('Property Tax Paid Receipts', 'Latest municipal tax receipt — confirms active ownership records', false),
    ('Survey Sketch (FMB)', 'From Survey Dept. — exact boundary map, prevents encroachment disputes', false),
    ('Bank Loan Sanction Letter', 'If bank has sanctioned loan on this plot — adds trust signal', false),
  ],

  // ════════════════════════════════════════════════════════════
  // COMMERCIAL PROPERTY
  // Risks: Residential property used commercially, no trade license, zoning violations
  // ════════════════════════════════════════════════════════════
  'Commercial Property': [
    // Ownership
    ('Sale Deed / Lease Agreement', 'Ownership or long-term lease — primary proof', true),
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — no loans/charges', true),
    ('Khata Certificate + Extract', 'From BBMP — confirms commercial classification in records', true),
    // Approvals
    ('Building Plan Approval', 'Sanctioned plan showing commercial usage — detects zoning violations', true),
    ('Occupancy Certificate (OC)', 'Building legally complete for commercial use', true),
    ('Trade License', 'From BBMP/municipal body — mandatory for commercial operations', true),
    ('Fire NOC', 'From Karnataka Fire Department — mandatory for all commercial buildings', true),
    // Supporting
    ('Property Tax Receipts', 'Confirms commercial tax classification — misclassification = risk', true),
    ('Usage/Zoning Certificate', 'Confirms land is zoned for commercial use — not residential zone', false),
    ('Lift License', 'From Dept. of Factories if multi-floor commercial', false),
  ],

  // ════════════════════════════════════════════════════════════
  // AGRICULTURAL LAND — biggest fraud category in India
  // Risks: Sold as plot illegally, not converted, ownership disputes
  // ════════════════════════════════════════════════════════════
  'Agricultural Land': [
    ('RTC / Pahani (Bhoomi)', 'MOST IMPORTANT — from landrecords.karnataka.gov.in. Shows classification, owner, tenancy', true),
    ('Sale Deed', 'Registered ownership document — current owner proof', true),
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — no loans/mortgages on land', true),
    ('Mutation Records (Pahani History)', 'Consecutive ownership transfers — detects disputed title', true),
    ('Survey Sketch (FMB)', 'From Survey Dept. — exact boundary, area, adjacent landowners', true),
    ('Land Use Certificate', 'Confirms agricultural zoning — building on agricultural land without conversion is illegal', true),
    ('Nil-Tenancy Certificate', 'Confirms no tenant/farmer has occupancy rights on land', false),
    ('Phodi Order', 'Survey subdivision order — if plot was split from larger survey number', false),
  ],

  // ════════════════════════════════════════════════════════════
  // BUILDING / CONSTRUCTED PROPERTY (entire building for sale)
  // Risks: No OC, unauthorized floors, structural issues, zoning
  // ════════════════════════════════════════════════════════════
  'Building / Constructed Property': [
    // Ownership (land)
    ('Sale Deed (Current Owner)', 'Registered deed proving current ownership of land + building', true),
    ('Mother Deed / Link Documents', 'Title chain for 30 years — every previous owner documented', true),
    // Land records
    ('RTC / Pahani (Bhoomi)', 'Land record — confirms land type (must be non-agricultural)', true),
    ('Encumbrance Certificate (EC)', 'From kaveri2.karnataka.gov.in — no loans/mortgages on land or building', true),
    ('Khata Certificate + Extract', 'From BBMP/BDA — confirms building in municipal records', true),
    // Layout (land component)
    ('Layout Approval Letter', 'From BDA/BMRDA/BIAPPA/TMC — land was part of approved layout', true),
    ('DC Conversion Certificate', 'Confirms land converted from agricultural — mandatory', true),
    // Building approvals (critical)
    ('Building Plan Sanction', 'BDA/BBMP approved building plan — any deviation = illegal construction', true),
    ('Commencement Certificate (CC)', 'Issued before construction began — proves legal start of building', true),
    ('Completion Certificate', 'Issued after construction — confirms building completed per approved plan', true),
    ('Occupancy Certificate (OC)', 'MANDATORY — without OC, building occupancy/sale is illegal', true),
    // Operational proof
    ('BESCOM Connection Letter', 'Electricity connection sanctioned — confirms building is live', true),
    ('BWSSB Connection Letter', 'Water supply connection — confirms municipal water provided', true),
    ('Property Tax Receipts (3 years)', 'BBMP property tax paid — confirms active records at correct value', true),
    // Risk documents
    ('Structural Stability Certificate', 'Required if building > 10 years or > G+3 floors — from licensed engineer', false),
    ('Fire NOC', 'Karnataka Fire Dept. NOC — mandatory if building height > 15m', false),
    ('Survey Sketch (FMB)', 'Boundary map — confirms building within plot boundaries, no encroachment', false),
    ('Lift License', 'If lifts installed — from Dept. of Factories & Boilers', false),
  ],
};

class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});
  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> {
  int _step = 0;
  String? _propertyType;
  String? _district;
  Map<int, Map<String, dynamic>> _ocrResults = {};

  static const _districts = [
    'Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru',
    'Belagavi', 'Kalaburagi', 'Ballari', 'Dharwad', 'Shivamogga',
    'Hassan', 'Tumakuru', 'Udupi', 'Haveri', 'Davanagere',
  ];

  static const _propertyTypes = [
    'Apartment / Flat',
    'House / Independent Villa',
    'Plot / Land',
    'Building / Constructed Property',
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
          title: const Text("I'm a Seller"),
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
            child: _StepBar(current: _step, total: 4),
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
      case 0: return _SellerStep1(key: const ValueKey(0), districts: _districts, onNext: (d) {
        setState(() { _district = d; _step = 1; });
      });
      case 1: return _SellerStep2(key: const ValueKey(1), types: _propertyTypes, onNext: (t) {
        setState(() { _propertyType = t; _step = 2; });
      });
      case 2: return _SellerStep3Docs(key: const ValueKey(2),
        propertyType: _propertyType!,
        onNext: (ocrData) => setState(() { _ocrResults = ocrData; _step = 3; }),
      );
      case 3: return _SellerStep4List(key: const ValueKey(3),
        propertyType: _propertyType!,
        district: _district!,
        ocrResults: _ocrResults,
      );
      default: return const SizedBox.shrink();
    }
  }
}

// ─── Seller Step 1: Location ──────────────────────────────────────────────────
class _SellerStep1 extends StatefulWidget {
  final List<String> districts;
  final void Function(String district) onNext;
  const _SellerStep1({super.key, required this.districts, required this.onNext});
  @override
  State<_SellerStep1> createState() => _SellerStep1State();
}

class _SellerStep1State extends State<_SellerStep1> {
  String? _district;
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _localityCtrl = TextEditingController();

  bool get _canProceed => _district != null && _titleCtrl.text.isNotEmpty && _priceCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _titleCtrl.dispose(); _priceCtrl.dispose();
    _areaCtrl.dispose(); _descCtrl.dispose(); _localityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 1 of 4', 'Property Details', Icons.home_outlined, AppColors.safe),
        const SizedBox(height: 20),

        // Property title
        TextField(
          controller: _titleCtrl,
          onChanged: (_) => setState(() {}),
          decoration: _deco('Property Title *').copyWith(
            hintText: 'e.g. 3BHK Flat in Jayanagar',
            prefixIcon: const Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // Price
        TextField(
          controller: _priceCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          decoration: _deco('Asking Price (₹) *').copyWith(
            hintText: 'e.g. 75,00,000',
            prefixIcon: const Icon(Icons.currency_rupee),
          ),
        ),
        const SizedBox(height: 12),

        // Area + Locality row
        Row(children: [
          Expanded(child: TextField(
            controller: _areaCtrl,
            keyboardType: TextInputType.number,
            decoration: _deco('Area (sq.ft / cents)').copyWith(
              hintText: 'e.g. 1200',
              prefixIcon: const Icon(Icons.straighten_outlined),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: _localityCtrl,
            decoration: _deco('Locality / Area').copyWith(
              hintText: 'e.g. Koramangala',
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          )),
        ]),
        const SizedBox(height: 12),

        // District
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
          decoration: _deco('District'),
          items: widget.districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _district = v),
        ),
        const SizedBox(height: 12),

        // Description
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: _deco('Description (optional)').copyWith(
            hintText: 'Describe the property — bedrooms, parking, amenities, facing, age...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceed ? () => widget.onNext(_district!) : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: AppColors.safe),
            child: const Text('Next: Choose Property Type →', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        if (!_canProceed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Fill property title, price and district to continue',
              style: TextStyle(fontSize: 11, color: AppColors.textLight), textAlign: TextAlign.center),
          ),
      ]),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle_outlined, size: 13, color: AppColors.safe),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
      ]),
    );
  }
}

// ─── Seller Step 2: Property Type ────────────────────────────────────────────
class _SellerStep2 extends StatefulWidget {
  final List<String> types;
  final void Function(String type) onNext;
  const _SellerStep2({super.key, required this.types, required this.onNext});
  @override
  State<_SellerStep2> createState() => _SellerStep2State();
}

class _SellerStep2State extends State<_SellerStep2> {
  String? _selected;

  static const _icons = [
    ('Apartment / Flat',          '🏢', Color(0xFF1565C0)),
    ('House / Independent Villa', '🏠', Color(0xFF2E7D32)),
    ('Plot / Land',               '🌿', Color(0xFF5D4037)),
    ('Commercial Property',       '🏬', Color(0xFF6A1B9A)),
    ('Agricultural Land',         '🌾', Color(0xFF558B2F)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 2 of 4', 'Property Type', Icons.category_outlined, AppColors.info),
        const SizedBox(height: 4),
        const Text('Documents required vary by type — choose carefully',
          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 20),
        ..._icons.map((t) {
          final isSelected = _selected == t.$1;
          final docs = _sellerDocsMap[t.$1] ?? [];
          final required = docs.where((d) => d.$3).length;
          return GestureDetector(
            onTap: () => setState(() => _selected = t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? t.$3.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? t.$3 : AppColors.borderColor, width: isSelected ? 2 : 1),
              ),
              child: Row(children: [
                Text(t.$2, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isSelected ? t.$3 : AppColors.textDark)),
                  Text('$required required docs · ${docs.length} total',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ])),
                if (isSelected) Icon(Icons.check_circle_rounded, color: t.$3, size: 20)
                else const Icon(Icons.radio_button_unchecked, color: AppColors.textLight, size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected == null ? null : () => widget.onNext(_selected!),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: AppColors.safe),
            child: const Text('Next: Upload Documents →', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

// ─── Seller Step 3: Document Upload Checklist ─────────────────────────────────
class _SellerStep3Docs extends StatefulWidget {
  final String propertyType;
  final void Function(Map<int, Map<String, dynamic>> ocrResults) onNext;
  const _SellerStep3Docs({super.key, required this.propertyType, required this.onNext});
  @override
  State<_SellerStep3Docs> createState() => _SellerStep3DocsState();
}

class _SellerStep3DocsState extends State<_SellerStep3Docs> {
  final Map<int, String> _uploaded = {};          // idx → file name
  final Map<int, String> _filePaths = {};         // idx → absolute file path
  final Map<int, Map<String, dynamic>> _ocrData = {}; // idx → Claude OCR result
  final Map<int, bool> _analyzing = {};           // idx → loading
  final _picker = ImagePicker();

  Future<void> _pickDoc(int idx) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Take Photo'), onTap: () => Navigator.pop(context, 'camera')),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from Gallery'), onTap: () => Navigator.pop(context, 'gallery')),
        ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Upload PDF or Image File'), onTap: () => Navigator.pop(context, 'file')),
      ])),
    );
    if (choice == null) return;

    String? path;
    String? name;

    if (choice == 'camera') {
      final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (f != null) { path = f.path; name = f.name; }
    } else if (choice == 'gallery') {
      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (f != null) { path = f.path; name = f.name; }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
        withReadStream: false,
      );
      if (result != null && result.files.single.path != null) {
        path = result.files.single.path;
        name = result.files.single.name;
      }
    }

    if (path == null || name == null) return;
    setState(() {
      _uploaded[idx] = name!;
      _filePaths[idx] = path!;
      _analyzing[idx] = true;
    });
    await _runOcr(idx, path);
  }

  Future<void> _runOcr(int idx, String filePath) async {
    try {
      final ext = filePath.toLowerCase();
      final isPdf = ext.endsWith('.pdf');

      if (isPdf) {
        // PDF: send as base64 to backend with pdf type
        final bytes = await File(filePath).readAsBytes();
        final b64 = base64Encode(bytes);
        final resp = await http.post(
          Uri.parse('${ApiConstants.backendBaseUrl}/rtc-from-image'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_base64': b64,
            'image_type': 'application/pdf',
            'document_hint': 'property_document',
          }),
        ).timeout(const Duration(seconds: 60));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          setState(() { _ocrData[idx] = data; _analyzing[idx] = false; });
          return;
        }
      } else {
        // Image: send as base64 image
        final bytes = await File(filePath).readAsBytes();
        final b64 = base64Encode(bytes);
        final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
        final resp = await http.post(
          Uri.parse('${ApiConstants.backendBaseUrl}/rtc-from-image'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_base64': b64,
            'image_type': mime,
            'document_hint': 'property_document',
          }),
        ).timeout(const Duration(seconds: 60));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          setState(() { _ocrData[idx] = data; _analyzing[idx] = false; });
          return;
        }
      }
    } catch (e) {
      debugPrint('[OCR] doc $idx failed: $e');
    }
    setState(() => _analyzing[idx] = false);
  }

  @override
  Widget build(BuildContext context) {
    final docs = _sellerDocsMap[widget.propertyType] ?? _sellerDocsMap['Apartment / Flat']!;
    final required = docs.where((d) => d.$3).toList();
    final optional = docs.where((d) => !d.$3).toList();
    final reqUploaded = required.where((d) => _uploaded.containsKey(docs.indexOf(d))).length;
    final allRequiredDone = reqUploaded == required.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 3 of 4', 'Upload Documents', Icons.upload_file_outlined, AppColors.warning),
        const SizedBox(height: 4),
        Text('For ${widget.propertyType}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 12),
        // Progress
        LinearProgressIndicator(
          value: required.isEmpty ? 0 : reqUploaded / required.length,
          backgroundColor: AppColors.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(allRequiredDone ? AppColors.safe : AppColors.warning),
          borderRadius: BorderRadius.circular(4), minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('$reqUploaded of ${required.length} required uploaded',
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 16),

        const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...required.asMap().entries.map((e) {
          final idx = docs.indexOf(required[e.key]);
          return _UploadRow(
            title: e.value.$1, subtitle: e.value.$2, required: true,
            uploaded: _uploaded.containsKey(idx),
            fileName: _uploaded[idx],
            ocrBadge: _ocrBadge(idx),
            onTap: () => _pickDoc(idx),
          );
        }),

        if (optional.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Optional Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          const SizedBox(height: 8),
          ...optional.asMap().entries.map((e) {
            final idx = docs.indexOf(optional[e.key]);
            return _UploadRow(
              title: e.value.$1, subtitle: e.value.$2, required: false,
              uploaded: _uploaded.containsKey(idx),
              fileName: _uploaded[idx],
              ocrBadge: _ocrBadge(idx),
              onTap: () => _pickDoc(idx),
            );
          }),
        ],

        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: allRequiredDone ? () => widget.onNext(_ocrData) : null,
          icon: const Icon(Icons.psychology_outlined),
          label: const Text('Get AI Verification Score →'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48),
            backgroundColor: allRequiredDone ? AppColors.safe : null),
        ),
        if (!allRequiredDone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Upload ${required.length - reqUploaded} more required document(s) to continue',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight), textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _ocrBadge(int idx) {
    if (_analyzing[idx] == true) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Row(children: [
          SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
          SizedBox(width: 6),
          Text('Reading with AI...', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
        ]),
      );
    }
    final data = _ocrData[idx];
    if (data == null) return const SizedBox.shrink();
    final docType = data['document_type']?.toString() ?? '';
    final owner = data['owner_name']?.toString() ?? data['ownerName']?.toString() ?? '';
    final survey = data['survey_number']?.toString() ?? '';
    final parts = <String>[];
    if (docType.isNotEmpty) parts.add(docType);
    if (owner.isNotEmpty) parts.add('Owner: $owner');
    if (survey.isNotEmpty) parts.add('Survey: $survey');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('AI Read: ${parts.join(' · ')}',
        style: const TextStyle(fontSize: 10, color: AppColors.safe, fontWeight: FontWeight.w500)),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final String title, subtitle;
  final bool required, uploaded;
  final String? fileName;
  final Widget ocrBadge;
  final VoidCallback onTap;
  const _UploadRow({required this.title, required this.subtitle,
    required this.required, required this.uploaded, required this.onTap,
    this.fileName, this.ocrBadge = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: uploaded ? AppColors.safe.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: uploaded ? AppColors.safe.withOpacity(0.4) : AppColors.borderColor),
        ),
        child: Row(children: [
          Icon(uploaded ? Icons.check_circle_rounded : Icons.upload_file_outlined,
            color: uploaded ? AppColors.safe : (required ? AppColors.warning : AppColors.textLight), size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              if (required && !uploaded) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Text('Required', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold)),
              ),
            ]),
            if (uploaded && fileName != null)
              Text(fileName!, style: const TextStyle(fontSize: 11, color: AppColors.safe, fontWeight: FontWeight.w500))
            else
              Text(uploaded ? 'Uploaded ✓' : subtitle, style: TextStyle(fontSize: 11, color: uploaded ? AppColors.safe : AppColors.textLight)),
            ocrBadge,
          ])),
          const SizedBox(width: 8),
          Text(uploaded ? 'Re-upload' : 'Upload', style: TextStyle(fontSize: 11, color: uploaded ? AppColors.textLight : AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Seller Step 4: AI Score + List Property ─────────────────────────────────
class _SellerStep4List extends StatefulWidget {
  final String propertyType, district;
  final Map<int, Map<String, dynamic>> ocrResults;
  const _SellerStep4List({super.key, required this.propertyType, required this.district, required this.ocrResults});
  @override
  State<_SellerStep4List> createState() => _SellerStep4ListState();
}

class _SellerStep4ListState extends State<_SellerStep4List> {
  String? _chosenPlan;
  bool _showScore = true;

  @override
  Widget build(BuildContext context) {
    if (_chosenPlan != null) return _buildSuccess();
    if (_showScore) return _buildScoreScreen();
    return _buildPlans();
  }

  // ── Real OCR-based trust score calculation ────────────────────────────────
  _TrustResult _computeScore() {
    final ocr = widget.ocrResults;
    if (ocr.isEmpty) return _TrustResult(score: 0, flags: ['No documents read by AI — upload real documents to get a score']);

    // Collect all extracted values across documents
    final allOwners = <String>[];
    final allSurveys = <String>[];
    final flags = <String>[];
    final positives = <String>[];
    bool injunctionFound = false;
    bool mortgageFound = false;
    bool agriculturalFound = false;
    bool ocFound = false;
    bool reraFound = false;
    String? khataType;
    int docsReadSuccessfully = 0;

    for (final entry in ocr.entries) {
      final d = entry.value;
      final raw = (d['raw_text'] ?? '').toString().toLowerCase();
      final owner = d['owner_name']?.toString() ?? d['ownerName']?.toString() ?? '';
      final survey = d['survey_number']?.toString() ?? d['surveyNumber']?.toString() ?? '';
      final docType = (d['document_type'] ?? d['documentType'] ?? '').toString().toLowerCase();
      final landType = (d['land_type'] ?? d['landType'] ?? '').toString().toLowerCase();
      final encFree = d['encumbrance_free'] ?? d['encumbranceFree'];
      final kt = (d['khata_type'] ?? d['khataType'] ?? '').toString().toLowerCase();

      if (owner.isNotEmpty || survey.isNotEmpty || docType.isNotEmpty) docsReadSuccessfully++;
      if (owner.isNotEmpty) allOwners.add(owner.toLowerCase().trim());
      if (survey.isNotEmpty) allSurveys.add(survey.trim());

      // Injunction detection
      if (raw.contains('injunction') || raw.contains('stay order') || raw.contains('nirbandha') || raw.contains('prohibitory')) {
        injunctionFound = true;
      }
      // Mortgage detection
      if (encFree == false || raw.contains('mortgage') || raw.contains('hypothecation') || raw.contains('charge')) {
        mortgageFound = true;
      }
      // Agricultural detection
      if (landType.contains('dry') || landType.contains('wet') || landType.contains('agriculture') ||
          raw.contains('agricultural') || raw.contains('krishi') || raw.contains('bagayat')) {
        agriculturalFound = true;
      }
      // OC detection
      if (docType.contains('occupancy') || raw.contains('occupancy certificate') || raw.contains('oc issued')) {
        ocFound = true;
      }
      // RERA
      if (docType.contains('rera') || raw.contains('rera') || raw.contains('real estate regulatory')) {
        reraFound = true;
      }
      // Khata type
      if (kt.contains('a-khata') || kt.contains('a khata')) khataType = 'A';
      if (kt.contains('b-khata') || kt.contains('b khata')) khataType = 'B';
    }

    // Score computation
    int score = 0;

    // Base: docs read
    final readRatio = ocr.isEmpty ? 0 : docsReadSuccessfully / ocr.length;
    score += (readRatio * 20).round(); // up to 20 pts for successful reads

    // Ownership consistency: all owner names match
    final uniqueOwners = allOwners.toSet();
    if (uniqueOwners.length == 1 && allOwners.length >= 2) {
      score += 20; positives.add('Owner name consistent across all documents ✓');
    } else if (allOwners.length == 1) {
      score += 12; positives.add('Owner name found in ${allOwners.length} document');
    } else if (uniqueOwners.length > 1) {
      flags.add('Owner name mismatch across documents — ${uniqueOwners.join(' vs ')}');
    }

    // Survey number consistency
    final uniqueSurveys = allSurveys.toSet();
    if (uniqueSurveys.length == 1 && allSurveys.length >= 2) {
      score += 15; positives.add('Survey number consistent: ${allSurveys.first} ✓');
    } else if (allSurveys.length == 1) {
      score += 8; positives.add('Survey number found: ${allSurveys.first}');
    } else if (uniqueSurveys.length > 1) {
      flags.add('Survey number mismatch: ${uniqueSurveys.join(' vs ')}');
    }

    // Encumbrance
    if (!mortgageFound) {
      score += 15; positives.add('No mortgage or charge detected in documents ✓');
    } else {
      flags.add('Active mortgage or charge found — buyer inherits liability');
    }

    // Injunction
    if (!injunctionFound) {
      score += 10; positives.add('No court injunction or stay order found ✓');
    } else {
      score -= 30; flags.add('CRITICAL: Court injunction or stay order detected');
    }

    // Agricultural
    if (!agriculturalFound) {
      score += 10; positives.add('Land is non-agricultural (safe for construction) ✓');
    } else {
      score -= 20; flags.add('Agricultural land detected — construction illegal without DC Conversion');
    }

    // Khata
    if (khataType == 'A') {
      score += 5; positives.add('A-Khata confirmed — safer ✓');
    } else if (khataType == 'B') {
      flags.add('B-Khata detected — risky, incomplete approval');
    }

    // OC
    if (ocFound) {
      score += 5; positives.add('Occupancy Certificate found ✓');
    }

    score = score.clamp(0, 100);
    return _TrustResult(score: score, flags: flags, positives: positives,
      injunctionFound: injunctionFound, mortgageFound: mortgageFound, agriculturalFound: agriculturalFound,
      ownerNames: allOwners.toSet().toList(), surveyNumbers: allSurveys.toSet().toList(), docsRead: docsReadSuccessfully);
  }

  // ── Property-type-aware trust score screen ────────────────────────────────
  Widget _buildScoreScreen() {
    final type = widget.propertyType;
    final isAgri = type == 'Agricultural Land';
    final result = _computeScore();
    final score = result.score;

    final scoreBand = score >= 80 ? 'Safe to Proceed' : score >= 60 ? 'Caution — Review Recommended' : 'High Risk — Do Not Proceed';
    final bandColor = score >= 80 ? AppColors.safe : score >= 60 ? const Color(0xFFE65100) : Colors.red;
    final bandBg = bandColor.withOpacity(0.15);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 4 of 4', 'AI Verification Report', Icons.analytics_outlined, AppColors.primary),
        const SizedBox(height: 16),

        // Score banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B3A5C), Color(0xFF0D2137)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text(type, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            const Text('Trust Score', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('$score', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
            const Text('/ 100', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 6),
            Text('${result.docsRead} of ${widget.ocrResults.length} documents read by AI',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: bandBg, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: bandColor.withOpacity(0.5))),
              child: Text(score >= 80 ? '✓  $scoreBand' : '⚠️  $scoreBand',
                style: TextStyle(color: bandColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // What AI found (positives)
        if (result.positives.isNotEmpty) ...[
          _ScoreSection('Verified ✓', result.positives.map((p) =>
            _ScoreRow(p, '', Colors.green, Icons.check_circle_rounded)).toList()),
          const SizedBox(height: 12),
        ],

        // Extracted values
        if (result.ownerNames.isNotEmpty || result.surveyNumbers.isNotEmpty)
          _ScoreSection('Extracted from Documents', [
            if (result.ownerNames.isNotEmpty)
              _ScoreRow('Owner Name(s)', result.ownerNames.join(', '), Colors.blueGrey, Icons.person_outline),
            if (result.surveyNumbers.isNotEmpty)
              _ScoreRow('Survey Number(s)', result.surveyNumbers.join(', '), Colors.blueGrey, Icons.map_outlined),
            if (result.ownerNames.toSet().length > 1)
              _ScoreRow('Name Mismatch', 'DIFFERENT names found — verify', Colors.red, Icons.warning_amber_rounded),
          ]),
        const SizedBox(height: 12),

        // Risk flags
        if (result.flags.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: result.injunctionFound ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: result.injunctionFound ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(result.injunctionFound ? Icons.dangerous_outlined : Icons.info_outline_rounded,
                  color: result.injunctionFound ? Colors.red : const Color(0xFFE65100), size: 16),
                const SizedBox(width: 6),
                Text('${result.flags.length} Risk Flag${result.flags.length > 1 ? 's' : ''} Detected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                    color: result.injunctionFound ? Colors.red : const Color(0xFFE65100))),
              ]),
              const SizedBox(height: 8),
              ...result.flags.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $f', style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87)),
              )),
            ]),
          ),
        if (result.flags.isEmpty && result.score > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.safe.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.safe.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('No risk flags detected in uploaded documents. Proceed with confidence.',
                style: TextStyle(fontSize: 12, color: AppColors.safe))),
            ]),
          ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showScore = false),
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Proceed to List Property →'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.safe,
              foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }


  // ── Listing plans ──────────────────────────────────────────────────────────
  Widget _buildPlans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 4 of 4', 'List & Set Price', Icons.sell_outlined, AppColors.primary),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), AppColors.safe]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Icon(Icons.verified_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Verified ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Your documents have been verified. Your listing will show a verified badge.',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Choose Listing Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _PlanCard('₹99', 'Basic Verified Listing',
          ['Verified badge on listing', 'Basic AI document score', 'Up to 3 buyer inquiries'],
          AppColors.primary, false, onChoose: () => setState(() => _chosenPlan = '₹99 Basic')),
        const SizedBox(height: 8),
        _PlanCard('₹199', 'Standard — Recommended',
          ['Everything in Basic', 'Full AI verification report', 'Unlimited buyer inquiries', 'Priority in search results'],
          AppColors.safe, true, onChoose: () => setState(() => _chosenPlan = '₹199 Standard')),
        const SizedBox(height: 8),
        _PlanCard('₹499', 'Premium — Maximum Visibility',
          ['Everything in Standard', 'Featured listing placement', 'Expert help (lawyer/surveyor)', 'Digital escrow setup'],
          const Color(0xFF6A1B9A), false, onChoose: () => setState(() => _chosenPlan = '₹499 Premium')),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), AppColors.safe]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 52),
            const SizedBox(height: 12),
            const Text('Listing Published!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Plan: $_chosenPlan', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Verified badge added. Buyers can now find your property.',
              style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _AfterListItem(Icons.notifications_outlined, 'Buyer alerts are live', 'You\'ll be notified when buyers show interest'),
        _AfterListItem(Icons.chat_outlined, 'Secure chat enabled', 'Buyers pay ₹99 to contact you — no spam'),
        _AfterListItem(Icons.lock_outlined, 'Document vault is active', 'Buyer can view your docs only after agreeing to proceed'),
        _AfterListItem(Icons.assignment_outlined, 'e-Sign agreement ready', 'When buyer is found, sign digitally — legally valid'),
        _AfterListItem(Icons.account_balance_outlined, 'SRO registration guide', 'We guide both parties through registration'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/partners'),
            icon: const Icon(Icons.people_outline, size: 16),
            label: const Text('Talk to a Legal Expert'),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Trust score result model ───────────────────────────────────────────────────
class _TrustResult {
  final int score;
  final List<String> flags;
  final List<String> positives;
  final bool injunctionFound;
  final bool mortgageFound;
  final bool agriculturalFound;
  final List<String> ownerNames;
  final List<String> surveyNumbers;
  final int docsRead;
  const _TrustResult({
    required this.score,
    this.flags = const [],
    this.positives = const [],
    this.injunctionFound = false,
    this.mortgageFound = false,
    this.agriculturalFound = false,
    this.ownerNames = const [],
    this.surveyNumbers = const [],
    this.docsRead = 0,
  });
}

// ── Score helpers ──────────────────────────────────────────────────────────────
Widget _ScoreSection(String title, List<Widget> rows) {
  return Container(
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
      ),
      const Divider(height: 1),
      ...rows,
    ]),
  );
}

Widget _ScoreRow(String label, String value, Color color, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
      Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _PlanCard extends StatelessWidget {
  final String price, title;
  final List<String> features;
  final Color color;
  final bool highlighted;
  final VoidCallback onChoose;
  const _PlanCard(this.price, this.title, this.features, this.color, this.highlighted, {required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlighted ? color : AppColors.borderColor, width: highlighted ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
          if (highlighted) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: const Text('Best', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: color, size: 14),
            const SizedBox(width: 6),
            Text(f, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
          ]),
        )),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onChoose,
            style: ElevatedButton.styleFrom(backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 10)),
            child: Text('Choose $price Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

class _AfterListItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _AfterListItem(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.safe.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.safe, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ])),
      ]),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────
class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          height: 3,
          margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
          color: i <= current ? AppColors.safe : AppColors.borderColor,
        ),
      )),
    );
  }
}

class _SHeader extends StatelessWidget {
  final String step, title;
  final IconData icon;
  final Color color;
  const _SHeader(this.step, this.title, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
      ]),
    ]);
  }
}

InputDecoration _deco(String label) => InputDecoration(
  labelText: label,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.borderColor)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);
