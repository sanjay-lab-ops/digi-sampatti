import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surveyController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedHobli;
  String? _selectedVillage;

  // Karnataka district → taluk mapping (abbreviated for key districts)
  static const Map<String, List<String>> districtTaluks = {
    'Bengaluru Urban': ['Anekal', 'Bengaluru East', 'Bengaluru North', 'Bengaluru South', 'Yelahanka'],
    'Bengaluru Rural': ['Devanahalli', 'Doddaballapura', 'Hoskote', 'Nelamangala'],
    'Mysuru': ['Hunsur', 'K.R.Nagar', 'Mysuru', 'Nanjangud', 'Periyapatna', 'T.Narasipura'],
    'Tumakuru': ['Chikkanayakanahalli', 'Gubbi', 'Koratagere', 'Kunigal', 'Madhugiri', 'Pavagada', 'Sira', 'Tiptur', 'Tumakuru'],
    'Mangaluru': ['Belthangady', 'Bantwal', 'Puttur', 'Sullia', 'Mangaluru'],
    'Hubballi-Dharwad': ['Dharwad', 'Hubballi', 'Kundgol', 'Kalghatgi', 'Navalgund'],
    'Belagavi': ['Athani', 'Bailhongal', 'Belagavi', 'Chikkodi', 'Gokak', 'Hukkeri', 'Khanapur', 'Raibag', 'Ramdurg', 'Savadatti'],
    'Kalaburagi': ['Afzalpur', 'Aland', 'Chincholi', 'Chittapur', 'Gurmatkal', 'Jevargi', 'Kalaburagi', 'Sedam'],
    'Hassan': ['Alur', 'Arakalagudu', 'Arsikere', 'Belur', 'Channarayapatna', 'Hassan', 'Holenarasipur', 'Sakleshpur'],
    'Shivamogga': ['Bhadravati', 'Hosanagara', 'Sagar', 'Shikaripura', 'Shivamogga', 'Sorab', 'Thirthahalli'],
  };

  List<String> get _taluks => _selectedDistrict != null
      ? (districtTaluks[_selectedDistrict] ?? [])
      : [];

  @override
  void dispose() {
    _surveyController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;

    final scan = PropertyScan(
      id: const Uuid().v4(),
      surveyNumber: _surveyController.text.trim(),
      district: _selectedDistrict,
      taluk: _selectedTaluk,
      hobli: _selectedHobli,
      village: _selectedVillage,
      location: ref.read(currentLocationProvider),
      scanMethod: ScanMethod.manual,
      scannedAt: DateTime.now(),
    );

    ref.read(currentScanProvider.notifier).state = scan;
    ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);

    context.push('/records', extra: {
      'district': _selectedDistrict,
      'taluk': _selectedTaluk,
      'hobli': _selectedHobli ?? '',
      'village': _selectedVillage ?? '',
      'surveyNumber': _surveyController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manual Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter the survey number from your sale deed or RTC document.\nDon\'t know it? Ask the seller — it\'s on every land document.',
                        style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Survey Number
              const _FieldLabel('Survey Number (from land document)', required: true),
              TextFormField(
                controller: _surveyController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 45/2  or  123  or  67/A',
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'Look for "Survey No." or "Sy. No." on the RTC / sale deed',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter survey number' : null,
              ),
              const SizedBox(height: 16),

              // District
              const _FieldLabel('District (where the land is)', required: true),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.location_city)),
                hint: const Text('Select District'),
                items: AppStrings.karnatakaDistricts.map((d) =>
                  DropdownMenuItem(value: d, child: Text(d))
                ).toList(),
                onChanged: (v) => setState(() {
                  _selectedDistrict = v;
                  _selectedTaluk = null;
                  _selectedHobli = null;
                  _selectedVillage = null;
                }),
                validator: (v) => v == null ? 'Select district' : null,
              ),
              const SizedBox(height: 16),

              // Taluk
              if (_selectedDistrict != null) ...[
                const _FieldLabel('Taluk (optional — helps narrow results)'),
                DropdownButtonFormField<String>(
                  value: _selectedTaluk,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.map_outlined)),
                  hint: const Text('Select Taluk (optional)'),
                  items: _taluks.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))
                  ).toList(),
                  onChanged: (v) => setState(() { _selectedTaluk = v; }),
                ),
                const SizedBox(height: 16),
              ],

              // Village (optional)
              const _FieldLabel('Village / Area (optional)'),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'e.g. Yelahanka, Devanahalli...',
                  prefixIcon: Icon(Icons.villa_outlined),
                ),
                onChanged: (v) => _selectedVillage = v,
              ),
              const SizedBox(height: 32),

              // Search Button
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text(AppStrings.searchRecords),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/map'),
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark,
          )),
          if (required)
            const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
