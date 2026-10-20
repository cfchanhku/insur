/// Displays standardized transient success, error, and information messages.
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Helpers for semantic, floating snackbars.
class AppSnackBar {
  const AppSnackBar._();

  /// Shows [message] with the success color.
  static void showSuccess(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      message,
      Icons.check_circle_outline,
      isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
    );
  }

  /// Shows [message] with the error color.
  static void showError(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    _show(context, message, Icons.error_outline, colors.error, colors.onError);
  }

  /// Shows [message] with the primary information color.
  static void showInfo(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      Icons.info_outline,
      colors.primary,
      colors.onPrimary,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: backgroundColor,
          content: Row(
            children: <Widget>[
              ExcludeSemantics(child: Icon(icon, color: foregroundColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foregroundColor)),
              ),
            ],
          ),
        ),
      );
  }
}
