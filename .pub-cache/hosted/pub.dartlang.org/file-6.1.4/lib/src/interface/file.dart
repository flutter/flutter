// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../io.dart' as io;

import 'file_system_entity.dart';

/// A reference to a file on the file system.
abstract class File implements FileSystemEntity, io.File {
  // Override method definitions to codify the return type covariance.
  @override
  Future<File> create({bool recursive = false, bool exclusive = false});

  @override
  Future<File> rename(String newPath);

  @override
  File renameSync(String newPath);

  @override
  Future<File> copy(String newPath);

  @override
  File copySync(String newPath);

  @override
  File get absolute;

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {io.FileMode mode = io.FileMode.write, bool flush = false});

  @override
  Future<File> writeAsString(String contents,
      {io.FileMode mode = io.FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});
}
