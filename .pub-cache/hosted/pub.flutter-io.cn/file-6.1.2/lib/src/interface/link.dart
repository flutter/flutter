// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../io.dart' as io;

import 'file_system_entity.dart';

/// A reference to a symbolic link on the file system.
abstract class Link implements FileSystemEntity, io.Link {
  // Override method definitions to codify the return type covariance.
  @override
  Future<Link> create(String target, {bool recursive = false});

  @override
  Future<Link> update(String target);

  @override
  Future<Link> rename(String newPath);

  @override
  Link renameSync(String newPath);

  @override
  Link get absolute;
}
