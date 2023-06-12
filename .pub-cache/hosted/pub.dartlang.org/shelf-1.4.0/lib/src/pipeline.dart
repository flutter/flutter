// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'handler.dart';
import 'middleware.dart';

/// A helper that makes it easy to compose a set of [Middleware] and a
/// [Handler].
///
/// ```dart
///  var handler = const Pipeline()
///      .addMiddleware(loggingMiddleware)
///      .addMiddleware(cachingMiddleware)
///      .addHandler(application);
/// ```
///
/// Note: this package also provides `addMiddleware` and `addHandler` extensions
///  members on [Middleware], which may be easier to use.
class Pipeline {
  const Pipeline();

  /// Returns a new [Pipeline] with [middleware] added to the existing set of
  /// [Middleware].
  ///
  /// [middleware] will be the last [Middleware] to process a request and
  /// the first to process a response.
  Pipeline addMiddleware(Middleware middleware) =>
      _Pipeline(middleware, addHandler);

  /// Returns a new [Handler] with [handler] as the final processor of a
  /// [Request] if all of the middleware in the pipeline have passed the request
  /// through.
  Handler addHandler(Handler handler) => handler;

  /// Exposes this pipeline of [Middleware] as a single middleware instance.
  Middleware get middleware => addHandler;
}

class _Pipeline extends Pipeline {
  final Middleware _middleware;
  final Middleware _parent;

  _Pipeline(this._middleware, this._parent);

  @override
  Handler addHandler(Handler handler) => _parent(_middleware(handler));
}
