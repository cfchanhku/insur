import 'package:flutter/material.dart';

/// A filled button that disables itself and shows progress while its action runs.
class AsyncButton extends StatefulWidget {
  /// Creates a button for an asynchronous action.
  const AsyncButton({required this.label, required this.onPressed, super.key});

  /// User-facing button label.
  final String label;

  /// Asynchronous action, or null when the button is unavailable.
  final Future<void> Function()? onPressed;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isRunning = false;

  Future<void> _run() async {
    final action = widget.onPressed;
    if (action == null || _isRunning) {
      return;
    }
    setState(() => _isRunning = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: widget.onPressed == null || _isRunning ? null : _run,
    child: _isRunning
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(widget.label),
  );
}
