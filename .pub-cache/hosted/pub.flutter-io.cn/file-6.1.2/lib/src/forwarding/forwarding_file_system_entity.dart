// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// A file system entity that forwards all methods and properties to a delegate.
abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> implements FileSystemEntity {
  /// The entity to which this entity will forward all methods and properties.
  @protected
  D get delegate;

  /// Creates a new entity with the same file system and same type as this
  /// entity but backed by the specified delegate.
  @protected
  T wrap(D delegate);

  /// Creates a new directory with the same file system as this entity and
  /// backed by the specified delegate.
  @protected
  Directory wrapDirectory(io.Directory delegate);

  /// Creates a new file with the same file system as this entity and
  /// backed by the specified delegate.
  @protected
  File wrapFile(io.File delegate);

  /// Creates a new link with the same file system as this entity and
  /// backed by the specified delegate.
  @protected
  Link wrapLink(io.Link delegate);

  @override
  Uri get uri => delegate.uri;

  @override
  Future<bool> exists() => delegate.exists();

  @override
  bool existsSync() => delegate.existsSync();

  @override
  Future<T> rename(String newPath) async =>
      wrap(await delegate.rename(newPath) as D);

  @override
  T renameSync(String newPath) => wrap(delegate.renameSync(newPath) as D);

  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => delegate.resolveSymbolicLinksSync();

  @override
  Future<io.FileStat> stat() => delegate.stat();

  @override
  io.FileStat statSync() => delegate.statSync();

  @override
  Future<T> delete({bool recursive = false}) async =>
      wrap(await delegate.delete(recursive: recursive) as D);

  @override
  void deleteSync({bool recursive = false}) =>
      delegate.deleteSync(recursive: recursive);

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      delegate.watch(events: events, recursive: recursive);

  @override
  bool get isAbsolute => delegate.isAbsolute;

  @override
  T get absolute => wrap(delegate.absolute as D);

  @override
  Directory get parent => wrapDirectory(delegate.parent);

  @override
  String get path => delegate.path;

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  String get dirname => fileSystem.path.dirname(path);
}
