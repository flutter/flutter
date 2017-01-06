// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as dart_io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

export 'package:file/file.dart';
export 'package:file/local.dart';

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem fs = new LocalFileSystem();

/// Exits the process with the given [exitCode].
typedef void ExitFunction([int exitCode]);

final ExitFunction _defaultExitFunction = ([int exitCode]) {
  dart_io.exit(exitCode);
};

/// Exits the process.
ExitFunction exit = _defaultExitFunction;

/// Restores [fs] to the default local disk-based implementation.
void restoreFileSystem() {
  fs = new LocalFileSystem();
  exit = _defaultExitFunction;
}

/// Uses in-memory replacments for `dart:io` functionality. Useful in tests.
void useInMemoryFileSystem({ String cwd: '/', ExitFunction exitFunction }) {
  fs = new MemoryFileSystem();
  if (!fs.directory(cwd).existsSync()) {
    fs.directory(cwd).createSync(recursive: true);
  }
  fs.currentDirectory = cwd;
  exit = exitFunction ?? ([int exitCode]) {
    throw new Exception('Exited with code $exitCode');
  };
}

/// Create the ancestor directories of a file path if they do not already exist.
void ensureDirectoryExists(String filePath) {
  String dirPath = path.dirname(filePath);

  if (fs.typeSync(dirPath) == FileSystemEntityType.DIRECTORY)
    return;
  fs.directory(dirPath).createSync(recursive: true);
}

/// Recursively copies a folder from `srcPath` to `destPath`
void copyFolderSync(String srcPath, String destPath) {
  dart_io.Directory srcDir = new dart_io.Directory(srcPath);
  if (!srcDir.existsSync())
    throw new Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');

  dart_io.Directory destDir = new dart_io.Directory(destPath);
  if (!destDir.existsSync())
    destDir.createSync(recursive: true);

  srcDir.listSync().forEach((dart_io.FileSystemEntity entity) {
    String newPath = path.join(destDir.path, path.basename(entity.path));
    if (entity is dart_io.File) {
      dart_io.File newFile = new dart_io.File(newPath);
      newFile.writeAsBytesSync(entity.readAsBytesSync());
    } else if (entity is dart_io.Directory) {
      copyFolderSync(entity.path, newPath);
    } else {
      throw new Exception('${entity.path} is neither File nor Directory');
    }
  });
}
