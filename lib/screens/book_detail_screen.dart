import 'package:flutter/material.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../models/book.dart';
import '../models/section.dart';
import '../widgets/section_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../services/export_service.dart';
import 'section_detail_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();
  late Book _book;
  List<Section> _sections = [];
  Map<int, int> _chapterCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sections = await _sectionDao.getByBookId(_book.id!);
    final counts = <int, int>{};
    for (final section in sections) {
      final chapters = await _chapterDao.getBySectionId(section.id!);
      counts[section.id!] = chapters.length;
    }
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _chapterCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _createSection() async {
    final now = DateTime.now().toIso8601String();
    final section = Section(
      bookId: _book.id!,
      title: '第${_sections.length + 1}卷',
      createdAt: now,
      updatedAt: now,
      sortOrder: _sections.length,
    );
    await _sectionDao.insert(section);
    _loadData();
  }

  void _openSection(Section section) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SectionDetailScreen(section: section)),
    );
    _loadData();
  }

  Future<void> _deleteSection(Section section) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除卷',
      message: '将同时删除《${section.title}》的所有章节，此操作不可撤销。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await _sectionDao.delete(section.id!);
      _loadData();
    }
  }

  Future<void> _renameSection(Section section) async {
    final controller = TextEditingController(text: section.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名卷'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('确认')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      final updated = section.copyWith(
          title: newTitle, updatedAt: DateTime.now().toIso8601String());
      await _sectionDao.update(updated);
      _loadData();
    }
  }

  Future<void> _exportBook() async {
    await ExportService().exportBook(_book, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') _exportBook();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'export', child: Text('导出全书')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? const EmptyStateWidget(
                  message: '还没有卷',
                  actionHint: '点击右下角添加卷',
                )
              : ListView.builder(
                  itemCount: _sections.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemBuilder: (_, i) {
                    final section = _sections[i];
                    return SectionTile(
                      key: ValueKey(section.id),
                      section: section,
                      chapterCount: _chapterCounts[section.id] ?? 0,
                      onTap: () => _openSection(section),
                      onDelete: () => _deleteSection(section),
                      onRename: () => _renameSection(section),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSection,
        icon: const Icon(Icons.add),
        label: const Text('添加卷'),
      ),
    );
  }
}
