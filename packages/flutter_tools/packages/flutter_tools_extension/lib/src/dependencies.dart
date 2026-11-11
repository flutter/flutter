// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

/// Dependency container injected into tool extension services to isolate host
/// file system side effects.
@immutable
final class ExtensionDependencies {
  /// Creates an [ExtensionDependencies] container with explicit dependencies.
  const ExtensionDependencies({required this.fileSystem});

  /// Creates an [ExtensionDependencies] container wired to the host file system.
  const ExtensionDependencies.bootstrap() : fileSystem = const LocalExtensionFileSystem();

  /// File system abstraction used for reading and writing files and directories.
  final ExtensionFileSystem fileSystem;
}

/// Abstract file system interface for tool extensions.
abstract interface class ExtensionFileSystem {
  /// Returns an [ExtensionDirectory] handle for [uri].
  ExtensionDirectory directory(Uri uri);

  /// Returns an [ExtensionFile] handle for [uri].
  ExtensionFile file(Uri uri);
}

/// Abstract directory handle for tool extensions.
abstract interface class ExtensionDirectory {
  /// The normalized `file://` URI of this directory (always ending with `/`).
  Uri get uri;

  /// The file system path of this directory.
  String get path;

  /// Whether this directory exists on the file system.
  bool existsSync();

  /// Creates this directory synchronously.
  void createSync({bool recursive = false});

  /// Deletes this directory asynchronously.
  Future<void> delete({bool recursive = false});

  /// Deletes this directory synchronously.
  void deleteSync({bool recursive = false});

  /// Returns a child [ExtensionDirectory] with relative [name].
  ExtensionDirectory childDirectory(String name);

  /// Returns a child [ExtensionFile] with relative [name].
  ExtensionFile childFile(String name);
}

/// Abstract file handle for tool extensions.
abstract interface class ExtensionFile {
  /// The `file://` URI of this file.
  Uri get uri;

  /// The file system path of this file.
  String get path;

  /// Whether this file exists on the file system.
  bool existsSync();

  /// Creates this file synchronously.
  void createSync({bool recursive = false});

  /// Deletes this file asynchronously.
  Future<void> delete({bool recursive = false});

  /// Deletes this file synchronously.
  void deleteSync({bool recursive = false});

  /// Reads the entire file contents as a UTF-8 string.
  String readAsStringSync();

  /// Writes [contents] to this file as a UTF-8 string.
  void writeAsStringSync(String contents);

  /// Reads the entire file contents as bytes.
  List<int> readAsBytesSync();

  /// Writes [bytes] to this file.
  void writeAsBytesSync(List<int> bytes);
}

/// Host `dart:io`-backed implementation of [ExtensionFileSystem].
final class LocalExtensionFileSystem implements ExtensionFileSystem {
  const LocalExtensionFileSystem();

  @override
  ExtensionDirectory directory(Uri uri) => _LocalExtensionDirectory(Directory.fromUri(uri));

  @override
  ExtensionFile file(Uri uri) => _LocalExtensionFile(File.fromUri(uri));
}

final class _LocalExtensionDirectory implements ExtensionDirectory {
  const _LocalExtensionDirectory(this._delegate);

  final Directory _delegate;

  @override
  Uri get uri => _delegate.uri;

  @override
  String get path => _delegate.path;

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  void createSync({bool recursive = false}) => _delegate.createSync(recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async {
    await _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) => _delegate.deleteSync(recursive: recursive);

  @override
  ExtensionDirectory childDirectory(String name) =>
      _LocalExtensionDirectory(Directory.fromUri(_delegate.uri.resolve('$name/')));

  @override
  ExtensionFile childFile(String name) =>
      _LocalExtensionFile(File.fromUri(_delegate.uri.resolve(name)));
}

final class _LocalExtensionFile implements ExtensionFile {
  const _LocalExtensionFile(this._delegate);

  final File _delegate;

  @override
  Uri get uri => _delegate.uri;

  @override
  String get path => _delegate.path;

  @override
  bool existsSync() => _delegate.existsSync();

  @override
  void createSync({bool recursive = false}) => _delegate.createSync(recursive: recursive);

  @override
  Future<void> delete({bool recursive = false}) async {
    await _delegate.delete(recursive: recursive);
  }

  @override
  void deleteSync({bool recursive = false}) => _delegate.deleteSync(recursive: recursive);

  @override
  String readAsStringSync() => _delegate.readAsStringSync();

  @override
  void writeAsStringSync(String contents) => _delegate.writeAsStringSync(contents);

  @override
  List<int> readAsBytesSync() => _delegate.readAsBytesSync();

  @override
  void writeAsBytesSync(List<int> bytes) => _delegate.writeAsBytesSync(bytes);
}
