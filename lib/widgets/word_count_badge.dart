import 'package:flutter/material.dart';

class WordCountBadge extends StatelessWidget {
  final int wordCount;
  final bool isSaving;

  const WordCountBadge({
    super.key,
    required this.wordCount,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_fields, size: 14, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(
              '$wordCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSaving) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
