import '../database_helper.dart';
import '../../models/book.dart';

class BookDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Book>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('books', orderBy: 'sort_order ASC');
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<List<Book>> getActive() async {
    final db = await _db.database;
    final maps = await db.query('books',
        where: 'status = ?', whereArgs: ['active'], orderBy: 'sort_order ASC');
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<Book?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Book.fromMap(maps.first);
  }

  Future<int> insert(Book book) async {
    final db = await _db.database;
    return await db.insert('books', book.toMap());
  }

  Future<int> update(Book book) async {
    final db = await _db.database;
    return await db.update('books', book.toMap(),
        where: 'id = ?', whereArgs: [book.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<int> ids) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < ids.length; i++) {
        await txn.update('books', {'sort_order': i},
            where: 'id = ?', whereArgs: [ids[i]]);
      }
    });
  }
}
