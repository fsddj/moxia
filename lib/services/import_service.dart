import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/dao/chapter_dao.dart';
import '../models/chapter.dart';
import '../utils/word_counter.dart';

class ImportService {
  final ChapterDao _chapterDao = ChapterDao();

  Future<int> importTxtFiles(int sectionId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return 0;

    final chapters = await _chapterDao.getBySectionId(sectionId);
    int nextOrder = chapters.isEmpty ? 0 : chapters.last.sortOrder + 1;
    int count = 0;

    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;

      String content;
      try {
        content = await File(path).readAsString(encoding: utf8);
      } on FormatException {
        // Fallback: read bytes and decode as Latin-1 (never fails)
        final bytes = await File(path).readAsBytes();
        content = String.fromCharCodes(bytes);
      }

      if (content.isEmpty) continue;

      final fileName = file.name.replaceAll('.txt', '');
      final now = DateTime.now().toIso8601String();
      final chapter = Chapter(
        sectionId: sectionId,
        title: fileName.isNotEmpty ? fileName : '导入章节',
        content: content,
        wordCount: WordCounter.count(content),
        createdAt: now,
        updatedAt: now,
        sortOrder: nextOrder++,
      );
      await _chapterDao.insert(chapter);
      count++;
    }

    return count;
  }
}
