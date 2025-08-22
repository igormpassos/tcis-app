import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:tcis_app/services/api_service.dart';

// Import condicional para File
import 'dart:io' if (dart.library.html) 'package:tcis_app/utils/web_stub.dart' as io;
import 'dart:html' as html;

class ImageUploadService {
  static final Dio _dio = Dio();

  /// Upload de múltiplas imagens para o servidor (suporta File e XFile)
  static Future<List<String>> uploadImages({
    required List<dynamic> images, // Aceita dynamic em vez de File
    required String folderName,
  }) async {
    try {
      final List<String> uploadedPaths = [];
      final baseUrl = ApiService.baseUrl;

      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        
        if (kIsWeb && imageFile.runtimeType.toString().contains('XFile')) {
          // Para web: usar XMLHttpRequest nativo
          final bytes = await imageFile.readAsBytes() as Uint8List;
          final fileName = imageFile.name.isNotEmpty 
              ? imageFile.name 
              : 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          
          // Upload usando método web específico
          final result = await _uploadImageWeb(bytes, fileName, folderName, baseUrl);
          uploadedPaths.add(result);
          
        } else {
          // Para mobile: usar Dio com MultipartFile
          final processedImage = imageFile as io.File;
          final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          
          final multipartFile = await MultipartFile.fromFile(
            processedImage.path,
            filename: fileName,
          );
          
          final formData = FormData.fromMap({
            'image': multipartFile,
            'folder': folderName,
          });

          // Upload usando Dio
          final apiService = ApiService();
          await apiService.loadToken();
          
          final response = await _dio.post(
            '$baseUrl/api/uploads/image',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
                'Authorization': 'Bearer ${apiService.currentToken}',
              },
            ),
          );

          if (response.statusCode == 200) {
            final data = response.data;
            if (data['success'] == true) {
              uploadedPaths.add(data['data']['path']);
            } else {
              throw Exception('Erro no upload: ${data['message']}');
            }
          } else {
            throw Exception('Erro HTTP: ${response.statusCode}');
          }
        }
      }

      return uploadedPaths;
    } catch (e) {
      throw Exception('Erro no upload das imagens: $e');
    }
  }
  
  /// Upload específico para web usando XMLHttpRequest
  static Future<String> _uploadImageWeb(Uint8List bytes, String fileName, String folderName, String baseUrl) async {
    try {
      final apiService = ApiService();
      await apiService.loadToken();
      
      // Determinar o tipo MIME baseado na extensão do arquivo
      String mimeType = 'image/jpeg'; // padrão
      if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.toLowerCase().endsWith('.heic') || fileName.toLowerCase().endsWith('.heif')) {
        // Converter HEIC para JPEG no nome do arquivo para compatibilidade
        fileName = fileName.replaceAll(RegExp(r'\.(heic|heif)$', caseSensitive: false), '.jpg');
        mimeType = 'image/jpeg';
      }
      
      // Criar FormData para web
      final formData = html.FormData();
      final blob = html.Blob([bytes], mimeType);
      formData.appendBlob('image', blob, fileName);
      formData.append('folder', folderName);
      
      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/api/uploads/image');
      request.setRequestHeader('Authorization', 'Bearer ${apiService.currentToken}');
      
      final completer = Completer<String>();
      
      request.onLoad.listen((_) {
        if (request.status == 200) {
          final response = jsonDecode(request.responseText!);
          if (response['success'] == true) {
            completer.complete(response['data']['path']);
          } else {
            completer.completeError(Exception('Erro no upload: ${response['message']}'));
          }
        } else {
          completer.completeError(Exception('Erro HTTP: ${request.status}'));
        }
      });
      
      request.onError.listen((_) {
        completer.completeError(Exception('Erro de rede durante upload'));
      });
      
      request.send(formData);
      return await completer.future;
      
    } catch (e) {
      throw Exception('Erro no upload web: $e');
    }
  }

  /// Upload de PDF para o servidor
  static Future<String> uploadPdf({
    required dynamic pdfFile, // Aceita dynamic para compatibilidade
    required String folderName,
  }) async {
    try {
      final baseUrl = ApiService.baseUrl;
      
      if (kIsWeb) {
        // Para web, pdfFile deve ser Uint8List
        final bytes = pdfFile as Uint8List;
        final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        final result = await _uploadPdfWeb(bytes, fileName, folderName, baseUrl);
        return result;
      } else {
        // Para mobile
        final multipartFile = await MultipartFile.fromFile(
          (pdfFile as io.File).path,
          filename: 'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        
        final formData = FormData.fromMap({
          'pdf': multipartFile,
          'folder': folderName,
        });

        final apiService = ApiService();
        await apiService.loadToken();
        
        final response = await _dio.post(
          '$baseUrl/api/uploads/pdf',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
              'Authorization': 'Bearer ${apiService.currentToken}',
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['success'] == true) {
            return data['data']['path'];
          } else {
            throw Exception('Erro no upload do PDF: ${data['message']}');
          }
        } else {
          throw Exception('Erro HTTP: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Erro no upload do PDF: $e');
    }
  }

  /// Upload específico de PDF para web
  static Future<String> _uploadPdfWeb(Uint8List bytes, String fileName, String folderName, String baseUrl) async {
    try {
      final apiService = ApiService();
      await apiService.loadToken();
      
      final formData = html.FormData();
      final blob = html.Blob([bytes], 'application/pdf'); // Especificar tipo MIME do PDF
      formData.appendBlob('pdf', blob, fileName);
      formData.append('folder', folderName);
      
      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/api/uploads/pdf');
      request.setRequestHeader('Authorization', 'Bearer ${apiService.currentToken}');
      
      final completer = Completer<String>();
      
      request.onLoad.listen((_) {
        if (request.status == 200) {
          final response = jsonDecode(request.responseText!);
          if (response['success'] == true) {
            completer.complete(response['data']['path']);
          } else {
            completer.completeError(Exception('Erro no upload: ${response['message']}'));
          }
        } else {
          completer.completeError(Exception('Erro HTTP: ${request.status}'));
        }
      });
      
      request.onError.listen((_) {
        completer.completeError(Exception('Erro de rede durante upload do PDF'));
      });
      
      request.send(formData);
      return await completer.future;
      
    } catch (e) {
      throw Exception('Erro no upload web do PDF: $e');
    }
  }

  /// Gera nome da pasta baseado no prefixo
  static String generateFolderName(String prefix) {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    return '$prefix-$year-$month';
  }
}