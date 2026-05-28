import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../utils/date_formatter.dart';

class ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onStatusCycle;

  const ChapterTile({
    super.key,
    required this.chapter,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onStatusCycle,
  });

  IconData _statusIcon() {
    switch (chapter.status) {
      case 'revised':
        return Icons.radio_button_unchecked;
      case 'final':
        return Icons.check_circle;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _statusColor() {
    switch (chapter.status) {
      case 'revised':
        return Colors.orange;
      case 'final':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: GestureDetector(
          onTap: onStatusCycle,
          child: Icon(_statusIcon(), color: _statusColor(), size: 22),
        ),
        title: Text(
          chapter.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${chapter.wordCount}字 · ${DateFormatter.format(chapter.updatedAt)}',
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
