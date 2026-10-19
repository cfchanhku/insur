/// Defines structured logging operations that must exclude sensitive data.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Writes redacted application events using stable event codes.
class InsurLogger {
  /// Records an informational event identified by a non-sensitive code.
  void info(String eventCode) {
    throw UnimplementedError('InsurLogger.info');
  }

  /// Records a failure without including personally identifiable information.
  void error(String eventCode, {Object? error, StackTrace? stackTrace}) {
    throw UnimplementedError('InsurLogger.error');
  }
}
