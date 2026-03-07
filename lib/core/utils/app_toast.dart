import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  /// Show a success toast
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    _showToast(
      context,
      message,
      ToastType.success,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    _showToast(
      context,
      message,
      ToastType.error,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    _showToast(
      context,
      message,
      ToastType.info,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    _showToast(
      context,
      message,
      ToastType.warning,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Internal method to show toast with specified type
  static void _showToast(
    BuildContext context,
    String message,
    ToastType type, {
    required Duration duration,
    VoidCallback? onDismiss,
  }) {
    final theme = Theme.of(context);
    final (icon, bgColor, textColor) = _getToastStyle(type, theme);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessenger.hideCurrentSnackBar();
            onDismiss?.call();
          },
        ),
      ),
    );
  }

  /// Get icon, background color, and text color based on toast type
  static (IconData, Color, Color) _getToastStyle(
    ToastType type,
    ThemeData theme,
  ) {
    switch (type) {
      case ToastType.success:
        return (
          Icons.check_circle_outline,
          Colors.green.shade700,
          Colors.green.shade300,
        );
      case ToastType.error:
        return (
          Icons.error_outline,
          Colors.red.shade700,
          Colors.red.shade300,
        );
      case ToastType.warning:
        return (
          Icons.warning_outlined,
          Colors.orange.shade700,
          Colors.orange.shade300,
        );
      case ToastType.info:
        return (
          Icons.info_outline,
          Colors.blue.shade700,
          Colors.blue.shade300,
        );
    }
  }
}
