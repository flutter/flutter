// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../io.dart' as io;

import 'file.dart';
import 'file_system_entity.dart';
import 'link.dart';

/// A reference to a directory on the file system.
abstract class Directory implements FileSystemEntity, io.Directory {
  // Override method definitions to codify the return type covariance.
  @override
  Future<Directory> create({bool recursive = false});

  @override
  Future<Directory> createTemp([String? prefix]);

  @override
  Directory createTempSync([String? prefix]);

  @override
  Future<Directory> rename(String newPath);

  @override
  Directory renameSync(String newPath);

  @override
  Directory get absolute;

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true});

  /// Returns a reference to a [Directory] that exists as a child of this
  /// directory and has the specified [basename].
  Directory childDirectory(String basename);

  /// Returns a reference to a [File] that exists as a child of this directory
  /// and has the specified [basename].
  File childFile(String basename);

  /// Returns a reference to a [Link] that exists as a child of this directory
  /// and has the specified [basename].
  Link childLink(String basename);
}
