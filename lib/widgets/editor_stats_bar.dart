import 'package:flutter/material.dart';

class EditorStatsBar extends StatelessWidget {
  final int wordCount;
  final String? lastSavedAt;
  final bool isSaving;

  const EditorStatsBar({
    super.key,
    required this.wordCount,
    this.lastSavedAt,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text('$wordCount 字', style: style),
            const Spacer(),
            if (isSaving)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('保存中...', style: style),
                ],
              )
            else if (lastSavedAt != null)
              Text('已保存 $lastSavedAt', style: style),
          ],
        ),
      ),
    );
  }
}
