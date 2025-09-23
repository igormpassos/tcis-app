import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/model/api_models.dart';
import 'package:tcis_app/services/api_service.dart';
import 'package:tcis_app/controllers/data_controller.dart';
import 'package:tcis_app/services/image_upload_service.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/utils/datetime_utils.dart';
import 'package:tcis_app/services/report_submission_manager.dart';

class ReportApiService {
  static final ApiService _apiService = ApiService();

  /// Mapeia um relatório local para o formato da API
  static Map<String, dynamic> _mapReportToApi(
    FullReportModel report, 
    DataController dataController,
    {List<String>? imagePaths}
  ) {
    // Buscar IDs baseados nos nomes (considerar formato "código - nome")
    final terminal = dataController.terminals
        .where((t) => '${t.code} - ${t.name}' == report.terminal)
        .firstOrNull;
    
    // Buscar múltiplos produtos baseados nas listas
    final products = report.produtos.isNotEmpty 
        ? dataController.products
            .where((p) => report.produtos.contains(p.name))
            .toList()
        : (report.produto.isNotEmpty 
            ? [dataController.products
                .where((p) => p.name == report.produto)
                .firstOrNull].where((p) => p != null).cast<Product>().toList()
            : []);
    
    // Buscar múltiplos fornecedores baseados nas listas
    final suppliers = report.fornecedores.isNotEmpty 
        ? dataController.suppliers
            .where((s) => report.fornecedores.contains(s.name))
            .toList()
        : (report.fornecedor != null && report.fornecedor!.isNotEmpty 
            ? [dataController.suppliers
                .where((s) => s.name == report.fornecedor)
                .firstOrNull].where((s) => s != null).cast<Supplier>().toList()
            : []);

    // Buscar ID do colaborador pelo nome
    final employee = dataController.users
        .where((u) => (u.name ?? u.username) == report.colaborador)
        .firstOrNull;

    // Buscar ID do cliente pelo nome
    final client = dataController.clients
        .where((c) => c.name == report.cliente)
        .firstOrNull;
    
    // Converter campos de data/hora separados para DateTime unificado
    final startDateTime = DateTimeUtils.combineDateTime(
      report.dataInicio, 
      report.horarioInicio
    );
    final endDateTime = DateTimeUtils.combineDateTime(
      report.dataTermino, 
      report.horarioTermino
    );
    final arrivalDateTime = DateTimeUtils.combineDateTime(
      report.dataInicio, 
      report.horarioChegada
    );
    final departureDateTime = DateTimeUtils.combineDateTime(
      report.dataInicio, 
      report.horarioSaida
    );

    final payload = {
      'prefix': report.prefixo,
      'terminalId': terminal?.id,
      'productIds': products.map((p) => p.id).toList(),
      'supplierIds': suppliers.map((s) => s.id).toList(),
      'clientId': client?.id,
      // Enviar userId do colaborador selecionado (se diferente do logado)
      'employeeUserId': employee?.id,
      // Campos unificados de data/hora
      'startDateTime': DateTimeUtils.toIsoString(startDateTime),
      'endDateTime': DateTimeUtils.toIsoString(endDateTime),
      'arrivalDateTime': DateTimeUtils.toIsoString(arrivalDateTime),
      'departureDateTime': DateTimeUtils.toIsoString(departureDateTime),
      'status': report.status,
      'hasContamination': report.houveContaminacao,
      'contaminationDescription': report.contaminacaoDescricao,
      'homogeneousMaterial': report.materialHomogeneo,
      'visibleMoisture': report.umidadeVisivel,
      'rainOccurred': report.houveChuva,
      'supplierAccompanied': report.fornecedorAcompanhou,
      'observations': report.observacoes,
      'imagePaths': imagePaths ?? [],
    };

    return payload;
  }

  /// Submete um relatório completo para o servidor com gerenciamento robusto de estado
  /// Usa ReportSubmissionManager para controle de etapas e retry
  static Future<OperationResult<Map<String, dynamic>>> submitReportWithManager({
    required FullReportModel report,
    required DataController dataController,
    required ReportSubmissionManager manager,
    List<File>? imageFiles,
  }) async {
    try {
      // PASSO 1: Criar relatório no banco de dados
      if (manager.reportId == null) {
        final reportData = _mapReportToApi(report, dataController);
        
        final createResponse = await ApiService.request(
          endpoint: '/reports',
          method: 'POST',
          data: reportData,
        );
        
        if (createResponse['success'] != true) {
          String errorMessage = createResponse['message'] ?? 'Erro desconhecido';
          if (createResponse['errors'] != null && createResponse['errors'].isNotEmpty) {
            final errors = createResponse['errors'] as List;
            final errorDetails = errors.map((e) => '${e['field']}: ${e['message']}').join('; ');
            errorMessage += '\nDetalhes: $errorDetails';
          }
          
          manager.markFailed(
            'Falha ao salvar relatório: $errorMessage',
            ErrorType.server,
            metadata: {'response': createResponse},
          );
          
          return OperationResult.failure(
            'Falha ao salvar relatório: $errorMessage',
            errorType: ErrorType.server,
          );
        }
        
        final reportId = createResponse['data']['id'];
        final serverPrefix = createResponse['data']['prefix'] ?? report.prefixo;
        final sequentialId = createResponse['data']['sequentialId'];
        
        manager.markCreationCompleted(reportId, serverPrefix, sequentialId);
      }
      
      // PASSO 2: Upload das imagens (se necessário)
      List<String> imageUrls = manager.uploadedImageUrls;
      if (imageUrls.isEmpty && imageFiles != null && imageFiles.isNotEmpty) {
        try {
          final folderName = '${manager.serverPrefix}-${manager.reportId}';
          imageUrls = await ImageUploadService.uploadImages(
            images: imageFiles,
            folderName: folderName,
          );
          manager.markImagesUploaded(imageUrls);
        } catch (e) {
          manager.markFailed(
            'Falha no upload das imagens: $e',
            ErrorType.upload,
            metadata: {'step': 'image_upload', 'error': e.toString()},
          );
          
          return OperationResult.failure(
            'Falha no upload das imagens: $e',
            errorType: ErrorType.upload,
          );
        }
      } else if (imageFiles == null || imageFiles.isEmpty) {
        manager.markImagesUploaded([]);
      }
      
      // PASSO 3: Gerar PDF (se necessário)
      if (manager.pdfUrl == null) {
        try {
          final reportWithServerData = FullReportModel.fromJson({
            ...report.toJson(),
            'prefixo': manager.serverPrefix,
            'sequentialId': manager.sequentialId,
          });
          
          final pdfPath = await _generatePdfWithServerImages(reportWithServerData, imageUrls);
          manager.markPdfGenerated();
          
          // PASSO 4: Upload do PDF
          final generatedPdfFile = File(pdfPath);
          final folderName = '${manager.serverPrefix}-${manager.reportId}';
          final pdfUrl = await ImageUploadService.uploadPdf(
            pdfFile: generatedPdfFile,
            folderName: folderName,
            reportPrefix: manager.serverPrefix!,
          );
          
          if (pdfUrl.isEmpty) {
            manager.markFailed(
              'Falha no upload do PDF',
              ErrorType.upload,
              metadata: {'step': 'pdf_upload'},
            );
            
            return OperationResult.failure(
              'Falha no upload do PDF',
              errorType: ErrorType.upload,
            );
          }
          
          manager.markPdfUploaded(pdfUrl);
          
        } catch (e) {
          ErrorType errorType = ErrorType.pdf;
          if (e.toString().contains('upload') || e.toString().contains('network')) {
            errorType = ErrorType.upload;
          } else if (e.toString().contains('server') || e.toString().contains('http')) {
            errorType = ErrorType.server;
          }
          
          manager.markFailed(
            'Falha na geração/upload do PDF: $e',
            errorType,
            metadata: {'step': 'pdf_generation', 'error': e.toString()},
          );
          
          return OperationResult.failure(
            'Falha na geração/upload do PDF: $e',
            errorType: errorType,
          );
        }
      }
      
      // PASSO 5: Atualizar relatório com URLs finais
      try {
        final updateResponse = await ApiService.request(
          endpoint: '/reports/${manager.reportId}',
          method: 'PUT',
          data: {
            'pdf_url': manager.pdfUrl,
            'image_urls': manager.uploadedImageUrls,
            'status': 1, // 1 = Em Revisão
          },
        );
        
        if (updateResponse['success'] != true) {
          // Não falhar aqui se o resto funcionou, apenas logar
          debugPrint('Aviso: Falha ao atualizar URLs do relatório: ${updateResponse['message']}');
        }
        
        manager.markCompleted();
        
        return OperationResult.success({
          'id': manager.reportId,
          'pdf_url': manager.pdfUrl,
          'image_urls': manager.uploadedImageUrls,
          'sequential_id': manager.sequentialId,
          'server_prefix': manager.serverPrefix,
        });
        
      } catch (e) {
        // Se chegou até aqui, o relatório foi criado com sucesso
        // Apenas avisar sobre a falha na atualização
        debugPrint('Aviso: Relatório criado mas falha ao atualizar URLs: $e');
        
        manager.markCompleted();
        
        return OperationResult.success({
          'id': manager.reportId,
          'pdf_url': manager.pdfUrl,
          'image_urls': manager.uploadedImageUrls,
          'sequential_id': manager.sequentialId,
          'server_prefix': manager.serverPrefix,
        });
      }
      
    } catch (e) {
      // Erro geral não capturado
      ErrorType errorType = ErrorType.unknown;
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorType = ErrorType.network;
      } else if (e.toString().contains('server') || e.toString().contains('http')) {
        errorType = ErrorType.server;
      }
      
      manager.markFailed(
        'Erro inesperado: $e',
        errorType,
        metadata: {'error': e.toString()},
      );
      
      return OperationResult.failure(
        'Erro inesperado: $e',
        errorType: errorType,
      );
    }
  }

  /// Método original mantido para compatibilidade
  /// 1. Salva relatório no banco → obter ID
  /// 2. Faz upload das imagens na pasta com o ID → obter URLs
  /// 3. Gera PDF com dados + imagens → obter URL do PDF
  /// 4. Atualiza o relatório com as URLs das imagens e PDF
  static Future<Map<String, dynamic>> submitReport({
    required FullReportModel report,
    required DataController dataController,
    List<File>? imageFiles,
  }) async {
    try {
      // PASSO 1: Salvar relatório básico no banco (sem PDF ainda)
      final reportData = _mapReportToApi(report, dataController);
      
      final createResponse = await ApiService.request(
        endpoint: '/reports',
        method: 'POST',
        data: reportData, // Usar dados sem modificação adicional
      );
      
      if (createResponse['success'] != true) {
        // Criar mensagem de erro mais detalhada
        String errorMessage = createResponse['message'] ?? 'Erro desconhecido';
        if (createResponse['errors'] != null && createResponse['errors'].isNotEmpty) {
          final errors = createResponse['errors'] as List;
          final errorDetails = errors.map((e) => '${e['field']}: ${e['message']}').join('; ');
          errorMessage += '\nDetalhes: $errorDetails';
        }
        
        throw Exception('Falha ao salvar relatório: $errorMessage');
      }
      
      final reportId = createResponse['data']['id'];
      final serverPrefix = createResponse['data']['prefix'] ?? report.prefixo;
      final sequentialId = createResponse['data']['sequentialId']; // Pegar o ID sequencial da resposta
      
      // PASSO 2: Upload das imagens
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // Usar prefixo do servidor + ID do relatório para nome da pasta
        final folderName = '$serverPrefix-$reportId';
        
        // Upload individual de cada imagem
        imageUrls = await ImageUploadService.uploadImages(
          images: imageFiles,
          folderName: folderName,
        );
        
      }
      
      // PASSO 3: Gerar PDF com as imagens já no servidor usando o prefixo correto
      
      // Criar uma cópia do relatório com o prefixo e sequentialId atualizados do servidor
      final reportWithServerData = FullReportModel.fromJson({
        ...report.toJson(),
        'prefixo': serverPrefix,
        'sequentialId': sequentialId,
      });
      
      final pdfPath = await _generatePdfWithServerImages(reportWithServerData, imageUrls);
      final generatedPdfFile = File(pdfPath);
      
      // PASSO 4: Upload do PDF (usando a mesma pasta das imagens)
      final folderName = '$serverPrefix-$reportId';
      final pdfUrl = await ImageUploadService.uploadPdf(
        pdfFile: generatedPdfFile,
        folderName: folderName,
        reportPrefix: serverPrefix,
      );
      
      if (pdfUrl.isEmpty) {
        throw Exception('Falha no upload do PDF');
      }
      
      // PASSO 5: Atualizar relatório com URL do PDF e status final
      final updateResponse = await ApiService.request(
        endpoint: '/reports/$reportId',
        method: 'PUT',
        data: {
          'pdf_url': pdfUrl,
          'image_urls': imageUrls,
          'status': 1, // 1 = Em Revisão
        },
      );
      
      if (updateResponse['success'] != true) {
      }
      
      
      return {
        'success': true,
        'message': 'Relatório enviado com sucesso',
        'data': {
          'id': reportId,
          'pdf_url': pdfUrl,
          'image_urls': imageUrls,
        }
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao enviar relatório: $e',
        'data': null
      };
    }
  }

  /// Gera PDF usando as imagens já no servidor (só baixa quando necessário)
  static Future<String> _generatePdfWithServerImages(
    FullReportModel report, 
    List<String> serverImageUrls
  ) async {
    final tempImages = <Map<String, dynamic>>[];
    final baseUrl = ApiService.baseUrl;
    
    // Baixar cada imagem do servidor e criar arquivo temporário
    for (int i = 0; i < serverImageUrls.length; i++) {
      try {
        final imageUrl = '$baseUrl/${serverImageUrls[i]}';
        
        // Fazer requisição HTTP para baixar a imagem
        final response = await http.get(Uri.parse(imageUrl));
        
        if (response.statusCode == 200) {
          // Criar arquivo temporário com a imagem baixada
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/temp_pdf_image_$i.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          
          tempImages.add({
            'file': tempFile,
            'timestamp': DateTime.now().add(Duration(seconds: i)), // Timestamps diferentes
          });
          
        } else {
        }
      } catch (e) {
      }
    }
    
    
    // Gerar PDF com as imagens baixadas
    final pdfPath = await generatePdf(
      prefixoController: TextEditingController(text: report.prefixo),
      selectedTerminal: report.terminal,
      selectedProduto: report.produto,
      selectedProdutos: report.produtos.isNotEmpty ? report.produtos : null,
      selectedFornecedores: report.fornecedores.isNotEmpty ? report.fornecedores : null,
      selectedVagao: null, // Campo removido
      colaborador: report.colaborador,
      fornecedor: report.fornecedor,
      selectedValue: null, // Campo removido
      dataInicioController: TextEditingController(text: report.dataInicio),
      horarioChegadaController: TextEditingController(text: report.horarioChegada),
      horarioInicioController: TextEditingController(text: report.horarioInicio),
      horarioTerminoController: TextEditingController(text: report.horarioTermino),
      horarioSaidaController: TextEditingController(text: report.horarioSaida),
      dataTerminoController: TextEditingController(text: report.dataTermino),
      houveContaminacao: report.houveContaminacao,
      contaminacaoDescricao: report.contaminacaoDescricao,
      materialHomogeneo: report.materialHomogeneo,
      umidadeVisivel: report.umidadeVisivel,
      houveChuva: report.houveChuva,
      fornecedorAcompanhou: report.fornecedorAcompanhou,
      observacoesController: TextEditingController(text: report.observacoes),
      images: tempImages,
      sequentialId: report.sequentialId, // Adicionar ID sequencial
    );
    
    
    // Limpar arquivos temporários
    for (var imageData in tempImages) {
      try {
        final file = imageData['file'] as File;
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
      }
    }
    
    return pdfPath;
  }

  /// Atualiza relatório existente no servidor
  static Future<Map<String, dynamic>> updateReport({
    required String reportId,
    required FullReportModel report,
    required DataController dataController,
    List<File>? newImageFiles,
    File? pdfFile,
    String? existingFolderName,
    List<String>? existingImagePaths,
    FullReportModel? originalReport, // Relatório original para comparação
  }) async {
    try {
      // Usar pasta existente ou gerar nova
      final folderName = existingFolderName ?? 
          ImageUploadService.generateFolderName(report.prefixo);
      
      // Upload de novas imagens se fornecidas
      List<String> imagePaths = [];
      
      // Manter imagens existentes
      if (existingImagePaths != null) {
        imagePaths.addAll(existingImagePaths);
      }
      
      // Adicionar novas imagens
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final newPaths = await ImageUploadService.uploadImages(
          images: newImageFiles,
          folderName: folderName,
        );
        imagePaths.addAll(newPaths);
      }

      // Verificar se precisa regenerar PDF
      bool shouldRegeneratePdf = false;
      
      if (pdfFile != null) {
        // PDF fornecido diretamente
        shouldRegeneratePdf = false;
      } else if (newImageFiles != null && newImageFiles.isNotEmpty) {
        // Há novas imagens - precisa regenerar
        shouldRegeneratePdf = true;
      } else if (originalReport != null) {
        // Verificar se houve mudanças nos dados do relatório que afetam o PDF
        shouldRegeneratePdf = _hasContentChanges(originalReport, report);
      }

      // Upload do PDF se fornecido
      String? pdfPath;
      
      if (pdfFile != null) {
        // PDF fornecido diretamente - fazer upload
        pdfPath = await ImageUploadService.uploadPdf(
          pdfFile: pdfFile,
          folderName: folderName,
          reportPrefix: report.prefixo,
        );
      } else if (shouldRegeneratePdf) {
        // Só gerar PDF se realmente necessário
        final tempPdfPath = await _generatePdfWithServerImages(report, imagePaths);
        final generatedPdfFile = File(tempPdfPath);
        
        pdfPath = await ImageUploadService.uploadPdf(
          pdfFile: generatedPdfFile,
          folderName: folderName,
          reportPrefix: report.prefixo,
        );
      }

      // Preparar dados para atualização
      final reportData = _mapReportToApi(
        report, 
        dataController,
        imagePaths: imagePaths.isNotEmpty ? imagePaths : null,
      );

      // Remover campos nulos para não sobrescrever dados existentes
      reportData.removeWhere((key, value) => value == null);
      
      // SÓ incluir URLs de imagens se houve mudanças nas imagens
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        // Há novas imagens - enviar lista completa (existentes + novas)
        reportData['image_urls'] = imagePaths;
      } else {
        // Sem novas imagens - não alterar as imagens no servidor
        reportData.remove('image_urls');
      }

      // Garantir que o novo PDF URL seja enviado APENAS se foi gerado
      if (pdfPath != null && pdfPath.isNotEmpty) {
        reportData['pdf_url'] = pdfPath;
      } else {
        reportData.remove('pdf_url');
      }

      await _apiService.loadToken();
      
      final response = await _apiService.put('/reports/$reportId', reportData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedReport = data['data'];
          
          // PDF já foi gerado e enviado acima se necessário
          // Não precisamos regenerar novamente aqui
          
          return {
            'success': true,
            'data': updatedReport,
            'folderName': folderName,
          };
        } else {
          throw Exception('Erro da API: ${data['message']}');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lista relatórios do servidor
  static Future<List<Map<String, dynamic>>> getReports({
    int page = 1,
    int limit = 20,
    int? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      await _apiService.loadToken();
      final response = await _apiService.get('/reports?$queryString');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Erro da API: ${data['message']}');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica se houve mudanças no conteúdo que afetam a geração do PDF
  static bool _hasContentChanges(FullReportModel original, FullReportModel updated) {
    // Campos que afetam o conteúdo do PDF
    final hasChanges = original.prefixo != updated.prefixo ||
           original.terminal != updated.terminal ||
           original.colaborador != updated.colaborador ||
           original.cliente != updated.cliente ||
           original.dataInicio != updated.dataInicio ||
           original.horarioInicio != updated.horarioInicio ||
           original.dataTermino != updated.dataTermino ||
           original.horarioTermino != updated.horarioTermino ||
           original.horarioChegada != updated.horarioChegada ||
           original.horarioSaida != updated.horarioSaida ||
           original.houveContaminacao != updated.houveContaminacao ||
           original.contaminacaoDescricao != updated.contaminacaoDescricao ||
           original.materialHomogeneo != updated.materialHomogeneo ||
           original.umidadeVisivel != updated.umidadeVisivel ||
           original.houveChuva != updated.houveChuva ||
           original.fornecedorAcompanhou != updated.fornecedorAcompanhou ||
           original.observacoes != updated.observacoes ||
           !_listEquals(original.produtos, updated.produtos) ||
           !_listEquals(original.fornecedores, updated.fornecedores);
    
    if (hasChanges) {
      if (original.prefixo != updated.prefixo) print('  - Prefixo: ${original.prefixo} -> ${updated.prefixo}');
      if (original.terminal != updated.terminal) print('  - Terminal: ${original.terminal} -> ${updated.terminal}');
      if (original.colaborador != updated.colaborador) print('  - Colaborador: ${original.colaborador} -> ${updated.colaborador}');
      if (original.cliente != updated.cliente) print('  - Cliente: ${original.cliente} -> ${updated.cliente}');
      // ... mais logs se necessário
    } else {
    }
    
    return hasChanges;
  }

  /// Compara duas listas para igualdade
  static bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Deleta um relatório (apenas para administradores)
  static Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final response = await ApiService.request(
        endpoint: '/reports/$reportId',
        method: 'DELETE',
      );
      
      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Relatório deletado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao deletar relatório',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao deletar relatório: $e',
      };
    }
  }
}

// Extensão para firstOrNull se não existir
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
