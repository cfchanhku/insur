/// Defines the application's light and dark theme configuration.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter/material.dart';

/// Semantic primary color token used by the application theme.
const Color appPrimaryColor = Color(0xFF145C74);

/// Semantic horizontal and vertical spacing token for standard content gaps.
const double appContentSpacing = 16;

/// Provides the supported application themes.
class AppTheme {
  /// Creates the application theme provider.
  const AppTheme();

  /// Returns the light theme.
  ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: appPrimaryColor,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24),
        titleLarge: TextStyle(fontSize: 20),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(appContentSpacing)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      useMaterial3: true,
    );
  }

  /// Returns the dark theme.
  ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: appPrimaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24),
        titleLarge: TextStyle(fontSize: 20),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(appContentSpacing)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      useMaterial3: true,
    );
  }
}
