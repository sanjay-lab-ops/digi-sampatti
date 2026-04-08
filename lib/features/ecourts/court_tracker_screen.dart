import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/property_data_service.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

// ─── Court Case Tracker ───────────────────────────────────────────────────────
// User saves a property's survey number here.
// Each saved property shows "last checked" date.
// Tap "Check Now" → opens eCourts portal for that property.
// User checks and taps "Clear" or "Cases Found" → saves status.
// ─────────────────────────────────────────────────────────────────────────────

class CourtTrackerScreen extends StatelessWidget {
  const CourtTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Court Case Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDialog(context),
            tooltip: 'Track a property',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: PropertyDataService().streamTrackedProperties(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyState(onAdd: () => _showAddDialog(context));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF360C).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBF360C).withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Color(0xFFBF360C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap "Check Now" to open eCourts for each property. After checking, mark the status. '
                        'Check regularly before making any payment.',
                        style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final lastChecked = (data['lastChecked'] as Timestamp?)?.toDate();
                final status = data['alertStatus'] as String? ?? 'monitoring';
                final survey = data['surveyNumber'] as String? ?? '';
                final district = data['district'] as String? ?? '';
                final owner = data['ownerName'] as String?;

                final daysSince = lastChecked != null
                    ? DateTime.now().difference(lastChecked).inDays
                    : null;

                Color statusColor = const Color(0xFF1B5E20);
                IconData statusIcon = Icons.check_circle_outline;
                String statusLabel = 'Clear';
                if (status == 'alert') {
                  statusColor = Colors.red[700]!;
                  statusIcon = Icons.warning_amber;
                  statusLabel = 'Cases Found';
                } else if (status == 'monitoring') {
                  statusColor = Colors.orange[700]!;
                  statusIcon = Icons.visibility_outlined;
                  statusLabel = 'Not yet checked';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: status == 'alert'
                          ? Colors.red.withOpacity(0.3)
                          : AppColors.borderColor,
                      width: status == 'alert' ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Survey No: $survey',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textDark)),
                                Text(district,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMedium)),
                                if (owner != null)
                                  Text('Owner: $owner',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMedium)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(statusLabel,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (lastChecked != null)
                        Text(
                          daysSince == 0
                              ? 'Last checked: Today'
                              : daysSince == 1
                                  ? 'Last checked: Yesterday'
                                  : 'Last checked: $daysSince days ago',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Check Now → opens eCourts
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await GovPortalLauncher.open(
                                  context,
                                  GovPortal.eCourts,
                                  surveyNumber: survey,
                                  district: district,
                                );
                                await PropertyDataService()
                                    .updateLastChecked(doc.id);
                                if (context.mounted) {
                                  _showUpdateStatusDialog(
                                      context, doc.id, survey);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 13),
                              label: const Text('Check Now',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBF360C),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete
                          IconButton(
                            onPressed: () async {
                              await PropertyDataService()
                                  .untrackProperty(doc.id);
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.grey),
                            tooltip: 'Stop tracking',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Track Property'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final surveyCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Track a Property', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Survey Number *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: surveyCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 74/4',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text('District *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: districtCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Bengaluru Urban',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text('Owner Name (optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: ownerCtrl,
              decoration: const InputDecoration(
                hintText: 'From Bhoomi RTC',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (surveyCtrl.text.trim().isEmpty ||
                  districtCtrl.text.trim().isEmpty) return;
              await PropertyDataService().trackProperty(
                surveyNumber: surveyCtrl.text.trim(),
                district: districtCtrl.text.trim(),
                ownerName: ownerCtrl.text.trim().isEmpty
                    ? null
                    : ownerCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(
      BuildContext context, String docId, String survey) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('What did you find for $survey?',
            style: const TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              icon: Icons.check_circle,
              label: 'All Clear — No cases found',
              color: const Color(0xFF1B5E20),
              onTap: () async {
                await PropertyDataService().updatePropertyStatus(docId, 'clear');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _StatusOption(
              icon: Icons.warning_amber,
              label: 'Cases Found — Need legal advice',
              color: Colors.red[700]!,
              onTap: () async {
                await PropertyDataService().updatePropertyStatus(docId, 'alert');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip')),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: color))),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No properties tracked yet',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Add a property\'s survey number to monitor it for court cases. '
              'Tap "Check Now" to verify on eCourts before making any payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textMedium, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Track a Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
