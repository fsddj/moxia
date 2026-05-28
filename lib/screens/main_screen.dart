import 'package:flutter/material.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/section_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../models/book.dart';
import '../models/section.dart';
import '../models/chapter.dart';
import '../widgets/nav_drawer.dart';
import '../widgets/book_selection_overlay.dart';
import '../widgets/word_count_badge.dart';
import '../widgets/empty_state_widget.dart';
import '../services/json_import_service.dart';
import '../services/json_export_service.dart';
import 'editor_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final BookDao _bookDao = BookDao();
  final SectionDao _sectionDao = SectionDao();
  final ChapterDao _chapterDao = ChapterDao();

  List<Book> _allBooks = [];
  Book? _currentBook;
  Chapter? _currentChapter;
  bool _isLoading = true;
  int _wordCount = 0;
  bool _isSaving = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;
  bool _overlayVisible = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOutCubic,
    );
    _loadInitialState();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final books = await _bookDao.getAll();
    if (!mounted) return;
    setState(() => _allBooks = books);

    if (books.isNotEmpty) {
      await _selectRecentBook(books);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectRecentBook(List<Book> books) async {
    Book recent = books.first;
    for (final b in books) {
      if (b.updatedAt.compareTo(recent.updatedAt) > 0) {
        recent = b;
      }
    }
    await _loadBook(recent);
  }

  Future<void> _loadBook(Book book) async {
    setState(() {
      _currentBook = book;
      _currentChapter = null;
      _isLoading = true;
    });

    // Try to restore last chapter
    if (book.lastChapterId != null) {
      final chapter = await _chapterDao.getById(book.lastChapterId!);
      if (chapter != null) {
        if (!mounted) return;
        setState(() {
          _currentChapter = chapter;
          _wordCount = chapter.wordCount;
          _isLoading = false;
        });
        return;
      }
    }

    // Fallback: load first chapter of first section
    final sections = await _sectionDao.getByBookId(book.id!);
    if (sections.isNotEmpty) {
      final chapters = await _chapterDao.getBySectionId(sections.first.id!);
      if (chapters.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _currentChapter = chapters.first;
          _wordCount = chapters.first.wordCount;
          _isLoading = false;
        });
        return;
      }
    }

    // No chapters exist yet
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _switchBook(Book book) async {
    _toggleOverlay();
    await _loadBook(book);
  }

  Future<void> _switchChapter(Chapter chapter) async {
    Navigator.pop(context); // close drawer
    // Persist last chapter on current book
    if (_currentBook != null) {
      await _bookDao.updateLastChapterId(_currentBook!.id!, chapter.id!);
    }
    // Refresh chapter from DB
    final fresh = await _chapterDao.getById(chapter.id!);
    if (fresh != null && mounted) {
      setState(() {
        _currentChapter = fresh;
        _wordCount = fresh.wordCount;
      });
    }
  }

  void _onChapterChanged(Chapter updated) {
    setState(() {
      _currentChapter = updated;
      _wordCount = updated.wordCount;
    });
    if (_currentBook != null) {
      _bookDao.updateLastChapterId(_currentBook!.id!, updated.id!);
    }
  }

  void _onSavingState(bool saving) {
    setState(() => _isSaving = saving);
  }

  void _onWordCountChanged(int count) {
    setState(() => _wordCount = count);
  }

  Future<void> _createBook() async {
    _toggleOverlay();
    final now = DateTime.now().toIso8601String();
    final book = Book(
      createdAt: now,
      updatedAt: now,
      sortOrder: _allBooks.length,
    );
    final id = await _bookDao.insert(book);
    final created = book.copyWith(id: id);
    if (!mounted) return;
    setState(() => _allBooks = [..._allBooks, created]);
    await _loadBook(created);

    // Create first section and chapter
    final section = Section(
      bookId: created.id!,
      title: '第一卷',
      createdAt: now,
      updatedAt: now,
      sortOrder: 0,
    );
    final sectionId = await _sectionDao.insert(section);
    final chapter = Chapter(
      sectionId: sectionId,
      title: '第一章',
      createdAt: now,
      updatedAt: now,
      sortOrder: 0,
    );
    final chapterId = await _chapterDao.insert(chapter);
    final newChapter = chapter.copyWith(id: chapterId);
    if (mounted) {
      setState(() {
        _currentChapter = newChapter;
        _wordCount = 0;
      });
    }
  }

  void _toggleOverlay() {
    setState(() {
      _overlayVisible = !_overlayVisible;
      if (_overlayVisible) {
        _overlayController.forward();
      } else {
        _overlayController.reverse();
      }
    });
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    if (details.primaryDelta! > 5 && !_overlayVisible) {
      _toggleOverlay();
    } else if (details.primaryDelta! < -5 && _overlayVisible) {
      _toggleOverlay();
    }
  }

  Future<void> _importJson() async {
    final result = await JsonImportService().pickAndImport();
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '已导入《${result.bookTitle}》：${result.sectionCount}卷 · ${result.chapterCount}章')),
    );
    _refreshBooks();
  }

  Future<void> _exportBook() async {
    if (_currentBook == null) return;
    await JsonExportService().exportBookToFile(_currentBook!, context);
  }

  Future<void> _refreshBooks() async {
    final books = await _bookDao.getAll();
    if (!mounted) return;
    setState(() => _allBooks = books);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _currentBook != null
          ? NavDrawer(
              book: _currentBook!,
              currentChapterId: _currentChapter?.id,
              onChapterSelected: _switchChapter,
              onBookChanged: _refreshBooks,
            )
          : null,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDrag,
        child: Stack(
          children: [
            // Main content
            _buildBody(),

            // Book selection overlay
            BookSelectionOverlay(
              books: _allBooks,
              currentBookId: _currentBook?.id,
              onBookSelected: _switchBook,
              onCreateBook: _createBook,
              onImport: _importJson,
              animation: _overlayAnimation,
            ),

            // Word count badge (top-right)
            if (_currentChapter != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: WordCountBadge(
                  wordCount: _wordCount,
                  isSaving: _isSaving,
                ),
              ),

            // Drag hint at top
            if (!_overlayVisible && _currentBook != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentBook == null) {
      return Scaffold(
        body: EmptyStateWidget(
          icon: Icons.menu_book_rounded,
          message: '还没有作品',
          actionHint: '从顶部下滑打开面板，新建第一部作品',
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createBook,
          icon: const Icon(Icons.add),
          label: const Text('新建作品'),
        ),
      );
    }

    if (_currentChapter == null) {
      // Book exists but has no chapters — create first chapter
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              const Text('还没有章节'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final now = DateTime.now().toIso8601String();
                  final sections = await _sectionDao.getByBookId(_currentBook!.id!);
                  int sectionId;
                  if (sections.isEmpty) {
                    final s = Section(bookId: _currentBook!.id!, title: '第一卷', createdAt: now, updatedAt: now, sortOrder: 0);
                    sectionId = await _sectionDao.insert(s);
                  } else {
                    sectionId = sections.first.id!;
                  }
                  final c = Chapter(sectionId: sectionId, title: '第一章', createdAt: now, updatedAt: now, sortOrder: 0);
                  final chapterId = await _chapterDao.insert(c);
                  final chapter = (await _chapterDao.getById(chapterId))!;
                  if (mounted) {
                    setState(() {
                      _currentChapter = chapter;
                      _wordCount = chapter.wordCount;
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('新建第一章'),
              ),
            ],
          ),
        ),
      );
    }

    return EditorScreen(
      key: ValueKey(_currentChapter!.id),
      chapter: _currentChapter!,
      bookId: _currentBook?.id,
      onChapterChanged: _onChapterChanged,
      onSavingState: _onSavingState,
      onWordCountChanged: _onWordCountChanged,
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      onExport: _exportBook,
    );
  }
}
