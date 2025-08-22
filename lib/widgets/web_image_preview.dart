import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

/// Widget otimizado para exibir imagens na web
class WebImagePreview extends StatefulWidget {
  final dynamic imageFile; // XFile ou File
  final double width;
  final double height;
  final BoxFit fit;

  const WebImagePreview({
    super.key,
    required this.imageFile,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  });

  @override
  State<WebImagePreview> createState() => _WebImagePreviewState();
}

class _WebImagePreviewState extends State<WebImagePreview> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageForWeb();
  }

  Future<void> _loadImageForWeb() async {
    if (!kIsWeb) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Verificar se é um XFile
      if (widget.imageFile != null &&
          widget.imageFile.runtimeType.toString().contains('XFile')) {
        final bytes = await widget.imageFile.readAsBytes() as Uint8List;
        final base64String = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg');
        
        setState(() {
          _imageUrl = base64String.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar imagem para web: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 4),
            Text('Carregando...', style: TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    if (_hasError || _imageUrl == null) {
      return Container(
        color: Colors.orange[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              Text('Erro', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Image.network(
      _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red[100],
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
  }
}
