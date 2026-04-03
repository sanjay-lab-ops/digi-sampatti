import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Government Services Hub ───────────────────────────────────────────────────
// Central screen for all government service applications.
// Built on top of existing seal/sign verification — no changes to existing code.
//
// What it covers (per the engine flowchart):
//   Apply → Mutation, Khata Transfer, Name Correction, EC Application
//   Track  → All submitted applications with live status
//   Grieve → Complaint if officer delays, rejects unfairly, or demands bribe
//   Verify → Links to existing document_verify_screen.dart (seal/sign)
// ──────────────────────────────────────────────────────────────────────────────

class GovtService {
  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final String department;
  final String slaLabel;   // Government SLA for this service
  final int slaDays;
  final String fee;
  final Color color;
  final List<String> requiredDocs;

  const GovtService({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.department,
    required this.slaLabel,
    required this.slaDays,
    required this.fee,
    required this.color,
    required this.requiredDocs,
  });
}

const _services = [
  GovtService(
    id: 'mutation',
    icon: '🔄',
    title: 'Mutation Application',
    subtitle: 'Transfer property ownership in Bhoomi after sale deed registration',
    department: 'Tahsildar Office',
    slaLabel: '30 days',
    slaDays: 30,
    fee: 'No fee',
    color: Color(0xFF6C63FF),
    requiredDocs: ['Registered Sale Deed', 'RTC (latest)', 'EC (3 years)', 'Aadhaar of buyer', 'Passport photo'],
  ),
  GovtService(
    id: 'khata_transfer',
    icon: '🏘️',
    title: 'Khata Transfer (BBMP)',
    subtitle: 'Transfer BBMP Khata to new owner after property purchase',
    department: 'BBMP ARO Office',
    slaLabel: '45 days',
    slaDays: 45,
    fee: '2% of property value',
    color: Color(0xFF10B981),
    requiredDocs: ['Sale Deed', 'Previous Khata', 'Property Tax receipts (3 yrs)', 'Aadhaar of buyer'],
  ),
  GovtService(
    id: 'name_correction',
    icon: '✏️',
    title: 'Name Correction in Bhoomi',
    subtitle: 'Correct spelling errors in RTC owner name or survey details',
    department: 'Tahsildar Office',
    slaLabel: '15 days',
    slaDays: 15,
    fee: 'No fee',
    color: Color(0xFFF59E0B),
    requiredDocs: ['Current RTC', 'Aadhaar card', 'Supporting document (ration card/passport)'],
  ),
  GovtService(
    id: 'ec_application',
    icon: '📜',
    title: 'Encumbrance Certificate',
    subtitle: 'Apply for EC from IGRS for a specific period (max 30 years)',
    department: 'Sub-Registrar Office',
    slaLabel: '3 days',
    slaDays: 3,
    fee: '₹200–500',
    color: Color(0xFF3B82F6),
    requiredDocs: ['Survey number', 'Period required', 'Aadhaar', 'Purpose declaration'],
  ),
  GovtService(
    id: 'khata_bifurcation',
    icon: '✂️',
    title: 'Khata Bifurcation',
    subtitle: 'Split one Khata into multiple for inherited or divided property',
    department: 'BBMP ARO Office',
    slaLabel: '60 days',
    slaDays: 60,
    fee: '₹500 per sub-unit',
    color: Color(0xFFEC4899),
    requiredDocs: ['Parent Khata', 'Legal partition deed', 'Survey sketch', 'All co-owner Aadhaar'],
  ),
  GovtService(
    id: 'rtc_certified',
    icon: '🌾',
    title: 'Certified RTC Copy',
    subtitle: 'Get an officially certified RTC copy from Tahsildar (for court/bank use)',
    department: 'Tahsildar Office',
    slaLabel: '7 days',
    slaDays: 7,
    fee: '₹100',
    color: Color(0xFF8B5CF6),
    requiredDocs: ['Survey number', 'Aadhaar', 'Purpose declaration'],
  ),
];

class GovernmentServicesScreen extends StatefulWidget {
  final String? surveyNumber;
  final String? ownerName;
  final String? district;

  const GovernmentServicesScreen({
    super.key,
    this.surveyNumber,
    this.ownerName,
    this.district,
  });

  @override
  State<GovernmentServicesScreen> createState() => _GovernmentServicesScreenState();
}

class _GovernmentServicesScreenState extends State<GovernmentServicesScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = true;
  int _scanStep = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _scanLines = [
    'Connecting to Bhoomi...',
    'Reading revenue records...',
    'Checking BBMP registry...',
    'Verifying KAVERI portal...',
    'Loading available services...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _runScan();
  }

  void _runScan() async {
    for (int i = 0; i < _scanLines.length; i++) {
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _scanStep = i);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _scanning = false);
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) return _buildScanOverlay();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Government Services'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/govt/track'),
            icon: const Icon(Icons.track_changes, size: 16, color: AppColors.primary),
            label: const Text('My Applications',
                style: TextStyle(color: AppColors.primary, fontSize: 11)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property context chip
            if (widget.surveyNumber != null) ...[
              _PropertyChip(surveyNumber: widget.surveyNumber!, ownerName: widget.ownerName),
              const SizedBox(height: 14),
            ],

            // Verify seal/sign shortcut
            _VerifyBanner(onTap: () => context.push('/verify/documents')),
            const SizedBox(height: 16),

            // SLA note
            _SlaNote(),
            const SizedBox(height: 16),

            const Text('Apply for Government Services',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 10),

            // Services grid
            ..._services.map((svc) => _ServiceCard(
              service: svc,
              surveyNumber: widget.surveyNumber,
              ownerName: widget.ownerName,
              district: widget.district,
            )),

            const SizedBox(height: 16),

            // Grievance shortcut
            _GrievanceBanner(onTap: () => context.push('/govt/grievance')),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Opacity(
                  opacity: _pulse.value,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primary, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Government Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              if (widget.surveyNumber != null)
                Text('Survey No: ${widget.surveyNumber}',
                  style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.8))),
              const SizedBox(height: 28),
              // Scan lines
              ...List.generate(_scanLines.length, (i) {
                final done = i < _scanStep;
                final active = i == _scanStep;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        done ? Icons.check_circle : (active ? Icons.radio_button_on : Icons.radio_button_off),
                        size: 14,
                        color: done ? AppColors.safe : (active ? AppColors.primary : Colors.white24),
                      ),
                      const SizedBox(width: 8),
                      Text(_scanLines[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: done ? AppColors.safe : (active ? Colors.white : Colors.white30),
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        )),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Verify Banner ────────────────────────────────────────────────────────────
class _VerifyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VerifyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Text('🔐', style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verify Government Seal & Sign',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Check if your documents are digitally authentic — RTC, EC, Khata, e-Stamp',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── SLA Note ─────────────────────────────────────────────────────────────────
class _SlaNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚡', style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DigiSampatti Tracks Government SLA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange)),
                SizedBox(height: 3),
                Text(
                  'Every application has a government-mandated deadline. If the officer doesn\'t act within the SLA, DigiSampatti helps you file a grievance — automatically escalating to DC or Commissioner.',
                  style: TextStyle(fontSize: 9, color: Colors.orange, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final GovtService service;
  final String? surveyNumber;
  final String? ownerName;
  final String? district;

  const _ServiceCard({
    required this.service,
    this.surveyNumber,
    this.ownerName,
    this.district,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: service.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: service.color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(service.icon, style: const TextStyle(fontSize: 22)),
          title: Text(service.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          subtitle: Text(service.subtitle,
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(service.slaLabel,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: service.color)),
              ),
              const SizedBox(height: 3),
              Text(service.fee, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            _ServiceDetails(
              service: service,
              surveyNumber: surveyNumber,
              ownerName: ownerName,
              district: district,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service Details (expanded) ───────────────────────────────────────────────
class _ServiceDetails extends StatelessWidget {
  final GovtService service;
  final String? surveyNumber;
  final String? ownerName;
  final String? district;

  const _ServiceDetails({
    required this.service,
    this.surveyNumber,
    this.ownerName,
    this.district,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 10),

        // Department
        _DetailRow('Department', service.department),
        _DetailRow('Government SLA', service.slaLabel),
        _DetailRow('Fee', service.fee),

        const SizedBox(height: 8),
        const Text('Required Documents:',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 4),
        ...service.requiredDocs.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 9)),
              Text(doc, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        )),

        const SizedBox(height: 12),

        // Pre-fill note
        if (surveyNumber != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Survey $surveyNumber data pre-filled from your verification report',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF4CAF50)),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push(
              '/govt/apply/${service.id}',
              extra: {
                'surveyNumber': surveyNumber,
                'ownerName': ownerName,
                'district': district,
                'serviceTitle': service.title,
                'department': service.department,
                'slaDays': service.slaDays,
              },
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: service.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text('Apply for ${service.title}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Property Chip ────────────────────────────────────────────────────────────
class _PropertyChip extends StatelessWidget {
  final String surveyNumber;
  final String? ownerName;
  const _PropertyChip({required this.surveyNumber, this.ownerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        '🔍 Survey $surveyNumber${ownerName != null ? "  ·  $ownerName" : ""}',
        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Grievance Banner ─────────────────────────────────────────────────────────
class _GrievanceBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _GrievanceBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Text('🚨', style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File a Grievance / Complaint',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(
                    'Officer delayed? Wrong rejection? Bribe demanded? File a complaint — DigiSampatti escalates to DC/Commissioner automatically if unresolved.',
                    style: TextStyle(fontSize: 9, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
