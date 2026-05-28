import 'package:flutter/material.dart';
import '../database/dao/book_dao.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirm_dialog.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookDao _bookDao = BookDao();
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await _bookDao.getActive();
    if (!mounted) return;
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  Future<void> _createBook() async {
    final now = DateTime.now().toIso8601String();
    final book = Book(
      createdAt: now,
      updatedAt: now,
      sortOrder: _books.length,
    );
    final id = await _bookDao.insert(book);
    if (!mounted) return;
    final created = book.copyWith(id: id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: created)),
    );
    _loadBooks();
  }

  void _openBook(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    _loadBooks();
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除作品',
      message: '将同时删除《${book.title}》的所有卷和章节，此操作不可撤销。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await _bookDao.delete(book.id!);
      _loadBooks();
    }
  }

  Future<void> _archiveBook(Book book) async {
    final updated = book.copyWith(
        status: 'archived', updatedAt: DateTime.now().toIso8601String());
    await _bookDao.update(updated);
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('墨匣'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.menu_book_rounded,
                  message: '还没有作品',
                  actionHint: '点击右下角开始创作',
                )
              : ListView.builder(
                  itemCount: _books.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemBuilder: (_, i) {
                    final book = _books[i];
                    return BookCard(
                      key: ValueKey(book.id),
                      book: book,
                      onTap: () => _openBook(book),
                      onDelete: () => _deleteBook(book),
                      onArchive: () => _archiveBook(book),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('新建作品'),
      ),
    );
  }
}
