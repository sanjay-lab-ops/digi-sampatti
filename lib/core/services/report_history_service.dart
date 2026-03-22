import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_sampatti/core/models/legal_report_model.dart';

class ReportHistoryService {
  static const _key = 'saved_reports';

  Future<void> saveReport(LegalReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadReports();
    existing.insert(0, report);
    if (existing.length > 50) existing.removeLast();
    final encoded = existing.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<List<LegalReport>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    return saved.map((s) {
      try {
        return LegalReport.fromJson(jsonDecode(s));
      } catch (_) {
        return null;
      }
    }).whereType<LegalReport>().toList();
  }

  Future<void> deleteReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadReports();
    existing.removeWhere((r) => r.reportId == reportId);
    final encoded = existing.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
