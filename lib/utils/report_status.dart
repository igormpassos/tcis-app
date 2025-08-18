import 'package:flutter/material.dart';

enum ReportStatus {
  rascunho(0, 'Rascunho', Colors.grey),
  finalizado(1, 'Finalizado', Colors.blue),
  revisao(2, 'Revisão', Colors.orange),
  enviado(3, 'Enviado', Colors.green);

  const ReportStatus(this.value, this.label, this.color);

  final int value;
  final String label;
  final Color color;

  static ReportStatus fromValue(int value) {
    switch (value) {
      case 0:
        return ReportStatus.rascunho;
      case 1:
        return ReportStatus.finalizado;
      case 2:
        return ReportStatus.revisao;
      case 3:
        return ReportStatus.enviado;
      default:
        return ReportStatus.rascunho;
    }
  }

  Widget toChip() {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget toBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class ReportStatusUtils {
  /// Status que podem ser salvos localmente (apenas rascunho)
  static const List<int> localStatuses = [0];
  
  /// Status que devem ser salvos no banco de dados
  static const List<int> serverStatuses = [1, 2, 3];
  
  /// Verifica se um status deve ser salvo apenas localmente
  static bool isLocalOnly(int status) => localStatuses.contains(status);
  
  /// Verifica se um status deve ser salvo no servidor
  static bool requiresServer(int status) => serverStatuses.contains(status);
  
  /// Próximos status possíveis baseado no status atual
  static List<ReportStatus> getNextPossibleStatuses(int currentStatus) {
    switch (currentStatus) {
      case 0: // Rascunho -> pode ir para Finalizado
        return [ReportStatus.finalizado];
      case 1: // Finalizado -> pode ir para Revisão ou Enviado
        return [ReportStatus.revisao, ReportStatus.enviado];
      case 2: // Revisão -> pode ir para Finalizado ou Enviado
        return [ReportStatus.finalizado, ReportStatus.enviado];
      case 3: // Enviado -> status final, não pode mudar
        return [];
      default:
        return [];
    }
  }
  
  /// Verifica se um status pode ser editado
  static bool canEdit(int status) {
    return status != 3; // Não pode editar relatórios enviados
  }
  
  /// Verifica se um status pode ser excluído
  static bool canDelete(int status) {
    return status == 0 || status == 1; // Apenas rascunhos e finalizados
  }
}
