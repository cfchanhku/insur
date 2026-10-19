/// Calls [onLock] after an inactivity interval.
///
/// Start this timer when the session is unlocked and call [reset] from an app
/// interaction listener, such as a `Listener` or `GestureDetector` wrapping
/// the application. The application remains responsible for choosing when to
/// stop or dispose of the timer.
library;

import 'dart:async';

class AutoLockTimer {
  /// Creates an auto-lock timer with a default fifteen-minute interval.
  AutoLockTimer({
    required void Function() onLock,
    Duration duration = const Duration(minutes: 15),
  }) : _onLock = onLock,
       _duration = duration;

  final void Function() _onLock;
  final Duration _duration;
  Timer? _timer;

  /// Starts the inactivity timer, replacing any previously started timer.
  void start() {
    _timer?.cancel();
    _timer = Timer(_duration, _onLock);
  }

  /// Restarts the inactivity timer after user interaction.
  void reset() {
    start();
  }

  /// Cancels the current inactivity timer, if any.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels and releases the timer.
  void dispose() {
    cancel();
  }
}
