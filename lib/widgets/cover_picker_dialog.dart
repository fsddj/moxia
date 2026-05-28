import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class CoverPickerDialog extends StatefulWidget {
  final Book book;

  const CoverPickerDialog({super.key, required this.book});

  @override
  State<CoverPickerDialog> createState() => _CoverPickerDialogState();
}

class _CoverPickerDialogState extends State<CoverPickerDialog> {
  final ImagePicker _picker = ImagePicker();
  static const List<int> _presetColors = [
    0xFFEADDFF, 0xFFD0E6FF, 0xFFFFD8D8, 0xFFD8FFD8,
    0xFFFFF0D0, 0xFFFFD8FF, 0xFFD0FFFF, 0xFFFFE0D0,
    0xFFE0E0FF, 0xFFD0FFD0, 0xFFFFD0D0, 0xFFD0D0FF,
    0xFFC8E6C9, 0xFFBBDEFB, 0xFFFFE082, 0xFFF8BBD0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('更换封面'),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetColors.map((c) => GestureDetector(
                  onTap: () => Navigator.pop(context, {'color': c}),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(c),
                      borderRadius: BorderRadius.circular(8),
                      border: widget.book.coverColor == c &&
                              widget.book.coverImage == null
                          ? Border.all(color: theme.colorScheme.primary, width: 2.5)
                          : null,
                    ),
                  ),
                )),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Icon(Icons.add_photo_alternate_outlined,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.book.coverImage != null)
          TextButton(
            onPressed: () => Navigator.pop(context, {'removeImage': true}),
            child: const Text('移除图片'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${appDir.path}/covers');
    if (!await coversDir.exists()) await coversDir.create(recursive: true);

    final destPath = '${coversDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(xfile.path).copy(destPath);

    if (mounted) {
      Navigator.pop(context, {'image': destPath});
    }
  }
}
