import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Seller Listing Screen ─────────────────────────────────────────────────────
// Step-by-step flow:
//   Step 1  — Location (state → district → taluk → village)
//   Step 2  — Property details (type, area, price, description)
//   Step 3  — Document upload (with CIBIL-like document score)
//   Step 4  — GPS + photos
//   Step 5  — Pricing & publish (₹99 basic / ₹499 full service)
// ──────────────────────────────────────────────────────────────────────────────

class SellerListingScreen extends ConsumerStatefulWidget {
  const SellerListingScreen({super.key});

  @override
  ConsumerState<SellerListingScreen> createState() =>
      _SellerListingScreenState();
}

class _SellerListingScreenState extends ConsumerState<SellerListingScreen> {
  int _step = 0; // 0–4
  final _pageController = PageController();

  // ── Step 1: Location ─────────────────────────────────────────────────────
  String? _state = 'Karnataka';
  final _districtCtrl = TextEditingController();
  final _talukCtrl    = TextEditingController();
  final _villageCtrl  = TextEditingController();

  // ── Step 2: Property details ──────────────────────────────────────────────
  String _propType = 'site';
  final _areaCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  // ── Step 3: Documents ─────────────────────────────────────────────────────
  final Map<String, bool> _docsPresent = {
    'RTC / Pahani':          false,
    'Encumbrance Certificate (EC)': false,
    'Khata Certificate':     false,
    'Khata Extract':         false,
    'Sale Deed / Title Deed': false,
    'Survey Sketch':         false,
    'Tax Receipts (3 years)': false,
    'NOC from Panchayat / BBMP': false,
    'Approved Building Plan': false,
    'RERA Certificate':      false,
  };

  final Map<String, String> _docGuidelines = {
    'RTC / Pahani':
        'Download from Bhoomi portal (bhoomi.karnataka.gov.in). Must be latest — within 3 months.',
    'Encumbrance Certificate (EC)':
        'Get EC for last 30 years from SRO. Must show no encumbrances or list them all.',
    'Khata Certificate':
        'Issued by BBMP / CMC / Panchayat. Confirms property is in their records.',
    'Khata Extract':
        'Shows property tax account details. Must match your name after mutation.',
    'Sale Deed / Title Deed':
        'Registered deed from SRO. Must have Sub-Registrar stamp. All pages present.',
    'Survey Sketch':
        'From Survey Department. Shows exact boundaries and survey number.',
    'Tax Receipts (3 years)':
        'Property tax paid receipts for the last 3 years. Proves no dues.',
    'NOC from Panchayat / BBMP':
        'No-objection from local body. Required for plots in approved layouts.',
    'Approved Building Plan':
        'BBMP / BDA approved plan. Required for constructed properties.',
    'RERA Certificate':
        'Required only for apartment projects. Download from RERA portal.',
  };

  // ── Step 4: GPS + photos ──────────────────────────────────────────────────
  final List<XFile> _photos = [];
  String? _gpsCoords;

  // ── Step 5: Pricing ───────────────────────────────────────────────────────
  String _plan = 'basic'; // 'basic' ₹99 or 'full' ₹499

  @override
  void dispose() {
    _pageController.dispose();
    _districtCtrl.dispose();
    _talukCtrl.dispose();
    _villageCtrl.dispose();
    _areaCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Document score (0–100) ────────────────────────────────────────────────
  int get _docScore {
    const weights = {
      'RTC / Pahani':               20,
      'Encumbrance Certificate (EC)': 20,
      'Khata Certificate':          15,
      'Khata Extract':              10,
      'Sale Deed / Title Deed':     15,
      'Survey Sketch':               5,
      'Tax Receipts (3 years)':      5,
      'NOC from Panchayat / BBMP':   5,
      'Approved Building Plan':      3,
      'RERA Certificate':            2,
    };
    int total = 0;
    for (final entry in _docsPresent.entries) {
      if (entry.value) total += (weights[entry.key] ?? 0);
    }
    return total;
  }

  Color get _scoreColor {
    if (_docScore >= 75) return AppColors.safe;
    if (_docScore >= 45) return AppColors.warning;
    return AppColors.critical;
  }

  String get _scoreLabel {
    if (_docScore >= 75) return 'Strong';
    if (_docScore >= 45) return 'Fair';
    return 'Weak';
  }

  void _nextStep() {
    if (_step < 4) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.take(10 - _photos.length));
      });
    }
  }

  Future<void> _getLocation() async {
    // Simulate GPS — in production wire up geolocator
    setState(() => _gpsCoords = '12.9716° N, 77.5946° E');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS location captured'),
        backgroundColor: AppColors.safe,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('List Your Property'),
        backgroundColor: Colors.white,
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              ),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepBar(current: _step),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Location ──────────────────────────────────────────────────────
  Widget _buildStep1() {
    final states = [
      'Karnataka', 'Maharashtra', 'Tamil Nadu', 'Telangana',
      'Andhra Pradesh', 'Kerala', 'Gujarat', 'Rajasthan',
    ];

    return _StepScroll(
      title: 'Where is the property?',
      subtitle: 'We use this to show it to buyers searching in your area.',
      child: Column(
        children: [
          // State picker
          DropdownButtonFormField<String>(
            value: _state,
            decoration: _inputDec('State'),
            items: states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _state = v),
          ),
          const SizedBox(height: 14),
          _Field(ctrl: _districtCtrl, label: 'District',
              hint: 'e.g. Bengaluru Urban'),
          const SizedBox(height: 14),
          _Field(ctrl: _talukCtrl, label: 'Taluk / Tehsil',
              hint: 'e.g. Bangalore North'),
          const SizedBox(height: 14),
          _Field(ctrl: _villageCtrl, label: 'Village / Locality',
              hint: 'e.g. Yelahanka'),
          const SizedBox(height: 28),
          _NextButton(
            onTap: _districtCtrl.text.isNotEmpty ? _nextStep : null,
            label: 'Next: Property Details →',
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Property details ──────────────────────────────────────────────
  Widget _buildStep2() {
    final types = [
      ('site',       Icons.landscape_outlined,      'Site / Plot'),
      ('apartment',  Icons.apartment_outlined,       'Apartment'),
      ('house',      Icons.house_outlined,           'House / Villa'),
      ('bda_layout', Icons.grid_view_outlined,       'BDA Layout'),
      ('commercial', Icons.store_outlined,           'Commercial'),
      ('farm',       Icons.agriculture_outlined,     'Farm Land'),
    ];

    return _StepScroll(
      title: 'Tell us about the property',
      subtitle: 'Accurate details help buyers trust your listing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: types.map((t) {
              final selected = _propType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _propType = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t.$2,
                        size: 16,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(t.$3,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textDark,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: _Field(
                ctrl: _areaCtrl,
                label: 'Area',
                hint: 'e.g. 1200',
                suffix: 'sq.ft',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                ctrl: _priceCtrl,
                label: 'Asking Price (₹)',
                hint: 'e.g. 4500000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _inputDec('Description').copyWith(
              hintText: 'Describe your property — key features, nearby landmarks, '
                  'road access, water/electricity, vastu, etc.',
              hintMaxLines: 3,
            ),
          ),
          const SizedBox(height: 28),
          _NextButton(
            onTap: _areaCtrl.text.isNotEmpty ? _nextStep : null,
            label: 'Next: Upload Documents →',
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Documents + CIBIL-like score ─────────────────────────────────
  Widget _buildStep3() {
    return _StepScroll(
      title: 'Upload your documents',
      subtitle: 'Higher document score = more buyer trust = faster sale.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          _DocScoreCard(score: _docScore, label: _scoreLabel, color: _scoreColor),
          const SizedBox(height: 20),
          const Text('Check the documents you have ready',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text(
            'You can still list without all docs — but more docs = higher score.',
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          ..._docsPresent.entries.map((e) => _DocCheckTile(
                name: e.key,
                checked: e.value,
                guideline: _docGuidelines[e.key] ?? '',
                onChanged: (v) =>
                    setState(() => _docsPresent[e.key] = v ?? false),
              )),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Buyers who see RTC + EC + Khata are 3× more likely to '
                    'contact you. These 3 together add 55 points to your score.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _NextButton(
            onTap: _nextStep,
            label: 'Next: GPS & Photos →',
          ),
        ],
      ),
    );
  }

  // ─── Step 4: GPS + photos ──────────────────────────────────────────────────
  Widget _buildStep4() {
    return _StepScroll(
      title: 'GPS location & photos',
      subtitle: 'Buyers want to see exactly where and what the property looks like.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Property GPS Location',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 4),
                const Text(
                  'Stand at the property boundary and tap the button below.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                if (_gpsCoords != null) ...[
                  Row(children: [
                    const Icon(Icons.location_on,
                        color: AppColors.safe, size: 16),
                    const SizedBox(width: 6),
                    Text(_gpsCoords!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.safe,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: Text(_gpsCoords == null
                      ? 'Capture GPS Location'
                      : 'Re-capture Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Photos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Property Photos',
                        style: TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 13, color: AppColors.textDark)),
                    Text('${_photos.length}/10',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add exterior, interior, survey stone, road access, water source.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                if (_photos.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photos[i].path),
                              width: 80, height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _photos.removeAt(i)),
                              child: Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_photos.length < 10)
                  OutlinedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: Text(_photos.isEmpty
                        ? 'Add Photos (max 10)'
                        : 'Add More Photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _NextButton(
            onTap: _nextStep,
            label: 'Next: Choose Plan →',
          ),
        ],
      ),
    );
  }

  // ─── Step 5: Pricing & publish ─────────────────────────────────────────────
  Widget _buildStep5() {
    return _StepScroll(
      title: 'Choose your listing plan',
      subtitle: 'Start with Basic or go Full Service for more reach.',
      child: Column(
        children: [
          _PlanCard(
            selected: _plan == 'basic',
            price: '₹99',
            title: 'Basic Listing',
            tag: null,
            features: const [
              'Listed in search results',
              'Document score badge shown',
              'Buyers can request contact (moderated)',
              'Valid for 30 days',
            ],
            onTap: () => setState(() => _plan = 'basic'),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            selected: _plan == 'full',
            price: '₹499',
            title: 'Full Service Listing',
            tag: 'RECOMMENDED',
            features: const [
              'Everything in Basic +',
              'Arth ID Verified badge',
              'Buyers see your contact details',
              'AI property analysis report',
              'WhatsApp leads notification',
              'Document lock & share with buyer',
              'Valid for 90 days',
            ],
            onTap: () => setState(() => _plan = 'full'),
          ),
          const SizedBox(height: 20),
          // Document score reminder
          if (_docScore < 75) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _scoreColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _scoreColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your document score is $_docScore/100 ($_scoreLabel). '
                      'Uploading more documents before publishing will help '
                      'buyers trust your listing faster.',
                      style: TextStyle(
                          fontSize: 11, color: _scoreColor, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: _submitListing,
            style: ElevatedButton.styleFrom(
              backgroundColor: _plan == 'full'
                  ? const Color(0xFF7B1FA2)
                  : AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _plan == 'full'
                  ? 'Pay ₹499 & Publish Full Service'
                  : 'Pay ₹99 & Publish Basic Listing',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Payment via UPI. You can upgrade to Full Service anytime.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _submitListing() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.safe, size: 28),
          const SizedBox(width: 10),
          const Text('Listing Submitted!',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your property listing has been submitted with a document '
              'score of $_docScore/100.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Next steps:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text('• Complete payment to go live',
                style: TextStyle(fontSize: 12)),
            const Text('• Our team verifies within 24 hours',
                style: TextStyle(fontSize: 12)),
            const Text('• Buyers can then find and contact you',
                style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      );
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _StepScroll extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScroll({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current;

  const _StepBar({required this.current});

  static const labels = ['Location', 'Details', 'Documents', 'Photos', 'Publish'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.safe
                            : active
                                ? AppColors.primary
                                : AppColors.borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(labels[i],
                        style: TextStyle(
                            fontSize: 9,
                            color: active
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ],
                ),
                if (i < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: done ? AppColors.safe : AppColors.borderColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _NextButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: AppColors.borderColor,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _DocScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final Color color;

  const _DocScoreCard(
      {required this.score, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64, height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 7,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('$score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Document Score',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  score >= 75
                      ? 'Excellent! Buyers will trust your listing.'
                      : score >= 45
                          ? 'Good start. Add more docs to boost score.'
                          : 'Add at least RTC + EC + Khata to improve.',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocCheckTile extends StatelessWidget {
  final String name;
  final bool checked;
  final String guideline;
  final ValueChanged<bool?> onChanged;

  const _DocCheckTile({
    required this.name,
    required this.checked,
    required this.guideline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: checked
            ? AppColors.safe.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: checked
                ? AppColors.safe.withOpacity(0.3)
                : AppColors.borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.safe,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      checked ? FontWeight.w600 : FontWeight.normal,
                  color: checked
                      ? AppColors.safe
                      : AppColors.textDark)),
          trailing: const Icon(Icons.info_outline,
              size: 15, color: AppColors.textLight),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                guideline,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool selected;
  final String price;
  final String title;
  final String? tag;
  final List<String> features;
  final VoidCallback onTap;

  const _PlanCard({
    required this.selected,
    required this.price,
    required this.title,
    required this.tag,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPurple = tag != null;
    final accent = isPurple ? const Color(0xFF7B1FA2) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? accent : AppColors.borderColor,
              width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                      color:
                          selected ? accent : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark)),
                ]),
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(tag!,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accent)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(price,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accent)),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(f,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                                height: 1.3)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
