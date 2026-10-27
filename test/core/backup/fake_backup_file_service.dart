import 'dart:io';
import 'dart:typed_data';

import 'package:insur/core/backup/backup_exception.dart';
import 'package:insur/core/backup/backup_file_service.dart';
import 'package:path/path.dart' as path;

/// Filesystem-backed fake that avoids native file-picker dialogs.
class FakeBackupFileService implements BackupFileService {
  /// Creates a fake rooted in [directory].
  FakeBackupFileService(this.directory);

  /// Temporary directory used by this fake.
  final Directory directory;

  /// Optional path returned by [pickOpenFile].
  String? selectedFilePath;

  /// Path at which [writeBytes] should fail, if set.
  String? writeFailurePath;

  /// Optional folder returned by [pickDirectory].
  String? selectedDirectoryPath;

  @override
  Future<String?> pickDirectory() async =>
      selectedDirectoryPath ?? directory.path;

  @override
  Future<String?> pickSaveLocation({
    required String suggestedName,
    String extension = 'enc',
  }) async => path.join(directory.path, suggestedName);

  @override
  bool get pickerWritesBytes => false;

  @override
  Future<String?> saveBytes({
    required String suggestedName,
    required Uint8List bytes,
    String extension = 'enc',
  }) async {
    final destination = await pickSaveLocation(
      suggestedName: suggestedName,
      extension: extension,
    );
    if (destination == null) {
      return null;
    }
    await writeBytes(destination, bytes);
    return destination;
  }

  @override
  Future<String?> pickOpenFile() async => selectedFilePath;

  @override
  Future<void> writeBytes(String filePath, Uint8List bytes) async {
    if (filePath == writeFailurePath) {
      throw const BackupIoException('Synthetic file write failure');
    }
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List> readBytes(String filePath) async =>
      File(filePath).readAsBytes();

  @override
  Future<bool> exists(String filePath) async => File(filePath).existsSync();

  @override
  Future<void> delete(String filePath) async => File(filePath).delete();

  @override
  Future<Directory> getDefaultBackupDirectory() async => directory;
}
