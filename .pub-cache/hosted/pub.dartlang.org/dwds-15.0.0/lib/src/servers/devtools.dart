// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

typedef DevtoolsLauncher = Future<DevTools> Function(String hostname);

/// A server for Dart Devtools.
class DevTools {
  final String hostname;
  final int port;
  final HttpServer _server;

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  DevTools(this.hostname, this.port, this._server);

  Future<void> close() => _closed ??= _server.close();
}
