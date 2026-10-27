import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'backup_exception.dart';

/// Abstracts file selection and I/O so backup workflows can be tested without
/// opening native file-picker dialogs.
abstract class BackupFileService {
  /// Prompts the user to choose a directory, returning null when cancelled.
  Future<String?> pickDirectory();

  /// Prompts for a backup destination, returning null when cancelled.
  Future<String?> pickSaveLocation({
    required String suggestedName,
    String extension = 'enc',
  });

  /// Whether saving through the picker requires providing the bytes up front.
  bool get pickerWritesBytes;

  /// Saves [bytes] using the platform picker, returning null when cancelled.
  Future<String?> saveBytes({
    required String suggestedName,
    required Uint8List bytes,
    String extension = 'enc',
  });

  /// Prompts for a backup file, returning null when cancelled.
  Future<String?> pickOpenFile();

  /// Writes backup bytes to [path].
  Future<void> writeBytes(String path, Uint8List bytes);

  /// Reads backup bytes from [path].
  Future<Uint8List> readBytes(String path);

  /// Returns whether [path] exists.
  Future<bool> exists(String path);

  /// Deletes [path].
  Future<void> delete(String path);

  /// Resolves and creates the platform's default backup directory.
  Future<Directory> getDefaultBackupDirectory();
}

/// Uses the platform picker and local filesystem for backup files.
class PlatformBackupFileService implements BackupFileService {
  /// Creates the platform implementation.
  const PlatformBackupFileService();

  @override
  bool get pickerWritesBytes => Platform.isIOS || Platform.isAndroid;

  @override
  Future<String?> pickDirectory() async {
    try {
      return await FilePicker.platform.getDirectoryPath();
    } on PlatformException {
      throw const BackupIoException('Unable to choose backup folder');
    }
  }

  @override
  Future<String?> pickSaveLocation({
    required String suggestedName,
    String extension = 'enc',
  }) async {
    try {
      return await FilePicker.platform.saveFile(
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: <String>[extension],
      );
    } on PlatformException catch (error) {
      throw BackupIoException(
        'Unable to choose backup destination',
        platformCode: error.code,
      );
    }
  }

  @override
  Future<String?> saveBytes({
    required String suggestedName,
    required Uint8List bytes,
    String extension = 'enc',
  }) async {
    if (!pickerWritesBytes) {
      final destinationPath = await pickSaveLocation(
        suggestedName: suggestedName,
        extension: extension,
      );
      if (destinationPath == null) {
        return null;
      }
      await writeBytes(destinationPath, bytes);
      return destinationPath;
    }

    try {
      return await FilePicker.platform.saveFile(
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: <String>[extension],
        bytes: bytes,
      );
    } on PlatformException catch (error) {
      throw BackupIoException('Unable to save file', platformCode: error.code);
    }
  }

  @override
  Future<String?> pickOpenFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['enc'],
      );
      if (result == null) {
        return null;
      }
      if (result.files.isEmpty || result.files.single.path == null) {
        throw const BackupIoException('Unable to access selected backup file');
      }
      return result.files.single.path;
    } on PlatformException {
      throw const BackupIoException('Unable to choose backup file');
    }
  }

  @override
  Future<void> writeBytes(String pathValue, Uint8List bytes) async {
    try {
      final file = File(pathValue);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException {
      throw const BackupIoException('Unable to write backup file');
    }
  }

  @override
  Future<Uint8List> readBytes(String pathValue) async {
    try {
      return await File(pathValue).readAsBytes();
    } on FileSystemException {
      throw const BackupIoException('Unable to read backup file');
    }
  }

  @override
  Future<bool> exists(String pathValue) {
    try {
      return Future<bool>.value(
        FileSystemEntity.typeSync(pathValue) != FileSystemEntityType.notFound,
      );
    } on FileSystemException {
      return Future<bool>.error(
        const BackupIoException('Unable to check backup file'),
      );
    }
  }

  @override
  Future<void> delete(String pathValue) async {
    try {
      await File(pathValue).delete();
    } on FileSystemException {
      throw const BackupIoException('Unable to delete backup file');
    }
  }

  @override
  Future<Directory> getDefaultBackupDirectory() async {
    if (Platform.isIOS) {
      final supportDirectory = await getApplicationSupportDirectory();
      final directory = Directory(
        path.join(supportDirectory.path, 'insur_backups'),
      );
      try {
        await directory.create(recursive: true);
      } on FileSystemException {
        throw const BackupIoException('Unable to create backup directory');
      }
      return directory;
    }

    final String? documentsPath;
    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      documentsPath = profile == null || profile.isEmpty
          ? null
          : path.join(profile, 'Documents');
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      documentsPath = home == null || home.isEmpty
          ? null
          : path.join(home, 'Documents');
    } else {
      throw const BackupIoException(
        'Default backup directory is unsupported on this platform',
      );
    }
    if (documentsPath == null) {
      throw const BackupIoException(
        'Unable to locate the user documents directory',
      );
    }
    final directory = Directory(path.join(documentsPath, 'insur_backups'));
    try {
      await directory.create(recursive: true);
    } on FileSystemException {
      throw const BackupIoException('Unable to create backup directory');
    }
    return directory;
  }
}
