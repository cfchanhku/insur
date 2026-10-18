/// Defines platform file selection for backup and export workflows.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

/// Selects local files and destinations without exposing sensitive content.
class PlatformFilePicker {
  /// Selects a file and returns its local path, or null if cancelled.
  Future<String?> pickFile() async {
    throw UnimplementedError();
  }

  /// Writes [bytes] to a user-selected file named [suggestedName].
  Future<String?> saveFile({
    required String suggestedName,
    required Uint8List bytes,
  }) async {
    throw UnimplementedError();
  }
}
