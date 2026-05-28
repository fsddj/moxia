import 'dart:async';
import 'package:flutter/material.dart';
import '../database/dao/chapter_dao.dart';
import '../models/chapter.dart';
import '../utils/constants.dart';
import '../utils/word_counter.dart';
import '../utils/date_formatter.dart';
import '../utils/indent_controller.dart';
import '../utils/undo_redo_controller.dart';
import '../services/search_service.dart';
import '../services/export_service.dart';
import '../widgets/search_replace_bar.dart';
import '../widgets/confirm_dialog.dart';

class EditorScreen extends StatefulWidget {
  final Chapter chapter;
  final int? bookId;
  final void Function(Chapter updated) onChapterChanged;
  final void Function(bool saving) onSavingState;
  final void Function(int count) onWordCountChanged;
  final VoidCallback onOpenDrawer;
  final VoidCallback onExport;

  const EditorScreen({
    super.key,
    required this.chapter,
    this.bookId,
    required this.onChapterChanged,
    required this.onSavingState,
    required this.onWordCountChanged,
    required this.onOpenDrawer,
    required this.onExport,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ChapterDao _chapterDao = ChapterDao();
  final SearchService _searchService = SearchService();
  final UndoRedoController _undoRedo = UndoRedoController();
  final ExportService _exportService = ExportService();

  late IndentController _contentController;
  late TextEditingController _titleController;
  late FocusNode _contentFocus;

  late Chapter _currentChapter;
  int _wordCount = 0;
  bool _isDirty = false;
  Timer? _autoSaveTimer;

  // Search state
  bool _searchVisible = false;
  bool _showReplace = false;
  String _searchQuery = '';
  List<SearchMatch> _matches = [];
  int _currentMatchIndex = 0;
  SearchScope _searchScope = SearchScope.currentChapter;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    final displayContent = IndentController.addIndents(_currentChapter.content);
    _contentController = IndentController(text: displayContent);
    _titleController = TextEditingController(text: _currentChapter.title);
    _contentFocus = FocusNode();
    _wordCount = _currentChapter.wordCount;
    _undoRedo.reset(displayContent);

    widget.onWordCountChanged(_wordCount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.id != widget.chapter.id) {
      _saveNowSync();
      _currentChapter = widget.chapter;
      final displayContent = IndentController.addIndents(_currentChapter.content);
      _contentController.text = displayContent;
      _titleController.text = _currentChapter.title;
      _wordCount = _currentChapter.wordCount;
      _undoRedo.reset(displayContent);
      _isDirty = false;
      _searchVisible = false;
      _matches = [];
      widget.onWordCountChanged(_wordCount);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_isDirty) _saveNowSync();
    _contentController.dispose();
    _titleController.dispose();
    _contentFocus.dispose();
    _undoRedo.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    _undoRedo.push(text);
    _wordCount = WordCounter.count(text);
    _isDirty = true;
    widget.onWordCountChanged(_wordCount);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () => _saveNow());
    setState(() {});
  }

  void _onTitleChanged(String text) {
    _isDirty = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () => _saveNow());
  }

  Future<void> _saveNow() async {
    if (!_isDirty) return;
    widget.onSavingState(true);

    final cleanContent = IndentController.stripIndents(_contentController.text);
    final now = DateTime.now().toIso8601String();
    final updated = _currentChapter.copyWith(
      title: _titleController.text,
      content: cleanContent,
      wordCount: _wordCount,
      updatedAt: now,
    );

    await _chapterDao.update(updated);
    _currentChapter = updated;
    widget.onChapterChanged(updated);

    if (!mounted) return;
    _isDirty = false;
    widget.onSavingState(false);
  }

  void _saveNowSync() {
    if (!_isDirty) return;
    final cleanContent = IndentController.stripIndents(_contentController.text);
    final now = DateTime.now().toIso8601String();
    final updated = _currentChapter.copyWith(
      title: _titleController.text,
      content: cleanContent,
      wordCount: _wordCount,
      updatedAt: now,
    );
    _chapterDao.update(updated);
    _currentChapter = updated;
    widget.onChapterChanged(updated);
    _isDirty = false;
  }

  // Undo/Redo
  void _onUndo() {
    final restored = _undoRedo.undo(_contentController.text);
    _contentController.text = restored;
    _contentController.selection = TextSelection.collapsed(offset: restored.length);
    _undoRedo.endRestore();
    _wordCount = WordCounter.count(restored);
    widget.onWordCountChanged(_wordCount);
    _isDirty = true;
    setState(() {});
  }

  void _onRedo() {
    final restored = _undoRedo.redo(_contentController.text);
    _contentController.text = restored;
    _contentController.selection = TextSelection.collapsed(offset: restored.length);
    _undoRedo.endRestore();
    _wordCount = WordCounter.count(restored);
    widget.onWordCountChanged(_wordCount);
    _isDirty = true;
    setState(() {});
  }

  // Search / Replace
  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _matches = [];
        _searchQuery = '';
        _showReplace = false;
      }
    });
  }

  Future<void> _onSearch(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      setState(() => _matches = []);
      return;
    }
    final matches = await _searchService.search(query, _searchScope,
        chapterId: _currentChapter.id,
        sectionId: _searchScope == SearchScope.currentVolume ? _currentChapter.sectionId : null,
        bookId: _searchScope == SearchScope.entireBook ? widget.bookId : null);
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _currentMatchIndex = 0;
    });
    _navigateToCurrentMatch();
  }

  void _onScopeChanged(SearchScope scope) {
    _searchScope = scope;
    _onSearch(_searchQuery);
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _navigateToCurrentMatch();
  }

  void _prevMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _navigateToCurrentMatch();
  }

  void _navigateToCurrentMatch() {
    if (_matches.isEmpty) return;
    final match = _matches[_currentMatchIndex];
    // Adjust offset for indent characters
    final adjustedOffset = _getAdjustedOffset(match.startOffset);
    _contentController.selection = TextSelection(
      baseOffset: adjustedOffset,
      extentOffset: adjustedOffset + match.endOffset - match.startOffset,
    );
    // Scroll to selection would be handled by the TextField
  }

  int _getAdjustedOffset(int originalOffset) {
    // Account for 2 indent chars per paragraph
    final text = _contentController.text;
    int adjusted = 0;
    int lineStart = 0;
    int paragraphCount = 0;
    for (int i = 0; i < text.length && i < originalOffset + paragraphCount * 2; i++) {
      if (text[i] == '\n') {
        paragraphCount++;
        lineStart = i + 1;
      }
    }
    return originalOffset + paragraphCount * 2;
  }

  void _onReplace(String replacement) {
    if (_matches.isEmpty || _searchQuery.isEmpty) return;
    final text = _contentController.text;
    final match = _matches[_currentMatchIndex];
    final adjStart = _getAdjustedOffset(match.startOffset);
    final adjEnd = adjStart + match.endOffset - match.startOffset;
    final newText = text.substring(0, adjStart) + replacement + text.substring(adjEnd);
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(offset: adjStart + replacement.length);
    _onContentChanged(newText);
    _onSearch(_searchQuery); // Refresh matches
  }

  void _onReplaceAll(String replacement) {
    if (_searchQuery.isEmpty) return;
    var text = _contentController.text;
    // Replace in the display text (which has indents)
    text = text.replaceAll(_searchQuery, replacement);
    _contentController.text = text;
    _contentController.selection = TextSelection.collapsed(offset: text.length);
    _onContentChanged(text);
    setState(() => _matches = []);
  }

  void _cycleStatus() {
    const next = {'draft': 'revised', 'revised': 'final', 'final': 'draft'};
    final updated = _currentChapter.copyWith(
      status: next[_currentChapter.status]!,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _currentChapter = updated;
    widget.onChapterChanged(updated);
    _isDirty = true;
    _saveNow();
  }

  String _statusLabel(String status) {
    return {'draft': '草稿', 'revised': '修改中', 'final': '定稿'}[status] ?? status;
  }

  Future<void> _exportChapter() async {
    await _exportService.exportChapter(_currentChapter, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: '目录',
            onPressed: widget.onOpenDrawer,
          ),
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '章节标题',
            ),
            style: AppTheme.editorTitleStyle.copyWith(
              color: theme.textTheme.titleMedium?.color,
            ),
            textAlign: TextAlign.center,
            onChanged: _onTitleChanged,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: '撤销',
              onPressed: _undoRedo.canUndo ? _onUndo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: '重做',
              onPressed: _undoRedo.canRedo ? _onRedo : null,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'search':
                    _toggleSearch();
                    break;
                  case 'status':
                    _cycleStatus();
                    break;
                  case 'exportChapter':
                    _exportChapter();
                    break;
                  case 'exportBook':
                    widget.onExport();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'search', child: Text('查找替换')),
                PopupMenuItem(
                  value: 'status',
                  child: Text('切换状态 (当前: ${_statusLabel(_currentChapter.status)})'),
                ),
                const PopupMenuItem(value: 'exportChapter', child: Text('导出本章 (TXT)')),
                const PopupMenuItem(value: 'exportBook', child: Text('导出全书 (JSON)')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (_searchVisible)
              SearchReplaceBar(
                currentChapterContent: _contentController.text,
                matchCount: _matches.length,
                currentMatchIndex: _currentMatchIndex,
                scope: _searchScope,
                showReplace: _showReplace,
                onSearch: _onSearch,
                onScopeChanged: _onScopeChanged,
                onNextMatch: _nextMatch,
                onPrevMatch: _prevMatch,
                onReplace: _onReplace,
                onReplaceAll: _onReplaceAll,
                onToggleReplace: () => setState(() => _showReplace = !_showReplace),
                onClose: _toggleSearch,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocus,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTheme.editorContentStyle.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '开始写作...',
                    hintStyle: TextStyle(color: theme.colorScheme.outlineVariant),
                  ),
                  onChanged: _onContentChanged,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
