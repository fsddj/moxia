import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../models/book.dart';

class JsonExportService {
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();

  Future<String> exportToJson(Book book) async {
    final sections = await _sectionDao.getByBookId(book.id!);
    final sectionsData = <Map<String, dynamic>>[];
    for (final section in sections) {
      final chapters = await _chapterDao.getBySectionId(section.id!);
      sectionsData.add({
        'title': section.title,
        'description': section.description,
        'wordCount': section.wordCount,
        'createdAt': section.createdAt,
        'updatedAt': section.updatedAt,
        'sortOrder': section.sortOrder,
        'chapters': chapters.map((c) => {
          'title': c.title,
          'content': c.content,
          'wordCount': c.wordCount,
          'status': c.status,
          'createdAt': c.createdAt,
          'updatedAt': c.updatedAt,
          'sortOrder': c.sortOrder,
        }).toList(),
      });
    }

    return const JsonEncoder.withIndent('  ').convert({
      'moXiaExport': {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'app': '墨匣',
      },
      'book': {
        'title': book.title,
        'author': book.author,
        'description': book.description,
        'coverColor': book.coverColor,
        'coverImage': book.coverImage,
        'wordCount': book.wordCount,
        'createdAt': book.createdAt,
        'updatedAt': book.updatedAt,
        'sections': sectionsData,
      },
    });
  }

  Future<void> exportBookToFile(Book book, BuildContext context) async {
    final json = await exportToJson(book);
    final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/exports');
    if (!await dir.exists()) await dir.create(recursive: true);

    final safeName = book.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${dir.path}/${safeName}_export.json');
    await file.writeAsString(json, encoding: utf8);

    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)],
          text: '${book.title} - 墨匣导出');
    }
    try {
      await file.delete();
    } catch (_) {}
  }
}
