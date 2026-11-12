// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../dependencies.dart';

/// Creates a hermetic [ExtensionDependencies] container for unit testing
/// extension services in a single isolate without touching the host disk.
///
/// Because `Isolate.spawn` copies captured objects into the child isolate's
/// heap, mutations to a [MemoryExtensionFileSystem] inside an
/// `ExtensionTestHarness.spawn` isolate are not visible on the test isolate's
/// original instance. Use [createTestDependencies] for direct Tier 1 unit tests
/// of service methods, or forward state back over a `SendPort` / RPC when
/// testing across isolates.
ExtensionDependencies createTestDependencies({ExtensionFileSystem? fileSystem}) {
  return ExtensionDependencies(fileSystem: fileSystem ?? MemoryExtensionFileSystem());
}

/// Hermetic in-memory implementation of [ExtensionFileSystem] for unit testing.
final class MemoryExtensionFileSystem implements ExtensionFileSystem {
  MemoryExtensionFileSystem() {
    _directories.add('/');
  }

  final _directories = <String>{};
  final _files = <String, Uint8List>{};

  @override
  ExtensionDirectory directory(Uri uri) => _MemoryExtensionDirectory(this, _normalizeDirPath(uri));

  @override
  ExtensionFile file(Uri uri) => _MemoryExtensionFile(this, _normalizeFilePath(uri));

  static String _normalizeDirPath(Uri uri) {
    final String rawPath = uri.isScheme('file') ? uri.toFilePath(windows: false) : uri.path;
    final String normalized = _collapseSegments(rawPath);
    return normalized.endsWith('/') ? normalized : '$normalized/';
  }

  static String _normalizeFilePath(Uri uri) {
    final String rawPath = uri.isScheme('file') ? uri.toFilePath(windows: false) : uri.path;
    final String normalized = _collapseSegments(rawPath);
    if (normalized != '/' && normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _collapseSegments(String rawPath) {
    final List<String> parts = rawPath.replaceAll(r'\', '/').split('/');
    final stack = <String>[];
    for (final part in parts) {
      if (part.isEmpty || part == '.') {
        continue;
      }
      if (part == '..') {
        if (stack.isNotEmpty) {
          stack.removeLast();
        }
      } else {
        stack.add(part);
      }
    }
    return '/${stack.join('/')}';
  }

  static String _parentDirOf(String path) {
    final String trimmed = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    final int lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '/';
    }
    return '${trimmed.substring(0, lastSlash)}/';
  }

  void _createDir(String dirPath, {required bool recursive}) {
    if (_directories.contains(dirPath)) {
      return;
    }
    final String parent = _parentDirOf(dirPath);
    if (!recursive && !_directories.contains(parent)) {
      throw FileSystemException('Creation failed, parent directory does not exist', dirPath);
    }
    final List<String> segments = dirPath.split('/').where((String s) => s.isNotEmpty).toList();
    var current = '/';
    _directories.add(current);
    for (final segment in segments) {
      current = '$current$segment/';
      _directories.add(current);
    }
  }

  void _deleteDir(String dirPath, {required bool recursive}) {
    if (!_directories.contains(dirPath)) {
      throw FileSystemException('Deletion failed, directory does not exist', dirPath);
    }
    final bool hasChildDirs = _directories.any((String d) => d != dirPath && d.startsWith(dirPath));
    final bool hasChildFiles = _files.keys.any((String f) => f.startsWith(dirPath));
    if (!recursive && (hasChildDirs || hasChildFiles)) {
      throw FileSystemException('Directory is not empty', dirPath);
    }
    _directories.removeWhere((String d) => d == dirPath || d.startsWith(dirPath));
    _files.removeWhere((String f, Uint8List _) => f.startsWith(dirPath));
  }
}

final class _MemoryExtensionDirectory implements ExtensionDirectory {
  const _MemoryExtensionDirectory(this._fs, this._dirPath);

  final MemoryExtensionFileSystem _fs;
  final String _dirPath;

  @override
  Uri get uri => Uri(scheme: 'file', path: _dirPath);

  @override
  String get path => _dirPath.length > 1 && _dirPath.endsWith('/')
      ? _dirPath.substring(0, _dirPath.length - 1)
      : _dirPath;

  @override
  bool existsSync() => _fs._directories.contains(_dirPath);

  @override
  void createSync({bool recursive = false}) => _fs._createDir(_dirPath, recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async => deleteSync(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) => _fs._deleteDir(_dirPath, recursive: recursive);

  @override
  ExtensionDirectory childDirectory(String name) => _fs.directory(uri.resolve('$name/'));

  @override
  ExtensionFile childFile(String name) => _fs.file(uri.resolve(name));
}

final class _MemoryExtensionFile implements ExtensionFile {
  const _MemoryExtensionFile(this._fs, this._filePath);

  final MemoryExtensionFileSystem _fs;
  final String _filePath;

  @override
  Uri get uri => Uri(scheme: 'file', path: _filePath);

  @override
  String get path => _filePath;

  @override
  bool existsSync() => _fs._files.containsKey(_filePath);

  @override
  void createSync({bool recursive = false}) {
    if (existsSync()) {
      return;
    }
    final String parent = MemoryExtensionFileSystem._parentDirOf(_filePath);
    if (recursive) {
      _fs._createDir(parent, recursive: true);
    } else if (!_fs._directories.contains(parent)) {
      throw FileSystemException('Cannot create file, parent directory does not exist', _filePath);
    }
    _fs._files[_filePath] = Uint8List(0);
  }

  @override
  Future<void> delete({bool recursive = false}) async => deleteSync(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) {
    if (!_fs._files.containsKey(_filePath)) {
      throw FileSystemException('Cannot delete file, path does not exist', _filePath);
    }
    _fs._files.remove(_filePath);
  }

  @override
  String readAsStringSync() => utf8.decode(readAsBytesSync());

  @override
  void writeAsStringSync(String contents) => writeAsBytesSync(utf8.encode(contents));

  @override
  List<int> readAsBytesSync() {
    final Uint8List? bytes = _fs._files[_filePath];
    if (bytes == null) {
      throw FileSystemException('Cannot open file, path does not exist', _filePath);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  void writeAsBytesSync(List<int> bytes) {
    final String parent = MemoryExtensionFileSystem._parentDirOf(_filePath);
    if (!_fs._directories.contains(parent)) {
      throw FileSystemException('Cannot open file, parent directory does not exist', _filePath);
    }
    _fs._files[_filePath] = Uint8List.fromList(bytes);
  }
}
