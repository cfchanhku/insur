import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'backup_exception.dart';

/// Abstracts file selection and I/O so backup workflows can be tested without
/// opening native file-picker dialogs.
abstract class BackupFileService {
  /// Prompts the user to choose a directory, returning null when cancelled.
  Future<String?> pickDirectory();

  /// Prompts for a backup destination, returning null when cancelled.
  Future<String?> pickSaveLocation({required String suggestedName});

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
  Future<String?> pickDirectory() async {
    try {
      return await FilePicker.platform.getDirectoryPath();
    } on PlatformException {
      throw const BackupIoException('Unable to choose backup folder');
    }
  }

  @override
  Future<String?> pickSaveLocation({required String suggestedName}) async {
    try {
      return await FilePicker.platform.saveFile(
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: <String>['enc'],
      );
    } on PlatformException {
      throw const BackupIoException('Unable to choose backup destination');
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
