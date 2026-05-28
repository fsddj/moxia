import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/dao/chapter_dao.dart';
import '../models/chapter.dart';
import '../widgets/editor_stats_bar.dart';
import '../utils/word_counter.dart';
import '../utils/date_formatter.dart';
import '../services/export_service.dart';

class EditorScreen extends StatefulWidget {
  final Chapter chapter;

  const EditorScreen({super.key, required this.chapter});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ChapterDao _chapterDao = ChapterDao();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocus;

  late Chapter _currentChapter;
  int _wordCount = 0;
  bool _isSaving = false;
  String? _lastSavedAt;
  bool _isDirty = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _titleController = TextEditingController(text: _currentChapter.title);
    _contentController = TextEditingController(text: _currentChapter.content);
    _contentFocus = FocusNode();
    _wordCount = _currentChapter.wordCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_isDirty) _saveNow();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    _wordCount = WordCounter.count(text);
    _isDirty = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveNow);
    setState(() {});
  }

  void _onTitleChanged(String text) {
    _isDirty = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveNow);
  }

  Future<void> _saveNow() async {
    if (!_isDirty) return;
    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final updated = _currentChapter.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      wordCount: _wordCount,
      updatedAt: now,
    );

    await _chapterDao.update(updated);

    if (!mounted) return;
    setState(() {
      _currentChapter = updated;
      _isSaving = false;
      _isDirty = false;
      _lastSavedAt = DateFormatter.format(now);
    });
  }

  Future<bool> _onWillPop() async {
    if (_isDirty) await _saveNow();
    return true;
  }

  void _showEditorMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('导出本章'),
              onTap: () {
                Navigator.pop(ctx);
                ExportService().exportChapter(_currentChapter, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('统计信息'),
              onTap: () {
                Navigator.pop(ctx);
                _showStats();
              },
            ),
            ListTile(
              leading: const Icon(Icons.loop),
              title: Text(
                  '切换状态 (当前: ${_statusLabel(_currentChapter.status)})'),
              onTap: () {
                Navigator.pop(ctx);
                _cycleStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return {'draft': '草稿', 'revised': '修改中', 'final': '定稿'}[status] ?? status;
  }

  void _cycleStatus() {
    const next = {'draft': 'revised', 'revised': 'final', 'final': 'draft'};
    final updated = _currentChapter.copyWith(
        status: next[_currentChapter.status]!,
        updatedAt: DateTime.now().toIso8601String());
    setState(() => _currentChapter = updated);
    _isDirty = true;
    _saveNow();
  }

  void _showStats() {
    final stats = WordCounter.detailedStats(_contentController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('统计信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('字数', '${stats['charCount']}'),
            _statRow('含空格', '${stats['charWithSpace']}'),
            _statRow('段落数', '${stats['paragraphCount']}'),
            _statRow('行数', '${stats['lineCount']}'),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isDirty) await _saveNow();
        if (context.mounted) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.check),
            tooltip: '完成',
            onPressed: () async {
              if (_isDirty) await _saveNow();
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '章节标题',
            ),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
            onChanged: _onTitleChanged,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showEditorMenu,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 18, height: 1.8),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '开始写作...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            onChanged: _onContentChanged,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
        ),
        bottomNavigationBar: EditorStatsBar(
          wordCount: _wordCount,
          lastSavedAt: _lastSavedAt,
          isSaving: _isSaving,
        ),
      ),
    );
  }
}
