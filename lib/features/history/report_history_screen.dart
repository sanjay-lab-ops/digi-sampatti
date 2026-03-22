import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';
import 'package:digi_sampatti/core/services/report_history_service.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final _service = ReportHistoryService();
  List<LegalReport> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await _service.loadReports();
    if (mounted) setState(() { _reports = reports; _loading = false; });
  }

  Future<void> _delete(String reportId) async {
    await _service.deleteReport(reportId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          if (_reports.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _service.clearAll();
                await _load();
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reports.isEmpty
              ? _EmptyView()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, i) => _ReportCard(
                    report: _reports[i],
                    onDelete: () => _delete(_reports[i].reportId),
                    onTap: () => context.push('/report', extra: _reports[i].toJson()),
                  ),
                ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final LegalReport report;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = report.riskAssessment.score;
    final color = score >= 70 ? AppColors.safe : score >= 40 ? AppColors.warning : AppColors.danger;
    final date = DateFormat('dd MMM yyyy').format(report.generatedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(
          report.scan.surveyNumber != null
              ? 'Survey ${report.scan.surveyNumber}'
              : 'Property Report',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${report.scan.district ?? ""} • $date\n${report.riskAssessment.recommendation}',
          style: TextStyle(color: color, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: report.isPaid ? AppColors.safe.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.isPaid ? 'Paid' : 'Free',
                style: TextStyle(
                  fontSize: 10,
                  color: report.isPaid ? AppColors.safe : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textLight, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No reports yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Search a property to generate your first report',
              style: TextStyle(color: AppColors.textMedium), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/scan/manual'),
            icon: const Icon(Icons.search),
            label: const Text('Search Property'),
          ),
        ],
      ),
    );
  }
}
