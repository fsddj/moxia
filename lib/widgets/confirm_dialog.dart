import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool destructive;
  final String? requireTextConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.destructive = false,
    this.requireTextConfirm,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    bool destructive = false,
    String? requireTextConfirm,
  }) async {
    if (requireTextConfirm != null) {
      // Two-step: first confirm intent, then type to confirm
      final intent = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
                  : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
      if (intent != true) return false;

      // Step 2: type confirmation
      final controller = TextEditingController();
      final typed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            final matches = controller.text == requireTextConfirm;
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('请输入 "${requireTextConfirm}" 以确认删除：'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: requireTextConfirm,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
                      : null,
                  onPressed: matches ? () => Navigator.pop(ctx, true) : null,
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ),
      );
      return typed ?? false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
