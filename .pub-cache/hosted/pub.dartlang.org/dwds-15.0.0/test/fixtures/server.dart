// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';

import 'package:build_daemon/data/build_status.dart' as daemon;
import 'package:dds/devtools_server.dart';
import 'package:dwds/data/build_result.dart';
import 'package:dwds/dwds.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'utilities.dart';

Logger _logger = Logger('TestServer');

Handler _interceptFavicon(Handler handler) {
  return (request) async {
    if (request.url.pathSegments.isNotEmpty &&
        request.url.pathSegments.last == 'favicon.ico') {
      return Response.ok('');
    }
    return handler(request);
  };
}

class TestServer {
  final HttpServer _server;
  final String target;
  final Dwds dwds;
  final Stream<BuildResult> buildResults;
  final AssetReader assetReader;

  TestServer._(
    this.target,
    this._server,
    this.dwds,
    this.buildResults,
    bool autoRun,
    this.assetReader,
  ) {
    if (autoRun) {
      dwds.connectedApps.listen((connection) {
        connection.runMain();
      });
    }
  }

  String get host => _server.address.host;
  int get port => _server.port;

  Future<void> stop() async {
    await dwds.stop();
    await _server.close(force: true);
  }

  static Future<TestServer> start(
    String hostname,
    int port,
    Handler assetHandler,
    AssetReader assetReader,
    RequireStrategy strategy,
    String target,
    Stream<daemon.BuildResults> buildResults,
    Future<ChromeConnection> Function() chromeConnection,
    bool serveDevTools,
    bool enableDebugExtension,
    bool autoRun,
    bool enableDebugging,
    bool useSse,
    UrlEncoder urlEncoder,
    bool restoreBreakpoints,
    ExpressionCompiler expressionCompiler,
    bool spawnDds,
    ExpressionCompilerService ddcService,
  ) async {
    var pipeline = const Pipeline();

    pipeline = pipeline.addMiddleware(_interceptFavicon);

    final filteredBuildResults = buildResults.asyncMap<BuildResult>((results) {
      final result =
          results.results.firstWhere((result) => result.target == target);
      switch (result.status) {
        case daemon.BuildStatus.started:
          return BuildResult((b) => b.status = BuildStatus.started);
        case daemon.BuildStatus.failed:
          return BuildResult((b) => b.status = BuildStatus.failed);
        case daemon.BuildStatus.succeeded:
          return BuildResult((b) => b.status = BuildStatus.succeeded);
      }
      throw StateError('Unexpected Daemon build result: $result');
    });

    final dwds = await Dwds.start(
        assetReader: assetReader,
        buildResults: filteredBuildResults,
        chromeConnection: chromeConnection,
        loadStrategy: strategy,
        spawnDds: spawnDds,
        enableDebugExtension: enableDebugExtension,
        enableDebugging: enableDebugging,
        useSseForDebugProxy: useSse,
        useSseForDebugBackend: useSse,
        useSseForInjectedClient: useSse,
        hostname: hostname,
        urlEncoder: urlEncoder,
        expressionCompiler: expressionCompiler,
        devtoolsLauncher: serveDevTools
            ? (hostname) async {
                final server = await DevToolsServer().serveDevTools(
                  hostname: hostname,
                  enableStdinCommands: false,
                  customDevToolsPath: devToolsPath,
                );
                return DevTools(server.address.host, server.port, server);
              }
            : null);

    final server = await startHttpServer('localhost', port: port);
    var cascade = Cascade();

    cascade = cascade.add(dwds.handler).add(assetHandler);

    if (ddcService != null) {
      cascade = cascade.add(ddcService.handler);
    }

    serveHttpRequests(
        server,
        pipeline
            .addMiddleware(_logRequests)
            .addMiddleware(dwds.middleware)
            .addHandler(cascade.handler), (e, s) {
      _logger.warning('Error handling requests', e, s);
    });

    return TestServer._(
      target,
      server,
      dwds,
      filteredBuildResults,
      autoRun,
      assetReader,
    );
  }

  /// [Middleware] that logs all requests, inspired by [logRequests].
  static Handler _logRequests(Handler innerHandler) {
    return (Request request) async {
      final watch = Stopwatch()..start();
      try {
        final response = await innerHandler(request);
        final logFn =
            response.statusCode >= 500 ? _logger.warning : _logger.finest;
        final msg = _requestLabel(response.statusCode, request.requestedUri,
            request.method, watch.elapsed);
        logFn(msg);
        return response;
      } catch (error, stackTrace) {
        if (error is HijackException) rethrow;
        final msg = _requestLabel(
            500, request.requestedUri, request.method, watch.elapsed);
        _logger.severe(msg, error, stackTrace);
        rethrow;
      }
    };
  }

  static String _requestLabel(
      int statusCode, Uri requestedUri, String method, Duration elapsedTime) {
    return '$elapsedTime '
        '$method [$statusCode] '
        '${requestedUri.path}${_formatQuery(requestedUri.query)}';
  }

  static String _formatQuery(String query) {
    return query == '' ? '' : '?$query';
  }
}
