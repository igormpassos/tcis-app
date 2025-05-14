import 'package:flutter/material.dart';
import 'package:tcis_app/controllers/report/delete_report.dart';

Future<void> showDeleteConfirmationDialog(BuildContext context, String id, VoidCallback onDeleted) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este relatório? Esta ação não poderá ser desfeita.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await deleteReportById(id);
              Navigator.of(context).pop();
              onDeleted(); // Callback para atualizar a tela
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Relatório excluído com sucesso.')),
              );
            },
          ),
        ],
      );
    },
  );
}
