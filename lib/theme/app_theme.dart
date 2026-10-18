/// Defines the application's light and dark theme configuration.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter/material.dart';

/// Provides the supported application themes.
class AppTheme {
  /// Creates the application theme provider.
  const AppTheme();

  /// Returns the light theme.
  ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF145C74),
      ),
      useMaterial3: true,
    );
  }

  /// Returns the dark theme.
  ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF145C74),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
