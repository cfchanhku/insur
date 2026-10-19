/// Presents the app's loading state and routes according to vault setup.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Initial screen while secure storage is checked.
class SplashScreen extends ConsumerStatefulWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAndRoute());
  }

  Future<void> _loadAndRoute() async {
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      final initialized = await keyManager.isInitialized();
      if (!mounted) {
        return;
      }
      ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) {
        return;
      }
      if (!initialized) {
        context.go('/setup');
      } else if (keyManager.state == KeyManagerState.unlocked) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } on Exception {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.app_title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                l10n.app_tagline,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s6),
              if (_loadFailed)
                Text(
                  l10n.error_generic,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                )
              else ...<Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.s3),
                Text(l10n.splash_loading, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
