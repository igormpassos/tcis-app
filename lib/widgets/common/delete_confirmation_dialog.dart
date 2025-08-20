import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = 'Excluir',
    this.cancelText = 'Cancelar',
  });

  /// Método estático para mostrar o dialog de forma simples
  static Future<bool?> show({
    required BuildContext context,
    required String itemName,
    required String itemType,
    String? customMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => DeleteConfirmationDialog(
            title: 'Confirmar exclusão',
            content:
                customMessage ??
                'Tem certeza que deseja excluir ${itemType.toLowerCase()} "$itemName"?',
            onConfirm: () => Navigator.pop(context, true),
          ),
    );
  }

  /// Método para mostrar dialog com callback personalizado
  static Future<void> showWithCallback({
    required BuildContext context,
    required String itemName,
    required String itemType,
    required Future<void> Function() onConfirm,
    String? customMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    final confirm = await show(
      context: context,
      itemName: itemName,
      itemType: itemType,
      customMessage: customMessage,
    );

    if (confirm == true) {
      try {
        await onConfirm();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successMessage ??
                    '$itemType removido${itemType.toLowerCase().endsWith('a') ? 'a' : ''} com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage ?? 'Erro ao remover ${itemType.toLowerCase()}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        Column(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      ],
    );
  }
}
