// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import '../globals.dart' as globals;
import 'common.dart' show throwToolExit;

export 'package:file/file.dart';
export 'package:file/local.dart';

/// Create the ancestor directories of a file path if they do not already exist.
void ensureDirectoryExists(String filePath) {
  final String dirPath = globals.fs.path.dirname(filePath);
  if (globals.fs.isDirectorySync(dirPath)) {
    return;
  }
  try {
    globals.fs.directory(dirPath).createSync(recursive: true);
  } on FileSystemException catch (e) {
    throwToolExit('Failed to create directory "$dirPath": ${e.osError.message}');
  }
}

/// Creates `destDir` if needed, then recursively copies `srcDir` to `destDir`,
/// invoking [onFileCopied], if specified, for each source/destination file pair.
///
/// Skips files if [shouldCopyFile] returns `false`.
void copyDirectorySync(
  Directory srcDir,
  Directory destDir, {
  bool shouldCopyFile(File srcFile, File destFile),
  void onFileCopied(File srcFile, File destFile),
}) {
  if (!srcDir.existsSync()) {
    throw Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');
  }

  if (!destDir.existsSync()) {
    destDir.createSync(recursive: true);
  }

  for (final FileSystemEntity entity in srcDir.listSync()) {
    final String newPath = destDir.fileSystem.path.join(destDir.path, entity.basename);
    if (entity is File) {
      final File newFile = destDir.fileSystem.file(newPath);
      if (shouldCopyFile != null && !shouldCopyFile(entity, newFile)) {
        continue;
      }
      newFile.writeAsBytesSync(entity.readAsBytesSync());
      onFileCopied?.call(entity, newFile);
    } else if (entity is Directory) {
      copyDirectorySync(
        entity,
        destDir.fileSystem.directory(newPath),
        shouldCopyFile: shouldCopyFile,
        onFileCopied: onFileCopied,
      );
    } else {
      throw Exception('${entity.path} is neither File nor Directory');
    }
  }
}

/// Canonicalizes [path].
///
/// This function implements the behavior of `canonicalize` from
/// `package:path`. However, unlike the original, it does not change the ASCII
/// case of the path. Changing the case can break hot reload in some situations,
/// for an example see: https://github.com/flutter/flutter/issues/9539.
String canonicalizePath(String path) => globals.fs.path.normalize(globals.fs.path.absolute(path));

/// Escapes [path].
///
/// On Windows it replaces all '\' with '\\'. On other platforms, it returns the
/// path unchanged.
String escapePath(String path) => globals.platform.isWindows ? path.replaceAll('\\', '\\\\') : path;

/// Returns true if the file system [entity] has not been modified since the
/// latest modification to [referenceFile].
///
/// Returns true, if [entity] does not exist.
///
/// Returns false, if [entity] exists, but [referenceFile] does not.
bool isOlderThanReference({ @required FileSystemEntity entity, @required File referenceFile }) {
  if (!entity.existsSync()) {
    return true;
  }
  return referenceFile.existsSync()
      && referenceFile.statSync().modified.isAfter(entity.statSync().modified);
}

/// Exception indicating that a file that was expected to exist was not found.
class FileNotFoundException implements IOException {
  const FileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'File not found: $path';
}

/// Reads the process environment to find the current user's home directory.
///
/// If the searched environment variables are not set, '.' is returned instead.
String userHomePath() {
  final String envKey = globals.platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  return globals.platform.environment[envKey] ?? '.';
}
