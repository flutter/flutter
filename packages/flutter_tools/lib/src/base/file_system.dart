// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'package:file/file.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'common.dart' show throwToolExit;

export 'package:file/file.dart';
export 'package:file/local.dart';

/// Exception indicating that a file that was expected to exist was not found.
class FileNotFoundException implements IOException {
  const FileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'File not found: $path';
}

// Windows specific ffi functionality.
ffi.DynamicLibrary _windowsKernel;
typedef GetFileAttributes = int Function(ffi.Pointer<ffi.Utf16>);
typedef GetFileAttributesNative = ffi.Uint32 Function(ffi.Pointer<ffi.Utf16>);
GetFileAttributes _getFileAttributes;
const int kWindowsFileAttributeHidden = 0x2;
const int kWindowsFileAttributeInvalid = 4294967295;

/// Check whether a file is hidden.
///
/// on macOS and Linux, this checks whether the file name is prepended
/// with a `.`. On windows, this reads the file attribute contents to look
/// for `FILE_ATTRIBUTE_HIDDEN`.
bool isHiddenFile(File file, {
  @required bool windows,
}) {
  if (windows) {
    _windowsKernel ??= ffi.DynamicLibrary.open('Kernel32.dll');
    _getFileAttributes ??= _windowsKernel
      .lookupFunction<GetFileAttributesNative, GetFileAttributes>('GetFileAttributesW');
    final ffi.Pointer<ffi.Utf16> fileName = ffi.Utf16.toUtf16(file.path);
    final int attributes = _getFileAttributes(fileName);
    if (attributes == kWindowsFileAttributeInvalid) {
      throw FileSystemException('Failed to get file attributes', file.path);
    }
    return (attributes & kWindowsFileAttributeHidden) == kWindowsFileAttributeHidden;
  }
  return file.fileSystem.path.basename(file.path)
    .startsWith('.');
}

/// Various convenience file system methods.
class FileSystemUtils {
  FileSystemUtils({
    @required FileSystem fileSystem,
    @required Platform platform,
  }) : _fileSystem = fileSystem,
       _platform = platform;

  final FileSystem _fileSystem;

  final Platform _platform;

  /// Create the ancestor directories of a file path if they do not already exist.
  void ensureDirectoryExists(String filePath) {
    final String dirPath = _fileSystem.path.dirname(filePath);
    if (_fileSystem.isDirectorySync(dirPath)) {
      return;
    }
    try {
      _fileSystem.directory(dirPath).createSync(recursive: true);
    } on FileSystemException catch (e) {
      throwToolExit('Failed to create directory "$dirPath": ${e.osError.message}');
    }
  }

  /// Creates `destDir` if needed, then recursively copies `srcDir` to
  /// `destDir`, invoking [onFileCopied], if specified, for each
  /// source/destination file pair.
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

  /// Appends a number to a filename in order to make it unique under a
  /// directory.
  File getUniqueFile(Directory dir, String baseName, String ext) {
    final FileSystem fs = dir.fileSystem;
    int i = 1;

    while (true) {
      final String name = '${baseName}_${i.toString().padLeft(2, '0')}.$ext';
      final File file = fs.file(_fileSystem.path.join(dir.path, name));
      if (!file.existsSync()) {
        return file;
      }
      i++;
    }
  }

  /// Return a relative path if [fullPath] is contained by the cwd, else return an
  /// absolute path.
  String getDisplayPath(String fullPath) {
    final String cwd = _fileSystem.currentDirectory.path + _fileSystem.path.separator;
    return fullPath.startsWith(cwd) ? fullPath.substring(cwd.length) : fullPath;
  }

  /// Escapes [path].
  ///
  /// On Windows it replaces all '\' with '\\'. On other platforms, it returns the
  /// path unchanged.
  String escapePath(String path) => _platform.isWindows ? path.replaceAll(r'\', r'\\') : path;

  /// Returns true if the file system [entity] has not been modified since the
  /// latest modification to [referenceFile].
  ///
  /// Returns true, if [entity] does not exist.
  ///
  /// Returns false, if [entity] exists, but [referenceFile] does not.
  bool isOlderThanReference({
    @required FileSystemEntity entity,
    @required File referenceFile,
  }) {
    if (!entity.existsSync()) {
      return true;
    }
    return referenceFile.existsSync()
        && referenceFile.statSync().modified.isAfter(entity.statSync().modified);
  }

  /// Return the absolute path of the user's home directory
  String get homeDirPath {
    String path = _platform.isWindows
        ? _platform.environment['USERPROFILE']
        : _platform.environment['HOME'];
    if (path != null) {
      path = _fileSystem.path.absolute(path);
    }
    return path;
  }
}
