// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_packages_handler.dir_handler;

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import 'package_config_handler.dart';

/// A utility handler that mounts a sub-handler beneath a directory name,
/// wherever that directory name appears in a URL.
///
/// In practice, this is used to mount a [PackageConfigHandler] underneath
/// `packages/` directories.
class DirHandler {
  /// The directory name to look for.
  final String _name;

  /// The inner handler to mount.
  final Handler _inner;

  DirHandler(this._name, this._inner);

  /// The callback for handling a single request.
  FutureOr<Response> call(Request request) {
    final segments = request.url.pathSegments;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != _name) continue;
      return _inner(request.change(path: p.url.joinAll(segments.take(i + 1))));
    }

    return Response.notFound('Not found.');
  }
}
