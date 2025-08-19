import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/services/api_service.dart';
import 'package:tcis_app/controllers/data_controller.dart';
import 'package:tcis_app/services/image_upload_service.dart';
import 'package:tcis_app/controllers/report/report_pdf.dart';
import 'package:tcis_app/utils/datetime_utils.dart';

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
    final product = dataController.products
        .where((p) => p.name == report.produto)
        .firstOrNull;
    final supplier = dataController.suppliers
        .where((s) => s.name == report.fornecedor)
        .firstOrNull;

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
      'productId': product?.id,
      'supplierId': supplier?.id,
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

    // Log do payload para debug
    print('=== PAYLOAD DEBUG ===');
    print('Report data mapping:');
    print('prefixo: ${report.prefixo}');
    print('terminal: ${report.terminal} → ID: ${terminal?.id}');
    print('produto: ${report.produto} → ID: ${product?.id}');
    print('fornecedor: ${report.fornecedor} → ID: ${supplier?.id}');
    print('cliente: ${report.cliente} → ID: ${client?.id}');
    print('colaborador: ${report.colaborador} → ID: ${employee?.id}');
    print('dataInicio: ${report.dataInicio}');
    print('horarioInicio: ${report.horarioInicio}');
    print('dataTermino: ${report.dataTermino}');
    print('horarioTermino: ${report.horarioTermino}');
    print('horarioChegada: ${report.horarioChegada}');
    print('horarioSaida: ${report.horarioSaida}');
    print('startDateTime: ${DateTimeUtils.toIsoString(startDateTime)}');
    print('endDateTime: ${DateTimeUtils.toIsoString(endDateTime)}');
    print('arrivalDateTime: ${DateTimeUtils.toIsoString(arrivalDateTime)}');
    print('departureDateTime: ${DateTimeUtils.toIsoString(departureDateTime)}');
    print('Full payload: ${jsonEncode(payload)}');
    print('==================');

    return payload;
  }

  /// Submete um relatório completo para o servidor seguindo o fluxo:
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
      print('Iniciando envio do relatório...');
      
      // PASSO 1: Salvar relatório básico no banco (sem PDF ainda)
      final reportData = _mapReportToApi(report, dataController);
      
      print('=== FAZENDO REQUISIÇÃO API ===');
      print('Endpoint: /reports');
      print('Method: POST');
      print('Data: ${jsonEncode(reportData)}');
      print('============================');
      
      final createResponse = await ApiService.request(
        endpoint: '/reports',
        method: 'POST',
        data: reportData, // Usar dados sem modificação adicional
      );
      
      if (createResponse['success'] != true) {
        // Log detalhado do erro para debug
        print('=== ERRO DETALHADO DA API ===');
        print('Response completo: ${jsonEncode(createResponse)}');
        print('Message: ${createResponse['message']}');
        if (createResponse['errors'] != null) {
          print('Validation errors: ${jsonEncode(createResponse['errors'])}');
          for (var error in createResponse['errors']) {
            print('  - Campo: ${error['field']}, Erro: ${error['message']}, Valor: ${error['value']}');
          }
        }
        print('============================');
        
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
      print('Relatório salvo com ID: $reportId');
      print('Prefixo retornado do servidor: $serverPrefix');
      
      // PASSO 2: Upload das imagens
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('Fazendo upload de ${imageFiles.length} imagens...');
        // Usar prefixo do servidor + ID do relatório para nome da pasta
        final folderName = '$serverPrefix-$reportId';
        
        // Upload individual de cada imagem
        imageUrls = await ImageUploadService.uploadImages(
          images: imageFiles,
          folderName: folderName,
        );
        
        print('Upload de imagens concluído. URLs: ${imageUrls.length}');
      }
      
      // PASSO 3: Gerar PDF com as imagens já no servidor usando o prefixo correto
      print('Gerando PDF com prefixo: $serverPrefix');
      
      // Criar uma cópia do relatório com o prefixo atualizado do servidor
      final reportWithServerPrefix = FullReportModel.fromJson({
        ...report.toJson(),
        'prefixo': serverPrefix,
      });
      
      final pdfPath = await _generatePdfWithServerImages(reportWithServerPrefix, imageUrls);
      final generatedPdfFile = File(pdfPath);
      
      // PASSO 4: Upload do PDF (usando a mesma pasta das imagens)
      print('Fazendo upload do PDF...');
      final folderName = '$serverPrefix-$reportId';
      final pdfUrl = await ImageUploadService.uploadPdf(
        pdfFile: generatedPdfFile,
        folderName: folderName,
        reportPrefix: serverPrefix,
      );
      
      if (pdfUrl.isEmpty) {
        throw Exception('Falha no upload do PDF');
      }
      print('PDF enviado com sucesso. URL: $pdfUrl');
      
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
        print('Aviso: Falha ao atualizar URL do PDF: ${updateResponse['message']}');
      }
      
      print('Relatório enviado com sucesso!');
      
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
      print('Erro ao enviar relatório: $e');
      return {
        'success': false,
        'message': 'Erro ao enviar relatório: $e',
        'data': null
      };
    }
  }

  /// Gera PDF usando as imagens já no servidor
  static Future<String> _generatePdfWithServerImages(
    FullReportModel report, 
    List<String> serverImageUrls
  ) async {
    print('Baixando imagens do servidor para o PDF...');
    final tempImages = <Map<String, dynamic>>[];
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    
    // Baixar cada imagem do servidor e criar arquivo temporário
    for (int i = 0; i < serverImageUrls.length; i++) {
      try {
        final imageUrl = '$baseUrl/${serverImageUrls[i]}';
        print('Baixando imagem: $imageUrl');
        
        // Fazer requisição HTTP para baixar a imagem
        final response = await http.get(Uri.parse(imageUrl));
        
        if (response.statusCode == 200) {
          // Criar arquivo temporário com a imagem baixada
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/temp_image_$i.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          
          tempImages.add({
            'file': tempFile,
            'timestamp': DateTime.now().add(Duration(seconds: i)), // Timestamps diferentes
          });
          
          print('Imagem $i baixada com sucesso');
        } else {
          print('Erro ao baixar imagem $i: ${response.statusCode}');
        }
      } catch (e) {
        print('Erro ao processar imagem $i: $e');
      }
    }
    
    print('Total de imagens processadas: ${tempImages.length}');
    
    // Gerar PDF com as imagens baixadas
    final pdfPath = await generatePdf(
      prefixoController: TextEditingController(text: report.prefixo),
      selectedTerminal: report.terminal,
      selectedProduto: report.produto,
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
    );
    
    // Limpar arquivos temporários
    for (var imageData in tempImages) {
      try {
        final file = imageData['file'] as File;
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Erro ao deletar arquivo temporário: $e');
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

      // Upload do PDF se fornecido
      String? pdfPath;
      if (pdfFile != null) {
        pdfPath = await ImageUploadService.uploadPdf(
          pdfFile: pdfFile,
          folderName: folderName,
          reportPrefix: report.prefixo,
        );
      } else if (imagePaths.isNotEmpty) {
        // Gerar PDF temporário se há imagens (será regenerado após a atualização)
        print('Gerando PDF temporário para atualização...');
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
      
      // Adicionar URLs de imagens se houver
      if (imagePaths.isNotEmpty) {
        reportData['image_urls'] = imagePaths;
      }

      // Garantir que o novo PDF URL seja enviado
      if (pdfPath != null && pdfPath.isNotEmpty) {
        reportData['pdf_url'] = pdfPath;
        print('📄 Atualizando PDF URL: $pdfPath');
      }

      await _apiService.loadToken();
      final response = await _apiService.put('/reports/$reportId', reportData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedReport = data['data'];
          final newPrefix = updatedReport['prefix'] ?? report.prefixo;
          
          // SEMPRE regenerar PDF após qualquer atualização se há imagens ou PDF
          if (pdfFile != null || imagePaths.isNotEmpty) {
            print('🔄 Regenerando PDF após atualização do relatório...');
            
            // Criar uma cópia do report com dados atualizados (incluindo novo prefixo se houver)
            final reportWithUpdatedData = FullReportModel.fromJson({
              ...report.toJson(),
              'prefixo': newPrefix,
            });
            
            // Gerar novo PDF com os dados atualizados
            final newPdfPath = await _generatePdfWithServerImages(reportWithUpdatedData, imagePaths);
            final generatedPdfFile = File(newPdfPath);
            
            final finalPdfPath = await ImageUploadService.uploadPdf(
              pdfFile: generatedPdfFile,
              folderName: folderName,
              reportPrefix: newPrefix,
            );
            
            // Atualizar o PDF URL no backend
            await _apiService.put('/reports/$reportId', {'pdf_url': finalPdfPath});
            print('✅ PDF regenerado após atualização: $finalPdfPath');
            
            // Atualizar dados de retorno com o novo PDF
            updatedReport['pdfUrl'] = finalPdfPath;
          }
          
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
      print('Erro ao atualizar relatório: $e');
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
      print('Erro ao buscar relatórios: $e');
      rethrow;
    }
  }
}

// Extensão para firstOrNull se não existir
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
