import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';

class ImageGridPicker extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAddTap;
  final void Function(int index) onRemoveTap;
  final int maxImages;

  const ImageGridPicker({
    super.key,
    required this.images,
    required this.onAddTap,
    required this.onRemoveTap,
    this.maxImages = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...images.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildImageTile(file, index);
        }),
        if (images.length < maxImages) _buildAddButton(),
      ],
    );
  }

  Widget _buildImageTile(XFile file, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb
              ? Image.network(
                  file.path,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(file.path),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemoveTap(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppTheme.textSecondary,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Tambah Foto',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
