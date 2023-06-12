// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;

/// A handler that routes to sub-handlers based on exact path prefixes.
class PathHandler {
  /// A trie of path components to handlers.
  final _paths = _Node();

  /// The shelf handler.
  shelf.Handler get handler => _onRequest;

  /// Returns middleware that nests all requests beneath the URL prefix
  /// [beneath].
  static shelf.Middleware nestedIn(String beneath) {
    return (handler) {
      var pathHandler = PathHandler()..add(beneath, handler);
      return pathHandler.handler;
    };
  }

  /// Routes requests at or under [path] to [handler].
  ///
  /// If [path] is a parent or child directory of another path in this handler,
  /// the longest matching prefix wins.
  void add(String path, shelf.Handler handler) {
    var node = _paths;
    for (var component in p.url.split(path)) {
      node = node.children.putIfAbsent(component, () => _Node());
    }
    node.handler = handler;
  }

  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    shelf.Handler? handler;
    int? handlerIndex;
    _Node? node = _paths;
    var components = p.url.split(request.url.path);
    for (var i = 0; i < components.length; i++) {
      node = node!.children[components[i]];
      if (node == null) break;
      if (node.handler == null) continue;
      handler = node.handler;
      handlerIndex = i;
    }

    if (handler == null) return shelf.Response.notFound('Not found.');

    return handler(request.change(
        path: p.url.joinAll(components.take(handlerIndex! + 1))));
  }
}

/// A trie node.
class _Node {
  shelf.Handler? handler;
  final children = <String, _Node>{};
}
