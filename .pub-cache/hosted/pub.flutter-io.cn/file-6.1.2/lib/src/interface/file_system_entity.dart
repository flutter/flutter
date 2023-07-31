// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../io.dart' as io;

import 'directory.dart';
import 'file_system.dart';

/// The common super class for [io.File], [io.Directory], and [io.Link] objects.
abstract class FileSystemEntity implements io.FileSystemEntity {
  /// Returns the file system responsible for this entity.
  FileSystem get fileSystem;

  /// Gets the part of this entity's path after the last separator.
  ///
  ///     context.basename('path/to/foo.dart'); // -> 'foo.dart'
  ///     context.basename('path/to');          // -> 'to'
  ///
  /// Trailing separators are ignored.
  ///
  ///     context.basename('path/to/'); // -> 'to'
  String get basename;

  /// Gets the part of this entity's path before the last separator.
  ///
  ///     context.dirname('path/to/foo.dart'); // -> 'path/to'
  ///     context.dirname('path/to');          // -> 'path'
  ///     context.dirname('foo.dart');         // -> '.'
  ///
  /// Trailing separators are ignored.
  ///
  ///     context.dirname('path/to/'); // -> 'path'
  String get dirname;

  // Override method definitions to codify the return type covariance.
  @override
  Future<FileSystemEntity> delete({bool recursive = false});

  @override
  Directory get parent;
}
