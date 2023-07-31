// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of file.src.backends.chroot;

const String _thisDir = '.';
const String _parentDir = '..';

/// File system that provides a view into _another_ [FileSystem] via a path.
///
/// This is similar in concept to the `chroot` operation in Linux operating
/// systems. Such a modified file system cannot name or access files outside of
/// the designated directory tree.
///
/// ## Example use:
/// ```dart
/// // Create a "file system" where the root directory is /tmp/some-dir.
/// var fs = ChrootFileSystem(existingFileSystem, '/tmp/some-dir');
/// ```
///
/// **Notes on usage**:
///
/// * This file system maintains its _own_ [currentDirectory], distinct from
///   that of the underlying file system, and new instances automatically start
///   at the root (i.e. `/`).
///
/// * This file system does _not_ leverage any underlying OS system calls (such
///   as `chroot` itself), so the developer needs to take care to not assume any
///   more of a secure environment than is actually provided. For instance, the
///   underlying system is available via the [delegate] - which underscores this
///   file system is intended to be a convenient abstraction, not a security
///   measure.
///
/// * This file system _necessarily_ carries certain performance overhead due
///   to the fact that symbolic links are resolved manually (not delegated).
class ChrootFileSystem extends FileSystem {
  /// Creates a new file system backed by [root] path in [delegate] file system.
  ///
  /// **NOTE**: [root] must be a _canonicalized_ path; see [p.canonicalize].
  ChrootFileSystem(this.delegate, this.root) {
    if (root != delegate.path.canonicalize(root)) {
      throw ArgumentError.value(root, 'root', 'Must be canonical path');
    }
    _cwd = _localRoot;
  }

  /// Underlying file system.
  final FileSystem delegate;

  /// Directory in [delegate] file system that is treated as the root here.
  final String root;

  String? _systemTemp;

  /// Path to the synthetic current working directory in this file system.
  late String _cwd;

  /// Gets the root path, as seen by entities in this file system.
  String get _localRoot => delegate.path.rootPrefix(root);

  @override
  Directory directory(dynamic path) => _ChrootDirectory(this, getPath(path));

  @override
  File file(dynamic path) => _ChrootFile(this, getPath(path));

  @override
  Link link(dynamic path) => _ChrootLink(this, getPath(path));

  @override
  p.Context get path => p.Context(style: delegate.path.style, current: _cwd);

  /// Gets the system temp directory. This directory will be created on-demand
  /// in the local root of the file system. Once created, its location is fixed
  /// for the life of the process.
  @override
  Directory get systemTempDirectory {
    _systemTemp ??= directory(_localRoot).createTempSync('.tmp_').path;
    return directory(_systemTemp)..createSync();
  }

  /// Creates a directory object pointing to the current working directory.
  ///
  /// **NOTE** This does _not_ proxy to the underlying file system's current
  /// directory in any way; the state of this file system's current directory
  /// is local to this file system.
  @override
  Directory get currentDirectory => directory(_cwd);

  /// Sets the current working directory to the specified [path].
  ///
  /// **NOTE** This does _not_ proxy to the underlying file system's current
  /// directory in any way; the state of this file system's current directory
  /// is local to this file system.
  /// Gets the path context for this file system given the current working dir.

  @override
  set currentDirectory(dynamic path) {
    String value;
    if (path is io.Directory) {
      value = path.path;
    } else if (path is String) {
      value = path;
    } else {
      throw ArgumentError('Invalid type for "path": ${path?.runtimeType}');
    }

    value = _resolve(value, notFound: _NotFoundBehavior.throwError);
    String realPath = _real(value, resolve: false);
    switch (delegate.typeSync(realPath, followLinks: false)) {
      case FileSystemEntityType.directory:
        break;
      case FileSystemEntityType.notFound:
        throw common.noSuchFileOrDirectory(path as String);
      default:
        throw common.notADirectory(path as String);
    }
    assert(() {
      p.Context ctx = delegate.path;
      return ctx.isAbsolute(value) && value == ctx.canonicalize(value);
    }());
    _cwd = value;
  }

  @override
  Future<FileStat> stat(String path) {
    try {
      path = _resolve(path);
    } on FileSystemException {
      return Future<FileStat>.value(const _NotFoundFileStat());
    }
    return delegate.stat(_real(path, resolve: false));
  }

  @override
  FileStat statSync(String path) {
    try {
      path = _resolve(path);
    } on FileSystemException {
      return const _NotFoundFileStat();
    }
    return delegate.statSync(_real(path, resolve: false));
  }

  @override
  Future<bool> identical(String path1, String path2) => delegate.identical(
        _real(_resolve(path1, followLinks: false)),
        _real(_resolve(path2, followLinks: false)),
      );

  @override
  bool identicalSync(String path1, String path2) => delegate.identicalSync(
        _real(_resolve(path1, followLinks: false)),
        _real(_resolve(path2, followLinks: false)),
      );

  @override
  bool get isWatchSupported => false;

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true}) {
    String realPath;
    try {
      realPath = _real(path, followLinks: followLinks);
    } on FileSystemException {
      return Future<FileSystemEntityType>.value(FileSystemEntityType.notFound);
    }
    return delegate.type(realPath, followLinks: false);
  }

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    String realPath;
    try {
      realPath = _real(path, followLinks: followLinks);
    } on FileSystemException {
      return FileSystemEntityType.notFound;
    }
    return delegate.typeSync(realPath, followLinks: false);
  }

  /// Converts a [realPath] in the underlying file system to a local path here.
  ///
  /// If [relative] is set to `true`, then the resulting path will be relative
  /// to [currentDirectory], otherwise the resulting path will be absolute.
  ///
  /// An exception is thrown if the path is outside of this file system's root
  /// directory unless [keepInJail] is true, in which case this will instead
  /// return the path of the root of this file system.
  String _local(
    String realPath, {
    bool relative = false,
    bool keepInJail = false,
  }) {
    assert(path.isAbsolute(realPath));
    if (!realPath.startsWith(root)) {
      if (keepInJail) {
        return _localRoot;
      }
      throw _ChrootJailException();
    }
    // TODO(tvolkert): See if _context.relative() works here
    String result = realPath.substring(root.length);
    if (result.isEmpty) {
      result = _localRoot;
    }
    if (relative) {
      assert(result.startsWith(_cwd));
      result = path.relative(result, from: _cwd);
    }
    return result;
  }

  /// Converts [localPath] in this file system to the real path in the delegate.
  ///
  /// The returned path will always be absolute.
  ///
  /// If [resolve] is true, symbolic links will be resolved in the local file
  /// system _before_ converting the path to the delegate file system's
  /// namespace, and if the tail element of the path is a symbolic link, it will
  /// only be resolved if [followLinks] is true (where-as symbolic links found
  /// in the middle of the path will always be resolved).
  String _real(
    String localPath, {
    bool resolve = true,
    bool followLinks = false,
  }) {
    if (resolve) {
      localPath = _resolve(localPath, followLinks: followLinks);
    } else {
      assert(path.isAbsolute(localPath));
    }
    return '$root$localPath';
  }

  /// Resolves symbolic links on [path] and returns the resulting resolved path.
  ///
  /// The return value will always be an absolute path; if [path] is relative
  /// it will be interpreted relative to [from] (or [currentDirectory] if
  /// `null`).
  ///
  /// If the tail element is a symbolic link, then the link will be resolved
  /// only if [followLinks] is `true`. Symbolic links found in the middle of
  /// the path will always be resolved.
  ///
  /// If the path cannot be resolved, and [notFound] is:
  ///   - [_NotFoundBehavior.throwError]: a [FileSystemException] is thrown.
  ///   - [_NotFoundBehavior.mkdir]: the path will be created as needed.
  ///   - [_NotFoundBehavior.allowAtTail]: a [FileSystemException] is thrown,
  ///     unless only the *tail* path element cannot be resolved, in which case
  ///     the resolution will halt at the tail element, and the partially
  ///     resolved path will be returned.
  ///   - [_NotFoundBehavior.allow] (the default), the resolution will halt and
  ///     the partially resolved path will be returned.
  String _resolve(
    String path, {
    String? from,
    bool followLinks = true,
    _NotFoundBehavior notFound = _NotFoundBehavior.allow,
  }) {
    if (path.isEmpty) {
      throw common.noSuchFileOrDirectory(path);
    }

    p.Context ctx = this.path;
    String root = _localRoot;
    List<String> parts, ledger;
    if (ctx.isAbsolute(path)) {
      parts = ctx.split(path).sublist(1);
      ledger = <String>[];
    } else {
      from ??= _cwd;
      assert(ctx.isAbsolute(from));
      parts = ctx.split(path);
      ledger = ctx.split(from).sublist(1);
    }

    String getCurrentPath() => root + ctx.joinAll(ledger);
    Set<String> breadcrumbs = <String>{};
    while (parts.isNotEmpty) {
      String segment = parts.removeAt(0);
      if (segment == _thisDir) {
        continue;
      } else if (segment == _parentDir) {
        if (ledger.isNotEmpty) {
          ledger.removeLast();
        }
        continue;
      }

      ledger.add(segment);
      String currentPath = getCurrentPath();
      String realPath = _real(currentPath, resolve: false);

      switch (delegate.typeSync(realPath, followLinks: false)) {
        case FileSystemEntityType.directory:
          breadcrumbs.clear();
          break;
        case FileSystemEntityType.file:
          breadcrumbs.clear();
          if (parts.isNotEmpty) {
            throw common.notADirectory(currentPath);
          }
          break;
        case FileSystemEntityType.notFound:
          String returnEarly() {
            ledger.addAll(parts);
            return getCurrentPath();
          }

          switch (notFound) {
            case _NotFoundBehavior.mkdir:
              if (parts.isNotEmpty) {
                delegate.directory(realPath).createSync();
              }
              break;
            case _NotFoundBehavior.allow:
              return returnEarly();
            case _NotFoundBehavior.allowAtTail:
              if (parts.isEmpty) {
                return returnEarly();
              }
              throw common.noSuchFileOrDirectory(path);
            case _NotFoundBehavior.throwError:
              throw common.noSuchFileOrDirectory(path);
          }
          break;
        case FileSystemEntityType.link:
          if (parts.isEmpty && !followLinks) {
            break;
          }
          if (!breadcrumbs.add(currentPath)) {
            throw common.tooManyLevelsOfSymbolicLinks(path);
          }
          String target = delegate.link(realPath).targetSync();
          if (ctx.isAbsolute(target)) {
            ledger.clear();
            parts.insertAll(0, ctx.split(target).sublist(1));
          } else {
            ledger.removeLast();
            parts.insertAll(0, ctx.split(target));
          }
          break;
        default:
          throw AssertionError();
      }
    }

    return getCurrentPath();
  }
}

/// Thrown when a path is encountered that exists outside of the root path.
class _ChrootJailException implements IOException {}

/// What to do when `NOT_FOUND` paths are encountered while resolving.
enum _NotFoundBehavior {
  allow,
  allowAtTail,
  throwError,
  mkdir,
}

/// A [FileStat] representing a `NOT_FOUND` entity.
class _NotFoundFileStat implements FileStat {
  const _NotFoundFileStat();

  static final DateTime _empty = DateTime(0);

  @override
  DateTime get changed => _empty;

  @override
  DateTime get modified => _empty;

  @override
  DateTime get accessed => _empty;

  @override
  FileSystemEntityType get type => FileSystemEntityType.notFound;

  @override
  int get mode => 0;

  @override
  int get size => -1;

  @override
  String modeString() => '---------';
}
