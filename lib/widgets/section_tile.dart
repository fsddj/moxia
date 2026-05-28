import 'package:flutter/material.dart';
import '../models/section.dart';
import '../utils/date_formatter.dart';

class SectionTile extends StatelessWidget {
  final Section section;
  final int chapterCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const SectionTile({
    super.key,
    required this.section,
    required this.chapterCount,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          section.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$chapterCount章 · ${section.wordCount}字 · ${DateFormatter.format(section.updatedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'rename', child: Text('重命名')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ),
    );
  }
}
