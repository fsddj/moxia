import '../database_helper.dart';
import '../../models/section.dart';

class SectionDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Section>> getByBookId(int bookId) async {
    final db = await _db.database;
    final maps = await db.query('sections',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'sort_order ASC');
    return maps.map((m) => Section.fromMap(m)).toList();
  }

  Future<Section?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('sections', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Section.fromMap(maps.first);
  }

  Future<int> insert(Section section) async {
    final db = await _db.database;
    return await db.insert('sections', section.toMap());
  }

  Future<int> update(Section section) async {
    final db = await _db.database;
    return await db.update('sections', section.toMap(),
        where: 'id = ?', whereArgs: [section.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('sections', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<int> ids) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < ids.length; i++) {
        await txn.update('sections', {'sort_order': i},
            where: 'id = ?', whereArgs: [ids[i]]);
      }
    });
  }

  Future<void> updateWordCount(int sectionId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(word_count), 0) as total FROM chapters WHERE section_id = ?',
        [sectionId]);
    final total = result.first['total'] as int;
    await db.update('sections', {'word_count': total},
        where: 'id = ?', whereArgs: [sectionId]);
  }
}
