import 'package:flutter/material.dart';

/// Shows a non-dismissible modal progress dialog with a short message.
///
/// Use [Navigator.of(context, rootNavigator: true).pop()] to close it.
Future<void> showBlockingProgressDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    },
  );
}
