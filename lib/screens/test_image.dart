import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tcis_app/utils/utils.dart';
import 'package:tcis_app/components/imageSelectorGrid.dart';

class TestImageScreen extends StatefulWidget {
  const TestImageScreen({super.key});

  @override
  State<TestImageScreen> createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  final List<Map<String, dynamic>> _images = [];

  Future<void> _addImage() async {
    try {
      final newImages = await ImageUtils.pickImagesWithMetadata();
      if (newImages.isNotEmpty) {
        setState(() => _images.addAll(newImages));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newImages.length} imagens adicionadas com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar imagens: $e')),
      );
      print('Erro detalhado: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Imagens'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Teste de Inserção de Imagens',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ImageGrid(
              images: _images,
              onAddImage: _addImage,
              onRemoveImage: _removeImage,
            ),
            const SizedBox(height: 20),
            Text('Total de imagens: ${_images.length}'),
            const SizedBox(height: 20),
            if (_images.isNotEmpty) ...[
              const Text(
                'Preview das Imagens:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb 
                          ? Container(
                              color: Colors.blue[50],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, color: Colors.blue, size: 30),
                                    Text('Imagem', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                  ],
                                ),
                              ),
                            )
                          : Image.file(
                              image['file'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      Text('Erro', style: TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_images.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return ListTile(
                      title: Text('Imagem ${index + 1}'),
                      subtitle: Text(
                        'Path: ${image['file']?.path}\n'
                        'Timestamp: ${image['timestamp']}',
                      ),
                      leading: const Icon(Icons.image),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
