/// Applies one inactivity timer across every route in the unlocked app.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/auto_lock_timer.dart';
import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../router/app_router.dart';
import '../../settings/settings_keys.dart';
import '../../settings/settings_notifier.dart';
import '../../settings/settings_state.dart';

/// Keeps the inactivity timer active across route changes while unlocked.
class AutoLockWrapper extends ConsumerStatefulWidget {
  /// Creates the application-wide auto-lock wrapper.
  const AutoLockWrapper({required this.child, super.key});

  /// The app's current routed content.
  final Widget child;

  @override
  ConsumerState<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends ConsumerState<AutoLockWrapper> {
  late AutoLockTimer _timer;
  int _durationMinutes = SettingsKeys.defaultAutoLockMinutes;
  bool _isUnlocked = false;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _timer = _createTimer();
    ref
      ..listenManual<AsyncValue<SettingsState>>(settingsProvider, (
        AsyncValue<SettingsState>? previous,
        AsyncValue<SettingsState> next,
      ) {
        _configure(
          next.valueOrNull?.autoLockMinutes ?? _durationMinutes,
          ref.read(keyManagerStateProvider) == KeyManagerState.unlocked,
        );
      })
      ..listenManual<KeyManagerState>(keyManagerStateProvider, (
        KeyManagerState? previous,
        KeyManagerState next,
      ) {
        _configure(
          ref.read(settingsProvider).valueOrNull?.autoLockMinutes ??
              _durationMinutes,
          next == KeyManagerState.unlocked,
        );
      });

    _configure(
      ref.read(settingsProvider).valueOrNull?.autoLockMinutes ??
          SettingsKeys.defaultAutoLockMinutes,
      ref.read(keyManagerStateProvider) == KeyManagerState.unlocked,
    );
  }

  AutoLockTimer _createTimer() => AutoLockTimer(
    duration: Duration(minutes: _durationMinutes),
    onLock: () => unawaited(_lockAfterInactivity()),
  );

  void _configure(int durationMinutes, bool isUnlocked) {
    if (_durationMinutes == durationMinutes && _isUnlocked == isUnlocked) {
      return;
    }
    _durationMinutes = durationMinutes;
    _isUnlocked = isUnlocked;
    _timer.dispose();
    _timer = _createTimer();
    if (isUnlocked) {
      _timer.start();
    }
  }

  Future<void> _lockAfterInactivity() async {
    if (!mounted || !_isUnlocked || _isLocking) {
      return;
    }
    _isLocking = true;
    _timer.cancel();
    var auditFailed = false;
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      if (keyManager.state != KeyManagerState.unlocked) {
        return;
      }
      try {
        final audit = await ref.read(auditRepositoryProvider.future);
        await audit.append(eventType: AuditEventType.autoLock);
      } on Exception {
        auditFailed = true;
      }
      keyManager.onAudit = null;
      await keyManager.lock();
      ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      if (mounted) {
        ref.read(routerProvider).go('/lock');
        if (auditFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).error_generic)),
          );
        }
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error_generic)),
        );
      }
    } finally {
      _isLocking = false;
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (_isUnlocked) {
          _timer.reset();
        }
      },
      child: widget.child,
    );
  }
}
