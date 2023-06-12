// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;

/// A Shelf handler that provides support for one-time handlers.
///
/// This is useful for handlers that only expect to be hit once before becoming
/// invalid and don't need to have a persistent URL.
class OneOffHandler {
  /// A map from URL paths to handlers.
  final _handlers = <String, shelf.Handler>{};

  /// The counter of handlers that have been activated.
  var _counter = 0;

  /// The actual [shelf.Handler] that dispatches requests.
  shelf.Handler get handler => _onRequest;

  /// Creates a new one-off handler that forwards to [handler].
  ///
  /// Returns a string that's the URL path for hitting this handler, relative to
  /// the URL for the one-off handler itself.
  ///
  /// [handler] will be unmounted as soon as it receives a request.
  String create(shelf.Handler handler) {
    var path = _counter.toString();
    _handlers[path] = handler;
    _counter++;
    return path;
  }

  /// Dispatches [request] to the appropriate handler.
  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    var components = p.url.split(request.url.path);
    if (components.isEmpty) return shelf.Response.notFound(null);

    var path = components.removeAt(0);
    var handler = _handlers.remove(path);
    if (handler == null) return shelf.Response.notFound(null);
    return handler(request.change(path: path));
  }
}
