import 'dart:io';
import 'package:flutter/material.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../database/dao/book_dao.dart';
import '../models/book.dart';
import '../models/section.dart';
import '../models/chapter.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/cover_picker_dialog.dart';
import '../utils/theme_inherited.dart';

class NavDrawer extends StatefulWidget {
  final Book book;
  final int? currentChapterId;
  final void Function(Chapter chapter) onChapterSelected;
  final void Function() onBookChanged;

  const NavDrawer({
    super.key,
    required this.book,
    required this.currentChapterId,
    required this.onChapterSelected,
    required this.onBookChanged,
  });

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();
  final BookDao _bookDao = BookDao();
  late Book _book;
  List<Section> _sections = [];
  Map<int, List<Chapter>> _chapterMap = {};

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadData();
  }

  @override
  void didUpdateWidget(NavDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _book = widget.book;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final sections = await _sectionDao.getByBookId(_book.id!);
    final chapterMap = <int, List<Chapter>>{};
    for (final s in sections) {
      chapterMap[s.id!] = await _chapterDao.getBySectionId(s.id!);
    }
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _chapterMap = chapterMap;
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

  Future<void> _createChapter(int sectionId) async {
    final chapters = _chapterMap[sectionId] ?? [];
    final now = DateTime.now().toIso8601String();
    final chapter = Chapter(
      sectionId: sectionId,
      title: '第${chapters.length + 1}章',
      createdAt: now,
      updatedAt: now,
      sortOrder: chapters.length,
    );
    final id = await _chapterDao.insert(chapter);
    _loadData();
    widget.onChapterSelected(chapter.copyWith(id: id));
    Navigator.pop(context);
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('确认')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await _sectionDao.update(section.copyWith(
        title: newTitle,
        updatedAt: DateTime.now().toIso8601String(),
      ));
      _loadData();
    }
  }

  Future<void> _deleteSection(Section section) async {
    final confirmed = await ConfirmDialog.show(context,
        title: '删除卷',
        message: '将同时删除「${section.title}」的所有章节，此操作不可撤销。',
        confirmText: '删除',
        destructive: true);
    if (confirmed) {
      await _sectionDao.delete(section.id!);
      _loadData();
      widget.onBookChanged();
    }
  }

  Future<void> _renameChapter(Chapter chapter) async {
    final controller = TextEditingController(text: chapter.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名章节'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('确认')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await _chapterDao.update(chapter.copyWith(
        title: newTitle,
        updatedAt: DateTime.now().toIso8601String(),
      ));
      _loadData();
    }
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await ConfirmDialog.show(context,
        title: '删除章节',
        message: '确定删除「${chapter.title}」吗？此操作不可撤销。',
        confirmText: '删除',
        destructive: true);
    if (confirmed) {
      await _chapterDao.delete(chapter.id!);
      _loadData();
      widget.onBookChanged();
    }
  }

  void _cycleStatus(Chapter chapter) {
    const next = {'draft': 'revised', 'revised': 'final', 'final': 'draft'};
    final updated = chapter.copyWith(
      status: next[chapter.status]!,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _chapterDao.update(updated);
    _loadData();
  }

  Future<void> _openCoverPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CoverPickerDialog(book: _book),
    );
    if (result == null) return;

    final updated = _book.copyWith(updatedAt: DateTime.now().toIso8601String());

    if (result.containsKey('color')) {
      final updatedBook = updated.copyWith(coverColor: result['color'] as int, coverImage: null);
      await _bookDao.update(updatedBook);
      setState(() => _book = updatedBook);
    } else if (result.containsKey('image')) {
      final updatedBook = updated.copyWith(coverImage: result['image'] as String);
      await _bookDao.update(updatedBook);
      setState(() => _book = updatedBook);
    } else if (result.containsKey('removeImage')) {
      final updatedBook = updated.copyWith(coverImage: null);
      await _bookDao.update(updatedBook);
      setState(() => _book = updatedBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(_book.coverColor);
    final totalChapters = _chapterMap.values.fold(0, (sum, list) => sum + list.length);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _openCoverPicker,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _book.coverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_book.coverImage!),
                                width: 56, height: 56, fit: BoxFit.cover),
                          )
                        : Icon(Icons.menu_book_rounded, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_book.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$_sections.length卷 · $totalChapters章 · ${_book.wordCount}字',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _sections.isEmpty
                ? Center(
                    child: Text('暂无卷章', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                  )
                : ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (_, i) {
                      final section = _sections[i];
                      final chapters = _chapterMap[section.id] ?? [];
                      return _SectionExpansionTile(
                        section: section,
                        chapters: chapters,
                        currentChapterId: widget.currentChapterId,
                        onChapterSelected: widget.onChapterSelected,
                        onCreateChapter: () => _createChapter(section.id!),
                        onRenameSection: () => _renameSection(section),
                        onDeleteSection: () => _deleteSection(section),
                        onRenameChapter: _renameChapter,
                        onDeleteChapter: _deleteChapter,
                        onCycleStatus: _cycleStatus,
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加卷'),
            onTap: _createSection,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('夜间模式'),
            trailing: Switch(
              value: ThemeInherited.isDark(context),
              onChanged: (_) => ThemeInherited.toggleTheme(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionExpansionTile extends StatelessWidget {
  final Section section;
  final List<Chapter> chapters;
  final int? currentChapterId;
  final void Function(Chapter) onChapterSelected;
  final VoidCallback onCreateChapter;
  final VoidCallback onRenameSection;
  final VoidCallback onDeleteSection;
  final void Function(Chapter) onRenameChapter;
  final void Function(Chapter) onDeleteChapter;
  final void Function(Chapter) onCycleStatus;

  const _SectionExpansionTile({
    required this.section,
    required this.chapters,
    required this.currentChapterId,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onRenameSection,
    required this.onDeleteSection,
    required this.onRenameChapter,
    required this.onDeleteChapter,
    required this.onCycleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: Text(section.title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') onRenameSection();
              if (v == 'delete') onDeleteSection();
              if (v == 'addChapter') onCreateChapter();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'addChapter', child: Text('添加章节')),
              const PopupMenuItem(value: 'rename', child: Text('重命名')),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
      subtitle: Text('${chapters.length}章 · ${section.wordCount}字',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      children: [
        ...chapters.map((chapter) {
          IconData statusIcon() {
            switch (chapter.status) {
              case 'revised': return Icons.radio_button_unchecked;
              case 'final': return Icons.check_circle;
              default: return Icons.circle_outlined;
            }
          }

          Color statusColor() {
            switch (chapter.status) {
              case 'revised': return Colors.orange;
              case 'final': return Colors.green;
              default: return Colors.grey;
            }
          }

          return ListTile(
            selected: chapter.id == currentChapterId,
            selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(60),
            leading: GestureDetector(
              onTap: () => onCycleStatus(chapter),
              child: Icon(statusIcon(), color: statusColor(), size: 20),
            ),
            title: Text(chapter.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
            subtitle: Text('${chapter.wordCount}字',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rename') onRenameChapter(chapter);
                if (v == 'delete') onDeleteChapter(chapter);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'rename', child: Text('重命名')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
            onTap: () => onChapterSelected(chapter),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: TextButton.icon(
            onPressed: onCreateChapter,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加章节'),
          ),
        ),
      ],
    );
  }
}
