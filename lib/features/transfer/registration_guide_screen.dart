import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class RegistrationGuideScreen extends StatefulWidget {
  const RegistrationGuideScreen({super.key});

  @override
  State<RegistrationGuideScreen> createState() => _RegistrationGuideScreenState();
}

class _RegistrationGuideScreenState extends State<RegistrationGuideScreen> {
  int _activeSection = 0; // 0=Steps, 1=Checklist, 2=Tips

  final Set<int> _checked = {};

  static const _registrationDocs = [
    _RegDoc('Original Sale Deed (3 copies)', 'Printed on stamp paper — original + 2 photocopies', true),
    _RegDoc('e-Stamp Paper / Franking Receipt', 'Stamp duty paid proof from bank or CMC', true),
    _RegDoc('Aadhar Card — Buyer', 'Original + 2 photocopies', true),
    _RegDoc('Aadhar Card — Seller', 'Original + 2 photocopies', true),
    _RegDoc('PAN Card — Buyer', 'Original + 1 photocopy (mandatory above ₹10L)', true),
    _RegDoc('PAN Card — Seller', 'Original + 1 photocopy', true),
    _RegDoc('Passport Photos', '2 each for buyer, seller, and witnesses', true),
    _RegDoc('Witness 1 — Aadhar + Photo', 'Any adult with valid ID (not relative)', true),
    _RegDoc('Witness 2 — Aadhar + Photo', 'Second witness required by law', true),
    _RegDoc('Property Tax Receipt', 'Latest paid receipt (current year)', true),
    _RegDoc('Khata Certificate', 'From BBMP / Gram Panchayat', true),
    _RegDoc('Original Title Deed / Mother Deed', 'Chain of previous ownership documents', true),
    _RegDoc('Bank NOC', 'If property has an existing loan — mandatory', false),
    _RegDoc('Power of Attorney', 'If seller cannot be present (NRI / health reason)', false),
    _RegDoc('Marriage Certificate', 'If joint registration by married couple', false),
    _RegDoc('Death Certificate + Legal Heir', 'If seller has inherited the property', false),
  ];

  static const _steps = [
    _RegStep('Book Appointment Online', 'Visit kaveri2.karnataka.gov.in → Online Registration → Slot Booking. Choose your SRO and preferred date/time. Print appointment slip.', Icons.calendar_today, 'Before Registration Day'),
    _RegStep('Pay Stamp Duty', 'Pay stamp duty at nearest nationalized bank (SBI, Canara, etc.) or use e-Franking at CMC center. Keep the challan/receipt safely.', Icons.payment, 'Before Registration Day'),
    _RegStep('Print Sale Deed on Stamp Paper', 'Get sale deed printed on stamp paper of correct value. Your advocate does this. Carry 3 printed copies.', Icons.print, 'Before Registration Day'),
    _RegStep('Arrive at SRO Early', 'Reach 30 minutes before appointment. Queue at token counter. Carry originals + photocopies of everything in checklist.', Icons.location_on, 'Registration Day'),
    _RegStep('Document Submission at Counter', 'Submit documents at the counter. Clerk verifies all papers and enters details in the Kaveri system. Takes 30–60 mins.', Icons.assignment_turned_in, 'Registration Day'),
    _RegStep('Biometric & Photo', 'Both buyer and seller give fingerprints and photograph at the biometric station. Witnesses also give biometrics.', Icons.fingerprint, 'Registration Day'),
    _RegStep('Sub-Registrar Verification', 'SR reads out the deed details. Both parties confirm. SR asks if transaction is voluntary and without coercion.', Icons.gavel, 'Registration Day'),
    _RegStep('Registration Fee Payment', 'Pay 1% registration charge (min ₹500) at the cashier counter. Keep receipt.', Icons.receipt, 'Registration Day'),
    _RegStep('Collect Registered Deed', 'Registered deed returned same day or next working day with Registration Number stamped. This is your legal proof of ownership.', Icons.description, 'After Registration'),
    _RegStep('Apply for Mutation', 'Use the registered deed to apply for Bhoomi mutation (RTC name change) and Khata transfer immediately after registration.', Icons.swap_horiz, 'After Registration'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Registration Guide')),
      body: Column(
        children: [
          // Top banner with Kaveri link
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'kaveri2.karnataka.gov.in'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Website copied — open in browser'), duration: Duration(seconds: 2)));
            },
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.open_in_new, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Book Online Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('kaveri2.karnataka.gov.in  (tap to copy link)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.copy, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),

          // Section tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _Tab('Steps', 0, Icons.format_list_numbered),
                _Tab('Checklist', 1, Icons.checklist),
                _Tab('Tips', 2, Icons.lightbulb_outline),
              ].map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeSection = t.index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: _activeSection == t.index ? AppColors.primary : Colors.transparent,
                        width: 2.5,
                      )),
                    ),
                    child: Column(
                      children: [
                        Icon(t.icon, size: 18,
                          color: _activeSection == t.index ? AppColors.primary : AppColors.textLight),
                        const SizedBox(height: 3),
                        Text(t.label, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _activeSection == t.index ? AppColors.primary : AppColors.textLight,
                        )),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          // Content
          Expanded(
            child: _activeSection == 0
              ? _buildSteps()
              : _activeSection == 1
                ? _buildChecklist()
                : _buildTips(),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _steps.length,
      itemBuilder: (context, i) {
        final step = _steps[i];
        final isLast = i == _steps.length - 1;
        final phaseColor = step.phase.contains('Before') ? AppColors.info
            : step.phase.contains('After') ? AppColors.safe
            : AppColors.primary;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: phaseColor, shape: BoxShape.circle),
                  child: Center(child: Icon(step.icon, color: Colors.white, size: 16)),
                ),
                if (!isLast) Container(width: 2, height: 56, color: AppColors.borderColor),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(step.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(step.phase,
                            style: TextStyle(fontSize: 9, color: phaseColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(step.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChecklist() {
    final mandatory = _registrationDocs.where((d) => d.mandatory).length;
    final checked = _checked.length;

    return Column(
      children: [
        // Progress bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _registrationDocs.isEmpty ? 0 : checked / _registrationDocs.length,
                backgroundColor: AppColors.borderColor,
                color: checked == _registrationDocs.length ? AppColors.safe : AppColors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
              Text('$checked of ${_registrationDocs.length} documents ready ($mandatory mandatory)',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _registrationDocs.length,
            itemBuilder: (context, i) {
              final doc = _registrationDocs[i];
              final isChecked = _checked.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isChecked ? AppColors.safe.withOpacity(0.4) : AppColors.borderColor),
                ),
                child: CheckboxListTile(
                  value: isChecked,
                  onChanged: (_) => setState(() {
                    if (isChecked) _checked.remove(i);
                    else _checked.add(i);
                  }),
                  title: Row(
                    children: [
                      Expanded(child: Text(doc.name, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? AppColors.textLight : AppColors.textDark,
                      ))),
                      if (doc.mandatory)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Must', style: TextStyle(fontSize: 9, color: AppColors.danger, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(doc.description, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ),
                  activeColor: AppColors.safe,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTips() {
    const tips = [
      _Tip(Icons.schedule, AppColors.primary, 'Arrive 30 Minutes Early',
        'SRO offices get crowded. Arriving early ensures you get processed before lunch break (1–2 PM). Many SROs stop accepting documents after 4 PM.'),
      _Tip(Icons.people, AppColors.info, 'Both Parties Must Be Present',
        'Buyer AND seller must appear in person with biometrics. If seller cannot come, a registered Power of Attorney (POA) must be arranged in advance.'),
      _Tip(Icons.copy_all, AppColors.safe, 'Carry Extra Photocopies',
        'Always carry 3 sets of all photocopies. Clerks often need extra copies. Losing one set causes delays.'),
      _Tip(Icons.translate, AppColors.warning, 'Sale Deed Must Be in Kannada',
        'Karnataka requires sale deed to be in Kannada. English version alone is NOT accepted. Your advocate should provide the bilingual version.'),
      _Tip(Icons.money_off, AppColors.danger, 'Do Not Pay Bribes',
        'Registration is a government right. If asked for extra money, refuse and file complaint at district IGR office. Keep all payment receipts.'),
      _Tip(Icons.format_list_numbered, const Color(0xFF7C3AED), 'Note Your Registration Number',
        'After registration, note the Document Number immediately. You need this for Bhoomi mutation, Khata transfer, and future property transactions.'),
      _Tip(Icons.wb_sunny, AppColors.info, 'Avoid Monday & Friday',
        'These are the busiest days at SRO. Tuesday–Thursday mornings are fastest. Avoid end-of-month rush (all month\'s pending cases pile up).'),
      _Tip(Icons.phone_android, AppColors.safe, 'Download Kaveri App',
        '"Kaveri Online Services" app (Karnataka govt) lets you track your registration, download certified copies, and check EC online.'),
      _Tip(Icons.savings, AppColors.primary, 'Women Buyer Tip',
        'If woman is co-buyer with husband, stamp duty concession applies. Register property in wife\'s name first (or joint) to save 1–2% stamp duty.'),
      _Tip(Icons.elderly, AppColors.warning, 'Senior Citizen Friendly SRO',
        'Inform SRO staff if buyer/seller is senior citizen (60+) or specially abled. They get priority queue in most offices. Bring age proof.'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, i) {
        final tip = tips[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: tip.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(tip.icon, color: tip.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tip.color)),
                    const SizedBox(height: 4),
                    Text(tip.description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab {
  final String label;
  final int index;
  final IconData icon;
  const _Tab(this.label, this.index, this.icon);
}

class _RegDoc {
  final String name;
  final String description;
  final bool mandatory;
  const _RegDoc(this.name, this.description, this.mandatory);
}

class _RegStep {
  final String title;
  final String description;
  final IconData icon;
  final String phase;
  const _RegStep(this.title, this.description, this.icon, this.phase);
}

class _Tip {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Tip(this.icon, this.color, this.title, this.description);
}
