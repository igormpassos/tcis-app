import 'package:flutter/material.dart';
import 'package:tcis_app/constants.dart';
import '../services/report_submission_manager.dart';

class ReportSubmissionProgressDialog extends StatefulWidget {
  final ReportSubmissionManager manager;
  final VoidCallback? onCancel;

  const ReportSubmissionProgressDialog({
    super.key,
    required this.manager,
    this.onCancel,
  });

  @override
  State<ReportSubmissionProgressDialog> createState() =>
      _ReportSubmissionProgressDialogState();
}

class _ReportSubmissionProgressDialogState
    extends State<ReportSubmissionProgressDialog> {
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    
    // Configurar callback para atualizações de progresso
    widget.manager.setProgressCallback((step, message) {
      if (mounted) {
        setState(() {
          _currentMessage = message ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.manager.currentStep;
    final isRetrying = widget.manager.isRetrying;
    final retryCount = widget.manager.retryCount;

    return PopScope(
      canPop: false, // Impedir fechamento acidental
      child: AlertDialog(
        backgroundColor: colorPrimary,
        title: Row(
          children: [
            const Icon(Icons.upload_file, color: colorSecondary),
            const SizedBox(width: 8),
            Text(
              isRetrying 
                ? 'Tentativa ${retryCount + 1} - Enviando Relatório'
                : 'Enviando Relatório',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600,),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de progresso circular
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/loading-tcis.gif',
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              
              // Mensagem atual
              Text(
                _currentMessage,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Lista de etapas
              Column(
                children: [
                  _buildStepItem(
                    'Validando dados',
                    ReportSubmissionStep.validating,
                    step,
                    Icons.check_circle,
                  ),
                  _buildStepItem(
                    'Criando registro',
                    ReportSubmissionStep.creating,
                    step,
                    Icons.create,
                  ),
                  _buildStepItem(
                    'Upload de imagens',
                    ReportSubmissionStep.uploadingImages,
                    step,
                    Icons.image,
                  ),
                  _buildStepItem(
                    'Gerando PDF',
                    ReportSubmissionStep.generatingPdf,
                    step,
                    Icons.picture_as_pdf,
                  ),
                  _buildStepItem(
                    'Upload do PDF',
                    ReportSubmissionStep.uploadingPdf,
                    step,
                    Icons.cloud_upload,
                  ),
                  _buildStepItem(
                    'Finalizando',
                    ReportSubmissionStep.updating,
                    step,
                    Icons.done_all,
                  ),
                ],
              ),
              
              // Informações de retry se aplicável
              if (isRetrying) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tentativa ${retryCount + 1} de ${widget.manager.maxRetries + 1}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (widget.onCancel != null && step != ReportSubmissionStep.completed)
            TextButton(
              onPressed: () {
                widget.manager.cancel();
                widget.onCancel?.call();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    String title,
    ReportSubmissionStep stepType,
    ReportSubmissionStep currentStep,
    IconData icon,
  ) {
    bool isCompleted = _isStepCompleted(stepType, currentStep);
    bool isCurrent = stepType == currentStep;
    bool isPending = _isStepPending(stepType, currentStep);

    Color iconColor;
    Color textColor;
    Widget statusIcon;

    if (isCompleted) {
      iconColor = colorSecondary;
      textColor = Colors.white;
      statusIcon = const Icon(Icons.check_circle, color: colorSecondary, size: 20);
    } else if (isCurrent) {
      iconColor = Colors.blue;
      textColor = Colors.white;
      statusIcon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
        ),
      );
    } else if (isPending) {
      iconColor = Colors.grey.shade200;
      textColor = Colors.grey.shade200;
      statusIcon = Icon(Icons.radio_button_unchecked, color: Colors.grey.shade200, size: 20);
    } else {
      iconColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
      statusIcon = Icon(Icons.radio_button_unchecked, color: Colors.grey.shade200, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          statusIcon,
        ],
      ),
    );
  }

  bool _isStepCompleted(ReportSubmissionStep stepType, ReportSubmissionStep currentStep) {
    final stepOrder = [
      ReportSubmissionStep.validating,
      ReportSubmissionStep.creating,
      ReportSubmissionStep.uploadingImages,
      ReportSubmissionStep.generatingPdf,
      ReportSubmissionStep.uploadingPdf,
      ReportSubmissionStep.updating,
      ReportSubmissionStep.completed,
    ];

    final stepIndex = stepOrder.indexOf(stepType);
    final currentIndex = stepOrder.indexOf(currentStep);

    return stepIndex < currentIndex || currentStep == ReportSubmissionStep.completed;
  }

  bool _isStepPending(ReportSubmissionStep stepType, ReportSubmissionStep currentStep) {
    final stepOrder = [
      ReportSubmissionStep.validating,
      ReportSubmissionStep.creating,
      ReportSubmissionStep.uploadingImages,
      ReportSubmissionStep.generatingPdf,
      ReportSubmissionStep.uploadingPdf,
      ReportSubmissionStep.updating,
      ReportSubmissionStep.completed,
    ];

    final stepIndex = stepOrder.indexOf(stepType);
    final currentIndex = stepOrder.indexOf(currentStep);

    return stepIndex > currentIndex;
  }
}

/// Dialog para mostrar opções de retry quando ocorre falha
class ReportSubmissionRetryDialog extends StatelessWidget {
  final ReportSubmissionManager manager;
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const ReportSubmissionRetryDialog({
    super.key,
    required this.manager,
    required this.errorMessage,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canRetry = manager.canRetry;
    final retryCount = manager.retryCount;
    final maxRetries = manager.maxRetries;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro no Envio'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ocorreu um erro durante o envio do relatório:',
            style: TextStyle(color: Colors.grey.shade200),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          const SizedBox(height: 16),
          
          // Informações sobre progresso atual
          if (manager.reportId != null) ...[
            Text(
              'Progresso atual:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildProgressInfo(),
            const SizedBox(height: 16),
          ],
          
          // Informações sobre retry
          if (canRetry) ...[
            Text(
              'Você pode tentar novamente. O processo continuará de onde parou.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tentativa ${retryCount + 1} de ${maxRetries + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ] else ...[
            Text(
              'Limite de tentativas excedido. Por favor, tente novamente mais tarde.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        if (canRetry)
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tentar Novamente'),
          ),
      ],
    );
  }

  Widget _buildProgressInfo() {
    final info = manager.getProgressInfo();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info['reportId'] != null)
            Text('• Registro criado: ${info['reportId']}'),
          if (info['sequentialId'] != null)
            Text('• ID sequencial: ${info['sequentialId']}'),
          if (info['uploadedImages'] > 0)
            Text('• Imagens enviadas: ${info['uploadedImages']}'),
          if (info['pdfUrl'] != null)
            Text('• PDF gerado e enviado'),
        ],
      ),
    );
  }
}