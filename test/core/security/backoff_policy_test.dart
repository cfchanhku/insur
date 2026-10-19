import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/security/backoff_policy.dart';

void main() {
  group('BackoffPolicy.forAttempts', () {
    final expectedDelays = <int, Duration>{
      0: Duration.zero,
      2: Duration.zero,
      3: const Duration(seconds: 5),
      4: const Duration(seconds: 5),
      5: const Duration(seconds: 15),
      6: const Duration(seconds: 15),
      7: const Duration(seconds: 60),
      8: const Duration(seconds: 60),
      9: const Duration(seconds: 60),
      10: const Duration(minutes: 5),
      15: const Duration(minutes: 5),
    };

    for (final entry in expectedDelays.entries) {
      test('returns ${entry.value} after ${entry.key} attempts', () {
        expect(BackoffPolicy.forAttempts(entry.key), entry.value);
      });
    }

    test('returns no delay for negative attempt counts', () {
      expect(BackoffPolicy.forAttempts(-1), Duration.zero);
    });
  });

  group('BackoffPolicy.shouldRequireRestart', () {
    for (var attempts = 0; attempts < 10; attempts++) {
      test('does not require restart after $attempts attempts', () {
        expect(BackoffPolicy.shouldRequireRestart(attempts), isFalse);
      });
    }

    test('requires restart after ten attempts', () {
      expect(BackoffPolicy.shouldRequireRestart(10), isTrue);
    });

    test('requires restart after more than ten attempts', () {
      expect(BackoffPolicy.shouldRequireRestart(15), isTrue);
    });
  });
}
