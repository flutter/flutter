// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path/path.dart' as path; // flutter_ignore: package_path_import

bool _isDangerousDirectory(String dirPath) {
  final String canonical = path.canonicalize(dirPath);

  // Check if it is root
  if (canonical == '/' || canonical == r'C:\' || (io.Platform.isWindows && canonical.length <= 3)) {
    return true;
  }

  // Check if it is home or parent of home
  final String? home = io.Platform.environment['HOME'] ?? io.Platform.environment['USERPROFILE'];
  if (home != null) {
    final String canonicalHome = path.canonicalize(home);
    final String canonicalHomeParent = path.dirname(canonicalHome);
    if (canonical == canonicalHome || canonical == canonicalHomeParent) {
      return true;
    }
    // Check if it is Desktop
    final String desktop = path.join(canonicalHome, 'Desktop');
    final String canonicalDesktop = path.canonicalize(desktop);
    if (canonical == canonicalDesktop) {
      return true;
    }
  }

  return false;
}

bool _isAllowedPath(String entityPath) {
  final String canonicalEntity = path.canonicalize(entityPath);

  // Allow system temp
  String canonicalTemp;
  final io.IOOverrides? currentOverrides = io.IOOverrides.current;
  if (currentOverrides is FSGuardIOOverrides) {
    canonicalTemp = currentOverrides._canonicalSystemTemp;
  } else {
    canonicalTemp = path.canonicalize(io.Directory.systemTemp.path);
  }

  if (path.isWithin(canonicalTemp, canonicalEntity) || canonicalEntity == canonicalTemp) {
    return true;
  }

  // Allow modifications inside the Flutter installation root itself
  final String? flutterRoot = io.Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final String canonicalRoot = path.canonicalize(flutterRoot);
    if (!_isDangerousDirectory(canonicalRoot)) {
      if (path.isWithin(canonicalRoot, canonicalEntity) || canonicalEntity == canonicalRoot) {
        return true;
      }
    }
  }

  // Allow modifications inside the directory specified by FLUTTER_TEST_OUTPUTS_DIR
  final String? testOutputsDir = io.Platform.environment['FLUTTER_TEST_OUTPUTS_DIR'];
  if (testOutputsDir != null) {
    final String canonicalOutputs = path.canonicalize(testOutputsDir);
    if (!_isDangerousDirectory(canonicalOutputs)) {
      if (path.isWithin(canonicalOutputs, canonicalEntity) || canonicalEntity == canonicalOutputs) {
        return true;
      }
    }
  }

  return false;
}

bool _isGuardDisabled() {
  return io.Platform.environment['FLUTTER_TEST_DISABLE_FS_GUARD'] == 'true';
}

void _checkPath(String targetPath, String entityType, String operation) {
  if (_isGuardDisabled()) {
    return;
  }
  if (!_isAllowedPath(targetPath)) {
    throw io.FileSystemException(
      'Test attempted to $operation $entityType outside of temp directory: $targetPath. '
      'This check prevents tests from causing data loss or modifying non-test data on the system. '
      'To bypass this safety check during local debugging (e.g., to output logs outside the temp directory), '
      'set the environment variable FLUTTER_TEST_DISABLE_FS_GUARD=true in your shell or IDE.',
      targetPath,
    );
  }
}

/// A wrapper around [io.File] that prevents modifying operations on paths outside
/// of the system temporary directory during test execution.
class GuardedFile implements io.File {
  GuardedFile(this._delegate);

  final io.File _delegate;

  void _checkModify() {
    _checkPath(_delegate.path, 'file', 'modify');
  }

  @override
  String get path => _delegate.path;

  @override
  Uri get uri => _delegate.uri;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  Future<io.FileStat> stat() => _delegate.stat();

  @override
  io.FileStat statSync() => _delegate.statSync();

  @override
  Future<String> resolveSymbolicLinks() => _delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => _delegate.resolveSymbolicLinksSync();

  @override
  io.Directory get parent => GuardedDirectory(_delegate.parent);

  @override
  io.File get absolute => GuardedFile(_delegate.absolute);

  @override
  bool get isAbsolute => _delegate.isAbsolute;

  @override
  Future<int> length() => _delegate.length();

  @override
  int lengthSync() => _delegate.lengthSync();

  @override
  Future<DateTime> lastAccessed() => _delegate.lastAccessed();

  @override
  DateTime lastAccessedSync() => _delegate.lastAccessedSync();

  @override
  Future<DateTime> lastModified() => _delegate.lastModified();

  @override
  DateTime lastModifiedSync() => _delegate.lastModifiedSync();

  @override
  Stream<List<int>> openRead([int? start, int? end]) => _delegate.openRead(start, end);

  @override
  Future<Uint8List> readAsBytes() => _delegate.readAsBytes();

  @override
  Uint8List readAsBytesSync() => _delegate.readAsBytesSync();

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _delegate.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _delegate.readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      _delegate.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      _delegate.readAsLinesSync(encoding: encoding);

  @override
  Stream<io.FileSystemEvent> watch({int events = io.FileSystemEvent.all, bool recursive = false}) =>
      _delegate.watch(events: events, recursive: recursive);

  @override
  Future<io.File> create({bool recursive = false, bool exclusive = false}) {
    _checkModify();
    return _delegate.create(recursive: recursive, exclusive: exclusive).then((f) => GuardedFile(f));
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    _checkModify();
    _delegate.createSync(recursive: recursive, exclusive: exclusive);
  }

  @override
  Future<io.File> rename(String newPath) {
    _checkModify();
    _checkPath(newPath, 'file', 'rename');
    return _delegate.rename(newPath).then(GuardedFile.new);
  }

  @override
  io.File renameSync(String newPath) {
    _checkModify();
    _checkPath(newPath, 'file', 'rename');
    return GuardedFile(_delegate.renameSync(newPath));
  }

  @override
  Future<io.FileSystemEntity> delete({bool recursive = false}) {
    _checkModify();
    return _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) {
    _checkModify();
    _delegate.deleteSync(recursive: recursive);
  }

  @override
  Future<io.File> copy(String newPath) {
    _checkPath(newPath, 'file', 'copy');
    return _delegate.copy(newPath).then(GuardedFile.new);
  }

  @override
  io.File copySync(String newPath) {
    _checkPath(newPath, 'file', 'copy');
    return GuardedFile(_delegate.copySync(newPath));
  }

  @override
  Future<void> setLastAccessed(DateTime time) {
    _checkModify();
    return _delegate.setLastAccessed(time);
  }

  @override
  void setLastAccessedSync(DateTime time) {
    _checkModify();
    _delegate.setLastAccessedSync(time);
  }

  @override
  Future<void> setLastModified(DateTime time) {
    _checkModify();
    return _delegate.setLastModified(time);
  }

  @override
  void setLastModifiedSync(DateTime time) {
    _checkModify();
    _delegate.setLastModifiedSync(time);
  }

  @override
  Future<io.RandomAccessFile> open({io.FileMode mode = io.FileMode.read}) {
    if (mode != io.FileMode.read) {
      _checkModify();
    }
    return _delegate.open(mode: mode);
  }

  @override
  io.RandomAccessFile openSync({io.FileMode mode = io.FileMode.read}) {
    if (mode != io.FileMode.read) {
      _checkModify();
    }
    return _delegate.openSync(mode: mode);
  }

  @override
  io.IOSink openWrite({io.FileMode mode = io.FileMode.write, Encoding encoding = utf8}) {
    _checkModify();
    return _delegate.openWrite(mode: mode, encoding: encoding);
  }

  @override
  Future<io.File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    _checkModify();
    return _delegate.writeAsBytes(bytes, mode: mode, flush: flush).then((f) => GuardedFile(f));
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    _checkModify();
    _delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);
  }

  @override
  Future<io.File> writeAsString(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _checkModify();
    return _delegate
        .writeAsString(contents, mode: mode, encoding: encoding, flush: flush)
        .then((f) => GuardedFile(f));
  }

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _checkModify();
    _delegate.writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
  }
}

/// A wrapper around [io.Directory] that prevents modifying operations on paths outside
/// of the system temporary directory during test execution.
class GuardedDirectory implements io.Directory {
  GuardedDirectory(this._delegate);

  final io.Directory _delegate;

  void _checkModify() {
    _checkPath(_delegate.path, 'directory', 'modify');
  }

  @override
  String get path => _delegate.path;

  @override
  Uri get uri => _delegate.uri;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  Future<io.FileStat> stat() => _delegate.stat();

  @override
  io.FileStat statSync() => _delegate.statSync();

  @override
  Future<String> resolveSymbolicLinks() => _delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => _delegate.resolveSymbolicLinksSync();

  @override
  io.Directory get parent => GuardedDirectory(_delegate.parent);

  @override
  io.Directory get absolute => GuardedDirectory(_delegate.absolute);

  @override
  bool get isAbsolute => _delegate.isAbsolute;

  @override
  Stream<io.FileSystemEvent> watch({int events = io.FileSystemEvent.all, bool recursive = false}) =>
      _delegate.watch(events: events, recursive: recursive);

  @override
  Stream<io.FileSystemEntity> list({bool recursive = false, bool followLinks = true}) {
    return _delegate.list(recursive: recursive, followLinks: followLinks).map((entity) {
      if (entity is io.File) {
        return GuardedFile(entity);
      }
      if (entity is io.Directory) {
        return GuardedDirectory(entity);
      }
      if (entity is io.Link) {
        return GuardedLink(entity);
      }
      return entity;
    });
  }

  @override
  List<io.FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) {
    return _delegate.listSync(recursive: recursive, followLinks: followLinks).map((entity) {
      if (entity is io.File) {
        return GuardedFile(entity);
      }
      if (entity is io.Directory) {
        return GuardedDirectory(entity);
      }
      if (entity is io.Link) {
        return GuardedLink(entity);
      }
      return entity;
    }).toList();
  }

  @override
  Future<io.Directory> create({bool recursive = false}) {
    _checkModify();
    return _delegate.create(recursive: recursive).then((d) => GuardedDirectory(d));
  }

  @override
  void createSync({bool recursive = false}) {
    _checkModify();
    _delegate.createSync(recursive: recursive);
  }

  @override
  Future<io.Directory> createTemp([String? prefix]) {
    _checkModify();
    return _delegate.createTemp(prefix).then((d) => GuardedDirectory(d));
  }

  @override
  io.Directory createTempSync([String? prefix]) {
    _checkModify();
    return GuardedDirectory(_delegate.createTempSync(prefix));
  }

  @override
  Future<io.Directory> rename(String newPath) {
    _checkModify();
    _checkPath(newPath, 'directory', 'rename');
    return _delegate.rename(newPath).then(GuardedDirectory.new);
  }

  @override
  io.Directory renameSync(String newPath) {
    _checkModify();
    _checkPath(newPath, 'directory', 'rename');
    return GuardedDirectory(_delegate.renameSync(newPath));
  }

  @override
  Future<io.FileSystemEntity> delete({bool recursive = false}) {
    _checkModify();
    return _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) {
    _checkModify();
    _delegate.deleteSync(recursive: recursive);
  }
}

/// A wrapper around [io.Link] that prevents modifying operations on paths outside
/// of the system temporary directory during test execution.
class GuardedLink implements io.Link {
  GuardedLink(this._delegate);

  final io.Link _delegate;

  void _checkModify() {
    _checkPath(_delegate.path, 'link', 'modify');
  }

  @override
  String get path => _delegate.path;

  @override
  Uri get uri => _delegate.uri;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  Future<io.FileStat> stat() => _delegate.stat();

  @override
  io.FileStat statSync() => _delegate.statSync();

  @override
  Future<String> resolveSymbolicLinks() => _delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => _delegate.resolveSymbolicLinksSync();

  @override
  io.Directory get parent => GuardedDirectory(_delegate.parent);

  @override
  io.Link get absolute => GuardedLink(_delegate.absolute);

  @override
  bool get isAbsolute => _delegate.isAbsolute;

  @override
  Stream<io.FileSystemEvent> watch({int events = io.FileSystemEvent.all, bool recursive = false}) =>
      _delegate.watch(events: events, recursive: recursive);

  @override
  Future<io.Link> create(String target, {bool recursive = false}) {
    _checkModify();
    return _delegate.create(target, recursive: recursive).then((l) => GuardedLink(l));
  }

  @override
  void createSync(String target, {bool recursive = false}) {
    _checkModify();
    _delegate.createSync(target, recursive: recursive);
  }

  @override
  Future<io.Link> update(String target) {
    _checkModify();
    return _delegate.update(target).then((l) => GuardedLink(l));
  }

  @override
  void updateSync(String target) {
    _checkModify();
    _delegate.updateSync(target);
  }

  @override
  Future<String> target() => _delegate.target();

  @override
  String targetSync() => _delegate.targetSync();

  @override
  Future<io.Link> rename(String newPath) {
    _checkModify();
    _checkPath(newPath, 'link', 'rename');
    return _delegate.rename(newPath).then(GuardedLink.new);
  }

  @override
  io.Link renameSync(String newPath) {
    _checkModify();
    _checkPath(newPath, 'link', 'rename');
    return GuardedLink(_delegate.renameSync(newPath));
  }

  @override
  Future<io.FileSystemEntity> delete({bool recursive = false}) {
    _checkModify();
    return _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) {
    _checkModify();
    _delegate.deleteSync(recursive: recursive);
  }
}

/// A custom [io.IOOverrides] class that ensures all file system operations performed
/// by tests are isolated to the system temporary directory by returning guarded
/// wrappers ([GuardedFile], [GuardedDirectory], [GuardedLink]).
final class FSGuardIOOverrides extends io.IOOverrides {
  FSGuardIOOverrides() : _parent = io.IOOverrides.current;

  final io.IOOverrides? _parent;

  late final String _canonicalSystemTemp = () {
    final io.Directory rawTemp = _parent != null
        ? _parent.getSystemTempDirectory()
        : super.getSystemTempDirectory();
    try {
      return path.canonicalize(rawTemp.resolveSymbolicLinksSync());
    } on Object catch (_) {
      return path.canonicalize(rawTemp.path);
    }
  }();

  @override
  io.File createFile(String path) {
    final io.File rawFile = _parent != null ? _parent.createFile(path) : super.createFile(path);
    return GuardedFile(rawFile);
  }

  @override
  io.Directory createDirectory(String path) {
    final io.Directory rawDir = _parent != null
        ? _parent.createDirectory(path)
        : super.createDirectory(path);
    return GuardedDirectory(rawDir);
  }

  @override
  io.Link createLink(String path) {
    final io.Link rawLink = _parent != null ? _parent.createLink(path) : super.createLink(path);
    return GuardedLink(rawLink);
  }

  @override
  io.Directory getCurrentDirectory() {
    final io.Directory rawDir = _parent != null
        ? _parent.getCurrentDirectory()
        : super.getCurrentDirectory();
    return GuardedDirectory(rawDir);
  }

  @override
  io.Directory getSystemTempDirectory() {
    final io.Directory rawDir = _parent != null
        ? _parent.getSystemTempDirectory()
        : super.getSystemTempDirectory();
    return GuardedDirectory(rawDir);
  }

  @override
  void setCurrentDirectory(String path) {
    if (_parent != null) {
      _parent.setCurrentDirectory(path);
    } else {
      super.setCurrentDirectory(path);
    }
  }

  @override
  Stream<io.FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    return _parent != null
        ? _parent.fsWatch(path, events, recursive)
        : super.fsWatch(path, events, recursive);
  }

  @override
  bool fsWatchIsSupported() {
    return _parent != null ? _parent.fsWatchIsSupported() : super.fsWatchIsSupported();
  }

  @override
  Future<io.FileSystemEntityType> fseGetType(String path, bool followLinks) {
    return _parent != null
        ? _parent.fseGetType(path, followLinks)
        : super.fseGetType(path, followLinks);
  }

  @override
  io.FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    return _parent != null
        ? _parent.fseGetTypeSync(path, followLinks)
        : super.fseGetTypeSync(path, followLinks);
  }

  @override
  Future<bool> fseIdentical(String path1, String path2) {
    return _parent != null ? _parent.fseIdentical(path1, path2) : super.fseIdentical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    return _parent != null
        ? _parent.fseIdenticalSync(path1, path2)
        : super.fseIdenticalSync(path1, path2);
  }

  @override
  Future<io.FileStat> stat(String path) {
    return _parent != null ? _parent.stat(path) : super.stat(path);
  }

  @override
  io.FileStat statSync(String path) {
    return _parent != null ? _parent.statSync(path) : super.statSync(path);
  }
}
