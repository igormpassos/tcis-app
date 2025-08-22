import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:tcis_app/widgets/web_image_preview.dart';

class ImageDisplayWidget extends StatelessWidget {
  final dynamic imageFile;
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageDisplayWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Se tem URL, usar Image.network
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  Text('Erro ao\ncarregar', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    }

    if (imageFile == null) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Para web, usar widget otimizado
    if (kIsWeb) {
      return WebImagePreview(
        imageFile: imageFile,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Para plataformas móveis/desktop - usar imageFile como File
    try {
      // Garantir que seja um File válido
      if (imageFile is! File) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: Colors.grey, size: 20),
                Text('Arquivo\ninválido', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      }

      return Image.file(
        imageFile,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  Text('Erro', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.orange),
        ),
      );
    }
  }
}
