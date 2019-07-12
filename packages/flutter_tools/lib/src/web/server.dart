// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build_daemon/data/build_status.dart';
import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../globals.dart';
import 'chrome.dart';

/// The name of the built web project.
const String kBuildTargetName = 'web';

/// The server responsible for handling flutter web applications.
class FlutterWebServer {
  FlutterWebServer._(
    this._server,
    this.dwds,
    this.chrome,
  );

  final HttpServer _server;
  final Dwds dwds;
  final Chrome chrome;

  static const String _kHostName = 'localhost';

  Future<void> stop() async {
    await dwds.stop();
    await _server.close(force: true);
  }

  static Future<FlutterWebServer> start({
    Stream<BuildResults> buildResults,
    int daemonAssetPort,
  }) async {
    // Only provide relevant build results
    final Stream<BuildResult> filteredBuildResults = buildResults
        .asyncMap<BuildResult>((BuildResults results) {
          return results.results
            .firstWhere((BuildResult result) => result.target == kBuildTargetName);
        });
    final int port = await os.findFreePort();
    final Dwds dwds = await Dwds.start(
      hostname: _kHostName,
      applicationPort: port,
      applicationTarget: kBuildTargetName,
      assetServerPort: daemonAssetPort,
      buildResults: filteredBuildResults,
      chromeConnection: () async {
        return (await ChromeLauncher.connectedInstance).chromeConnection;
      },
      logWriter: (Level level, String message) {
        printTrace(message);
      },
      reloadConfiguration: ReloadConfiguration.none,
      serveDevTools: true,
      verbose: false,
    );
    final HttpServer server = await HttpMultiServer.bind(_kHostName, port);
    Cascade cascade = Cascade();
    cascade = cascade.add(dwds.handler);
    cascade = cascade.add(_assetHandler);
    shelf_io.serveRequests(server, cascade.handler);
    final Chrome chrome = await chromeLauncher.launch('http://$_kHostName:$port/',);
    return FlutterWebServer._(
      server,
      dwds,
      chrome,
    );
  }

  static final  FlutterProject _flutterProject = FlutterProject.current();

  static Future<Response> _assetHandler(Request request) async {
    final String generated = fs.path.join(
      _flutterProject.dartTool.path,
      'build',
      'flutter_web',
      _flutterProject.manifest.appName,
    );
    if (request.url.path.contains('main.dart.js')) {
      final File file = fs.file(fs.path.join(
        generated,
        'lib',
        'main_web_entrypoint.dart.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('stack_trace_mapper')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js'
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('require.js')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'kernel',
        'amd',
        'require.js'
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('.bootstrap.js')) {
      final File file = fs.file(fs.path.join(
        generated,
        'lib',
        'main_web_entrypoint.dart.bootstrap.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('dart_sdk')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('main_web_entrypoint.digests')) {
      final File file = fs.file(fs.path.join(
        generated,
        'lib',
        'main_web_entrypoint.digests',
      ));
      return Response.ok(file.readAsBytesSync());
    } else if (request.url.path.contains('assets')) {
      final String assetPath = request.url.path.replaceFirst('assets/', '');
      final File file = fs.file(fs.path.join(getAssetBuildDirectory(), assetPath));
      return Response.ok(file.readAsBytesSync());
    }
    return Response.notFound('');
  }
}
