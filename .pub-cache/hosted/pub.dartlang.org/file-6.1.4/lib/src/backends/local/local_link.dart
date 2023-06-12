// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;

import 'local_file_system_entity.dart';

/// [Link] implementation that forwards all calls to `dart:io`.
class LocalLink extends LocalFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  /// Instantiates a new [LocalLink] tied to the specified file system
  /// and delegating to the specified [delegate].
  LocalLink(FileSystem fs, io.Link delegate) : super(fs, delegate);

  @override
  String toString() => "LocalLink: '$path'";
}
