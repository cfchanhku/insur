/// Provides a reusable confirmation dialog.
library;

import 'package:flutter/material.dart';

/// Presents a confirmation dialog and returns whether it was confirmed.
class ConfirmDialog {
  const ConfirmDialog._();

  /// Shows a dialog and returns true only when the confirm action is selected.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: icon == null ? null : Icon(icon),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel ??
                  MaterialLocalizations.of(context).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(
              confirmLabel ?? MaterialLocalizations.of(context).okButtonLabel,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
