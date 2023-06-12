// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A file system that forwards all methods and properties to a delegate.
abstract class ForwardingFileSystem extends FileSystem {
  /// Creates a new [ForwardingFileSystem] that forwards all methods and
  /// properties to the specified [delegate].
  ForwardingFileSystem(this.delegate);

  /// The file system to which this file system will forward all activity.
  @protected
  final FileSystem delegate;

  @override
  Directory directory(dynamic path) => delegate.directory(path);

  @override
  File file(dynamic path) => delegate.file(path);

  @override
  Link link(dynamic path) => delegate.link(path);

  @override
  p.Context get path => delegate.path;

  @override
  Directory get systemTempDirectory => delegate.systemTempDirectory;

  @override
  Directory get currentDirectory => delegate.currentDirectory;

  @override
  set currentDirectory(dynamic path) => delegate.currentDirectory = path;

  @override
  Future<io.FileStat> stat(String path) => delegate.stat(path);

  @override
  io.FileStat statSync(String path) => delegate.statSync(path);

  @override
  Future<bool> identical(String path1, String path2) =>
      delegate.identical(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      delegate.identicalSync(path1, path2);

  @override
  bool get isWatchSupported => delegate.isWatchSupported;

  @override
  Future<io.FileSystemEntityType> type(String path,
          {bool followLinks = true}) =>
      delegate.type(path, followLinks: followLinks);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks = true}) =>
      delegate.typeSync(path, followLinks: followLinks);
}
