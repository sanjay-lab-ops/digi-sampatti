import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/property_data_service.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

// ─── Application Tracker Screen ───────────────────────────────────────────────
// Tracks every government application submitted through DigiSampatti.
// No office visits. No bribes. Government fee only. Allotted time enforced.
// If officer doesn't act within SLA → automatic grievance escalation path.
//
// Escalation ladder (as per user requirement):
//   VA (Village Accountant) → Tahsildar → DC (Deputy Commissioner)
//   → Commissioner → RTI application
// ──────────────────────────────────────────────────────────────────────────────

enum AppStatus {
  submitted,
  acknowledged,
  underReview,
  additionalDocRequired,
  approved,
  rejected,
  slaBreached,  // Government didn't act within their own deadline
  grievanceFiled,
  completed,
}

class GovApplication {
  final String id;
  final String serviceType;
  final String serviceTitle;
  final String department;
  final String referenceNumber;
  final DateTime submittedAt;
  final int slaDays;
  final AppStatus status;
  final List<AppStatusStep> timeline;
  final String? rejectionReason;
  final String? additionalDocNote;
  final String? officerName;
  final bool canAppeal;
  final bool canGrieve;

  const GovApplication({
    required this.id,
    required this.serviceType,
    required this.serviceTitle,
    required this.department,
    required this.referenceNumber,
    required this.submittedAt,
    required this.slaDays,
    required this.status,
    required this.timeline,
    this.rejectionReason,
    this.additionalDocNote,
    this.officerName,
    this.canAppeal = false,
    this.canGrieve = false,
  });

  DateTime get slaDeadline => submittedAt.add(Duration(days: slaDays));
  int get daysRemaining => slaDeadline.difference(DateTime.now()).inDays;
  bool get isSlaBreached => DateTime.now().isAfter(slaDeadline) &&
      status != AppStatus.approved &&
      status != AppStatus.completed &&
      status != AppStatus.rejected;
}

class AppStatusStep {
  final String label;
  final DateTime? date;
  final bool isDone;
  final bool isActive;
  final String? note;

  const AppStatusStep({
    required this.label,
    this.date,
    required this.isDone,
    this.isActive = false,
    this.note,
  });
}

// Demo data — in production this comes from Firestore
final _demoApplications = [
  GovApplication(
    id: 'app001',
    serviceType: 'mutation',
    serviceTitle: 'Mutation Application',
    department: 'Tahsildar Office, Yelahanka',
    referenceNumber: 'MUT/YLH/2026/00142',
    submittedAt: DateTime.now().subtract(const Duration(days: 18)),
    slaDays: 30,
    status: AppStatus.underReview,
    officerName: 'Sri Mahesh R, Tahsildar',
    canGrieve: false,
    timeline: [
      AppStatusStep(label: 'Application Submitted via DigiSampatti',
          date: DateTime.now().subtract(const Duration(days: 18)), isDone: true),
      AppStatusStep(label: 'Acknowledged by Tahsildar Office',
          date: DateTime.now().subtract(const Duration(days: 16)), isDone: true,
          note: 'Ref: MUT/YLH/2026/00142'),
      AppStatusStep(label: 'Under Review — Officer Assigned',
          date: DateTime.now().subtract(const Duration(days: 10)), isDone: true,
          isActive: true, note: 'Sri Mahesh R, Tahsildar'),
      AppStatusStep(label: 'Decision — Approve / Reject', isDone: false),
      AppStatusStep(label: 'Bhoomi Record Updated', isDone: false),
      AppStatusStep(label: 'New RTC Issued in Buyer\'s Name', isDone: false),
    ],
  ),
  GovApplication(
    id: 'app002',
    serviceType: 'ec_application',
    serviceTitle: 'Encumbrance Certificate',
    department: 'Sub-Registrar Office, Bengaluru North',
    referenceNumber: 'EC/BLR-N/2026/00891',
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    slaDays: 3,
    status: AppStatus.slaBreached,
    canGrieve: true,
    timeline: [
      AppStatusStep(label: 'Application Submitted via DigiSampatti',
          date: DateTime.now().subtract(const Duration(days: 2)), isDone: true),
      AppStatusStep(label: 'SLA BREACHED — 3 days passed, no response',
          date: DateTime.now(), isDone: false, isActive: true,
          note: 'Government SLA: 3 days. Grievance available now.'),
    ],
  ),
  GovApplication(
    id: 'app003',
    serviceType: 'name_correction',
    serviceTitle: 'Name Correction in Bhoomi',
    department: 'Tahsildar Office, Yelahanka',
    referenceNumber: 'NC/YLH/2026/00037',
    submittedAt: DateTime.now().subtract(const Duration(days: 8)),
    slaDays: 15,
    status: AppStatus.rejected,
    rejectionReason: 'Supporting document not matching. Aadhaar name "Ramu K" does not match RTC name "Ramaiah K". Please provide a gazette notification or court order for name change.',
    canAppeal: true,
    canGrieve: true,
    officerName: 'Smt. Rekha Nair, Revenue Inspector',
    timeline: [
      AppStatusStep(label: 'Application Submitted',
          date: DateTime.now().subtract(const Duration(days: 8)), isDone: true),
      AppStatusStep(label: 'Acknowledged',
          date: DateTime.now().subtract(const Duration(days: 7)), isDone: true),
      AppStatusStep(label: 'Rejected — Document Mismatch',
          date: DateTime.now().subtract(const Duration(days: 1)), isDone: true,
          isActive: true, note: 'Aadhaar vs RTC name mismatch'),
    ],
  ),
];

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: PropertyDataService().streamApplications(),
      builder: (context, snap) {
        // While loading or no data → show empty state with add button
        final docs = snap.data?.docs ?? [];
        // Convert Firestore docs to GovApplication objects
        final _apps = docs.isEmpty ? <GovApplication>[] : docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return GovApplication(
            id: d.id,
            serviceType: data['serviceType'] ?? '',
            serviceTitle: data['serviceTitle'] ?? '',
            department: data['department'] ?? '',
            referenceNumber: data['referenceNumber'],
            submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            slaDays: data['slaDays'] ?? 30,
            status: AppStatus.values.firstWhere(
              (s) => s.name == (data['status'] ?? 'submitted'),
              orElse: () => AppStatus.submitted,
            ),
            officerName: data['officerName'],
            canGrieve: data['canGrieve'] ?? false,
            canAppeal: data['canAppeal'] ?? false,
            rejectionReason: data['rejectionReason'],
            timeline: [],
          );
        }).toList();

        final active = _apps.where((a) =>
            a.status != AppStatus.completed && a.status != AppStatus.approved).toList();
        final completed = _apps.where((a) =>
            a.status == AppStatus.completed || a.status == AppStatus.approved).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My Applications'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final ref = await GovPortalLauncher.open(
                context,
                GovPortal.sakala,
              );
              if (ref != null && ref.isNotEmpty && context.mounted) {
                await PropertyDataService().submitApplication(
                  serviceType: 'mutation',
                  serviceTitle: 'Mutation Application',
                  department: 'Tahsildar Office, Karnataka',
                  slaDays: 30,
                  formData: {'referenceNumber': ref},
                );
              }
            },
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
            label: const Text('New Application',
                style: TextStyle(color: AppColors.primary, fontSize: 11)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary row
            _SummaryRow(apps: _apps),
            const SizedBox(height: 16),

            // No visits / no bribes pledge
            _NoBribePledge(),
            const SizedBox(height: 16),

            // Add application by reference number
            _AddByReferenceButton(),
            const SizedBox(height: 16),

            if (_apps.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text('No applications tracked yet',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                    const SizedBox(height: 6),
                    const Text('Submit on the official portal, then tap\n"Add Application" and enter the reference number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
                  ],
                ),
              ),
            ],

            if (active.isNotEmpty) ...[
              const Text('Active Applications',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 10),
              ...active.map((a) => _AppCard(app: a)),
            ],

            if (completed.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Completed',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              ...completed.map((a) => _AppCard(app: a)),
            ],
          ],
        ),
      ),
    );
      }, // end StreamBuilder builder
    ); // end StreamBuilder
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<GovApplication> apps;
  const _SummaryRow({required this.apps});

  @override
  Widget build(BuildContext context) {
    final total     = apps.length;
    final active    = apps.where((a) => a.status == AppStatus.underReview ||
        a.status == AppStatus.acknowledged || a.status == AppStatus.submitted).length;
    final breached  = apps.where((a) => a.status == AppStatus.slaBreached).length;
    final rejected  = apps.where((a) => a.status == AppStatus.rejected).length;

    return Row(
      children: [
        _StatChip('$total', 'Total', Colors.white30),
        const SizedBox(width: 8),
        _StatChip('$active', 'In Progress', AppColors.primary),
        const SizedBox(width: 8),
        if (breached > 0) _StatChip('$breached', 'SLA Breached', Colors.orange),
        if (breached > 0) const SizedBox(width: 8),
        if (rejected > 0) _StatChip('$rejected', 'Rejected', Colors.red),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String num;
  final String label;
  final Color color;
  const _StatChip(this.num, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(num, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 8, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

// ─── No Bribe Pledge ──────────────────────────────────────────────────────────
class _NoBribePledge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✅  Zero Office Visits · Zero Bribes · Government Fee Only',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
          SizedBox(height: 4),
          Text(
            'All applications submitted digitally. Fees paid online. Every step tracked with timestamps. '
            'If an officer demands payment outside official fee → file a complaint instantly.',
            style: TextStyle(fontSize: 9, color: Color(0xFF4CAF50), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Application Card ─────────────────────────────────────────────────────────
class _AppCard extends StatelessWidget {
  final GovApplication app;
  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _borderColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(_statusIcon, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.serviceTitle,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(app.department,
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Ref: ${app.referenceNumber}',
                          style: TextStyle(fontSize: 8, color: _borderColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _borderColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _borderColor)),
                ),
              ],
            ),
          ),

          // SLA bar
          if (app.status != AppStatus.completed && app.status != AppStatus.approved)
            _SlaBar(app: app),

          // Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _Timeline(steps: app.timeline),
          ),

          // Rejection reason
          if (app.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rejection Reason:',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
                    const SizedBox(height: 4),
                    Text(app.rejectionReason!,
                        style: const TextStyle(fontSize: 9, color: Colors.red, height: 1.5)),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (app.canAppeal) ...[
                  Expanded(
                    child: _ActionBtn(
                      label: 'File Appeal',
                      icon: Icons.gavel,
                      color: Colors.orange,
                      onTap: () => context.push(
                        '/govt/apply/${app.serviceType}',
                        extra: {'isAppeal': true, 'originalRef': app.referenceNumber},
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (app.canGrieve || app.isSlaBreached)
                  Expanded(
                    child: _ActionBtn(
                      label: app.status == AppStatus.slaBreached
                          ? '🚨 File Grievance (SLA Breached)'
                          : 'File Grievance',
                      icon: Icons.report_problem,
                      color: Colors.red,
                      onTap: () => context.push(
                        '/govt/grievance',
                        extra: {
                          'applicationRef': app.referenceNumber,
                          'serviceTitle': app.serviceTitle,
                          'department': app.department,
                          'isSlaBreached': app.isSlaBreached,
                          'slaDays': app.slaDays,
                          'submittedAt': app.submittedAt.toIso8601String(),
                        },
                      ),
                    ),
                  ),
                if (app.canGrieve || app.isSlaBreached)
                  ElevatedButton.icon(
                    onPressed: () => GovPortalLauncher.open(
                      context,
                      GovPortal.janaspandana,
                    ),
                    icon: const Icon(Icons.campaign_outlined, size: 14),
                    label: const Text('File Grievance', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (app.status == AppStatus.rejected || app.status == AppStatus.slaBreached)
                  TextButton.icon(
                    onPressed: () => GovPortalLauncher.open(
                      context,
                      GovPortal.rtiOnline,
                    ),
                    icon: const Icon(Icons.info_outline, size: 13),
                    label: const Text('File RTI', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (app.status) {
      case AppStatus.approved:
      case AppStatus.completed:   return const Color(0xFF4CAF50);
      case AppStatus.rejected:    return Colors.red;
      case AppStatus.slaBreached: return Colors.orange;
      case AppStatus.underReview:
      case AppStatus.acknowledged:return AppColors.primary;
      case AppStatus.grievanceFiled: return Colors.deepOrange;
      default:                    return Colors.grey;
    }
  }

  String get _statusIcon {
    switch (app.status) {
      case AppStatus.approved:
      case AppStatus.completed:      return '✅';
      case AppStatus.rejected:       return '❌';
      case AppStatus.slaBreached:    return '⚠️';
      case AppStatus.underReview:    return '🔍';
      case AppStatus.acknowledged:   return '📨';
      case AppStatus.submitted:      return '📤';
      case AppStatus.grievanceFiled: return '🚨';
      default:                       return '📋';
    }
  }

  String get _statusLabel {
    switch (app.status) {
      case AppStatus.approved:              return 'APPROVED';
      case AppStatus.completed:            return 'COMPLETE';
      case AppStatus.rejected:             return 'REJECTED';
      case AppStatus.slaBreached:          return 'SLA BREACHED';
      case AppStatus.underReview:          return 'UNDER REVIEW';
      case AppStatus.acknowledged:         return 'ACKNOWLEDGED';
      case AppStatus.submitted:            return 'SUBMITTED';
      case AppStatus.grievanceFiled:       return 'GRIEVANCE FILED';
      case AppStatus.additionalDocRequired:return 'DOCS NEEDED';
    }
  }
}

// ─── SLA Progress Bar ─────────────────────────────────────────────────────────
class _SlaBar extends StatelessWidget {
  final GovApplication app;
  const _SlaBar({required this.app});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(app.submittedAt).inDays;
    final pct = (elapsed / app.slaDays).clamp(0.0, 1.0);
    final isBreached = pct >= 1.0;
    final color = isBreached ? Colors.red : (pct > 0.75 ? Colors.orange : AppColors.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBreached
                    ? '⚠ SLA BREACHED — ${elapsed - app.slaDays} day(s) overdue'
                    : 'Day $elapsed of ${app.slaDays} — ${app.slaDays - elapsed} day(s) remaining',
                style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700),
              ),
              Text('Govt SLA: ${app.slaDays} days',
                  style: const TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final List<AppStatusStep> steps;
  const _Timeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final idx = e.key;
        final step = e.value;
        final isLast = idx == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isDone
                          ? const Color(0xFF4CAF50)
                          : step.isActive
                          ? Colors.orange
                          : Colors.grey.shade800,
                    ),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 24, color: Colors.grey.shade800),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.label,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: step.isDone
                                ? Colors.white
                                : step.isActive
                                ? Colors.orange
                                : Colors.grey.shade700)),
                    if (step.note != null)
                      Text(step.note!,
                          style: const TextStyle(fontSize: 8, color: Colors.grey, height: 1.4)),
                    if (step.date != null)
                      Text(_fmt(step.date!),
                          style: const TextStyle(fontSize: 7, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Application by Reference Number ─────────────────────────────────────
// User submits on official portal, gets reference number, enters it here.
// App then tracks SLA days and alerts if deadline passes.
class _AddByReferenceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_circle_outline, size: 16),
        label: const Text('Add Application (enter reference number)',
            style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String? selectedType;
    final refCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final surveyCtrl = TextEditingController();

    final serviceTypes = [
      ('mutation', 'Mutation / Name Transfer', 'Tahsildar Office', 30),
      ('ec_application', 'Encumbrance Certificate', 'Sub-Registrar Office', 3),
      ('khata_transfer', 'Khata Transfer', 'BBMP / Panchayat', 30),
      ('bkhata_conversion', 'B Khata → A Khata Conversion', 'BBMP', 60),
      ('name_correction', 'Name Correction in Bhoomi', 'Tahsildar Office', 15),
      ('land_conversion', 'Agricultural Land Conversion', 'DC Office', 90),
      ('rera_complaint', 'RERA Complaint', 'RERA Karnataka', 60),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Track Application', style: TextStyle(fontSize: 16)),
        content: StatefulBuilder(
          builder: (ctx2, setState2) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  hint: const Text('Select service', style: TextStyle(fontSize: 12)),
                  isExpanded: true,
                  items: serviceTypes.map((t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(t.$2, style: const TextStyle(fontSize: 12)),
                  )).toList(),
                  onChanged: (v) {
                    setState2(() => selectedType = v);
                    final match = serviceTypes.firstWhere((t) => t.$1 == v, orElse: () => serviceTypes[0]);
                    deptCtrl.text = match.$3;
                  },
                ),
                const SizedBox(height: 12),
                const Text('Reference Number (from portal) *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. MUT/YLH/2026/00142',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                const Text('Survey Number (optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: surveyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 74/4',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Submit on the official portal first. Enter the reference number you received there. DigiSampatti will track SLA days and alert you if the deadline passes.',
                    style: TextStyle(fontSize: 10, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedType == null || refCtrl.text.trim().isEmpty) return;
              final match = serviceTypes.firstWhere((t) => t.$1 == selectedType!);
              await PropertyDataService().submitApplication(
                serviceType: match.$1,
                serviceTitle: match.$2,
                department: deptCtrl.text.isNotEmpty ? deptCtrl.text : match.$3,
                slaDays: match.$4,
                formData: {'referenceNumber': refCtrl.text.trim()},
                surveyNumber: surveyCtrl.text.trim().isEmpty ? null : surveyCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save & Track'),
          ),
        ],
      ),
    );
  }
}
