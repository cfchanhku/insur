/// Displays a centered progress indicator.
library;

import 'package:flutter/material.dart';

/// A reusable loading state.
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
