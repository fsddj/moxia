import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../models/book.dart';
import '../models/section.dart';
import '../models/chapter.dart';

class ExportService {
  final BookDao _bookDao = BookDao();
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();

  Future<void> exportChapter(Chapter chapter, BuildContext context) async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    final safeName =
        chapter.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('$dir/$safeName.txt');

    final buffer = StringBuffer();
    buffer.writeln(chapter.title);
    buffer.writeln('');
    buffer.writeln(chapter.content);
    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)],
          text: '${chapter.title} - 墨匣');
    }
  }

  Future<void> exportSection(
      Section section, List<Chapter> chapters, BuildContext context) async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    final safeName =
        section.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('$dir/$safeName.txt');

    final buffer = StringBuffer();
    buffer.writeln('【${section.title}】');
    buffer.writeln('');

    for (final chapter in chapters) {
      buffer.writeln(chapter.title);
      buffer.writeln('');
      buffer.writeln(chapter.content);
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)],
          text: '${section.title} - 墨匣');
    }
  }

  Future<void> exportBook(Book book, BuildContext context) async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    final safeName =
        book.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('$dir/$safeName.txt');

    final buffer = StringBuffer();
    buffer.writeln(book.title);
    if (book.author.isNotEmpty) {
      buffer.writeln('作者：${book.author}');
    }
    buffer.writeln('');
    buffer.writeln('=' * 40);
    buffer.writeln('');

    final sections = await _sectionDao.getByBookId(book.id!);
    for (final section in sections) {
      buffer.writeln('');
      buffer.writeln('【${section.title}】');
      buffer.writeln('');

      final chapters = await _chapterDao.getBySectionId(section.id!);
      for (final chapter in chapters) {
        buffer.writeln(chapter.title);
        buffer.writeln('');
        buffer.writeln(chapter.content);
        buffer.writeln('');
        buffer.writeln('---');
        buffer.writeln('');
      }
    }

    await file.writeAsString(buffer.toString());

    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)],
          text: '${book.title} - 墨匣');
    }
  }
}
