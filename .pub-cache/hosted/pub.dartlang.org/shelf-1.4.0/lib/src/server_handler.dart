// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

import 'handler.dart';
import 'request.dart';
import 'response.dart';
import 'server.dart';

/// A connected pair of a [Server] and a [Handler].
///
/// Requests to the handler are sent to the server's mounted handler once it's
/// available. This is used to expose a virtual [Server] that's actually one
/// part of a larger URL-space.
@Deprecated('Do not use. If you have a use case for this class add a comment '
    'at https://github.com/dart-lang/shelf/issues/205')
class ServerHandler {
  /// The server.
  ///
  /// Once this has a handler mounted, it's passed all requests to [handler]
  /// until this server is closed.
  Server get server => _server;
  final _HandlerServer _server;

  /// The handler.
  ///
  /// This passes requests to [server]'s handler. If that handler isn't mounted
  /// yet, the requests are handled once it is.
  Handler get handler => _onRequest;

  /// Creates a new connected pair of a [Server] with the given [url] and a
  /// [Handler].
  ///
  /// The caller is responsible for ensuring that requests to [url] or any URL
  /// beneath it are handled by [handler].
  ///
  /// If [onClose] is passed, it's called when [server] is closed. It may return
  /// a [Future] or `null`; its return value is returned by [Server.close].
  ServerHandler(Uri url, {Future<void>? Function()? onClose})
      : _server = _HandlerServer(url, onClose);

  /// Pipes requests to [server]'s handler.
  FutureOr<Response> _onRequest(Request request) {
    if (_server._closeMemo.hasRun) {
      throw StateError('Request received after the server was closed.');
    }

    if (_server._handler != null) return _server._handler!(request);

    // Avoid async/await so that the common case of a handler already being
    // mounted doesn't involve any extra asynchronous delays.
    return _server._onMounted.then((_) => _server._handler!(request));
  }
}

// ignore: deprecated_member_use_from_same_package
/// The [Server] returned by [ServerHandler].
class _HandlerServer implements Server {
  @override
  final Uri url;

  /// The callback to call when [close] is called, or `null`.
  final ZoneCallback<void>? _onClose;

  /// The mounted handler.
  ///
  /// This is `null` until [mount] is called.
  Handler? _handler;

  /// A future that fires once [mount] has been called.
  Future<void> get _onMounted => _onMountedCompleter.future;
  final _onMountedCompleter = Completer();

  _HandlerServer(this.url, this._onClose);

  @override
  void mount(Handler handler) {
    if (_handler != null) {
      throw StateError("Can't mount two handlers for the same server.");
    }

    _handler = handler;
    _onMountedCompleter.complete();
  }

  @override
  Future<void> close() => _closeMemo.runOnce(() {
        return _onClose == null ? null : _onClose!();
      });
  final _closeMemo = AsyncMemoizer();
}
