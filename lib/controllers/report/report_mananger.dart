import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcis_app/model/full_report_model.dart';

Future<void> saveOrUpdateReport(FullReportModel report) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getStringList('full_reports') ?? [];

  // Encontrar índice do relatório existente com o mesmo ID
  int existingIndex = -1;
  for (int i = 0; i < existing.length; i++) {
    final decoded = jsonDecode(existing[i]);
    if (decoded['id'] == report.id) {
      existingIndex = i;
      break;
    }
  }

  if (existingIndex >= 0) {
    // Atualizar relatório existente
    existing[existingIndex] = jsonEncode(report.toJson());
  } else {
    // Adicionar novo relatório
    existing.add(jsonEncode(report.toJson()));
  }

  await prefs.setStringList('full_reports', existing);
}
