/// Displays a localized error message and optional retry action.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A reusable error state.
class ErrorState extends StatelessWidget {
  /// Creates an error state.
  const ErrorState({super.key, required this.message, this.onRetry});

  /// Safe user-facing error message.
  final String message;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).action_retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
