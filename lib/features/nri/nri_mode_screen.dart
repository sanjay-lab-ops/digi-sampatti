import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ── NRI Mode Provider ──────────────────────────────────────────────────────
final nriModeProvider = StateProvider<bool>((ref) => false);

// NRI country selection
final nriCountryProvider = StateProvider<String>((ref) => 'UAE / Dubai');

const _countries = [
  ('UAE / Dubai',     '🇦🇪', 'AED', 37.0),
  ('USA',             '🇺🇸', 'USD', 84.0),
  ('UK',              '🇬🇧', 'GBP', 107.0),
  ('Singapore',       '🇸🇬', 'SGD', 63.0),
  ('Canada',          '🇨🇦', 'CAD', 62.0),
  ('Australia',       '🇦🇺', 'AUD', 54.0),
  ('Germany',         '🇩🇪', 'EUR', 91.0),
  ('Saudi Arabia',    '🇸🇦', 'SAR', 22.0),
  ('Kuwait',          '🇰🇼', 'KWD', 274.0),
  ('Qatar',           '🇶🇦', 'QAR', 23.0),
];

class NriModeScreen extends ConsumerStatefulWidget {
  const NriModeScreen({super.key});
  @override
  ConsumerState<NriModeScreen> createState() => _NriModeScreenState();
}

class _NriModeScreenState extends ConsumerState<NriModeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final isNri = ref.watch(nriModeProvider);
    final country = ref.watch(nriCountryProvider);
    final countryData = _countries.firstWhere((c) => c.$1 == country,
        orElse: () => _countries[0]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('NRI Property Guide'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(isNri ? 'NRI ON' : 'NRI',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(width: 6),
                Switch(
                  value: isNri,
                  onChanged: (v) => ref.read(nriModeProvider.notifier).state = v,
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.amber.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            children: [
              _Tab('Overview', 0, _tab, (i) => setState(() => _tab = i)),
              _Tab('FEMA Rules', 1, _tab, (i) => setState(() => _tab = i)),
              _Tab('Request Verify', 2, _tab, (i) => setState(() => _tab = i)),
              _Tab('Pricing', 3, _tab, (i) => setState(() => _tab = i)),
            ],
          ),
        ),
      ),
      body: isNri
          ? IndexedStack(
              index: _tab,
              children: [
                _OverviewTab(countryData: countryData, country: country),
                const _FemaTab(),
                const _RequestVerifyTab(),
                _PricingTab(countryData: countryData, country: country),
              ],
            )
          : _NriOffScreen(onEnable: () => ref.read(nriModeProvider.notifier).state = true),
    );
  }
}

// ── NRI Mode OFF placeholder ───────────────────────────────────────────────
class _NriOffScreen extends StatelessWidget {
  final VoidCallback onEnable;
  const _NriOffScreen({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            const Text('NRI Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1))),
            const SizedBox(height: 12),
            const Text(
              'Turn on NRI Mode to see:\n'
              '• Dual-currency pricing (AED / USD / GBP…)\n'
              '• FEMA compliance rules for NRI buyers\n'
              '• Remote verification & POA guidance\n'
              '• WhatsApp-shareable PDF reports',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.flight_takeoff),
              label: const Text('Turn On NRI Mode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country Selector ───────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  final (String, String, String, double) countryData;
  final String country;
  const _OverviewTab({required this.countryData, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price99 = (99 / countryData.$4).toStringAsFixed(2);
    final price499 = (499 / countryData.$4).toStringAsFixed(2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Country selector
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Your Country',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: country,
                dropdownColor: const Color(0xFF0D47A1),
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: _countries.map((c) => DropdownMenuItem(
                  value: c.$1,
                  child: Text('${c.$2}  ${c.$1}'),
                )).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(nriCountryProvider.notifier).state = v;
                },
              ),
              const SizedBox(height: 8),
              Text('Report fee: ${countryData.$3} $price99 (₹99)',
                  style: const TextStyle(color: Colors.amber, fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // What NRIs can buy
        _SectionCard(
          icon: Icons.home,
          color: const Color(0xFF1B5E20),
          title: 'What NRIs Can Buy in India',
          child: Column(
            children: const [
              _RuleRow('✅', 'Residential property (flat, house, villa)'),
              _RuleRow('✅', 'Commercial property (office, shop)'),
              _RuleRow('✅', 'No limit on number of properties'),
              _RuleRow('✅', 'No RBI approval required'),
              _RuleRow('❌', 'Agricultural land — NOT allowed'),
              _RuleRow('❌', 'Plantation property — NOT allowed'),
              _RuleRow('❌', 'Farmhouse — NOT allowed'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Payment rules
        _SectionCard(
          icon: Icons.account_balance,
          color: const Color(0xFF0D47A1),
          title: 'Payment Rules (FEMA)',
          child: Column(
            children: const [
              _RuleRow('✅', 'Pay from NRE / NRO / FCNR account'),
              _RuleRow('✅', 'Foreign remittance via banking channel'),
              _RuleRow('✅', 'Cheque / RTGS / NEFT acceptable'),
              _RuleRow('❌', 'Cash payment NOT allowed'),
              _RuleRow('❌', 'Traveller\'s cheque NOT allowed'),
              _RuleRow('ℹ️', 'Repatriate up to \$1M/year from NRO account'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Power of Attorney
        _SectionCard(
          icon: Icons.description,
          color: const Color(0xFF4A148C),
          title: 'Power of Attorney (POA)',
          child: Column(
            children: const [
              _RuleRow('📋', 'NRIs usually buy via POA — trusted person in India'),
              _RuleRow('📋', 'POA must be notarized in your country'),
              _RuleRow('📋', 'Apostille stamp required for POA'),
              _RuleRow('📋', 'POA holder can sign sale deed on your behalf'),
              _RuleRow('⚠️', 'DigiSampatti can verify property BEFORE POA is given'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Landeed gap — what we offer that Landeed doesn't
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                const Text('Why NRIs Choose DigiSampatti',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              const _RuleRow('🌍', 'Verify remotely — no need to visit India'),
              const _RuleRow('📱', 'WhatsApp-shareable PDF report'),
              const _RuleRow('⚖️', 'FEMA compliance check built in'),
              const _RuleRow('🏦', 'NRE/NRO payment guidance'),
              const _RuleRow('👨‍💼', 'Request Verification — agent visits on your behalf'),
              const _RuleRow('📊', 'Safety Score in USD/AED — easy to understand'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── FEMA Tab ───────────────────────────────────────────────────────────────
class _FemaTab extends StatelessWidget {
  const _FemaTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FemaCard(
          title: '1. Before Buying',
          color: const Color(0xFF1B5E20),
          items: const [
            'Verify property title with DigiSampatti — before paying advance',
            'Check property is residential or commercial (not agricultural)',
            'Confirm seller\'s identity — NRIs are frequent fraud targets',
            'Get EC (Encumbrance Certificate) — check for existing loans',
            'Check RERA registration if buying from builder',
          ],
        ),
        const SizedBox(height: 12),
        _FemaCard(
          title: '2. Payment Compliance',
          color: const Color(0xFF0D47A1),
          items: const [
            'Open NRE account (for repatriable funds) or NRO account',
            'Transfer money from abroad via banking channel only',
            'All payments in INR — no foreign currency directly',
            'Keep all bank transfer records — needed for tax later',
            'Avoid cash transactions — illegal under FEMA',
          ],
        ),
        const SizedBox(height: 12),
        _FemaCard(
          title: '3. During Registration',
          color: const Color(0xFF4A148C),
          items: const [
            'POA holder attends Sub-Registrar Office on your behalf',
            'Stamp duty same as resident Indians',
            'PAN card mandatory for property above ₹50 lakh',
            'TAN number if seller is NRI (TDS deduction required)',
            'OCI card holders have same rights as NRIs',
          ],
        ),
        const SizedBox(height: 12),
        _FemaCard(
          title: '4. After Purchase',
          color: const Color(0xFFB71C1C),
          items: const [
            'Mutation — change ownership in revenue records',
            'Property tax registration in your name',
            'File income tax return if rental income earned',
            'Repatriation: up to \$1M/year from NRO after tax certificate',
            'Full repatriation allowed from NRE / FCNR accounts',
          ],
        ),
        const SizedBox(height: 12),
        _LinkCard(
          title: 'Official FEMA Guidelines',
          subtitle: 'Reserve Bank of India — NRI Property',
          url: 'https://www.rbi.org.in/Scripts/FAQView.aspx?Id=95',
          icon: Icons.account_balance,
        ),
        const SizedBox(height: 8),
        _LinkCard(
          title: 'Income Tax — NRI Property',
          subtitle: 'incometax.gov.in',
          url: 'https://www.incometax.gov.in',
          icon: Icons.receipt_long,
        ),
      ],
    );
  }
}

// ── Request Verification Tab ───────────────────────────────────────────────
class _RequestVerifyTab extends StatefulWidget {
  const _RequestVerifyTab();
  @override
  State<_RequestVerifyTab> createState() => _RequestVerifyTabState();
}

class _RequestVerifyTabState extends State<_RequestVerifyTab> {
  final _surveyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF1B5E20), size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Verification Request Submitted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Our ground team will visit the property within 2-3 working days '
                'and send the full DigiSampatti report to your WhatsApp.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text('Request ID: DS-NRI-2026-1001',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1))),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => setState(() => _submitted = false),
                child: const Text('Submit Another'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Ground Verification',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'Cannot visit India? Our verified agent will physically '
                'visit the property, take GPS-stamped photos, scan documents '
                'and send you a complete DigiSampatti report.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 8),
              Row(children: [
                Icon(Icons.timer, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text('2–3 working days  ·  Report on WhatsApp',
                    style: TextStyle(color: Colors.amber, fontSize: 12)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // How it works
        const _HowItWorksCard(),
        const SizedBox(height: 16),

        // Form
        const Text('Property Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        _Field('Survey Number *', 'e.g. 45/2', _surveyCtrl),
        const SizedBox(height: 10),
        _Field('Village / Area *', 'e.g. Yelahanka', _villageCtrl),
        const SizedBox(height: 10),
        _Field('District *', 'e.g. Bengaluru Urban', _districtCtrl),
        const SizedBox(height: 16),

        const Text('Local Contact (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        const Text(
          'Someone we can coordinate with at the property location',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        _Field('Contact Name', 'Relative / neighbour name', _contactCtrl),
        const SizedBox(height: 10),
        _Field('Contact Phone', '+91 XXXXX XXXXX', _contactPhoneCtrl,
            keyboard: TextInputType.phone),
        const SizedBox(height: 10),
        _Field('Additional Notes', 'Any specific concerns or areas to check',
            _notesCtrl, maxLines: 3),
        const SizedBox(height: 20),

        // Pricing note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fee: ₹499 (~\$6 USD / AED 22) per verification\n'
                  'Includes: Physical visit + GPS photos + full DigiSampatti report',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () async {
            if (_surveyCtrl.text.isEmpty || _villageCtrl.text.isEmpty ||
                _districtCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill Survey No., Village and District')),
              );
              return;
            }
            // Send real WhatsApp message to DigiSampatti verification team
            final msg = Uri.encodeComponent(
              '🏡 *DigiSampatti — NRI Verification Request*\n\n'
              'Survey No: ${_surveyCtrl.text.trim()}\n'
              'Village: ${_villageCtrl.text.trim()}\n'
              'District: ${_districtCtrl.text.trim()}\n'
              '${_contactCtrl.text.isNotEmpty ? "Local Contact: ${_contactCtrl.text.trim()}" : ""}'
              '${_contactPhoneCtrl.text.isNotEmpty ? "\nContact Phone: ${_contactPhoneCtrl.text.trim()}" : ""}'
              '${_notesCtrl.text.isNotEmpty ? "\nNotes: ${_notesCtrl.text.trim()}" : ""}\n\n'
              '_Please arrange ground verification and send report to this WhatsApp._',
            );
            // Opens WhatsApp to DigiSampatti business number
            final waUrl = Uri.parse('https://wa.me/919900000000?text=$msg');
            if (await canLaunchUrl(waUrl)) {
              await launchUrl(waUrl, mode: LaunchMode.externalApplication);
              setState(() => _submitted = true);
            } else {
              // Fallback: open WhatsApp without pre-filled number
              final waFallback = Uri.parse('https://wa.me/?text=$msg');
              await launchUrl(waFallback, mode: LaunchMode.externalApplication);
              setState(() => _submitted = true);
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Send Request via WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Pricing Tab ────────────────────────────────────────────────────────────
class _PricingTab extends StatelessWidget {
  final (String, String, String, double) countryData;
  final String country;
  const _PricingTab({required this.countryData, required this.country});

  @override
  Widget build(BuildContext context) {
    final rate = countryData.$4;
    final curr = countryData.$3;
    final flag = countryData.$2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(country,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('1 $curr = ₹${rate.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PriceCard(
          title: 'Single Report',
          inr: '₹99',
          foreign: '$curr ${(99 / rate).toStringAsFixed(2)}',
          features: const [
            'Full legal verification report',
            'Safety Score (0–100)',
            'EC + RTC + Court case check',
            'FEMA compliance note',
            'PDF download + WhatsApp share',
          ],
          color: const Color(0xFF1B5E20),
        ),
        const SizedBox(height: 12),
        _PriceCard(
          title: 'Ground Verification',
          inr: '₹499',
          foreign: '$curr ${(499 / rate).toStringAsFixed(2)}',
          features: const [
            'Physical agent visit to property',
            'GPS-stamped photographs',
            'Document scan on ground',
            'Full DigiSampatti report',
            'WhatsApp delivery in 2–3 days',
          ],
          color: const Color(0xFF0D47A1),
          highlighted: true,
        ),
        const SizedBox(height: 12),
        _PriceCard(
          title: 'NRI Pro (Monthly)',
          inr: '₹999/month',
          foreign: '$curr ${(999 / rate).toStringAsFixed(2)}/mo',
          features: const [
            'Unlimited online reports',
            '2 ground verifications/month',
            'Priority WhatsApp support',
            'Document storage — Property Locker',
            'POA guidance + lawyer referral',
          ],
          color: const Color(0xFF4A148C),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'All payments accepted via international cards, '
            'NRE/NRO account transfer, UPI (if linked to Indian bank).\n'
            'Receipts sent to email. GST invoice available on request.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _Tab(this.label, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.amber : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.amber : Colors.white60,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.color,
      required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 13, color: color)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String emoji, text;
  const _RuleRow(this.emoji, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _FemaCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  const _FemaCard({required this.title, required this.color, required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: color)),
            const SizedBox(height: 8),
            ...items.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Expanded(child: Text(e, style: const TextStyle(fontSize: 12.5))),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String title, subtitle, url;
  final IconData icon;
  const _LinkCard({required this.title, required this.subtitle,
      required this.url, required this.icon});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.open_in_new, size: 16),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How It Works', style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
          const SizedBox(height: 10),
          ...[
            ('1', 'Submit request with survey no. + district'),
            ('2', 'Pay ₹499 online — card / NRE account'),
            ('3', 'Our verified agent visits the property'),
            ('4', 'GPS photos + document scan done on ground'),
            ('5', 'Full DigiSampatti report sent to your WhatsApp'),
          ].map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              CircleAvatar(radius: 12,
                  backgroundColor: const Color(0xFF1B5E20),
                  child: Text(s.$1, style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(child: Text(s.$2, style: const TextStyle(fontSize: 12.5))),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final int maxLines;
  const _Field(this.label, this.hint, this.ctrl,
      {this.keyboard = TextInputType.text, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title, inr, foreign;
  final List<String> features;
  final Color color;
  final bool highlighted;
  const _PriceCard({required this.title, required this.inr, required this.foreign,
      required this.features, required this.color, this.highlighted = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlighted ? color : Colors.grey.shade200, width: highlighted ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('RECOMMENDED FOR NRIs',
                  style: TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            if (highlighted) const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 14, color: color)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(inr, style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: color)),
                Text(foreign, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
              ]),
            ]),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(Icons.check_circle, color: color, size: 14),
                const SizedBox(width: 6),
                Text(f, style: const TextStyle(fontSize: 12)),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}
