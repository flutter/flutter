// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';

/// A directory that forwards all methods and properties to a delegate.
abstract class ForwardingDirectory<T extends Directory>
    implements ForwardingFileSystemEntity<T, io.Directory>, Directory {
  @override
  T wrap(io.Directory delegate) => wrapDirectory(delegate) as T;

  @override
  Future<Directory> create({bool recursive = false}) async =>
      wrap(await delegate.create(recursive: recursive));

  @override
  void createSync({bool recursive = false}) =>
      delegate.createSync(recursive: recursive);

  @override
  Future<Directory> createTemp([String? prefix]) async =>
      wrap(await delegate.createTemp(prefix));

  @override
  Directory createTempSync([String? prefix]) =>
      wrap(delegate.createTempSync(prefix));

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) =>
      delegate.list(recursive: recursive, followLinks: followLinks).map(_wrap);

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) =>
      delegate
          .listSync(recursive: recursive, followLinks: followLinks)
          .map(_wrap)
          .toList();

  FileSystemEntity _wrap(io.FileSystemEntity entity) {
    if (entity is io.File) {
      return wrapFile(entity);
    } else if (entity is io.Directory) {
      return wrapDirectory(entity);
    } else if (entity is io.Link) {
      return wrapLink(entity);
    }
    throw FileSystemException('Unsupported type: $entity', entity.path);
  }
}
