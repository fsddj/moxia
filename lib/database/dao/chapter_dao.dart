import '../database_helper.dart';
import '../../models/chapter.dart';

class ChapterDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Chapter>> getBySectionId(int sectionId) async {
    final db = await _db.database;
    final maps = await db.query('chapters',
        where: 'section_id = ?',
        whereArgs: [sectionId],
        orderBy: 'sort_order ASC');
    return maps.map((m) => Chapter.fromMap(m)).toList();
  }

  Future<Chapter?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('chapters', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Chapter.fromMap(maps.first);
  }

  Future<int> insert(Chapter chapter) async {
    final db = await _db.database;
    final id = await db.insert('chapters', chapter.toMap());
    await _recalculateWordCounts(chapter.sectionId);
    return id;
  }

  Future<int> update(Chapter chapter) async {
    final db = await _db.database;
    final affected = await db.update('chapters', chapter.toMap(),
        where: 'id = ?', whereArgs: [chapter.id]);
    await _recalculateWordCounts(chapter.sectionId);
    return affected;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    final chapter = await getById(id);
    final affected =
        await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
    if (chapter != null) {
      await _recalculateWordCounts(chapter.sectionId);
    }
    return affected;
  }

  Future<void> reorder(List<int> ids) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < ids.length; i++) {
        await txn.update('chapters', {'sort_order': i},
            where: 'id = ?', whereArgs: [ids[i]]);
      }
    });
  }

  Future<void> _recalculateWordCounts(int sectionId) async {
    final db = await _db.database;

    // Update section word count
    final sectionResult = await db.rawQuery(
        'SELECT COALESCE(SUM(word_count), 0) as total FROM chapters WHERE section_id = ?',
        [sectionId]);
    final sectionTotal = sectionResult.first['total'] as int;
    await db.update('sections', {'word_count': sectionTotal},
        where: 'id = ?', whereArgs: [sectionId]);

    // Update book word count by summing all its sections
    final section = await db
        .query('sections', where: 'id = ?', whereArgs: [sectionId]);
    if (section.isNotEmpty) {
      final bookId = section.first['book_id'] as int;
      final bookResult = await db.rawQuery(
          'SELECT COALESCE(SUM(word_count), 0) as total FROM sections WHERE book_id = ?',
          [bookId]);
      final bookTotal = bookResult.first['total'] as int;
      await db.update('books', {'word_count': bookTotal},
          where: 'id = ?', whereArgs: [bookId]);
    }
  }
}
