import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/theme_inherited.dart';
import '../models/book.dart';

class BookSelectionOverlay extends StatelessWidget {
  final List<Book> books;
  final int? currentBookId;
  final void Function(Book book) onBookSelected;
  final VoidCallback onCreateBook;
  final VoidCallback onImport;
  final Animation<double> animation;

  const BookSelectionOverlay({
    super.key,
    required this.books,
    required this.currentBookId,
    required this.onBookSelected,
    required this.onCreateBook,
    required this.onImport,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.55 * animation.value,
          child: Material(
            elevation: 8,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('我的作品',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          ThemeInherited.isDark(context) ? Icons.light_mode : Icons.dark_mode,
                        ),
                        tooltip: '夜间模式',
                        onPressed: () => ThemeInherited.toggleTheme(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined),
                        tooltip: '导入JSON',
                        onPressed: onImport,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: books.isEmpty
                      ? Center(
                          child: Text('还没有作品',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: books.length,
                          itemBuilder: (_, i) => _BookGridItem(
                            book: books[i],
                            isSelected: books[i].id == currentBookId,
                            onTap: () => onBookSelected(books[i]),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: onCreateBook,
                    icon: const Icon(Icons.add),
                    label: const Text('新建作品'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookGridItem extends StatelessWidget {
  final Book book;
  final bool isSelected;
  final VoidCallback onTap;

  const _BookGridItem({required this.book, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(book.coverColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (book.coverImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.file(
                  File(book.coverImage!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const Spacer(),
            Icon(Icons.menu_book_rounded, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${book.wordCount}字',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
