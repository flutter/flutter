// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'local_file_system_entity.dart';

/// [File] implementation that forwards all calls to `dart:io`.
class LocalFile extends LocalFileSystemEntity<File, io.File>
    with ForwardingFile {
  /// Instantiates a new [LocalFile] tied to the specified file system
  /// and delegating to the specified [delegate].
  LocalFile(FileSystem fs, io.File delegate) : super(fs, delegate);

  @override
  String toString() => "LocalFile: '$path'";
}
