import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class BackendManager implements BackendManagerInterface {
  final _delimiter = Platform.isWindows ? '\\' : '/';

  static BackendManager select(
          [HiveStorageBackendPreference? backendPreference]) =>
      BackendManager();

  @override
  Future<StorageBackend> open(String name, String? path, bool crashRecovery,
      HiveCipher? cipher, String? collection) async {
    if (path == null) {
      throw HiveError('You need to initialize Hive or '
          'provide a path to store the box.');
    }

    if (path.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    var dir = Directory(path);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    var file = await findHiveFileAndCleanUp(name, path);
    var lockFile = File('$path$_delimiter$name.lock');

    var backend = StorageBackendVm(file, lockFile, crashRecovery, cipher);
    await backend.open();
    return backend;
  }

  /// Not part of public API
  @visibleForTesting
  Future<File> findHiveFileAndCleanUp(String name, String path) async {
    var hiveFile = File('$path$_delimiter$name.hive');
    var compactedFile = File('$path$_delimiter$name.hivec');

    if (await hiveFile.exists()) {
      if (await compactedFile.exists()) {
        await compactedFile.delete();
      }
      return hiveFile;
    } else if (await compactedFile.exists()) {
      print('Restoring compacted file.');
      return await compactedFile.rename(hiveFile.path);
    } else {
      await hiveFile.create();
      return hiveFile;
    }
  }

  @override
  Future<void> deleteBox(String name, String? path, String? collection) async {
    ArgumentError.checkNotNull(path, 'path');

    if (path!.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    await _deleteFileIfExists(File('$path$_delimiter$name.hive'));
    await _deleteFileIfExists(File('$path$_delimiter$name.hivec'));
    await _deleteFileIfExists(File('$path$_delimiter$name.lock'));
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> boxExists(String name, String? path, String? collection) async {
    ArgumentError.checkNotNull(path, 'path');

    if (path!.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    return await File('$path$_delimiter$name.hive').exists() ||
        await File('$path$_delimiter$name.hivec').exists() ||
        await File('$path$_delimiter$name.lock').exists();
  }
}
