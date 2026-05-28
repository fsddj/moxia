import 'package:flutter/material.dart';
import '../database/dao/chapter_dao.dart';
import '../database/dao/section_dao.dart' as section_mod;
import '../models/section.dart';
import '../models/chapter.dart';
import '../widgets/chapter_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';
import 'editor_screen.dart';

class SectionDetailScreen extends StatefulWidget {
  final Section section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  final ChapterDao _chapterDao = ChapterDao();
  final section_mod.SectionDao _sectionDao = section_mod.SectionDao();
  late Section _section;
  List<Chapter> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _section = widget.section;
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    final chapters = await _chapterDao.getBySectionId(_section.id!);
    if (!mounted) return;
    setState(() {
      _chapters = chapters;
      _isLoading = false;
    });
  }

  Future<void> _createChapter() async {
    final now = DateTime.now().toIso8601String();
    final chapter = Chapter(
      sectionId: _section.id!,
      title: '第${_chapters.length + 1}章',
      createdAt: now,
      updatedAt: now,
      sortOrder: _chapters.length,
    );
    final id = await _chapterDao.insert(chapter);
    if (!mounted) return;
    final created = chapter.copyWith(id: id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(chapter: created)),
    );
    _loadChapters();
  }

  void _openChapter(Chapter chapter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(chapter: chapter)),
    );
    _loadChapters();
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除章节',
      message: '确定删除《${chapter.title}》吗？此操作不可撤销。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await _chapterDao.delete(chapter.id!);
      _loadChapters();
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('确认')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      final updated = chapter.copyWith(
          title: newTitle, updatedAt: DateTime.now().toIso8601String());
      await _chapterDao.update(updated);
      _loadChapters();
    }
  }

  void _cycleStatus(Chapter chapter) {
    const next = {'draft': 'revised', 'revised': 'final', 'final': 'draft'};
    final updated = chapter.copyWith(
        status: next[chapter.status]!, updatedAt: DateTime.now().toIso8601String());
    _chapterDao.update(updated);
    _loadChapters();
  }

  Future<void> _importTxt() async {
    final count = await ImportService().importTxtFiles(_section.id!);
    if (!mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $count 个章节')),
      );
      _loadChapters();
    }
  }

  Future<void> _exportChapter(Chapter chapter) async {
    await ExportService().exportChapter(chapter, context);
  }

  Future<void> _exportSection() async {
    await ExportService().exportSection(_section, _chapters, context);
  }

  Future<void> _renameSection() async {
    final controller = TextEditingController(text: _section.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑卷名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入卷名'),
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
      final updated = _section.copyWith(
          title: newTitle, updatedAt: DateTime.now().toIso8601String());
      await _sectionDao.update(updated);
      setState(() => _section = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_section.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入TXT',
            onPressed: _importTxt,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') _exportSection();
              if (value == 'rename') _renameSection();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'export', child: Text('导出本卷')),
              const PopupMenuItem(value: 'rename', child: Text('编辑卷名')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
              ? const EmptyStateWidget(
                  message: '还没有章节',
                  actionHint: '点击右下角新建，或点击右上角导入TXT',
                )
              : ListView.builder(
                  itemCount: _chapters.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemBuilder: (_, i) {
                    final chapter = _chapters[i];
                    return ChapterTile(
                      key: ValueKey(chapter.id),
                      chapter: chapter,
                      onTap: () => _openChapter(chapter),
                      onDelete: () => _deleteChapter(chapter),
                      onRename: () => _renameChapter(chapter),
                      onStatusCycle: () => _cycleStatus(chapter),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createChapter,
        icon: const Icon(Icons.edit),
        label: const Text('新建章节'),
      ),
    );
  }
}
