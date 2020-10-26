// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_server/devtools_server.dart' as devtools_server;
import 'package:meta/meta.dart';

import '../base/io.dart' as io;
import '../base/logger.dart';
import '../resident_runner.dart';

/// An implementation of the devtools launcher that uses the server package.
///
/// This is implemented in isolated to prevent the flutter_tool from needing
/// a devtools dep in google3.
class DevtoolsServerLauncher extends DevtoolsLauncher {
  DevtoolsServerLauncher({
    @required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  io.HttpServer _devtoolsServer;

  @override
  Future<void> launch(Uri observatoryAddress) async {
    try {
      await serve();
      await devtools_server.launchDevTools(
        <String, dynamic>{
          'reuseWindows': true,
        },
        observatoryAddress,
        'http://${_devtoolsServer.address.host}:${_devtoolsServer.port}',
        false,  // headless mode,
        false,  // machine mode
      );
    } on Exception catch (e, st) {
      _logger.printTrace('Failed to launch DevTools: $e\n$st');
    }
  }

  @override
  Future<DevToolsServerAddress> serve() async {
    try {
      _devtoolsServer ??= await devtools_server.serveDevTools(
        enableStdinCommands: false,
      );
      return DevToolsServerAddress(_devtoolsServer.address.host, _devtoolsServer.port);
    } on Exception catch (e, st) {
      _logger.printTrace('Failed to serve DevTools: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _devtoolsServer?.close();
    _devtoolsServer = null;
  }
}
