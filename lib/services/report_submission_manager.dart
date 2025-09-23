import 'dart:async';
import 'package:flutter/material.dart';

/// Enum para definir as etapas do processo de envio de relatório
enum ReportSubmissionStep {
  idle,
  validating,
  creating,
  uploadingImages,
  generatingPdf,
  uploadingPdf,
  updating,
  completed,
  failed,
}

/// Enum para tipos de erro que podem ocorrer
enum ErrorType {
  validation,
  network,
  server,
  upload,
  pdf,
  unknown,
}

/// Classe para representar o resultado de uma operação
class OperationResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final ErrorType? errorType;
  final Map<String, dynamic>? metadata;

  const OperationResult({
    required this.success,
    this.data,
    this.error,
    this.errorType,
    this.metadata,
  });

  factory OperationResult.success(T data, {Map<String, dynamic>? metadata}) {
    return OperationResult<T>(
      success: true,
      data: data,
      metadata: metadata,
    );
  }

  factory OperationResult.failure(
    String error, {
    ErrorType? errorType,
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult<T>(
      success: false,
      error: error,
      errorType: errorType ?? ErrorType.unknown,
      metadata: metadata,
    );
  }
}

/// Classe para gerenciar o estado de submissão de relatórios
class ReportSubmissionManager {
  static final Map<String, ReportSubmissionManager> _instances = {};
  
  final String _sessionId;
  ReportSubmissionStep _currentStep = ReportSubmissionStep.idle;
  String? _reportId;
  String? _serverPrefix;
  String? _sequentialId;
  List<String> _uploadedImageUrls = [];
  String? _pdfUrl;
  int _retryCount = 0;
  final int maxRetries = 3;
  bool _isRetrying = false;
  
  // Callback para atualização de progresso
  Function(ReportSubmissionStep, String?)? onProgressUpdate;
  
  // Completer para operações async
  Completer<OperationResult<Map<String, dynamic>>>? _currentOperation;

  ReportSubmissionManager._(this._sessionId);

  factory ReportSubmissionManager.getInstance(String sessionId) {
    return _instances.putIfAbsent(
      sessionId, 
      () => ReportSubmissionManager._(sessionId),
    );
  }

  /// Limpa a instância da sessão
  static void clearSession(String sessionId) {
    _instances.remove(sessionId);
  }

  String get sessionId => _sessionId;
  /// Getters para o estado atual
  ReportSubmissionStep get currentStep => _currentStep;
  String? get reportId => _reportId;
  String? get serverPrefix => _serverPrefix;
  String? get sequentialId => _sequentialId;
  List<String> get uploadedImageUrls => List.unmodifiable(_uploadedImageUrls);
  String? get pdfUrl => _pdfUrl;
  int get retryCount => _retryCount;
  bool get isRetrying => _isRetrying;
  bool get canRetry => _retryCount < maxRetries;
  bool get isProcessing => _currentStep != ReportSubmissionStep.idle && 
                          _currentStep != ReportSubmissionStep.completed && 
                          _currentStep != ReportSubmissionStep.failed;

  /// Define callback para atualização de progresso
  void setProgressCallback(Function(ReportSubmissionStep, String?) callback) {
    onProgressUpdate = callback;
  }

  /// Atualiza o estado atual e notifica callbacks
  void _updateStep(ReportSubmissionStep step, [String? message]) {
    _currentStep = step;
    onProgressUpdate?.call(step, message);
    debugPrint('ReportSubmission ($_sessionId): $step - $message');
  }

  /// Verifica se é seguro iniciar uma nova operação
  bool canStartNewOperation() {
    return _currentStep == ReportSubmissionStep.idle || 
           _currentStep == ReportSubmissionStep.completed ||
           _currentStep == ReportSubmissionStep.failed;
  }

  /// Inicia o processo de submissão
  Future<OperationResult<Map<String, dynamic>>> startSubmission() async {
    if (!canStartNewOperation()) {
      return OperationResult.failure(
        'Operação já em andamento',
        errorType: ErrorType.validation,
      );
    }

    // Reset do estado para nova tentativa
    if (_currentStep == ReportSubmissionStep.failed) {
      _resetForRetry();
    }

    _currentOperation = Completer<OperationResult<Map<String, dynamic>>>();
    _updateStep(ReportSubmissionStep.validating, 'Validando dados...');
    
    return _currentOperation!.future;
  }

  /// Marca a criação do relatório como concluída
  void markCreationCompleted(String reportId, String serverPrefix, String? sequentialId) {
    _reportId = reportId;
    _serverPrefix = serverPrefix;
    _sequentialId = sequentialId;
    _updateStep(ReportSubmissionStep.uploadingImages, 'Fazendo upload das imagens...');
  }

  /// Marca o upload de imagens como concluído
  void markImagesUploaded(List<String> imageUrls) {
    _uploadedImageUrls = imageUrls;
    _updateStep(ReportSubmissionStep.generatingPdf, 'Gerando PDF...');
  }

  /// Marca a geração do PDF como concluída
  void markPdfGenerated() {
    _updateStep(ReportSubmissionStep.uploadingPdf, 'Fazendo upload do PDF...');
  }

  /// Marca o upload do PDF como concluído
  void markPdfUploaded(String pdfUrl) {
    _pdfUrl = pdfUrl;
    _updateStep(ReportSubmissionStep.updating, 'Finalizando...');
  }

  /// Marca o processo como concluído com sucesso
  void markCompleted() {
    _updateStep(ReportSubmissionStep.completed, 'Relatório enviado com sucesso!');
    _currentOperation?.complete(OperationResult.success({
      'id': _reportId,
      'pdf_url': _pdfUrl,
      'image_urls': _uploadedImageUrls,
      'sequential_id': _sequentialId,
      'server_prefix': _serverPrefix,
    }));
  }

  /// Marca o processo como falhado
  void markFailed(String error, ErrorType errorType, {Map<String, dynamic>? metadata}) {
    _updateStep(ReportSubmissionStep.failed, error);
    _currentOperation?.complete(OperationResult.failure(
      error,
      errorType: errorType,
      metadata: metadata,
    ));
  }

  /// Inicia uma tentativa de retry
  Future<OperationResult<Map<String, dynamic>>> retry() async {
    if (!canRetry) {
      return OperationResult.failure(
        'Limite de tentativas excedido',
        errorType: ErrorType.validation,
      );
    }

    _retryCount++;
    _isRetrying = true;
    
    // Determinar de onde continuar baseado no que já foi concluído
    ReportSubmissionStep resumeStep;
    if (_reportId == null) {
      resumeStep = ReportSubmissionStep.creating;
    } else if (_uploadedImageUrls.isEmpty) {
      resumeStep = ReportSubmissionStep.uploadingImages;
    } else if (_pdfUrl == null) {
      resumeStep = ReportSubmissionStep.generatingPdf;
    } else {
      resumeStep = ReportSubmissionStep.updating;
    }

    _currentStep = resumeStep;
    _currentOperation = Completer<OperationResult<Map<String, dynamic>>>();
    
    String stepMessage = _getStepMessage(resumeStep);
    _updateStep(resumeStep, 'Tentativa ${_retryCount + 1}: $stepMessage');
    
    return _currentOperation!.future;
  }

  /// Obtém mensagem descritiva para cada etapa
  String _getStepMessage(ReportSubmissionStep step) {
    switch (step) {
      case ReportSubmissionStep.creating:
        return 'Criando relatório...';
      case ReportSubmissionStep.uploadingImages:
        return 'Fazendo upload das imagens...';
      case ReportSubmissionStep.generatingPdf:
        return 'Gerando PDF...';
      case ReportSubmissionStep.uploadingPdf:
        return 'Fazendo upload do PDF...';
      case ReportSubmissionStep.updating:
        return 'Finalizando...';
      default:
        return 'Processando...';
    }
  }

  /// Reset do estado para retry
  void _resetForRetry() {
    _isRetrying = false;
    // Manter dados já obtidos (reportId, etc.) para continuar de onde parou
  }

  /// Cancela a operação atual
  void cancel() {
    if (_currentOperation != null && !_currentOperation!.isCompleted) {
      _currentOperation!.complete(OperationResult.failure(
        'Operação cancelada pelo usuário',
        errorType: ErrorType.validation,
      ));
    }
    _updateStep(ReportSubmissionStep.idle, 'Operação cancelada');
  }

  /// Limpa completamente o estado (para nova submissão)
  void reset() {
    _currentStep = ReportSubmissionStep.idle;
    _reportId = null;
    _serverPrefix = null;
    _sequentialId = null;
    _uploadedImageUrls.clear();
    _pdfUrl = null;
    _retryCount = 0;
    _isRetrying = false;
    _currentOperation = null;
  }

  /// Obtém informações detalhadas sobre o progresso
  Map<String, dynamic> getProgressInfo() {
    return {
      'sessionId': _sessionId,
      'currentStep': _currentStep.toString(),
      'reportId': _reportId,
      'serverPrefix': _serverPrefix,
      'sequentialId': _sequentialId,
      'uploadedImages': _uploadedImageUrls.length,
      'pdfUrl': _pdfUrl,
      'retryCount': _retryCount,
      'canRetry': canRetry,
      'isRetrying': _isRetrying,
      'isProcessing': isProcessing,
    };
  }
}