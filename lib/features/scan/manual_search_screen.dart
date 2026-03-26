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
  final _ownerNameController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedHobli;
  String? _selectedVillage;

  // 0 = Survey Number mode, 1 = Village/Name mode (rural friendly)
  int _searchMode = 0;

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
    _ownerNameController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    final surveyNo = _searchMode == 0
        ? _surveyController.text.trim()
        : (_selectedVillage ?? '');
    final scan = PropertyScan(
      id: const Uuid().v4(),
      surveyNumber: surveyNo,
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
      'surveyNumber': surveyNo,
      'ownerName': _ownerNameController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ಜಮೀನು ಪರಿಶೀಲನೆ / Property Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Mode Toggle ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModeTab(
                      icon: Icons.tag,
                      label: 'ಸರ್ವೆ ನಂಬರ್ ಇದೆ',
                      sublabel: 'I have survey number',
                      selected: _searchMode == 0,
                      onTap: () => setState(() => _searchMode = 0),
                    ),
                    _ModeTab(
                      icon: Icons.location_village,
                      label: 'ಹಳ್ಳಿ / ಹೆಸರಿನಿಂದ',
                      sublabel: 'Search by village / name',
                      selected: _searchMode == 1,
                      onTap: () => setState(() => _searchMode = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── MODE 0: Survey Number ────────────────────────────────
              if (_searchMode == 0) ...[
                _KannadaFieldLabel(
                  kannada: 'ಸರ್ವೆ ನಂಬರ್',
                  english: 'Survey Number (from land document)',
                  required: true,
                ),
                TextFormField(
                  controller: _surveyController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 45/2  or  123  or  67/A',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'ಸರ್ವೆ ನಂಬರ್ ನಮೂದಿಸಿ / Enter survey number'
                      : null,
                ),
                const SizedBox(height: 6),
                const _SurveyHint(),
                const SizedBox(height: 16),
              ],

              // ── MODE 1: Village / Owner Name ─────────────────────────
              if (_searchMode == 1) ...[
                // Rural-friendly banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ಸರ್ವೆ ನಂಬರ್ ಗೊತ್ತಿಲ್ಲವೇ? ಹಳ್ಳಿ ಮತ್ತು ಮಾಲೀಕರ ಹೆಸರಿನಿಂದ ಹುಡುಕಿ.\n'
                          'No survey number? Search by village + owner name.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _KannadaFieldLabel(
                  kannada: 'ಮಾಲೀಕರ ಹೆಸರು',
                  english: 'Owner / Seller Name',
                  required: false,
                ),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ramesh Kumar, Krishnappa...',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Common: District / Taluk / Village ───────────────────
              _KannadaFieldLabel(
                kannada: 'ಜಿಲ್ಲೆ',
                english: 'District (where the land is)',
                required: true,
              ),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city)),
                hint: const Text('ಜಿಲ್ಲೆ ಆಯ್ಕೆ ಮಾಡಿ / Select District'),
                isExpanded: true,
                items: AppStrings.karnatakaDistricts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedDistrict = v;
                  _selectedTaluk = null;
                  _selectedHobli = null;
                  _selectedVillage = null;
                }),
                validator: (v) =>
                    v == null ? 'ಜಿಲ್ಲೆ ಆಯ್ಕೆ ಮಾಡಿ / Select district' : null,
              ),
              const SizedBox(height: 16),

              if (_selectedDistrict != null) ...[
                _KannadaFieldLabel(
                  kannada: 'ತಾಲ್ಲೂಕು',
                  english: 'Taluk',
                  required: false,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedTaluk,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.map_outlined)),
                  hint: const Text('ತಾಲ್ಲೂಕು ಆಯ್ಕೆ ಮಾಡಿ / Select Taluk'),
                  isExpanded: true,
                  items: _taluks
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTaluk = v),
                ),
                const SizedBox(height: 16),
              ],

              _KannadaFieldLabel(
                kannada: 'ಹಳ್ಳಿ / ಬಡಾವಣೆ',
                english: 'Village / Area',
                required: _searchMode == 1,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'ಉದಾ: ಯಲಹಂಕ, ದೇವನಹಳ್ಳಿ... / e.g. Yelahanka...',
                  prefixIcon: Icon(Icons.villa_outlined),
                ),
                onChanged: (v) => setState(() => _selectedVillage = v),
                validator: (v) => _searchMode == 1 && (v == null || v.isEmpty)
                    ? 'ಹಳ್ಳಿ ಹೆಸರು ನಮೂದಿಸಿ / Enter village name'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Rural Help Box ───────────────────────────────────────
              const _RuralHelpCard(),
              const SizedBox(height: 24),

              // ── Search Button ────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('ಹುಡುಕಿ / Search Property'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/map'),
                icon: const Icon(Icons.map),
                label: const Text('ನಕ್ಷೆಯಲ್ಲಿ ನೋಡಿ / View on Map'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Tab ──────────────────────────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.icon, required this.label, required this.sublabel,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey)),
              Text(sublabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kannada Field Label ───────────────────────────────────────────────────────
class _KannadaFieldLabel extends StatelessWidget {
  final String kannada, english;
  final bool required;
  const _KannadaFieldLabel({
    required this.kannada, required this.english, this.required = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(kannada,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary)),
          const SizedBox(width: 6),
          Text('/ $english',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (required)
            const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

// ── Rural Help Card ───────────────────────────────────────────────────────────
class _RuralHelpCard extends StatefulWidget {
  const _RuralHelpCard();
  @override
  State<_RuralHelpCard> createState() => _RuralHelpCardState();
}

class _RuralHelpCardState extends State<_RuralHelpCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ಸಹಾಯ ಬೇಕೇ? / Need help finding property details?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: Colors.amber),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Divider(),
                  SizedBox(height: 4),
                  _HelpRow('📄', 'ಆರ್‌ಟಿಸಿ / RTC ಪತ್ರ',
                      'ಸರ್ವೆ ನಂಬರ್ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಇರುತ್ತದೆ\nSurvey number is on top of RTC document'),
                  SizedBox(height: 8),
                  _HelpRow('🏠', 'ಮಾರಾಟ ಪತ್ರ / Sale Deed',
                      '"Schedule of Property" ಅಡಿಯಲ್ಲಿ ಸರ್ವೆ ನಂಬರ್ ಇರುತ್ತದೆ\nSurvey number is under "Schedule of Property"'),
                  SizedBox(height: 8),
                  _HelpRow('📱', 'ಸಿಎಸ್ಸಿ ಕೇಂದ್ರ / CSC Centre',
                      'ಗ್ರಾಮ ಪಂಚಾಯತ್ ಡಿಜಿಟಲ್ ಕೇಂದ್ರದಲ್ಲಿ ಸಹಾಯ ಪಡೆಯಿರಿ\nGet help at your village panchayat CSC centre'),
                  SizedBox(height: 8),
                  _HelpRow('⚠️', 'ಎಚ್ಚರಿಕೆ / Warning',
                      'ಸರ್ವೆ ನಂಬರ್ ಇಲ್ಲದೆ ಮುಂಗಡ ಹಣ ನೀಡಬೇಡಿ\nNever pay advance without knowing survey number'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String emoji, title, desc;
  const _HelpRow(this.emoji, this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text(desc,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurveyHint extends StatefulWidget {
  const _SurveyHint();
  @override
  State<_SurveyHint> createState() => _SurveyHintState();
}

class _SurveyHintState extends State<_SurveyHint> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              Icon(_open ? Icons.expand_less : Icons.help_outline,
                  size: 15, color: AppColors.info),
              const SizedBox(width: 5),
              const Text('Where do I find the survey number?',
                  style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HintRow('On the RTC / Pahani document', 'Top section — printed as "Sy. No." or "Survey No."'),
                SizedBox(height: 6),
                _HintRow('On the sale deed / agreement', 'First page — under "Schedule of Property"'),
                SizedBox(height: 6),
                _HintRow('Don\'t have it?', 'Ask the seller — every land has one. No survey number = verify before paying anything'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  final String title, desc;
  const _HintRow(this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
        Expanded(child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
            children: [
              TextSpan(text: '$title — ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: desc),
            ],
          ),
        )),
      ],
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
