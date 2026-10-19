/// Root widget configuring routing, theme, and localized resources.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/widgets/auto_lock_wrapper.dart';
import 'features/settings/settings_notifier.dart';
import 'features/settings/settings_state.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Configures the localized Material application and GoRouter.
class InsurApp extends ConsumerWidget {
  /// Creates the application root.
  const InsurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const SettingsState();
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).app_title,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: settings.language == 'zh-Hant'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
          : const Locale('en'),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) =>
          AutoLockWrapper(child: child ?? const SizedBox.shrink()),
    );
  }
}
