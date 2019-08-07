// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/constants.dart' hide BuildMode;
import 'package:build_daemon/constants.dart' as daemon show BuildMode;
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:dwds/dwds.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../globals.dart';
import '../project.dart';
import 'chrome.dart';

/// The name of the built web project.
const String kBuildTargetName = 'web';

/// A factory for creating a [Dwds] instance.
DwdsFactory get dwdsFactpory => context.get<DwdsFactory>() ?? Dwds.start;

/// The [BuildDaemonCreator] instance.
BuildDaemonCreator get buildDaemonCreator => context.get<BuildDaemonCreator>() ?? const BuildDaemonCreator();

/// A factory for creating a [WebFs] instance.
WebFsFactory get webFsFactory => context.get<WebFsFactory>() ?? WebFs.start;

/// A factory for creating an [HttpMultiServer] instance.
HttpMultiServerFactory get httpMultiServerFactory => context.get<HttpMultiServerFactory>() ?? HttpMultiServer.bind;

/// A function with the same signature as [HttpMultiServier.bind].
typedef HttpMultiServerFactory = Future<HttpServer> Function(dynamic address, int port);

/// A function with the same signatire as [Dwds.start].
typedef DwdsFactory = Future<Dwds> Function({
  @required int applicationPort,
  @required int assetServerPort,
  @required String applicationTarget,
  @required Stream<BuildResult> buildResults,
  @required ConnectionProvider chromeConnection,
  String hostname,
  ReloadConfiguration reloadConfiguration,
  bool serveDevTools,
  LogWriter logWriter,
  bool verbose,
  bool enableDebugExtension,
});

/// A function with the same signatuure as [WebFs.start].
typedef WebFsFactory = Future<WebFs> Function({
  @required String target,
  @required FlutterProject flutterProject,
  @required BuildInfo buildInfo,
});

/// The dev filesystem responsible for building and serving  web applications.
class WebFs {
  @visibleForTesting
  WebFs(
    this._client,
    this._server,
    this._dwds,
    this._chrome,
  );

  final HttpServer _server;
  final Dwds _dwds;
  final Chrome _chrome;
  final BuildDaemonClient _client;

  static const String _kHostName = 'localhost';

  Future<void> stop() async {
    await _client.close();
    await _dwds.stop();
    await _server.close(force: true);
    await _chrome.close();
  }

  /// Retrieve the [DebugConnection] for the current application.
  Future<DebugConnection> runAndDebug() async {
    final AppConnection appConnection = await _dwds.connectedApps.first;
    appConnection.runMain();
    return _dwds.debugConnection(appConnection);
  }

  /// Perform a hard refresh of all connected browser tabs.
  Future<void> hardRefresh() async {
    final List<ChromeTab> tabs = await _chrome.chromeConnection.getTabs();
    for (ChromeTab tab in tabs) {
      if (!tab.url.contains('localhost')) {
        continue;
      }
      final WipConnection connection = await tab.connect();
      await connection.sendCommand('Page.reload');
    }
  }

  /// Recompile the web application and return whether this was successful.
  Future<bool> recompile() async {
    _client.startBuild();
    await for (BuildResults results in _client.buildResults) {
      final BuildResult result = results.results.firstWhere((BuildResult result) {
        return result.target == 'web';
      });
      if (result.status == BuildStatus.failed) {
        return false;
      }
      if (result.status == BuildStatus.succeeded) {
        return true;
      }
    }
    return true;
  }

  /// Start the web compiler and asset server.
  static Future<WebFs> start({
    @required String target,
    @required FlutterProject flutterProject,
    @required BuildInfo buildInfo
  }) async {
    // Start the build daemon and run an initial build.
    final BuildDaemonClient client = await buildDaemonCreator
      .startBuildDaemon(fs.currentDirectory.path, release: buildInfo.isRelease);
    client.startBuild();
    // Only provide relevant build results
    final Stream<BuildResult> filteredBuildResults = client.buildResults
        .asyncMap<BuildResult>((BuildResults results) {
          return results.results
            .firstWhere((BuildResult result) => result.target == kBuildTargetName);
        });
    final int daemonAssetPort = buildDaemonCreator.assetServerPort(fs.currentDirectory);

    // Initialize the asset bundle.
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    await assetBundle.build();
    await writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    // Initialize the dwds server.
    final int port = await os.findFreePort();
    final Dwds dwds = await dwdsFactpory(
      hostname: _kHostName,
      applicationPort: port,
      applicationTarget: kBuildTargetName,
      assetServerPort: daemonAssetPort,
      buildResults: filteredBuildResults,
      chromeConnection: () async {
        return (await ChromeLauncher.connectedInstance).chromeConnection;
      },
      reloadConfiguration: ReloadConfiguration.none,
      serveDevTools: true,
      verbose: false,
      enableDebugExtension: true,
      logWriter: (dynamic level, String message) => printTrace(message),
    );
    // Map the bootstrap files to the correct package directory.
    final String targetBaseName = fs.path
      .withoutExtension(target).replaceFirst('lib${fs.path.separator}', '');
    final Map<String, String> mappedUrls = <String, String>{
      'main.dart.js': 'packages/${flutterProject.manifest.appName}/'
        '${targetBaseName}_web_entrypoint.dart.js',
      '${targetBaseName}_web_entrypoint.dart.bootstrap.js': 'packages/${flutterProject.manifest.appName}/'
        '${targetBaseName}_web_entrypoint.dart.bootstrap.js',
      '${targetBaseName}_web_entrypoint.digests': 'packages/${flutterProject.manifest.appName}/'
        '${targetBaseName}_web_entrypoint.digests',
    };
    final Handler handler = const Pipeline().addMiddleware((Handler innerHandler) {
      return (Request request) async {
        // Redirect the main.dart.js to the target file we decided to serve.
        if (mappedUrls.containsKey(request.url.path)) {
          final String newPath = mappedUrls[request.url.path];
          return innerHandler(
            Request(
              request.method,
              Uri.parse(request.requestedUri.toString()
                  .replaceFirst(request.requestedUri.path, '/$newPath')),
              headers: request.headers,
              url: Uri.parse(request.url.toString()
                  .replaceFirst(request.url.path, newPath)),
            ),
          );
        } else {
          return innerHandler(request);
        }
      };
    })
      .addHandler(dwds.handler);
    Cascade cascade = Cascade();
    cascade = cascade.add(handler);
    cascade = cascade.add(_assetHandler);
    final HttpServer server = await httpMultiServerFactory(_kHostName, port);
    shelf_io.serveRequests(server, cascade.handler);
    final Chrome chrome = await chromeLauncher.launch('http://$_kHostName:$port/');
    return WebFs(
      client,
      server,
      dwds,
      chrome,
    );
  }

  static Future<Response> _assetHandler(Request request) async {
    if (request.url.path.contains('stack_trace_mapper')) {
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
    } else if (request.url.path.contains('assets')) {
      final String assetPath = request.url.path.replaceFirst('assets/', '');
      final File file = fs.file(fs.path.join(getAssetBuildDirectory(), assetPath));
      return Response.ok(file.readAsBytesSync());
    }
    return Response.notFound('');
  }
}

/// A testable interface for starting a build daemon.
class BuildDaemonCreator {
  const BuildDaemonCreator();

  /// Start a build daemon and register the web targets.
  Future<BuildDaemonClient> startBuildDaemon(String workingDirectory, {bool release = false}) async {
    try {
      final BuildDaemonClient client = await _connectClient(
        workingDirectory,
        release: release,
      );
      _registerBuildTargets(client);
      return client;
    } on OptionsSkew {
      throwToolExit(
        'Incompatible options with current running build daemon.\n\n'
        'Please stop other flutter_tool instances running in this directory '
        'before starting a new instance with these options.');
    }
    return null;
  }

  void _registerBuildTargets(
    BuildDaemonClient client,
  ) {
    final OutputLocation outputLocation = OutputLocation((OutputLocationBuilder b) => b
      ..output = ''
      ..useSymlinks = true
      ..hoist = false);
    client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) => b
      ..target = 'web'
      ..outputLocation = outputLocation?.toBuilder()));
  }

  Future<BuildDaemonClient> _connectClient(
    String workingDirectory,
    { bool release }
  ) {
    final String flutterToolsPackages = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools', '.packages');
    final String buildScript = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools', 'lib', 'src', 'build_runner', 'build_script.dart');
    final String flutterWebSdk = artifacts.getArtifactPath(Artifact.flutterWebSdk);
    return BuildDaemonClient.connect(
      workingDirectory,
      // On Windows we need to call the snapshot directly otherwise
      // the process will start in a disjoint cmd without access to
      // STDIO.
      <String>[
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        '--packages=$flutterToolsPackages',
        buildScript,
        'daemon',
        '--skip-build-script-check',
        '--define', 'flutter_tools:ddc=flutterWebSdk=$flutterWebSdk',
        '--define', 'flutter_tools:entrypoint=flutterWebSdk=$flutterWebSdk',
        '--define', 'flutter_tools:entrypoint=release=$release',
        '--define', 'flutter_tools:shell=flutterWebSdk=$flutterWebSdk',
      ],
      logHandler: (ServerLog serverLog) {
        switch (serverLog.level) {
          case Level.CONFIG:
          case Level.FINE:
          case Level.FINER:
          case Level.FINEST:
          case Level.INFO:
            printTrace(serverLog.message);
            break;
          case Level.SEVERE:
          case Level.SHOUT:
            printError(
              serverLog?.error ?? '',
              stackTrace: serverLog.stackTrace != null
                  ? StackTrace.fromString(serverLog?.stackTrace)
                  : null,
            );
        }
      },
      buildMode: daemon.BuildMode.Manual,
    );
  }

  /// Retrieve the asset server port for the current daemon.
  int assetServerPort(Directory workingDirectory) {
    final String portFilePath = fs.path.join(daemonWorkspace(workingDirectory.path), '.asset_server_port');
    return int.tryParse(fs.file(portFilePath).readAsStringSync());
  }
}