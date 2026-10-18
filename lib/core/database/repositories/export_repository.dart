/// Defines operations for creating local policy exports.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'dart:typed_data';

import '../../../features/export/models/export_request.dart';

/// Prepares PDF data for an explicitly requested export.
class ExportRepository {
  /// Generates a PDF from [request] and protects it with [password].
  Future<Uint8List> createPdf({
    required ExportRequest request,
    required String password,
  }) async {
    throw UnimplementedError('ExportRepository.createPdf');
  }
}
