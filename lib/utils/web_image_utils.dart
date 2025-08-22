import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;

/// Utilitário simplificado para seleção de imagens com suporte otimizado para web
class WebImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona múltiplas imagens com melhor suporte para web
  static Future<List<Map<String, dynamic>>> pickMultipleImages() async {
    try {
      print('Iniciando seleção de imagens para web: $kIsWeb');
      
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: 10, // Limitar a 10 imagens
      );
      
      print('Imagens selecionadas: ${pickedFiles.length}');
      
      if (pickedFiles.isEmpty) return [];

      final List<Map<String, dynamic>> images = [];
      
      for (int i = 0; i < pickedFiles.length; i++) {
        final pickedFile = pickedFiles[i];
        print('Processando imagem $i: ${pickedFile.name}');
        
        try {
          if (kIsWeb) {
            // Para web, ler os bytes da XFile e salvar
            final bytes = await pickedFile.readAsBytes();
            images.add({
              'file': pickedFile,
              'bytes': bytes, // Adicionar bytes para o PDF
              'name': pickedFile.name,
              'path': pickedFile.name,
              'timestamp': DateTime.now(),
              'isWeb': true,
            });
          } else {
            // Para outras plataformas, converter para File
            final file = File(pickedFile.path);
            if (await file.exists()) {
              images.add({
                'file': file,
                'name': pickedFile.name,
                'path': file.path,
                'timestamp': DateTime.now(),
                'isWeb': false,
              });
            }
          }
        } catch (e) {
          print('Erro ao processar imagem $i: $e');
          // Adicionar mesmo com erro para debug
          images.add({
            'file': kIsWeb ? pickedFile : File(pickedFile.path),
            'name': pickedFile.name,
            'path': kIsWeb ? pickedFile.name : pickedFile.path,
            'timestamp': DateTime.now(),
            'error': e.toString(),
            'isWeb': kIsWeb,
          });
        }
      }
      
      print('Total de imagens processadas: ${images.length}');
      return images;
    } catch (e) {
      print('Erro geral na seleção de imagens: $e');
      rethrow;
    }
  }

  /// Seleciona uma única imagem
  static Future<Map<String, dynamic>?> pickSingleImage() async {
    try {
      print('Iniciando seleção de imagem única para web: $kIsWeb');
      
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile == null) {
        print('Nenhuma imagem foi selecionada');
        return null;
      }
      
      print('Imagem selecionada: ${pickedFile.name}');
      
      if (kIsWeb) {
        return {
          'file': pickedFile,
          'name': pickedFile.name,
          'path': pickedFile.name,
          'timestamp': DateTime.now(),
          'isWeb': true,
        };
      } else {
        final file = File(pickedFile.path);
        return {
          'file': file,
          'name': pickedFile.name,
          'path': file.path,
          'timestamp': DateTime.now(),
          'isWeb': false,
        };
      }
    } catch (e) {
      print('Erro na seleção de imagem única: $e');
      rethrow;
    }
  }
}
