import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> deleteReportById(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final savedReports = prefs.getStringList('full_reports') ?? [];

  final updatedReports = savedReports.where((reportJson) {
    final decoded = jsonDecode(reportJson);
    return decoded['id'] != id;
  }).toList();

  await prefs.setStringList('full_reports', updatedReports);
}
