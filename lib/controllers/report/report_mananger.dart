import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcis_app/model/full_report_model.dart';

Future<void> saveOrUpdateReport(FullReportModel report) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getStringList('full_reports') ?? [];

  // Remove qualquer com o mesmo ID
  final updated = existing.where((e) {
    final decoded = jsonDecode(e);
    return decoded['id'] != report.id;
  }).toList();

  updated.add(jsonEncode(report.toJson()));
  await prefs.setStringList('full_reports', updated);
}
