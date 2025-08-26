import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'api_service.dart';

class ImageUploadService {
  static final Dio _dio = Dio();

  /// Redimensiona e comprime uma imagem
  static Future<File> processImage(File imageFile, {int maxWidth = 800}) async {
    try {
      // Ler bytes da imagem
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Não foi possível processar a imagem');
      }

      // Redimensionar mantendo a proporção
      final resized = img.copyResize(originalImage, width: maxWidth);
      
      // Comprimir como JPEG com qualidade 85%
      final compressedBytes = img.encodeJpg(resized, quality: 85);

      // Criar arquivo temporário
      final tempDir = Directory.systemTemp;
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final tempFile = File('${tempDir.path}/${fileName}_processed.jpg');
      
      await tempFile.writeAsBytes(compressedBytes);
      return tempFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload de múltiplas imagens para o servidor
  static Future<List<String>> uploadImages({
    required List<File> images,
    required String folderName,
  }) async {
    try {
      final List<String> uploadedPaths = [];
  final baseUrl = ApiService.baseUrl;

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        
        // Processar imagem (redimensionar e comprimir)
        final processedImage = await processImage(image);
        
        // Preparar dados para upload
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            processedImage.path,
            filename: fileName,
          ),
          'folder': folderName,
        });

        // Upload
        final apiService = ApiService();
        await apiService.loadToken(); // Carregar token salvo
        
        final response = await _dio.post(
          '$baseUrl/uploads/image',
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

        // Limpar arquivo temporário
        try {
          await processedImage.delete();
        } catch (e) {
          // Ignore deletion errors
        }
      }

      return uploadedPaths;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload de PDF
  static Future<String> uploadPdf({
    required File pdfFile,
    required String folderName,
    required String reportPrefix,
  }) async {
    try {
  final baseUrl = ApiService.apiBaseUrl;
      final fileName = '${reportPrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(
          pdfFile.path,
          filename: fileName,
        ),
        'folder': folderName,
      });

      final apiService = ApiService();
      await apiService.loadToken();

      final response = await _dio.post(
  '$baseUrl/uploads/pdf',
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
    } catch (e) {
      rethrow;
    }
  }

  /// Gera nome da pasta no padrão: prefixo-data-hora
  static String generateFolderName(String prefix) {
    final now = DateTime.now();
    final formattedDate = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
    
    return '$prefix-$formattedDate-$formattedTime';
  }
}
