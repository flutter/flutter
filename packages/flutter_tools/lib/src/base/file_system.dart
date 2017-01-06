// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'context.dart';

export 'package:file/file.dart';
export 'package:file/local.dart';

const FileSystem _kLocalFs = const LocalFileSystem();

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem get fs => context == null ? _kLocalFs : context[FileSystem];

/// Exits the process with the given [exitCode].
typedef void ExitFunction([int exitCode]);

final ExitFunction _defaultExitFunction = ([int exitCode]) {
  io.exit(exitCode);
};

ExitFunction _exitFunction = _defaultExitFunction;

/// Exits the process.
///
/// During tests, this may be set to a testing-friendly value by calling
/// [setExitFunctionForTests] (and then restored with [restoreExitFunction]).
ExitFunction get exit => _exitFunction;

/// Sets the [exit] function to a function that throws an exception rather
/// than exiting the process; intended for testing purposes.
@visibleForTesting
void setExitFunctionForTests([ExitFunction exitFunction]) {
  _exitFunction = exitFunction ?? ([int exitCode]) {
    throw new Exception('Exited with code $exitCode');
  };
}

/// Restores the [exit] function to the `dart:io` implementation.
@visibleForTesting
void restoreExitFunction() {
  _exitFunction = _defaultExitFunction;
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
  Directory srcDir = fs.directory(srcPath);
  if (!srcDir.existsSync())
    throw new Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');

  Directory destDir = fs.directory(destPath);
  if (!destDir.existsSync())
    destDir.createSync(recursive: true);

  srcDir.listSync().forEach((FileSystemEntity entity) {
    String newPath = path.join(destDir.path, path.basename(entity.path));
    if (entity is File) {
      File newFile = fs.file(newPath);
      newFile.writeAsBytesSync(entity.readAsBytesSync());
    } else if (entity is Directory) {
      copyFolderSync(entity.path, newPath);
    } else {
      throw new Exception('${entity.path} is neither File nor Directory');
    }
  });
}
