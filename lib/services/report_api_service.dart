import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:tcis_app/model/full_report_model.dart';
import 'package:tcis_app/model/api_models.dart';
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

  /// Submete um relatório completo para o servidor seguindo o fluxo:
  /// 1. Salva relatório no banco → obter ID
  /// 2. Faz upload das imagens na pasta com o ID → obter URLs
  /// 3. Gera PDF com dados + imagens → obter URL do PDF
  /// 4. Atualiza o relatório com as URLs das imagens e PDF
  static Future<Map<String, dynamic>> submitReport({
    required FullReportModel report,
    required DataController dataController,
    List<dynamic>? imageFiles, // Mudança: aceita dynamic (File ou XFile)
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
      
      // PASSO 3: Gerar PDF
      String pdfPath;
      dynamic pdfFileForUpload; // Pode ser File ou Uint8List
      
      if (kIsWeb && imageFiles != null && imageFiles.isNotEmpty) {
        // Na web: gerar PDF com imagens locais diretamente
        final reportWithServerPrefix = FullReportModel.fromJson({
          ...report.toJson(),
          'prefixo': serverPrefix,
        });
        
        // Na web, vamos gerar o PDF e obter os bytes diretamente
        pdfPath = await _generatePdfWithLocalImages(reportWithServerPrefix, imageFiles);
        
        // Obter bytes do PDF recém-gerado
        final pdfBytes = getLastGeneratedPdfBytes();
        if (pdfBytes != null) {
          pdfFileForUpload = pdfBytes;
        } else {
          throw Exception('Erro ao obter bytes do PDF gerado');
        }
      } else {
        // No mobile ou sem imagens: usar método tradicional com download do servidor
        final reportWithServerPrefix = FullReportModel.fromJson({
          ...report.toJson(),
          'prefixo': serverPrefix,
        });
        
        pdfPath = await _generatePdfWithServerImages(reportWithServerPrefix, imageUrls);
        final generatedPdfFile = File(pdfPath);
        pdfFileForUpload = generatedPdfFile;
      }
      
      // PASSO 4: Upload do PDF (usando a mesma pasta das imagens)
      final folderName = '$serverPrefix-$reportId';
      
      final pdfUrl = await ImageUploadService.uploadPdf(
        pdfFile: pdfFileForUpload,
        folderName: folderName,
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
        throw Exception('Falha ao atualizar relatório: ${updateResponse['message']}');
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

  /// Gera PDF usando as imagens já no servidor
  static Future<String> _generatePdfWithServerImages(
    FullReportModel report, 
    List<String> serverImageUrls
  ) async {
    final tempImages = <Map<String, dynamic>>[];
    final baseUrl = ApiService.baseUrl;
    
    // Carregar token de autenticação
    await _apiService.loadToken();
    
    // Baixar cada imagem do servidor e criar arquivo temporário
    for (int i = 0; i < serverImageUrls.length; i++) {
      try {
        // Tentar múltiplas estratégias para acessar a imagem
        Uint8List? imageBytes;
        
        // Estratégia 1: Acesso direto (sem auth)
        final directUrl = '$baseUrl/${serverImageUrls[i]}';
        print('Estratégia 1 - URL direta: $directUrl');
        
        final directResponse = await http.get(Uri.parse(directUrl));
        if (directResponse.statusCode == 200) {
          imageBytes = directResponse.bodyBytes;
          print('Sucesso com acesso direto');
        } else {
          print('Acesso direto falhou: ${directResponse.statusCode}');
          
          // Estratégia 2: Acesso com autenticação
          final authUrl = '$baseUrl/${serverImageUrls[i]}';
          print('Estratégia 2 - URL com auth: $authUrl');
          
          final authResponse = await http.get(
            Uri.parse(authUrl),
            headers: _apiService.headers,
          );
          
          if (authResponse.statusCode == 200) {
            imageBytes = authResponse.bodyBytes;
            print('Sucesso com autenticação');
          } else {
            print('Acesso com auth falhou: ${authResponse.statusCode} - ${authResponse.body}');
            
            // Estratégia 3: API específica para download
            final downloadUrl = '$baseUrl/uploads/download/${Uri.encodeComponent(serverImageUrls[i])}';
            print('Estratégia 3 - URL download: $downloadUrl');
            
            final downloadResponse = await http.get(
              Uri.parse(downloadUrl),
              headers: _apiService.headers,
            );
            
            if (downloadResponse.statusCode == 200) {
              imageBytes = downloadResponse.bodyBytes;
              print('Sucesso com API de download');
            } else {
              print('API download falhou: ${downloadResponse.statusCode} - ${downloadResponse.body}');
            }
          }
        }
        
        if (imageBytes != null && imageBytes.isNotEmpty) {
          // Criar arquivo temporário com a imagem baixada
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/temp_image_$i.jpg');
          await tempFile.writeAsBytes(imageBytes);
          
          tempImages.add({
            'file': tempFile,
            'timestamp': DateTime.now().add(Duration(seconds: i)), // Timestamps diferentes
          });
          print('Imagem $i processada com sucesso');
        } else {
          print('Erro ao baixar imagem $i: nenhuma estratégia funcionou');
        }
        
      } catch (e) {
        print('Erro ao processar imagem $i: $e');
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
    List<dynamic>? newImageFiles, // Mudança: aceita dynamic
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
        );
      } else if (imagePaths.isNotEmpty) {
        // Gerar PDF temporário se há imagens (será regenerado após a atualização)
        final tempPdfPath = await _generatePdfWithServerImages(report, imagePaths);
        final generatedPdfFile = File(tempPdfPath);
        
        pdfPath = await ImageUploadService.uploadPdf(
          pdfFile: generatedPdfFile,
          folderName: folderName,
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
            );
            
            // Atualizar o PDF URL no backend
            await _apiService.put('/reports/$reportId', {'pdf_url': finalPdfPath});
            
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

  /// Gera PDF com imagens locais para web
  static Future<String> _generatePdfWithLocalImages(
    FullReportModel report, 
    List<dynamic> localImages
  ) async {
    // Converter XFiles para o formato esperado pelo generatePdf
    final imagesForPdf = <Map<String, dynamic>>[];
    
    for (int i = 0; i < localImages.length; i++) {
      final imageFile = localImages[i];
      
      if (kIsWeb && imageFile.runtimeType.toString().contains('XFile')) {
        // Para web: extrair bytes do XFile
        final bytes = await imageFile.readAsBytes();
        imagesForPdf.add({
          'bytes': bytes,
          'timestamp': DateTime.now().add(Duration(seconds: i)),
        });
      } else {
        // Para mobile: usar File diretamente
        imagesForPdf.add({
          'file': imageFile,
          'timestamp': DateTime.now().add(Duration(seconds: i)),
        });
      }
    }
    
    // Gerar PDF usando a função existente
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
      images: imagesForPdf, // Usar imagens locais
    );
    
    return pdfPath;
  }
}

// Extensão para firstOrNull se não existir
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
