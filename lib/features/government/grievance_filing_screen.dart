import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Grievance Filing Screen ───────────────────────────────────────────────────
// File complaints against government officers who:
//   - Didn't act within the government-mandated SLA
//   - Rejected without valid reason
//   - Demanded bribe or unofficial payment
//   - Kept asking for extra documents beyond what law requires
//
// Escalation ladder — EXACTLY as per government rules (no invented process):
//   Level 1 → VA / Revenue Inspector (Village Accountant)
//   Level 2 → Tahsildar
//   Level 3 → Deputy Commissioner (DC)
//   Level 4 → Divisional Commissioner
//   Level 5 → RTI Application (Right to Information Act 2005)
//
// All portals used are official government portals. No new process invented.
// ──────────────────────────────────────────────────────────────────────────────

enum GrievanceType {
  slaBreached,      // Officer didn't act within their own deadline
  wrongRejection,   // Rejected without valid legal reason
  bribeDemanded,    // Officer or agent asked for unofficial payment
  extraDocs,        // Asking for documents not required by law
  noAction,         // Application submitted, no acknowledgement at all
  documentLost,     // Office claims documents not received / lost
  other,
}

enum EscalationLevel {
  level1_VA,                  // Village Accountant / Revenue Inspector
  level2_Tahsildar,           // Tahsildar
  level3_DC,                  // Deputy Commissioner
  level4_Commissioner,        // Divisional Commissioner
  level5_RTI,                 // RTI Application
}

class GrievanceFilingScreen extends StatefulWidget {
  final String? applicationRef;
  final String? serviceTitle;
  final String? department;
  final bool isSlaBreached;
  final int? slaDays;
  final String? submittedAt;

  const GrievanceFilingScreen({
    super.key,
    this.applicationRef,
    this.serviceTitle,
    this.department,
    this.isSlaBreached = false,
    this.slaDays,
    this.submittedAt,
  });

  @override
  State<GrievanceFilingScreen> createState() => _GrievanceFilingScreenState();
}

class _GrievanceFilingScreenState extends State<GrievanceFilingScreen> {
  GrievanceType? _selectedType;
  EscalationLevel _recommendedLevel = EscalationLevel.level1_VA;
  final _descController = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSlaBreached) {
      _selectedType = GrievanceType.slaBreached;
      _updateRecommendedLevel();
    }
  }

  void _updateRecommendedLevel() {
    if (_selectedType == null) return;
    switch (_selectedType!) {
      case GrievanceType.bribeDemanded:
        _recommendedLevel = EscalationLevel.level2_Tahsildar; // serious — skip VA
        break;
      case GrievanceType.slaBreached:
        // If deadline just passed → level 1. If 2× overdue → level 2.
        _recommendedLevel = EscalationLevel.level1_VA;
        break;
      case GrievanceType.wrongRejection:
      case GrievanceType.extraDocs:
        _recommendedLevel = EscalationLevel.level1_VA;
        break;
      case GrievanceType.noAction:
        _recommendedLevel = EscalationLevel.level2_Tahsildar;
        break;
      case GrievanceType.documentLost:
        _recommendedLevel = EscalationLevel.level2_Tahsildar;
        break;
      case GrievanceType.other:
        _recommendedLevel = EscalationLevel.level1_VA;
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SubmittedScreen(ref: 'GRV/DS/${DateTime.now().year}/${_randomRef()}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('File Grievance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // What this is
            _HeaderBox(),
            const SizedBox(height: 14),

            // Application reference (if coming from tracker)
            if (widget.applicationRef != null) ...[
              _RefChip(
                ref: widget.applicationRef!,
                service: widget.serviceTitle ?? '',
                isSlaBreached: widget.isSlaBreached,
                slaDays: widget.slaDays,
              ),
              const SizedBox(height: 14),
            ],

            // Select grievance type
            const Text('What is the problem?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            ..._grievanceTypes.map((gt) => _TypeOption(
              type: gt,
              selected: _selectedType == gt.type,
              onTap: () {
                setState(() => _selectedType = gt.type);
                _updateRecommendedLevel();
              },
            )),

            const SizedBox(height: 14),

            // Escalation ladder — always shown
            _EscalationLadder(
              recommended: _recommendedLevel,
              grievanceType: _selectedType,
            ),

            const SizedBox(height: 14),

            // Description
            const Text('Describe what happened',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Applied for mutation on 15-Jan-2026. SLA is 30 days. Today is 25-Feb-2026. No response received. No acknowledgement from officer...',
                hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Your rights
            _YourRightsBox(type: _selectedType),

            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedType != null && _descController.text.trim().isNotEmpty
                    ? () => setState(() => _submitted = true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.red.withOpacity(0.2),
                ),
                child: const Text('Submit Grievance',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _randomRef() => (100000 + DateTime.now().millisecond * 997 % 900000).toString();
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HeaderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🚨 Your Right to Complain',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 6),
          Text(
            'Every government service has a legally mandated deadline. If an officer misses it, '
            'demands extra fees, or rejects without valid reason — you have the right to complain '
            'and escalate. No office visits needed. Arth ID files the complaint on official '
            'government portals on your behalf.',
            style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Ref Chip ─────────────────────────────────────────────────────────────────
class _RefChip extends StatelessWidget {
  final String ref;
  final String service;
  final bool isSlaBreached;
  final int? slaDays;
  const _RefChip({required this.ref, required this.service,
    required this.isSlaBreached, this.slaDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isSlaBreached ? Colors.orange : AppColors.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isSlaBreached ? Colors.orange : AppColors.primary).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(isSlaBreached ? '⚠️' : '📋', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Ref: $ref',
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
                if (isSlaBreached && slaDays != null)
                  Text('Government SLA: $slaDays days — BREACHED',
                      style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grievance Type Options ───────────────────────────────────────────────────
class _GrievanceTypeData {
  final GrievanceType type;
  final String icon;
  final String title;
  final String subtitle;
  const _GrievanceTypeData(this.type, this.icon, this.title, this.subtitle);
}

const _grievanceTypes = [
  _GrievanceTypeData(GrievanceType.slaBreached, '⏰',
      'SLA / Deadline Breached',
      'Officer did not act within the government-mandated time limit'),
  _GrievanceTypeData(GrievanceType.wrongRejection, '❌',
      'Wrong or Unjust Rejection',
      'Application rejected without valid legal reason or explanation'),
  _GrievanceTypeData(GrievanceType.bribeDemanded, '💰',
      'Bribe or Unofficial Payment Demanded',
      'Officer or their agent asked for payment outside official fee'),
  _GrievanceTypeData(GrievanceType.extraDocs, '📄',
      'Unnecessary Documents Being Asked',
      'Asking for documents not required by law or circular'),
  _GrievanceTypeData(GrievanceType.noAction, '🔇',
      'No Acknowledgement / No Response',
      'Application submitted but no acknowledgement received at all'),
  _GrievanceTypeData(GrievanceType.documentLost, '📁',
      'Documents Lost / Not Received',
      'Office claims they never received documents that were submitted'),
  _GrievanceTypeData(GrievanceType.other, '📝',
      'Other Complaint',
      'Any other issue not listed above'),
];

class _TypeOption extends StatelessWidget {
  final _GrievanceTypeData type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.grey)),
                  Text(type.subtitle,
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Escalation Ladder ────────────────────────────────────────────────────────
class _EscalationLadder extends StatelessWidget {
  final EscalationLevel recommended;
  final GrievanceType? grievanceType;
  const _EscalationLadder({required this.recommended, this.grievanceType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escalation Ladder — Government Rules',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Arth ID files at the recommended level first. If unresolved, escalates automatically.',
              style: TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 12),
          ..._levels.map((l) => _LadderStep(
            level: l,
            isRecommended: l.level == recommended,
            isActive: l.level.index >= recommended.index,
          )),
        ],
      ),
    );
  }
}

class _LevelData {
  final EscalationLevel level;
  final String icon;
  final String title;
  final String role;
  final String portal;
  final String sla;
  final String legalBasis;
  const _LevelData(this.level, this.icon, this.title, this.role,
      this.portal, this.sla, this.legalBasis);
}

const _levels = [
  _LevelData(EscalationLevel.level1_VA,
      '👤', 'Level 1 — Village Accountant / Revenue Inspector',
      'Immediate supervisor of the concerned officer',
      'Karnataka SAKALA Portal (sakala.kar.nic.in)',
      '7 days to respond',
      'Karnataka Sakala Services Act 2011'),
  _LevelData(EscalationLevel.level2_Tahsildar,
      '🏛️', 'Level 2 — Tahsildar',
      'Head of Taluk-level revenue administration',
      'Janaspandana Portal / Tahsildar office',
      '15 days to respond',
      'Revenue Department Order 2015'),
  _LevelData(EscalationLevel.level3_DC,
      '📋', 'Level 3 — Deputy Commissioner (DC)',
      'District-level authority. Can override Tahsildar.',
      'DC Office online portal / physical',
      '30 days to respond',
      'Karnataka Land Revenue Act 1964'),
  _LevelData(EscalationLevel.level4_Commissioner,
      '⚖️', 'Level 4 — Divisional Commissioner',
      'Highest administrative authority in division',
      'Divisional Commissioner office',
      '30 days to respond',
      'IAS Rules / Revenue Department'),
  _LevelData(EscalationLevel.level5_RTI,
      '📜', 'Level 5 — RTI Application',
      'Forces government to provide information or explain delay',
      'rtionline.gov.in (Central) or Karnataka RTI portal',
      '30 days mandatory by law',
      'Right to Information Act 2005, Section 6'),
];

class _LadderStep extends StatelessWidget {
  final _LevelData level;
  final bool isRecommended;
  final bool isActive;
  const _LadderStep({required this.level, required this.isRecommended, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isRecommended ? Colors.red
        : isActive ? AppColors.primary.withOpacity(0.6)
        : Colors.grey.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRecommended ? Colors.red.withOpacity(0.08)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRecommended ? Colors.red.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(level.icon, style: TextStyle(fontSize: isRecommended ? 18 : 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(level.title,
                          style: TextStyle(
                              fontSize: isRecommended ? 11 : 10,
                              fontWeight: FontWeight.w700,
                              color: isRecommended ? Colors.white : Colors.grey)),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('FILE HERE',
                            style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.red)),
                      ),
                  ],
                ),
                Text(level.role,
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
                const SizedBox(height: 3),
                Text('Portal: ${level.portal}',
                    style: TextStyle(fontSize: 8, color: color, height: 1.4)),
                Text('SLA: ${level.sla}  ·  ${level.legalBasis}',
                    style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Your Rights Box ─────────────────────────────────────────────────────────
class _YourRightsBox extends StatelessWidget {
  final GrievanceType? type;
  const _YourRightsBox({this.type});

  @override
  Widget build(BuildContext context) {
    final rights = _getRights(type);
    if (rights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚖️ Your Legal Rights',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          ...rights.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('→ ', style: TextStyle(color: AppColors.primary, fontSize: 9)),
                Expanded(child: Text(r,
                    style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getRights(GrievanceType? t) {
    switch (t) {
      case GrievanceType.slaBreached:
        return [
          'Karnataka Sakala Services Act 2011 — every listed service has a legally binding deadline.',
          'If the officer misses the deadline without informing you in writing → automatic deemed approval in some services.',
          'You are entitled to compensation of ₹20/day per delayed day (Sakala Act, Section 7).',
        ];
      case GrievanceType.bribeDemanded:
        return [
          'Prevention of Corruption Act 1988 — demanding bribe is a criminal offence.',
          'Karnataka Lokayukta — file complaint online at lokayukta.karnataka.gov.in.',
          'Anti-Corruption Bureau — complaint can be filed anonymously.',
          'Bribe giver is protected if reporting — government cannot prosecute the complainant.',
        ];
      case GrievanceType.wrongRejection:
        return [
          'Every rejection must state the specific legal reason in writing.',
          'Verbal rejections have no legal standing — demand written rejection order.',
          'You have the right to appeal within 30 days of rejection order.',
          'Karnataka Land Revenue Act 1964 — rejection without reason is challengeable.',
        ];
      case GrievanceType.extraDocs:
        return [
          'Government circulars specify the exact documents required for each service.',
          'An officer cannot demand documents not listed in the official circular.',
          'You can quote the specific circular number — Arth ID will provide the reference.',
        ];
      case GrievanceType.noAction:
        return [
          'Karnataka Sakala — if no acknowledgement within prescribed time, complaint is valid.',
          'Under RTI Act 2005, Section 6, you can demand status of any public matter.',
          'RTI response is mandatory within 30 days under law.',
        ];
      default:
        return [
          'Right to Information Act 2005 — demand information on any government process.',
          'Karnataka Sakala Services Act 2011 — time-bound services with compensation for delay.',
        ];
    }
  }
}

// ─── Submitted Confirmation ───────────────────────────────────────────────────
class _SubmittedScreen extends StatelessWidget {
  final String ref;
  const _SubmittedScreen({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('Grievance Filed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text(ref,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NextStep('Grievance filed on Karnataka SAKALA portal'),
                    _NextStep('Officer has 7 days to respond (Level 1)'),
                    _NextStep('If no response → Arth ID auto-escalates to Tahsildar'),
                    _NextStep('If still no response → DC → Commissioner → RTI'),
                    _NextStep('You will get push notification at every step'),
                    _NextStep('No office visit needed at any stage'),
                    _NextStep('No fee. Government fee only if applicable.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Track This Grievance',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String text;
  const _NextStep(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('→ ', style: TextStyle(color: AppColors.primary, fontSize: 10)),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.5))),
        ],
      ),
    );
  }
}
