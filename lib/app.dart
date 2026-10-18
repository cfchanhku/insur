/// Root widget for the Insurance Policy Manager application.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Configures the application shell, routes, theme, and localized resources.
class InsurApp extends StatelessWidget {
  /// Creates the root application widget.
  const InsurApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTheme = AppTheme();

    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).app_title,
      theme: appTheme.light(),
      darkTheme: appTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SizedBox.shrink(), // TODO(insur): Replace with SplashScreen.
    );
  }
}
