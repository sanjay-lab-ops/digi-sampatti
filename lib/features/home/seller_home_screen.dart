import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// Documents seller must upload per property type (same categories as buyer checklist)
const _sellerDocsMap = {
  'Apartment / Flat': [
    ('Sale Deed / Agreement to Sell', 'Your primary ownership proof', true),
    ('Encumbrance Certificate (EC)', 'Obtain from SRO — shows no loans', true),
    ('Khata Certificate + Extract', 'From BBMP/BDA — current record', true),
    ('Occupancy Certificate (OC)', 'From BDA/BBMP — construction approval', true),
    ('RERA Registration', 'Builder/project RERA number', false),
    ('Share Certificate', 'From housing society', false),
    ('Property Tax Receipts', 'Last 3 years — download from BBMP', true),
  ],
  'House / Independent Villa': [
    ('Sale Deed', 'Original ownership document', true),
    ('RTC (Pahani)', 'From Bhoomi portal — land record', true),
    ('Encumbrance Certificate', 'From SRO — no pending loans', true),
    ('Khata Certificate + Extract', 'From municipal body', true),
    ('Building Plan Sanction', 'Approved plan from BDA/BBMP', false),
    ('DC Conversion Certificate', 'If converted from agriculture', false),
    ('Property Tax Receipts', 'Last 3 years', true),
    ('Mutation Records', 'Ownership transfer history', false),
  ],
  'Plot / Land': [
    ('Sale Deed / Title Deed', 'Original ownership proof', true),
    ('RTC (Record of Rights)', 'From Bhoomi portal', true),
    ('Encumbrance Certificate', 'From SRO — no loans/mortgages', true),
    ('Survey Sketch (FMB)', 'From Survey Dept. — boundary map', true),
    ('DC Conversion Certificate', 'If non-agricultural', false),
    ('Mutation Records', 'Previous owner chain', true),
    ('Katha Certificate', 'From BBMP/Panchayat', false),
  ],
  'Commercial Property': [
    ('Sale Deed', 'Ownership proof', true),
    ('Encumbrance Certificate', 'No pending charges', true),
    ('Occupancy Certificate', 'Building is legally complete', true),
    ('Fire NOC', 'From Fire Department', true),
    ('Building Plan Sanction', 'Approved layout', false),
    ('Property Tax Receipts', 'Current & up to date', true),
  ],
  'Agricultural Land': [
    ('RTC (Pahani)', 'Primary land record from Bhoomi', true),
    ('Mutation Records', 'Ownership history', true),
    ('Survey Sketch (FMB)', 'Boundary & area measurement', true),
    ('Land Use Certificate', 'Confirms agricultural zoning', true),
    ('Encumbrance Certificate', 'No loans/mortgages', true),
    ('Nil-Tenancy Certificate', 'No tenant occupying land', false),
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
        onNext: () => setState(() => _step = 3),
      );
      case 3: return _SellerStep4List(key: const ValueKey(3),
        propertyType: _propertyType!,
        district: _district!,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 1 of 4', 'Where is your property?', Icons.location_on_outlined, AppColors.safe),
        const SizedBox(height: 20),
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
        const SizedBox(height: 24),
        // Seller tips
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.safe.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.safe.withOpacity(0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.tips_and_updates_outlined, color: AppColors.safe, size: 16),
              SizedBox(width: 6),
              Text('Seller Tips', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.safe, fontSize: 13)),
            ]),
            SizedBox(height: 8),
            _Tip('Verified sellers get 3× more buyer inquiries'),
            _Tip('AI score > 80 means your property sells 40% faster'),
            _Tip('₹99 verification unlocks verified badge on listing'),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _district == null ? null : () => widget.onNext(_district!),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: AppColors.safe),
            child: const Text('Next: Choose Property Type →', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
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
  final VoidCallback onNext;
  const _SellerStep3Docs({super.key, required this.propertyType, required this.onNext});
  @override
  State<_SellerStep3Docs> createState() => _SellerStep3DocsState();
}

class _SellerStep3DocsState extends State<_SellerStep3Docs> {
  final Set<int> _uploaded = {};

  @override
  Widget build(BuildContext context) {
    final docs = _sellerDocsMap[widget.propertyType] ?? _sellerDocsMap['Apartment / Flat']!;
    final required = docs.where((d) => d.$3).toList();
    final optional = docs.where((d) => !d.$3).toList();
    final reqUploaded = required.where((d) => _uploaded.contains(docs.indexOf(d))).length;
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
            uploaded: _uploaded.contains(idx),
            onTap: () => setState(() {
              if (_uploaded.contains(idx)) _uploaded.remove(idx);
              else _uploaded.add(idx);
            }),
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
              uploaded: _uploaded.contains(idx),
              onTap: () => setState(() {
                if (_uploaded.contains(idx)) _uploaded.remove(idx);
                else _uploaded.add(idx);
              }),
            );
          }),
        ],

        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: allRequiredDone ? widget.onNext : null,
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
}

class _UploadRow extends StatelessWidget {
  final String title, subtitle;
  final bool required, uploaded;
  final VoidCallback onTap;
  const _UploadRow({required this.title, required this.subtitle,
    required this.required, required this.uploaded, required this.onTap});

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
              if (required) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Text('Required', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold)),
              ),
            ]),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
        ]),
      ),
    );
  }
}

// ─── Seller Step 4: List Property ────────────────────────────────────────────
class _SellerStep4List extends StatelessWidget {
  final String propertyType, district;
  const _SellerStep4List({super.key, required this.propertyType, required this.district});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SHeader('Step 4 of 4', 'List & Set Price', Icons.sell_outlined, AppColors.primary),
        const SizedBox(height: 16),
        // AI score badge
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
        // Listing plans
        const Text('Choose Listing Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _PlanCard('₹99', 'Basic Verified Listing',
          ['Verified badge on listing', 'Basic AI document score', 'Up to 3 buyer inquiries'],
          AppColors.primary, false, context),
        const SizedBox(height: 8),
        _PlanCard('₹199', 'Standard — Recommended',
          ['Everything in Basic', 'Full AI verification report', 'Unlimited buyer inquiries', 'Priority in search results'],
          AppColors.safe, true, context),
        const SizedBox(height: 8),
        _PlanCard('₹499', 'Premium — Maximum Visibility',
          ['Everything in Standard', 'Featured listing placement', 'Expert help (lawyer/surveyor)', 'Digital escrow setup'],
          const Color(0xFF6A1B9A), false, context),
        const SizedBox(height: 20),
        const Text('After Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _AfterListItem(Icons.notifications_outlined, 'Instant buyer alerts', 'Get notified when buyers show interest'),
        _AfterListItem(Icons.chat_outlined, 'Secure chat', 'No direct number shared — DigiSampatti mediates'),
        _AfterListItem(Icons.lock_outlined, 'Document vault', 'Buyer views docs only after escrow starts'),
        _AfterListItem(Icons.assignment_outlined, 'e-Sign agreement', 'Digital sale agreement — legally valid'),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String price, title;
  final List<String> features;
  final Color color;
  final bool highlighted;
  final BuildContext ctx;
  const _PlanCard(this.price, this.title, this.features, this.color, this.highlighted, this.ctx);

  @override
  Widget build(BuildContext ctx2) {
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
            onPressed: () => ScaffoldMessenger.of(ctx2).showSnackBar(
              SnackBar(content: Text('Starting $title plan at $price'))),
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
