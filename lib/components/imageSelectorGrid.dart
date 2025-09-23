import 'package:flutter/material.dart';
import 'package:tcis_app/components/image_display_widget.dart';

class ImageGrid extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;

  const ImageGrid({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        GestureDetector(
          onTap: onAddImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
          ),
        ),
        ...images.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          final file = image['file'];
          final url = image['url'];
          
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: ImageDisplayWidget(
                  imageFile: file,
                  imageUrl: url,
                  width: 100,
                  height: 100,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemoveImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
