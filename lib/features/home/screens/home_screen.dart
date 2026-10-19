/// Presents the temporary home screen and manages its inactivity lock.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/auto_lock_timer.dart';
import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Placeholder home route until the client list is implemented.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AutoLockTimer _timer;

  @override
  void initState() {
    super.initState();
    _timer = AutoLockTimer(onLock: () => unawaited(_lockForInactivity()))
      ..start();
  }

  Future<void> _lockForInactivity() async {
    await _lock();
  }

  Future<void> _lockManually() async {
    await _lock();
  }

  Future<void> _lock() async {
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.append(eventType: AuditEventType.autoLock);
    final keyManager = await ref.read(keyManagerProvider.future);
    keyManager.onAudit = null;
    await keyManager.lock();
    if (!mounted) {
      return;
    }
    ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
    context.go('/lock');
  }

  Future<void> _logout() async {
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.append(eventType: AuditEventType.logout);
    final keyManager = await ref.read(keyManagerProvider.future);
    keyManager.onAudit = null;
    await keyManager.logout();
    if (!mounted) {
      return;
    }
    ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
    context.go('/login');
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Listener(
      onPointerDown: (_) => _timer.reset(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.app_title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l10n.home_welcome, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.s2),
                Text(l10n.home_coming_soon, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s4),
                FutureBuilder<KeyManager>(
                  future: ref.watch(keyManagerProvider.future),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n.error_generic);
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final state = switch (snapshot.requireData.state) {
                      KeyManagerState.uninitialized =>
                        l10n.key_state_uninitialized,
                      KeyManagerState.locked => l10n.key_state_locked,
                      KeyManagerState.unlocked => l10n.key_state_unlocked,
                    };
                    return Text(l10n.home_state(state));
                  },
                ),
                const SizedBox(height: AppSpacing.s4),
                FilledButton(
                  onPressed: _lockManually,
                  child: Text(l10n.home_lock),
                ),
                const SizedBox(height: AppSpacing.s2),
                OutlinedButton(
                  onPressed: _logout,
                  child: Text(l10n.home_logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
