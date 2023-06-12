// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

/// A shelf handler that serves a virtual packages directory based on a package
/// config.
class PackageConfigHandler {
  /// The static handlers for serving entries in the package config, indexed by
  /// name.
  final _packageHandlers = <String, Future<Handler>>{};

  /// Optional, a map of package names to base uri for resolving `package:`
  /// uris for that package.
  final Map<String, Uri>? _packageMap;

  PackageConfigHandler({Map<String, Uri>? packageMap})
      : _packageMap = packageMap;

  /// The callback for handling a single request.
  Future<Response> handleRequest(Request request) async {
    final segments = request.url.pathSegments;
    final handler = await _handlerFor(segments.first);
    return handler(request.change(path: segments.first));
  }

  /// Creates a handler for [packageName] based on the package map in
  /// [_packageMap] or the current isolate resolver.
  Future<Handler> _handlerFor(String packageName) =>
      _packageHandlers.putIfAbsent(packageName, () async {
        Uri? packageUri;
        if (_packageMap != null) {
          packageUri = _packageMap![packageName];
        } else {
          final fakeResolvedUri = await Isolate.resolvePackageUri(
              Uri(scheme: 'package', path: '$packageName/'));
          packageUri = fakeResolvedUri;
        }

        final handler = packageUri == null
            ? (_) => Response.notFound('Package $packageName not found.')
            : createStaticHandler(p.fromUri(packageUri),
                serveFilesOutsidePath: true);

        return handler;
      });
}
