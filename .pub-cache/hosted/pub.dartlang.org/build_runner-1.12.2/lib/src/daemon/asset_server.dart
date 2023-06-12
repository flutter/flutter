// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../server/server.dart';
import 'daemon_builder.dart';

class AssetServer {
  final HttpServer _server;

  AssetServer._(this._server);

  int get port => _server.port;

  Future<void> stop() => _server.close(force: true);

  static Future<AssetServer> run(
    BuildRunnerDaemonBuilder builder,
    String rootPackage,
  ) async {
    var server = await HttpMultiServer.loopback(0);
    var cascade = Cascade().add((_) async {
      await builder.building;
      return Response.notFound('');
    }).add(AssetHandler(builder.reader, rootPackage).handle);
    shelf_io.serveRequests(server, cascade.handler);
    return AssetServer._(server);
  }
}
