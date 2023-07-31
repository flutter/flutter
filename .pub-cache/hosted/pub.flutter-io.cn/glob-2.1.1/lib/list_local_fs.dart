// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:glob/glob.dart';

/// Platform specific extensions for where `dart:io` exists, which use the
/// local file system.
extension ListLocalFileSystem on Glob {
  /// Convenience method for [Glob.listFileSystem] which uses the local file
  /// system.
  Stream<FileSystemEntity> list({String? root, bool followLinks = true}) =>
      listFileSystem(const LocalFileSystem(),
          root: root, followLinks: followLinks);

  /// Convenience method for [Glob.listFileSystemSync] which uses the local
  /// file system.
  List<FileSystemEntity> listSync({String? root, bool followLinks = true}) =>
      listFileSystemSync(const LocalFileSystem(),
          root: root, followLinks: followLinks);
}
