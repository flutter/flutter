// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart' as daemon;
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:dwds/asset_handler.dart';
import 'package:dwds/dwds.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:mime/mime.dart' as mime;

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../web/chrome.dart';
import '../web/compile.dart';

/// The name of the built web project.
const String kBuildTargetName = 'web';

/// A factory for creating a [Dwds] instance.
DwdsFactory get dwdsFactory => context.get<DwdsFactory>() ?? Dwds.start;

/// The [BuildDaemonCreator] instance.
BuildDaemonCreator get buildDaemonCreator => context.get<BuildDaemonCreator>() ?? const BuildDaemonCreator();

/// A factory for creating a [WebFs] instance.
WebFsFactory get webFsFactory => context.get<WebFsFactory>() ?? WebFs.start;

/// A factory for creating an [HttpMultiServer] instance.
HttpMultiServerFactory get httpMultiServerFactory => context.get<HttpMultiServerFactory>() ?? HttpMultiServer.bind;

/// A function with the same signature as [HttpMultiServer.bind].
typedef HttpMultiServerFactory = Future<HttpServer> Function(dynamic address, int port);

/// A function with the same signature as [Dwds.start].
typedef DwdsFactory = Future<Dwds> Function({
  @required AssetHandler assetHandler,
  @required Stream<BuildResult> buildResults,
  @required ConnectionProvider chromeConnection,
  String hostname,
  ReloadConfiguration reloadConfiguration,
  bool serveDevTools,
  LogWriter logWriter,
  bool verbose,
  bool enableDebugExtension,
});

/// A function with the same signature as [WebFs.start].
typedef WebFsFactory = Future<WebFs> Function({
  @required String target,
  @required FlutterProject flutterProject,
  @required BuildInfo buildInfo,
  @required bool skipDwds,
  @required bool initializePlatform,
  @required String hostname,
  @required String port,
  @required List<String> dartDefines,
});

/// The dev filesystem responsible for building and serving  web applications.
class WebFs {
  @visibleForTesting
  WebFs(
    this._client,
    this._server,
    this._dwds,
    this.uri,
    this._assetServer,
    this._useBuildRunner,
    this._flutterProject,
    this._target,
    this._buildInfo,
    this._initializePlatform,
    this._dartDefines,
  );

  /// The server URL.
  final String uri;

  final HttpServer _server;
  final Dwds _dwds;
  final BuildDaemonClient _client;
  final AssetServer _assetServer;
  final bool _useBuildRunner;
  final FlutterProject _flutterProject;
  final String _target;
  final BuildInfo _buildInfo;
  final bool _initializePlatform;
  final List<String> _dartDefines;
  StreamSubscription<void> _connectedApps;

  static const String _kHostName = 'localhost';

  Future<void> stop() async {
    await _client?.close();
    await _dwds?.stop();
    await _server.close(force: true);
    await _connectedApps?.cancel();
    _assetServer?.dispose();
  }

  Future<DebugConnection> _cachedExtensionFuture;

  /// Connect and retrieve the [DebugConnection] for the current application.
  ///
  /// Only calls [AppConnection.runMain] on the subsequent connections.
  Future<ConnectionResult> connect(bool useDebugExtension) {
    final Completer<ConnectionResult> firstConnection = Completer<ConnectionResult>();
    _connectedApps = _dwds.connectedApps.listen((AppConnection appConnection) async {
      final DebugConnection debugConnection = useDebugExtension
        ? await (_cachedExtensionFuture ??= _dwds.extensionDebugConnections.stream.first)
        : await _dwds.debugConnection(appConnection);
      if (!firstConnection.isCompleted) {
        firstConnection.complete(ConnectionResult(appConnection, debugConnection));
      } else {
        appConnection.runMain();
      }
    });
    return firstConnection.future;
  }

  /// Recompile the web application and return whether this was successful.
  Future<bool> recompile() async {
    if (!_useBuildRunner) {
      await buildWeb(_flutterProject, _target, _buildInfo, _initializePlatform, _dartDefines);
      return true;
    }
    _client.startBuild();
    await for (BuildResults results in _client.buildResults) {
      final BuildResult result = results.results.firstWhere((BuildResult result) {
        return result.target == kBuildTargetName;
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
    @required BuildInfo buildInfo,
    @required bool skipDwds,
    @required bool initializePlatform,
    @required String hostname,
    @required String port,
    @required List<String> dartDefines,
  }) async {
    // workaround for https://github.com/flutter/flutter/issues/38290
    if (!flutterProject.dartTool.existsSync()) {
      flutterProject.dartTool.createSync(recursive: true);
    }
    // Workaround for https://github.com/flutter/flutter/issues/41681.
    final String toolPath = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools');
    if (!fs.isFileSync(fs.path.join(toolPath, '.packages'))) {
      await pub.get(
        context: PubContext.pubGet,
        directory: toolPath,
        offline: true,
        skipPubspecYamlCheck: true,
        checkLastModified: false,
      );
    }

    final Completer<bool> firstBuildCompleter = Completer<bool>();

    // Initialize the asset bundle.
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    await assetBundle.build();
    await writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);

    final String targetBaseName = fs.path
      .withoutExtension(target).replaceFirst('lib${fs.path.separator}', '');
    final Map<String, String> mappedUrls = <String, String>{
      'main.dart.js': 'packages/${flutterProject.manifest.appName}/'
          '${targetBaseName}_web_entrypoint.dart.js',
      '${targetBaseName}_web_entrypoint.dart.js.map': 'packages/${flutterProject.manifest.appName}/'
          '${targetBaseName}_web_entrypoint.dart.js.map',
      '${targetBaseName}_web_entrypoint.dart.bootstrap.js': 'packages/${flutterProject.manifest.appName}/'
          '${targetBaseName}_web_entrypoint.dart.bootstrap.js',
      '${targetBaseName}_web_entrypoint.digests': 'packages/${flutterProject.manifest.appName}/'
          '${targetBaseName}_web_entrypoint.digests',
    };

    // Initialize the dwds server.
    final String effectiveHostname = hostname ?? _kHostName;
    final int hostPort = port == null ? await os.findFreePort() : int.tryParse(port);

    final Pipeline pipeline = const Pipeline().addMiddleware((Handler innerHandler) {
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
    });

    Handler handler;
    Dwds dwds;
    BuildDaemonClient client;
    StreamSubscription<void> firstBuild;
    if (buildInfo.isDebug) {
      final bool hasWebPlugins = findPlugins(flutterProject)
          .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
      // Start the build daemon and run an initial build.
      client = await buildDaemonCreator
        .startBuildDaemon(fs.currentDirectory.path,
            release: buildInfo.isRelease,
            profile: buildInfo.isProfile,
            hasPlugins: hasWebPlugins,
            initializePlatform: initializePlatform,
        );
      client.startBuild();
      // Only provide relevant build results
      final Stream<BuildResult> filteredBuildResults = client.buildResults
        .asyncMap<BuildResult>((BuildResults results) {
          return results.results
            .firstWhere((BuildResult result) => result.target == kBuildTargetName);
        });
      // Start the build daemon and run an initial build.
      firstBuild = client.buildResults.listen((BuildResults buildResults) {
        if (firstBuildCompleter.isCompleted) {
          return;
        }
        final BuildResult result = buildResults.results.firstWhere((BuildResult result) {
          return result.target == kBuildTargetName;
        });
        if (result.status == BuildStatus.failed) {
          firstBuildCompleter.complete(false);
        }
        if (result.status == BuildStatus.succeeded) {
          firstBuildCompleter.complete(true);
        }
      });
      final int daemonAssetPort = buildDaemonCreator.assetServerPort(fs.currentDirectory);

      // Initialize the asset bundle.
      final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
      await assetBundle.build();
      await writeBundle(fs.directory(getAssetBuildDirectory()), assetBundle.entries);
      if (!skipDwds) {
        final BuildRunnerAssetHandler assetHandler = BuildRunnerAssetHandler(
          daemonAssetPort,
          kBuildTargetName,
          effectiveHostname,
          hostPort);
        dwds = await dwdsFactory(
          hostname: effectiveHostname,
          assetHandler: assetHandler,
          buildResults: filteredBuildResults,
          chromeConnection: () async {
            return (await ChromeLauncher.connectedInstance).chromeConnection;
          },
          reloadConfiguration: ReloadConfiguration.none,
          serveDevTools: false,
          verbose: false,
          enableDebugExtension: true,
          logWriter: (dynamic level, String message) => printTrace(message),
        );
        handler = pipeline.addHandler(dwds.handler);
      } else {
        handler = pipeline.addHandler(proxyHandler('http://localhost:$daemonAssetPort/web/'));
      }
    } else {
      await buildWeb(flutterProject, target, buildInfo, initializePlatform, dartDefines);
      firstBuildCompleter.complete(true);
    }

    final AssetServer assetServer = buildInfo.isDebug
      ? DebugAssetServer(flutterProject, targetBaseName)
      : ReleaseAssetServer();
    Cascade cascade = Cascade();
    cascade = cascade.add(handler);
    cascade = cascade.add(assetServer.handle);
    final HttpServer server = await httpMultiServerFactory(effectiveHostname, hostPort);
    shelf_io.serveRequests(server, cascade.handler);
    final WebFs webFS = WebFs(
      client,
      server,
      dwds,
      'http://$effectiveHostname:$hostPort/',
      assetServer,
      buildInfo.isDebug,
      flutterProject,
      target,
      buildInfo,
      initializePlatform,
      dartDefines,
    );
    if (!await firstBuildCompleter.future) {
      throw const BuildException();
    }
    await firstBuild?.cancel();
    return webFS;
  }
}

/// An exception thrown when build runner fails.
///
/// This contains no error information as it will have already been printed to
/// the console.
class BuildException implements Exception {
  const BuildException();
}

abstract class AssetServer {
  Future<Response> handle(Request request);

  void dispose() {}
}

class ReleaseAssetServer extends AssetServer {
  @override
  Future<Response> handle(Request request) async {
    final Uri artifactUri = fs.directory(getWebBuildDirectory()).uri.resolveUri(request.url);
    final File file = fs.file(artifactUri);
    if (file.existsSync()) {
      final Uint8List bytes = file.readAsBytesSync();
      // Fallback to "application/octet-stream" on null which
      // makes no claims as to the structure of the data.
      final String mimeType = mime.lookupMimeType(file.path, headerBytes: bytes)
        ?? 'application/octet-stream';
      return Response.ok(bytes, headers: <String, String>{
        'Content-Type': mimeType,
      });
    }
    if (request.url.path == '') {
      final File file = fs.file(fs.path.join(getWebBuildDirectory(), 'index.html'));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/html',
      });
    }
    return Response.notFound('');
  }
}

class DebugAssetServer extends AssetServer {
  DebugAssetServer(this.flutterProject, this.targetBaseName);

  final FlutterProject flutterProject;
  final String targetBaseName;
  final PackageMap packageMap = PackageMap(PackageMap.globalPackagesPath);
  Directory partFiles;

  @override
  Future<Response> handle(Request request) async {
    if (request.url.path.endsWith('.html')) {
      final Uri htmlUri = flutterProject.web.directory.uri.resolveUri(request.url);
      final File htmlFile = fs.file(htmlUri);
      if (htmlFile.existsSync()) {
        return Response.ok(htmlFile.readAsBytesSync(), headers: <String, String>{
          'Content-Type': 'text/html',
        });
      }
      return Response.notFound('');
    } else if (request.url.path.contains('stack_trace_mapper')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.endsWith('part.js')) {
      // Lazily unpack any deferred imports in release/profile mode. These are
      // placed into an archive by build_runner, and are named based on the main
      // entrypoint + a "part" suffix (Though the actual names are arbitrary).
      // To make this easier to deal with they are copied into a temp directory.
      if (partFiles == null) {
        final File dart2jsArchive = fs.file(fs.path.join(
          flutterProject.dartTool.path,
          'build',
          'flutter_web',
          '${flutterProject.manifest.appName}',
          'lib',
          '${targetBaseName}_web_entrypoint.dart.js.tar.gz',
        ));
        if (dart2jsArchive.existsSync()) {
          final Archive archive = TarDecoder().decodeBytes(dart2jsArchive.readAsBytesSync());
          partFiles = fs.systemTempDirectory.createTempSync('flutter_tool.')
            ..createSync();
          for (ArchiveFile file in archive) {
            partFiles.childFile(file.name).writeAsBytesSync(file.content as List<int>);
          }
        }
      }
      final String fileName = fs.path.basename(request.url.path);
      return Response.ok(partFiles.childFile(fileName).readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.contains('require.js')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'kernel',
        'amd',
        'require.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.endsWith('dart_sdk.js.map')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js.map',
      ));
      return Response.ok(file.readAsBytesSync());
    } else if (request.url.path.endsWith('dart_sdk.js')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));
      return Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/javascript',
      });
    } else if (request.url.path.endsWith('.dart')) {
      // This is likely a sourcemap request. The first segment is the
      // package name, and the rest is the path to the file relative to
      // the package uri. For example, `foo/bar.dart` would represent a
      // file at a path like `foo/lib/bar.dart`. If there is no leading
      // segment, then we assume it is from the current package.
      String basePath = request.url.path;
      basePath = basePath.replaceFirst('packages/build_web_compilers/', '');
      basePath = basePath.replaceFirst('packages/', '');

      // Handle sdk requests that have mangled urls from engine build.
      if (request.url.path.contains('dart-sdk')) {
        // Note: the request is a uri and not a file path, so they always use `/`.
        final String sdkPath = fs.path.joinAll(request.url.path.split('dart-sdk/').last.split('/'));
        final String dartSdkPath = artifacts.getArtifactPath(Artifact.engineDartSdkPath);
        final File candidateFile = fs.file(fs.path.join(dartSdkPath, sdkPath));
        return Response.ok(candidateFile.readAsBytesSync());
      }

      // See if it is a flutter sdk path.
      final String webSdkPath = artifacts.getArtifactPath(Artifact.flutterWebSdk);
      final File candidateFile = fs.file(fs.path.join(webSdkPath,
        basePath.split('/').join(platform.pathSeparator)));
      if (candidateFile.existsSync()) {
        return Response.ok(candidateFile.readAsBytesSync());
      }

      final String packageName = request.url.pathSegments.length == 1
          ? flutterProject.manifest.appName
          : request.url.pathSegments.first;
      String filePath = fs.path.joinAll(request.url.pathSegments.length == 1
          ? request.url.pathSegments
          : request.url.pathSegments.skip(1));
      String packagePath = packageMap.map[packageName]?.toFilePath(windows: platform.isWindows);
      // If the package isn't found, then we have an issue with relative
      // paths within the main project.
      if (packagePath == null) {
        packagePath = packageMap.map[flutterProject.manifest.appName]
            .toFilePath(windows: platform.isWindows);
        filePath = request.url.path;
      }
      final File file = fs.file(fs.path.join(packagePath, filePath));
      if (file.existsSync()) {
        return Response.ok(file.readAsBytesSync());
      }
      return Response.notFound('');
    } else if (request.url.path.contains('assets')) {
      final String assetPath = request.url.path.replaceFirst('assets/', '');
      final File file = fs.file(fs.path.join(getAssetBuildDirectory(), assetPath));
      if (file.existsSync()) {
        final Uint8List bytes = file.readAsBytesSync();
        // Fallback to "application/octet-stream" on null which
        // makes no claims as to the structure of the data.
        final String mimeType = mime.lookupMimeType(file.path, headerBytes: bytes)
          ?? 'application/octet-stream';
        return Response.ok(bytes, headers: <String, String>{
          'Content-Type': mimeType,
        });
      } else {
        return Response.notFound('');
      }
    }
    return Response.notFound('');
  }

  @override
  void dispose() {
    partFiles?.deleteSync(recursive: true);
  }
}

class ConnectionResult {
  ConnectionResult(this.appConnection, this.debugConnection);

  final AppConnection appConnection;
  final DebugConnection debugConnection;
}

class WebTestTargetManifest {
  WebTestTargetManifest(this.buildFilters);

  WebTestTargetManifest.all() : buildFilters = null;

  final List<String> buildFilters;

  bool get hasBuildFilters => buildFilters != null && buildFilters.isNotEmpty;
}

/// A testable interface for starting a build daemon.
class BuildDaemonCreator {
  const BuildDaemonCreator();

  // TODO(jonahwilliams): find a way to get build checks working for flutter for web.
  static const String _ignoredLine1 = 'Warning: Interpreting this as package URI';
  static const String _ignoredLine2 = 'build_script.dart was not found in the asset graph, incremental builds will not work';
  static const String _ignoredLine3 = 'have your dependencies specified fully in your pubspec.yaml';

  /// Start a build daemon and register the web targets.
  ///
  /// [initializePlatform] controls whether we should invoke [webOnlyInitializePlatform].
  Future<BuildDaemonClient> startBuildDaemon(String workingDirectory, {
    bool release = false,
    bool profile = false,
    bool hasPlugins = false,
    bool initializePlatform = true,
    WebTestTargetManifest testTargets,
  }) async {
    try {
      final BuildDaemonClient client = await _connectClient(
        workingDirectory,
        release: release,
        profile: profile,
        hasPlugins: hasPlugins,
        initializePlatform: initializePlatform,
        testTargets: testTargets,
      );
      _registerBuildTargets(client, testTargets);
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
    WebTestTargetManifest testTargets,
  ) {
    final OutputLocation outputLocation = OutputLocation((OutputLocationBuilder b) => b
      ..output = ''
      ..useSymlinks = true
      ..hoist = false);
    client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) => b
      ..target = 'web'
      ..outputLocation = outputLocation?.toBuilder()));
    if (testTargets != null) {
      client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) {
        b.target = 'test';
        b.outputLocation = outputLocation?.toBuilder();
        if (testTargets.hasBuildFilters) {
          b.buildFilters.addAll(testTargets.buildFilters);
        }
        return b;
      }));
    }
  }

  Future<BuildDaemonClient> _connectClient(
    String workingDirectory, {
    bool release,
    bool profile,
    bool hasPlugins,
    bool initializePlatform,
    WebTestTargetManifest testTargets,
  }) {
    final String flutterToolsPackages = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools', '.packages');
    final String buildScript = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools', 'lib', 'src', 'build_runner', 'build_script.dart');
    final String flutterWebSdk = artifacts.getArtifactPath(Artifact.flutterWebSdk);

    // On Windows we need to call the snapshot directly otherwise
    // the process will start in a disjoint cmd without access to
    // STDIO.
    final List<String> args = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      '--packages=$flutterToolsPackages',
      buildScript,
      'daemon',
      '--skip-build-script-check',
      '--define', 'flutter_tools:ddc=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=release=$release',
      '--define', 'flutter_tools:entrypoint=profile=$profile',
      '--define', 'flutter_tools:shell=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:shell=hasPlugins=$hasPlugins',
      '--define', 'flutter_tools:shell=initializePlatform=$initializePlatform',
      // The following will cause build runner to only build tests that were requested.
      if (testTargets != null && testTargets.hasBuildFilters)
        for (String buildFilter in testTargets.buildFilters)
          '--build-filter=$buildFilter',
    ];

    return BuildDaemonClient.connect(
      workingDirectory,
      args,
      logHandler: (ServerLog serverLog) {
        switch (serverLog.level) {
          case Level.SEVERE:
          case Level.SHOUT:
            // Ignore certain non-actionable messages on startup.
            if (serverLog.message.contains(_ignoredLine1) ||
                serverLog.message.contains(_ignoredLine2) ||
                serverLog.message.contains(_ignoredLine3)) {
              return;
            }
            printError(serverLog.message);
            if (serverLog.error != null) {
              printError(serverLog.error);
            }
            if (serverLog.stackTrace != null) {
              printTrace(serverLog.stackTrace);
            }
            break;
          default:
            if (serverLog.message.contains('Skipping compiling')) {
              printError(serverLog.message);
            } else {
              printTrace(serverLog.message);
            }
        }
      },
      buildMode: daemon.BuildMode.Manual,
    );
  }

  /// Retrieve the asset server port for the current daemon.
  int assetServerPort(Directory workingDirectory) {
    final String portFilePath = fs.path.join(daemon.daemonWorkspace(workingDirectory.path), '.asset_server_port');
    return int.tryParse(fs.file(portFilePath).readAsStringSync());
  }
}
