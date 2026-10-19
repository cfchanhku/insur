/// A scaffold for routes whose feature screen is not implemented.
library;

import 'package:flutter/material.dart';

/// Displays a localized placeholder for an unimplemented feature.
class PlaceholderScreen extends StatelessWidget {
  /// Creates the placeholder screen with a localized [title].
  const PlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
  });

  /// Localized title of the placeholder feature.
  final String title;

  /// Localized placeholder message.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(message)),
    );
  }
}
