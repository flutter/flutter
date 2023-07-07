// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/backends/memory/operations.dart';
import 'package:file/src/io.dart' as io;
import 'package:path/path.dart' as p;

import 'clock.dart';
import 'common.dart';
import 'memory_directory.dart';
import 'memory_file.dart';
import 'memory_file_stat.dart';
import 'memory_link.dart';
import 'node.dart';
import 'style.dart';
import 'utils.dart' as utils;

const String _thisDir = '.';
const String _parentDir = '..';

void _defaultOpHandle(String context, FileSystemOp operation) {}

/// An implementation of [FileSystem] that exists entirely in memory with an
/// internal representation loosely based on the Filesystem Hierarchy Standard.
///
/// [MemoryFileSystem] is suitable for mocking and tests, as well as for
/// caching or staging before writing or reading to a live system.
///
/// This implementation of the [FileSystem] interface does not directly use
/// any `dart:io` APIs; it merely uses the library's enum values and interfaces.
/// As such, it is suitable for use in the browser.
abstract class MemoryFileSystem implements StyleableFileSystem {
  /// Creates a new `MemoryFileSystem`.
  ///
  /// The file system will be empty, and the current directory will be the
  /// root directory.
  ///
  /// The clock will be a real-time clock; file modification times will
  /// reflect the real time as reported by the operating system.
  ///
  /// If [style] is specified, the file system will use the specified path
  /// style. The default is [FileSystemStyle.posix].
  factory MemoryFileSystem({
    FileSystemStyle style = FileSystemStyle.posix,
    void Function(String context, FileSystemOp operation) opHandle =
        _defaultOpHandle,
  }) =>
      _MemoryFileSystem(
        style: style,
        clock: const Clock.realTime(),
        opHandle: opHandle,
      );

  /// Creates a new `MemoryFileSystem` that has a fake clock.
  ///
  /// The file system will be empty, and the current directory will be the
  /// root directory.
  ///
  /// The clock will increase monotonically each time it is used, disconnected
  /// from any real-world clock.
  ///
  /// If [style] is specified, the file system will use the specified path
  /// style. The default is [FileSystemStyle.posix].
  factory MemoryFileSystem.test({
    FileSystemStyle style = FileSystemStyle.posix,
    void Function(String context, FileSystemOp operation) opHandle =
        _defaultOpHandle,
  }) =>
      _MemoryFileSystem(
        style: style,
        clock: Clock.monotonicTest(),
        opHandle: opHandle,
      );
}

/// Internal implementation of [MemoryFileSystem].
class _MemoryFileSystem extends FileSystem
    implements MemoryFileSystem, NodeBasedFileSystem {
  _MemoryFileSystem({
    this.style = FileSystemStyle.posix,
    required this.clock,
    this.opHandle = _defaultOpHandle,
  }) : _context = style.contextFor(style.root) {
    _root = RootNode(this);
  }

  RootNode? _root;
  String? _systemTemp;
  p.Context _context;

  @override
  final Function(String context, FileSystemOp operation) opHandle;

  @override
  final Clock clock;

  @override
  final FileSystemStyle style;

  @override
  RootNode? get root => _root;

  @override
  String get cwd => _context.current;

  @override
  Directory directory(dynamic path) => MemoryDirectory(this, getPath(path));

  @override
  File file(dynamic path) => MemoryFile(this, getPath(path));

  @override
  Link link(dynamic path) => MemoryLink(this, getPath(path));

  @override
  p.Context get path => _context;

  /// Gets the system temp directory. This directory will be created on-demand
  /// in the root of the file system. Once created, its location is fixed for
  /// the life of the process.
  @override
  Directory get systemTempDirectory {
    _systemTemp ??= directory(style.root).createTempSync('.tmp_').path;
    return directory(_systemTemp)..createSync();
  }

  @override
  Directory get currentDirectory => directory(cwd);

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

    value = directory(value).resolveSymbolicLinksSync();
    Node? node = findNode(value);
    checkExists(node, () => value);
    utils.checkIsDir(node!, () => value);
    assert(_context.isAbsolute(value));
    _context = style.contextFor(value);
  }

  @override
  Future<io.FileStat> stat(String path) async => statSync(path);

  @override
  io.FileStat statSync(String path) {
    try {
      return findNode(path)?.stat ?? MemoryFileStat.notFound;
    } on io.FileSystemException {
      return MemoryFileStat.notFound;
    }
  }

  @override
  Future<bool> identical(String path1, String path2) async =>
      identicalSync(path1, path2);

  @override
  bool identicalSync(String path1, String path2) {
    Node? node1 = findNode(path1);
    checkExists(node1, () => path1);
    Node? node2 = findNode(path2);
    checkExists(node2, () => path2);
    return node1 != null && node1 == node2;
  }

  @override
  bool get isWatchSupported => false;

  @override
  Future<io.FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async =>
      typeSync(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    Node? node;
    try {
      node = findNode(path, followTailLink: followLinks);
    } on io.FileSystemException {
      node = null;
    }
    if (node == null) {
      return io.FileSystemEntityType.notFound;
    }
    return node.type;
  }

  /// Gets the node backing for the current working directory. Note that this
  /// can return null if the directory has been deleted or moved from under our
  /// feet.
  DirectoryNode get _current => findNode(cwd) as DirectoryNode;

  @override
  Node? findNode(
    String path, {
    Node? reference,
    SegmentVisitor? segmentVisitor,
    bool visitLinks = false,
    List<String>? pathWithSymlinks,
    bool followTailLink = false,
  }) {
    if (_context.isAbsolute(path)) {
      reference = _root;
      path = path.substring(style.drive.length);
    } else {
      reference ??= _current;
    }

    List<String> parts = path.split(style.separator)
      ..removeWhere(utils.isEmpty);
    DirectoryNode? directory = reference?.directory;
    Node? child = directory;

    int finalSegment = parts.length - 1;
    for (int i = 0; i <= finalSegment; i++) {
      String basename = parts[i];
      assert(basename.isNotEmpty);

      switch (basename) {
        case _thisDir:
          child = directory;
          break;
        case _parentDir:
          child = directory?.parent;
          directory = directory?.parent;
          break;
        default:
          child = directory?.children[basename];
      }

      if (pathWithSymlinks != null) {
        pathWithSymlinks.add(basename);
      }

      // Generates a subpath for the current segment.
      String subpath() => parts.sublist(0, i + 1).join(_context.separator);

      if (utils.isLink(child) && (i < finalSegment || followTailLink)) {
        if (visitLinks || segmentVisitor == null) {
          if (segmentVisitor != null) {
            child =
                segmentVisitor(directory!, basename, child, i, finalSegment);
          }
          child = utils.resolveLinks(child as LinkNode, subpath,
              ledger: pathWithSymlinks);
        } else {
          child = utils.resolveLinks(
            child as LinkNode,
            subpath,
            ledger: pathWithSymlinks,
            tailVisitor: (DirectoryNode parent, String childName, Node? child) {
              return segmentVisitor(parent, childName, child, i, finalSegment);
            },
          );
        }
      } else if (segmentVisitor != null) {
        child = segmentVisitor(directory!, basename, child, i, finalSegment);
      }

      if (i < finalSegment) {
        checkExists(child, subpath);
        utils.checkIsDir(child!, subpath);
        directory = child as DirectoryNode;
      }
    }
    return child;
  }
}
