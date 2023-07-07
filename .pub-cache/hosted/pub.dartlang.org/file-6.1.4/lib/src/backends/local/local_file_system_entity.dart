// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'local_directory.dart';
import 'local_file.dart';
import 'local_link.dart';

/// [FileSystemEntity] implementation that forwards all calls to `dart:io`.
abstract class LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {
  /// Instantiates a new [LocalFileSystemEntity] tied to the specified file
  /// system and delegating to the specified [delegate].
  LocalFileSystemEntity(this.fileSystem, this.delegate);

  @override
  final FileSystem fileSystem;

  @override
  final D delegate;

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      LocalDirectory(fileSystem, delegate);

  @override
  File wrapFile(io.File delegate) => LocalFile(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) => LocalLink(fileSystem, delegate);
}
