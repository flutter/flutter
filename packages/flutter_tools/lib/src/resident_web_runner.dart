// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:dwds/service.dart';
import 'package:logging/logging.dart' as logging;
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/src/request.dart';
import 'package:vm_service_lib/vm_service_lib.dart' as vmservice;
import 'package:webdev/src/command/configuration.dart';
import 'package:webdev/src/daemon_client.dart';
import 'package:webdev/src/logging.dart';
import 'package:webdev/src/serve/chrome.dart';
import 'package:webdev/src/serve/debugger/app_debug_services.dart';
import 'package:webdev/src/serve/debugger/devtools.dart';
import 'package:webdev/src/serve/handlers/dev_handler.dart';
import 'package:webdev/src/serve/server_manager.dart';
import 'package:webdev/src/serve/webdev_server.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/terminal.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'cache.dart';
import 'convert.dart';
import 'device.dart';
import 'globals.dart';
import 'project.dart';
import 'resident_runner.dart';
import 'run_hot.dart';

import 'web/asset_server.dart';

Future<BuildDaemonClient> connectClient(
  String workingDirectory,
  List<String> options,
  Function(ServerLog) logHandler,
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
      '--delete-conflicting-outputs',
      '--define', 'flutter_tools:ddc=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=release=false', // hard coded for now
      '--define', 'flutter_tools:shell=flutterWebSdk=$flutterWebSdk',
      ...options,
    ],
    logHandler: logHandler,
  );
}

Future<BuildDaemonClient> _startBuildDaemon(String workingDirectory, List<String> buildOptions) async {
  try {
    return await connectClient(
      workingDirectory,
      buildOptions,
      (ServerLog serverLog) {
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
    );
  } on OptionsSkew {
    throw StateError(
        'Incompatible options with current running build daemon.\n\n'
        'Please stop other WebDev instances running in this directory '
        'before starting a new instance with these options.');
  }
}

Future<Chrome> _startChrome(
  Configuration configuration,
  ServerManager serverManager,
  BuildDaemonClient client,
) async {
  final List<String> uris =
      serverManager.servers.map((WebDevServer s) => 'http://${s.host}:${s.port}/').toList();
  try {
    return await Chrome.start(uris, port: configuration.chromeDebugPort);
  } on ChromeError {
    await serverManager.stop();
    await client.close();
    rethrow;
  }
}

Future<DevTools> _startDevTools(
  Configuration configuration,
) async {
  DevTools devTool;
  try {
    devTool = await DevTools.start(configuration.hostname);
      printTrace('Serving DevTools at http://${devTool.hostname}:${devTool.port}\n');
  } catch (err) {}
  return devTool;
}

void _registerBuildTargets(
  BuildDaemonClient client,
  Configuration configuration,
  Map<String, int> targetPorts,
) {
  // Register a target for each serve target.
  for (String target in targetPorts.keys) {
    OutputLocation outputLocation;
    if (configuration.outputPath != null &&
        (configuration.outputInput == null ||
            target == configuration.outputInput)) {
      outputLocation = OutputLocation((OutputLocationBuilder b) => b
        ..output = configuration.outputPath
        ..useSymlinks = true
        ..hoist = true);
    }
    client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) => b
      ..target = target
      ..outputLocation = outputLocation?.toBuilder()));
  }
  // Empty string indicates we should build everything, register a corresponding
  // target.
  if (configuration.outputInput == '') {
    final OutputLocation outputLocation = OutputLocation((OutputLocationBuilder b) => b
      ..output = configuration.outputPath
      ..useSymlinks = true
      ..hoist = false);
    client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) => b
      ..target = ''
      ..outputLocation = outputLocation?.toBuilder()));
  }
}

Future<ServerManager> _startServerManager(
  Configuration configuration,
  Map<String, int> targetPorts,
  String workingDirectory,
  BuildDaemonClient client,
  DevTools devTools,
  Handler handler,
) async {
  final int assetPort = daemonPort(workingDirectory);
  final Set<ServerOptions> serverOptions = <ServerOptions>{};
  for (String target in targetPorts.keys) {
    serverOptions.add(ServerOptions(
      configuration,
      targetPorts[target],
      target,
      assetPort,
      handler,
    ));
  }
  logWriter(logging.Level.INFO, 'Starting resource servers...');
  final ServerManager serverManager =
      await ServerManager.start(serverOptions, client.buildResults, devTools);

  for (WebDevServer server in serverManager.servers) {
    printTrace(
      'Serving `${server.target}` on '
      'http://${server.host}:${server.port}\n');
  }

  return serverManager;
}

/// A hot-runner which handles browser specific delegation.
class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(this.device, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
  }) : super(
          <FlutterDevice>[],
          target: target,
          usesTerminalUI: true,
          stayResident: true,
          saveCompilationTrace: false,
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
        );

  final Device device;
  // WebAssetServer _server;
  ProjectFileInvalidator projectFileInvalidator;
  // WipConnection _connection;
  final FlutterProject flutterProject;

  StreamSubscription<BuildResults> _buildResults;
  DevTools _devTools;
  Chrome _chrome;
  ServerManager _serverManager;
  BuildDaemonClient _client;
  AppDebugServices _appDebugServices;

  DebugService get _debugService => _appDebugServices?.debugService;

  vmservice.VmService get _vmService => _appDebugServices?.webdevClient?.client;

  StreamSubscription<BuildResult> _resultSub;

  StreamSubscription<vmservice.Event> _stdOutSub;
  //String _appId;

  @override
  Future<int> attach(
      {Completer<DebugConnectionInfo> connectionInfoCompleter,
      Completer<void> appStartedCompleter}) async {
    // Connect to app and invoke main.
    final DevHandler devHandler = _serverManager.servers.first.devHandler;
    // This should probably only be for a single app for now..

    final DevConnection connection = await devHandler.connectedApps.first;
    await _stdOutSub?.cancel();
    await _resultSub?.cancel();
    _appDebugServices = await devHandler.loadAppServices(
        connection.request.appId, connection.request.instanceId);
    //_appId = connection.request.appId;

    // When a tab is closed we exit an app.
    unawaited(_appDebugServices.chromeProxyService.tabConnection.onClose.first.then((_) {
      appFinished();
    }));

    // Cleanup old subscriptions.
    try {
      await _vmService.streamCancel('Stdout');
    } catch (_) {}
    try {
      await _vmService.streamListen('Stdout');
    } catch (_) {}

    _stdOutSub = _vmService.onStdoutEvent.listen((vmservice.Event log) {
      // TODO: determine correct print to let daemon pick.
      printStatus(utf8.decode(base64.decode(log.bytes)));
    });

    // Response with debug info!
    // How does this map from the existing code?
    connectionInfoCompleter?.complete(DebugConnectionInfo(
      wsUri: Uri.parse(_debugService.wsUri),
    ));
    // Run main!
    connection.runMain();
    _resultSub = devHandler.buildResults.listen(_handleBuildResult);
    setupTerminal();
    final int result = await waitForAppToFinish();
    await cleanupAtFinish();
    return result;
  }

  void _handleBuildResult(BuildResult result) {
    printStatus(result.status.name);
  }

  @override
  Future<void> cleanupAfterSignal() async {
    await _cleanup();
  }

  @override
  Future<void> cleanupAtFinish() async {
    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _buildResults?.cancel();
    await _chrome?.close();
    await _client?.close();
    await _devTools?.close();
    await _serverManager?.stop();
  }

  @override
  Future<void> handleTerminalCommand(String code) async {
    if (code == 'R') {
      // If hot restart is not supported for all devices, ignore the command.
      if (!canHotRestart) {
        return;
      }
      await restart(fullRestart: true);
    }
  }

  @override
  void printHelp({bool details}) {
    if (details) {
      return printHelpDetails();
    }
    const String fire = '🔥';
    const String rawMessage =
        '  To hot restart (and rebuild state), press "R".';
    final String message = terminal.color(
      fire + terminal.bolden(rawMessage),
      TerminalColor.red,
    );
    const String warning = '👻 ';
    printStatus(warning * 20);
    printStatus('Warning: Flutter\'s support for building web applications is highly experimental.');
    printStatus('For more information see https://github.com/flutter/flutter/issues/34082.');
    printStatus(warning * 20);
    printStatus('');
    printStatus(message);
    const String quitMessage = 'To quit, press "q".';
    printStatus('For a more detailed help message, press "h". $quitMessage');
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
    bool shouldBuild = true,
  }) async {
    final ApplicationPackage package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      TargetPlatform.web_javascript,
      applicationBinary: null,
    );
    if (package == null) {
      printError('No application found for TargetPlatform.web_javascript');
      return 1;
    }
    if (!fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message +=
            '\nConsider using the -t option to specify the Dart file to start.';
      }
      printError(message);
      return 1;
    }
    // Create configuration.
    final Configuration configuration = Configuration(
      autoRun: true,
      logRequests: true,
      verbose: true,
      debug: true,
      hostname: 'localhost',
    );
    final Map<String, int> targetPorts = <String, int>{
      'web': await os.findFreePort()
    };

    /// Start the build daemon and run an initial build.
    final List<String> buildOptions = <String>[];
    final String workingDirectory = fs.currentDirectory.path;
    _client = await _startBuildDaemon(workingDirectory, buildOptions);
    _client.startBuild();

    // Listen to build results to log error messages.
    _buildResults = _client.buildResults.listen((BuildResults data) {
      if (data.results.any((BuildResult result) =>
          result.status == BuildStatus.failed ||
          result.status == BuildStatus.succeeded)) {
        printTrace(data.results.toString());
      }
    });

    // Register the current build targets.
    _registerBuildTargets(_client, configuration, targetPorts);

    // Start the daemon build.
    _client.startBuild();

    // Start flutter dev tools.
    _devTools = await _startDevTools(configuration);

    // Start the server manager?

    print('1');
    _serverManager = await _startServerManager(
      configuration, targetPorts, workingDirectory, _client, _devTools, (Request request) async {
      print('Looking for ${request.url}');
      if (request.url.path.contains('main.dart.js')) {
        final File file = fs.file(fs.path.join(
          flutterProject.dartTool.path,
          'build',
          'flutter_web',
          flutterProject.manifest.appName,
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
          flutterProject.dartTool.path,
          'build',
          'flutter_web',
          flutterProject.manifest.appName,
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
          flutterProject.dartTool.path,
          'build',
          'flutter_web',
          flutterProject.manifest.appName,
          'lib',
          'main_web_entrypoint.digests',
        ));
        return Response.ok(file.readAsBytesSync());
      }
      return Response.notFound('');
    });

    // Start chrome?
    print('2');
    _chrome = await _startChrome(configuration, _serverManager, _client);

    // We don't support the debugging proxy yet.
    appStartedCompleter?.complete();
    print('3');
    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pauseAfterRestart = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    if (!fullRestart) {
      return OperationResult(1, 'hotReload not supported');
    }
    final Stopwatch timer = Stopwatch()..start();
    final Status status = logger.startProgress(
      'Performing hot restart...',
      timeout: timeoutConfiguration.fastOperation,
      progressId: 'hot.restart',
    );
    final vmservice.Response reloadResponse = await _vmService.callServiceExtension('hotRestart');
    status.stop();
    printStatus('Restarted application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
    return reloadResponse.type == 'Success'
        ? OperationResult.ok
        : OperationResult(1, reloadResponse.toString());
  }

  @override
  Future<void> debugDumpApp() async {
    await _vmService.callServiceExtension(
      'ext.flutter.debugDumpApp',
    );
  }

  @override
  Future<void> debugDumpRenderTree() async {
    await _vmService.callServiceExtension(
      'ext.flutter.debugDumpRenderTree',
    );
  }

  @override
  Future<void> debugDumpLayerTree() async {
    await _vmService.callServiceExtension(
      'ext.flutter.debugDumpLayerTree',
    );
  }

  @override
  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    await _vmService.callServiceExtension(
        'ext.flutter.debugDumpSemanticsTreeInTraversalOrder');
  }

  @override
  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    await _vmService.callServiceExtension(
        'ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder');
  }


  @override
  Future<void> debugToggleDebugPaintSizeEnabled() async {
    final vmservice.Response response = await _vmService.callServiceExtension(
      'ext.flutter.debugPaint',
    );
    await _vmService.callServiceExtension(
      'ext.flutter.debugPaint',
      args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
    );
  }

  @override
  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    final vmservice.Response response = await _vmService.callServiceExtension(
      'ext.flutter.debugCheckElevationsEnabled',
    );
    await _vmService.callServiceExtension(
      'ext.flutter.debugCheckElevationsEnabled',
      args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
    );
  }

  @override
  Future<void> debugTogglePerformanceOverlayOverride() async {
    final vmservice.Response response = await _vmService.callServiceExtension(
      'ext.flutter.showPerformanceOverlay'
    );
    await _vmService.callServiceExtension(
      'ext.flutter.showPerformanceOverlay',
      args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
    );
  }

  @override
  Future<void> debugToggleWidgetInspector() async {
    final vmservice.Response response = await _vmService.callServiceExtension(
      'ext.flutter.debugToggleWidgetInspector'
    );
    await _vmService.callServiceExtension(
      'ext.flutter.debugToggleWidgetInspector',
      args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
    );
  }

  @override
  Future<void> debugToggleProfileWidgetBuilds() async {
    final vmservice.Response response = await _vmService.callServiceExtension(
      'ext.flutter.profileWidgetBuilds'
    );
    await _vmService.callServiceExtension(
      'ext.flutter.profileWidgetBuilds',
      args: <dynamic, dynamic>{'enabled': !(response.json['enabled'] == 'true')},
    );
  }
}
