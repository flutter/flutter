// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/src/io.dart' as io;
import 'package:file/file.dart';

/// A link that forwards all methods and properties to a delegate.
abstract class ForwardingLink
    implements ForwardingFileSystemEntity<Link, io.Link>, Link {
  @override
  ForwardingLink wrap(io.Link delegate) => wrapLink(delegate) as ForwardingLink;

  @override
  Future<Link> create(String target, {bool recursive = false}) async =>
      wrap(await delegate.create(target, recursive: recursive));

  @override
  void createSync(String target, {bool recursive = false}) =>
      delegate.createSync(target, recursive: recursive);

  @override
  Future<Link> update(String target) async =>
      wrap(await delegate.update(target));

  @override
  void updateSync(String target) => delegate.updateSync(target);

  @override
  Future<String> target() => delegate.target();

  @override
  String targetSync() => delegate.targetSync();
}
