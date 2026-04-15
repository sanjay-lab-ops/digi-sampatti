import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Post-Purchase Tracker ────────────────────────────────────────────────────
// Strategy: "Platform owns the relationship forever"
// After purchase, buyer needs to:
//   1. Apply for Khata mutation (transfer BBMP/panchayat records to new owner)
//   2. Pay property tax annually
//   3. Monitor if anyone files a case on their property
//   4. Keep documents updated
//   5. Resale readiness when they want to sell
//
// This screen is the RETENTION LOOP — brings users back every year.
// Revenue: ₹999/year subscription.
// ──────────────────────────────────────────────────────────────────────────────

class TrackedProperty {
  final String id;
  final String surveyNumber;
  final String address;
  final DateTime purchaseDate;
  bool mutationDone;
  DateTime? lastTaxPaid;
  DateTime? nextTaxDue;

  TrackedProperty({
    required this.id,
    required this.surveyNumber,
    required this.address,
    required this.purchaseDate,
    this.mutationDone = false,
    this.lastTaxPaid,
    this.nextTaxDue,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'surveyNumber': surveyNumber, 'address': address,
    'purchaseDate': purchaseDate.toIso8601String(),
    'mutationDone': mutationDone,
    'lastTaxPaid': lastTaxPaid?.toIso8601String(),
    'nextTaxDue': nextTaxDue?.toIso8601String(),
  };

  factory TrackedProperty.fromJson(Map<String, dynamic> j) => TrackedProperty(
    id: j['id'], surveyNumber: j['surveyNumber'], address: j['address'],
    purchaseDate: DateTime.parse(j['purchaseDate']),
    mutationDone: j['mutationDone'] ?? false,
    lastTaxPaid: j['lastTaxPaid'] != null ? DateTime.parse(j['lastTaxPaid']) : null,
    nextTaxDue: j['nextTaxDue'] != null ? DateTime.parse(j['nextTaxDue']) : null,
  );
}

class PostPurchaseScreen extends ConsumerStatefulWidget {
  const PostPurchaseScreen({super.key});
  @override
  ConsumerState<PostPurchaseScreen> createState() => _PostPurchaseScreenState();
}

class _PostPurchaseScreenState extends ConsumerState<PostPurchaseScreen> {
  List<TrackedProperty> _properties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('tracked_properties') ?? [];
    setState(() {
      _properties = raw.map((s) =>
          TrackedProperty.fromJson(jsonDecode(s))).toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tracked_properties',
        _properties.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<void> _addProperty() async {
    final scan = ref.read(currentScanProvider);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AddPropertyDialog(
        defaultSurvey: scan?.surveyNumber ?? '',
        defaultAddress: '${scan?.village ?? ""}, ${scan?.taluk ?? ""}, '
            '${scan?.district ?? ""}',
      ),
    );
    if (result != null) {
      final prop = TrackedProperty(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        surveyNumber: result['survey']!,
        address: result['address']!,
        purchaseDate: DateTime.now(),
        nextTaxDue: DateTime(DateTime.now().year + 1, 4, 1),
      );
      setState(() => _properties.add(prop));
      await _save();
    }
  }

  Future<void> _markMutationDone(TrackedProperty p) async {
    setState(() => p.mutationDone = true);
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mutation marked as completed ✓')));
  }

  Future<void> _markTaxPaid(TrackedProperty p) async {
    setState(() {
      p.lastTaxPaid = DateTime.now();
      p.nextTaxDue  = DateTime(DateTime.now().year + 1, 4, 1);
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tax payment recorded ✓')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post-Purchase Tracker'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            onPressed: _addProperty,
            tooltip: 'Track new property',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _infoBox(),
                    const SizedBox(height: 16),
                    ..._properties.map(_buildPropertyCard),
                    const SizedBox(height: 80),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProperty,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_home, color: Colors.white),
        label: const Text('Track My Property',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _infoBox() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.track_changes, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text('After you buy — 4 things to track',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: AppColors.primary)),
        ]),
        SizedBox(height: 6),
        Text(
          '1. Mutation — transfer BBMP/panchayat records to your name\n'
          '2. Property tax — pay annually before April 1st\n'
          '3. Annual health check — is anyone claiming your property?\n'
          '4. Resale readiness — pre-verify before you sell',
          style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _buildPropertyCard(TrackedProperty p) {
    final pendingItems = <_TaskItem>[];
    final doneItems    = <_TaskItem>[];

    // Mutation task
    if (!p.mutationDone) {
      pendingItems.add(_TaskItem(
        title: 'Apply for Khata Mutation',
        subtitle: 'Transfer municipal records to your name within 6 months of registration',
        urgency: _TaskUrgency.high,
        actionLabel: 'Apply Online',
        actionUrl: 'https://bbmpeaasthi.karnataka.gov.in',
        onTap: () => _markMutationDone(p),
        markDoneLabel: 'Mark as Done',
      ));
    } else {
      doneItems.add(_TaskItem(
        title: 'Khata Mutation',
        subtitle: 'Completed',
        urgency: _TaskUrgency.done,
      ));
    }

    // Tax task
    final taxOverdue = p.nextTaxDue != null &&
        DateTime.now().isAfter(p.nextTaxDue!);
    if (taxOverdue || p.lastTaxPaid == null) {
      pendingItems.add(_TaskItem(
        title: p.lastTaxPaid == null
            ? 'Pay Property Tax (First Time)'
            : 'Property Tax Due — ${_dateStr(p.nextTaxDue!)}',
        subtitle: 'BBMP / Panchayat tax. Late payment = penalty.',
        urgency: taxOverdue ? _TaskUrgency.critical : _TaskUrgency.medium,
        actionLabel: 'Pay BBMP Tax',
        actionUrl: 'https://bbmpeaasthi.karnataka.gov.in',
        onTap: () => _markTaxPaid(p),
        markDoneLabel: 'Mark Tax Paid',
      ));
    } else {
      doneItems.add(_TaskItem(
        title: 'Property Tax',
        subtitle: 'Paid ${p.lastTaxPaid != null ? _dateStr(p.lastTaxPaid!) : ""}. Next due: ${p.nextTaxDue != null ? _dateStr(p.nextTaxDue!) : "Apr 2026"}',
        urgency: _TaskUrgency.done,
      ));
    }

    // Annual check
    pendingItems.add(_TaskItem(
      title: 'Annual Property Health Check',
      subtitle: 'Check if anyone filed a case or mutation on your property',
      urgency: _TaskUrgency.medium,
      actionLabel: 'Run Check Now',
      onTap: () => _runAnnualCheck(p),
    ));

    // Resale readiness
    pendingItems.add(_TaskItem(
      title: 'Resale Readiness',
      subtitle: 'When ready to sell — pre-verify your own property first',
      urgency: _TaskUrgency.low,
      actionLabel: 'Check Resale Value',
      onTap: () => _checkResaleValue(p),
    ));

    final completedCount = doneItems.length;
    final totalCount = pendingItems.length + doneItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.home, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Survey ${p.surveyNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14, color: AppColors.primary)),
                  Text(p.address, style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$completedCount/$totalCount',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16, color: AppColors.primary)),
                const Text('tasks done',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight)),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              ...pendingItems.map(_buildTask),
              if (doneItems.isNotEmpty) ...[
                const Divider(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Completed',
                      style: TextStyle(fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                ...doneItems.map(_buildTask),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTask(_TaskItem task) {
    final isDone = task.urgency == _TaskUrgency.done;
    final urgencyColor = isDone ? Colors.grey : switch (task.urgency) {
      _TaskUrgency.critical => Colors.red,
      _TaskUrgency.high     => Colors.orange,
      _TaskUrgency.medium   => AppColors.info,
      _TaskUrgency.low      => Colors.grey,
      _TaskUrgency.done     => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18, color: isDone ? AppColors.safe : urgencyColor),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12,
                color: isDone ? Colors.grey : null,
                decoration: isDone ? TextDecoration.lineThrough : null)),
            Text(task.subtitle, style: const TextStyle(
                fontSize: 11, color: AppColors.textLight, height: 1.3)),
            if (!isDone && (task.actionLabel != null || task.markDoneLabel != null)) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (task.actionLabel != null)
                  InkWell(
                    onTap: task.actionUrl != null
                        ? () async {
                            final uri = Uri.parse(task.actionUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        : task.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: urgencyColor.withOpacity(0.3)),
                      ),
                      child: Text(task.actionLabel!,
                          style: TextStyle(fontSize: 11,
                              color: urgencyColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (task.markDoneLabel != null && task.onTap != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: task.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(task.markDoneLabel!,
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.safe,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ]),
            ],
          ],
        )),
      ]),
    );
  }

  void _runAnnualCheck(TrackedProperty p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checking Survey ${p.surveyNumber}...')));
    // Navigate to auto-scan with this property
    // TODO: populate scan from tracked property and push /auto-scan
  }

  void _checkResaleValue(TrackedProperty p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Resale Readiness'),
      content: Text(
        'Survey ${p.surveyNumber} — ${p.address}\n\n'
        'When ready to sell:\n'
        '1. Run a fresh DigiSampatti check on your own property\n'
        '2. Get all mutation, tax, EC documents up to date\n'
        '3. Get a current Guidance Value estimate\n'
        '4. Get a lawyer to draft sale agreement',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_), child: const Text('OK')),
      ],
    ));
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Track Your Property After Purchase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Add a property to get mutation alerts, tax reminders, '
            'annual health checks, and resale readiness notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addProperty,
            icon: const Icon(Icons.add_home),
            label: const Text('Track My Property'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
          ),
        ],
      ),
    ),
  );

  String _dateStr(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

enum _TaskUrgency { critical, high, medium, low, done }

class _TaskItem {
  final String title;
  final String subtitle;
  final _TaskUrgency urgency;
  final String? actionLabel;
  final String? actionUrl;
  final VoidCallback? onTap;
  final String? markDoneLabel;

  const _TaskItem({
    required this.title,
    required this.subtitle,
    required this.urgency,
    this.actionLabel,
    this.actionUrl,
    this.onTap,
    this.markDoneLabel,
  });
}

// ─── Add Property Dialog ──────────────────────────────────────────────────────
class _AddPropertyDialog extends StatefulWidget {
  final String defaultSurvey;
  final String defaultAddress;
  const _AddPropertyDialog(
      {required this.defaultSurvey, required this.defaultAddress});

  @override
  State<_AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<_AddPropertyDialog> {
  late final TextEditingController _surveyCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _surveyCtrl  = TextEditingController(text: widget.defaultSurvey);
    _addressCtrl = TextEditingController(text: widget.defaultAddress);
  }

  @override
  void dispose() {
    _surveyCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Property to Track'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _surveyCtrl,
          decoration: const InputDecoration(labelText: 'Survey Number'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, {
          'survey':  _surveyCtrl.text,
          'address': _addressCtrl.text,
        }),
        child: const Text('Track'),
      ),
    ],
  );
}
