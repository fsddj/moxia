import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../models/book.dart';
import '../models/section.dart';
import '../models/chapter.dart';

class JsonImportResult {
  final String bookTitle;
  final int sectionCount;
  final int chapterCount;

  const JsonImportResult({
    required this.bookTitle,
    required this.sectionCount,
    required this.chapterCount,
  });
}

class JsonImportService {
  final BookDao _bookDao = BookDao();
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();

  Future<JsonImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return null;

    String content;
    try {
      content = await File(path).readAsString(encoding: utf8);
    } catch (_) {
      return null;
    }

    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['moXiaExport'] == null || json['book'] == null) return null;

    final bookData = json['book'] as Map<String, dynamic>;
    final now = DateTime.now().toIso8601String();

    // Create book
    final book = Book(
      title: bookData['title'] as String? ?? '导入作品',
      author: bookData['author'] as String? ?? '',
      description: bookData['description'] as String? ?? '',
      coverColor: bookData['coverColor'] as int? ?? 0xFFEADDFF,
      coverImage: bookData['coverImage'] as String?,
      createdAt: now,
      updatedAt: now,
      sortOrder: 0,
    );
    final bookId = await _bookDao.insert(book);

    // Create sections and chapters
    final sectionsData = bookData['sections'] as List<dynamic>? ?? [];
    int totalChapters = 0;

    for (int i = 0; i < sectionsData.length; i++) {
      final sData = sectionsData[i] as Map<String, dynamic>;
      final section = Section(
        bookId: bookId,
        title: sData['title'] as String? ?? '第${i + 1}卷',
        description: sData['description'] as String? ?? '',
        createdAt: sData['createdAt'] as String? ?? now,
        updatedAt: sData['updatedAt'] as String? ?? now,
        sortOrder: sData['sortOrder'] as int? ?? i,
      );
      final sectionId = await _sectionDao.insert(section);

      final chaptersData = sData['chapters'] as List<dynamic>? ?? [];
      for (int j = 0; j < chaptersData.length; j++) {
        final cData = chaptersData[j] as Map<String, dynamic>;
        final chapter = Chapter(
          sectionId: sectionId,
          title: cData['title'] as String? ?? '第${j + 1}章',
          content: cData['content'] as String? ?? '',
          wordCount: cData['wordCount'] as int? ?? 0,
          status: cData['status'] as String? ?? 'draft',
          createdAt: cData['createdAt'] as String? ?? now,
          updatedAt: cData['updatedAt'] as String? ?? now,
          sortOrder: cData['sortOrder'] as int? ?? j,
        );
        await _chapterDao.insert(chapter);
        totalChapters++;
      }
    }

    return JsonImportResult(
      bookTitle: book.title,
      sectionCount: sectionsData.length,
      chapterCount: totalChapters,
    );
  }
}
