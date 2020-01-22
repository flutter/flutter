// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/client.dart';
import 'package:dwds/dwds.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vmservice;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    hide StackTrace;

import '../application_package.dart';
import '../base/async_guard.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/os.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../devfs.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../web/chrome.dart';
import '../web/devfs_web.dart';
import '../web/web_device.dart';
import '../web/web_runner.dart';
import 'web_fs.dart';

/// Injectable factory to create a [ResidentWebRunner].
class DwdsWebRunnerFactory extends WebRunnerFactory {
  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String target,
    @required bool stayResident,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    @required List<String> dartDefines,
    @required UrlTunneller urlTunneller,
  }) {
    if (featureFlags.isWebIncrementalCompilerEnabled && debuggingOptions.buildInfo.isDebug) {
      return _ExperimentalResidentWebRunner(
        device,
        target: target,
        flutterProject: flutterProject,
        debuggingOptions: debuggingOptions,
        ipv6: ipv6,
        stayResident: stayResident,
        dartDefines: dartDefines,
        // TODO(dantup): If this becomes default it may need to urlTunneller.
      );
    }
    return _DwdsResidentWebRunner(
      device,
      target: target,
      flutterProject: flutterProject,
      debuggingOptions: debuggingOptions,
      ipv6: ipv6,
      stayResident: stayResident,
      dartDefines: dartDefines,
      urlTunneller: urlTunneller,
    );
  }
}

/// A hot-runner which handles browser specific delegation.
abstract class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    this.device, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    bool stayResident = true,
    @required this.dartDefines,
  }) : super(
          <FlutterDevice>[],
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
        );

  final FlutterDevice device;
  final FlutterProject flutterProject;
  final List<String> dartDefines;
  DateTime firstBuildTime;

  // Only the debug builds of the web support the service protocol.
  @override
  bool get supportsServiceProtocol => isRunningDebug && deviceIsDebuggable;

  @override
  bool get debuggingEnabled => isRunningDebug && deviceIsDebuggable;

  /// WebServer device is debuggable when running with --start-paused.
  bool get deviceIsDebuggable => device.device is! WebServerDevice || debuggingOptions.startPaused;

  bool get _enableDwds => debuggingEnabled;

  WebFs _webFs;
  ConnectionResult _connectionResult;
  StreamSubscription<vmservice.Event> _stdOutSub;
  bool _exited = false;
  WipConnection _wipConnection;

  vmservice.VmService get _vmService =>
      _connectionResult?.debugConnection?.vmService;

  @override
  bool get canHotRestart {
    return true;
  }

  @override
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRawOnFirstIsolate(
    String method, {
    Map<String, dynamic> params,
  }) async {
    final vmservice.Response response =
        await _vmService.callServiceExtension(method, args: params);
    return response.toJson();
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
    if (_exited) {
      return;
    }
    await _stdOutSub?.cancel();
    await _webFs?.stop();
    await device.device.stopApp(null);
    if (ChromeLauncher.hasChromeInstance) {
      final Chrome chrome = await ChromeLauncher.connectedInstance;
      await chrome.close();
    }
    _exited = true;
  }

  Future<void> _cleanupAndExit() async {
    await _cleanup();
    appFinished();
  }

  @override
  void printHelp({bool details = true}) {
    if (details) {
      return printHelpDetails();
    }
    const String fire = '🔥';
    const String rawMessage =
        '  To hot restart changes while running, press "r". '
        'To hot restart (and refresh the browser), press "R".';
    final String message = globals.terminal.color(
      fire + globals.terminal.bolden(rawMessage),
      TerminalColor.red,
    );
    globals.printStatus(
        'Warning: Flutter\'s support for web development is not stable yet and hasn\'t');
    globals.printStatus('been thoroughly tested in production environments.');
    globals.printStatus('For more information see https://flutter.dev/web');
    globals.printStatus('');
    globals.printStatus(message);
    const String quitMessage = 'To quit, press "q".';
    globals.printStatus('For a more detailed help message, press "h". $quitMessage');
  }

  @override
  Future<void> debugDumpApp() async {
    try {
      await _vmService?.callServiceExtension(
        'ext.flutter.debugDumpApp',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpRenderTree() async {
    try {
      await _vmService?.callServiceExtension(
        'ext.flutter.debugDumpRenderTree',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpLayerTree() async {
    try {
      await _vmService?.callServiceExtension(
        'ext.flutter.debugDumpLayerTree',
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    try {
      await _vmService?.callServiceExtension(
          'ext.flutter.debugDumpSemanticsTreeInTraversalOrder');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePlatform() async {
    try {
      final vmservice.Response response = await _vmService
          ?.callServiceExtension('ext.flutter.platformOverride');
      final String currentPlatform = response.json['value'] as String;
      final String platform = nextPlatform(currentPlatform, featureFlags);
      await _vmService?.callServiceExtension('ext.flutter.platformOverride',
          args: <String, Object>{
            'value': platform,
          });
      globals.printStatus('Switched operating system to $platform');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    try {
      await _vmService?.callServiceExtension(
          'ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleDebugPaintSizeEnabled() async {
    try {
      final vmservice.Response response =
          await _vmService?.callServiceExtension(
        'ext.flutter.debugPaint',
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.debugPaint',
        args: <dynamic, dynamic>{
          'enabled': !(response.json['enabled'] == 'true')
        },
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    try {
      final vmservice.Response response =
          await _vmService?.callServiceExtension(
        'ext.flutter.debugCheckElevationsEnabled',
      );
      await _vmService?.callServiceExtension(
        'ext.flutter.debugCheckElevationsEnabled',
        args: <dynamic, dynamic>{
          'enabled': !(response.json['enabled'] == 'true')
        },
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePerformanceOverlayOverride() async {
    try {
      final vmservice.Response response = await _vmService
          ?.callServiceExtension('ext.flutter.showPerformanceOverlay');
      await _vmService?.callServiceExtension(
        'ext.flutter.showPerformanceOverlay',
        args: <dynamic, dynamic>{
          'enabled': !(response.json['enabled'] == 'true')
        },
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleWidgetInspector() async {
    try {
      final vmservice.Response response = await _vmService
          ?.callServiceExtension('ext.flutter.debugToggleWidgetInspector');
      await _vmService?.callServiceExtension(
        'ext.flutter.debugToggleWidgetInspector',
        args: <dynamic, dynamic>{
          'enabled': !(response.json['enabled'] == 'true')
        },
      );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleProfileWidgetBuilds() async {
    try {
      final vmservice.Response response = await _vmService
          ?.callServiceExtension('ext.flutter.profileWidgetBuilds');
      await _vmService?.callServiceExtension(
        'ext.flutter.profileWidgetBuilds',
        args: <dynamic, dynamic>{
          'enabled': !(response.json['enabled'] == 'true')
        },
      );
    } on vmservice.RPCError {
      return;
    }
  }
}

class _ExperimentalResidentWebRunner extends ResidentWebRunner {
  _ExperimentalResidentWebRunner(
    FlutterDevice device, {
    String target,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    bool stayResident = true,
    @required List<String> dartDefines,
  }) : super(
          device,
          flutterProject: flutterProject,
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
          dartDefines: dartDefines,
        );

  @override
  bool get debuggingEnabled => false;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    firstBuildTime = DateTime.now();
    final ApplicationPackage package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      TargetPlatform.web_javascript,
      applicationBinary: null,
    );
    if (package == null) {
      globals.printError('This application is not configured to build on the web.');
      globals.printError('To add web support to a project, run `flutter create .`.');
      return 1;
    }
    if (!globals.fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message +=
            '\nConsider using the -t option to specify the Dart file to start.';
      }
      globals.printError(message);
      return 1;
    }
    final String modeName = debuggingOptions.buildInfo.friendlyModeName;
    globals.printStatus(
      'Launching ${fsUtils.getDisplayPath(target)} '
      'on ${device.device.name} in $modeName mode...',
    );
    final String effectiveHostname = debuggingOptions.hostname ?? 'localhost';
    final int hostPort = debuggingOptions.port == null
        ? await os.findFreePort()
        : int.tryParse(debuggingOptions.port);
    device.devFS = WebDevFS(
      effectiveHostname,
      hostPort,
      packagesFilePath,
    );
    final Uri url = await device.devFS.create();
    await _updateDevFS(fullRestart: true);
    device.generator.accept();
    await device.device.startApp(
      package,
      mainPath: target,
      debuggingOptions: debuggingOptions,
      platformArgs: <String, Object>{
        'uri': url.toString(),
      },
    );
    return attach(
      connectionInfoCompleter: connectionInfoCompleter,
      appStartedCompleter: appStartedCompleter,
    );
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pause = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    final Stopwatch timer = Stopwatch()..start();
    final Status status = globals.logger.startProgress(
      'Performing hot restart...',
      timeout: supportsServiceProtocol
          ? timeoutConfiguration.fastOperation
          : timeoutConfiguration.slowOperation,
      progressId: 'hot.restart',
    );

    final UpdateFSReport report = await _updateDevFS(fullRestart: fullRestart);
    if (report.success) {
      device.generator.accept();
    } else {
      await device.generator.reject();
    }
    final String modules = report.invalidatedModules
      .map((String module) => '"$module"')
      .join(',');

    try {
      if (fullRestart) {
        await _wipConnection?.sendCommand('Page.reload');
      } else {
        await _wipConnection?.debugger
            ?.sendCommand('Runtime.evaluate', params: <String, Object>{
          'expression': 'window.\$hotReloadHook([$modules])',
          'awaitPromise': true,
          'returnByValue': true,
        });
      }
    } on WipError catch (err) {
      globals.printError(err.toString());
      return OperationResult(1, err.toString());
    } finally {
      status.stop();
    }
    final String verb = fullRestart ? 'Restarted' : 'Reloaded';
    globals.printStatus('$verb application in ${getElapsedAsMilliseconds(timer.elapsed)}.');
    if (!fullRestart) {
      flutterUsage.sendTiming('hot', 'web-incremental-restart', timer.elapsed);
    }
    HotEvent(
      'restart',
      targetPlatform: getNameForTargetPlatform(TargetPlatform.web_javascript),
      sdkName: await device.device.sdkNameAndVersion,
      emulator: false,
      fullRestart: true,
      reason: reason,
    ).send();
    return OperationResult.ok;
  }

  Future<UpdateFSReport> _updateDevFS({bool fullRestart = false}) async {
    final bool isFirstUpload = !assetBundle.wasBuiltOnce();
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      globals.printTrace('Updating assets');
      final int result = await assetBundle.build();
      if (result != 0) {
        return UpdateFSReport(success: false);
      }
    }
    final List<Uri> invalidatedFiles =
        await projectFileInvalidator.findInvalidated(
      lastCompiled: device.devFS.lastCompiled,
      urisToMonitor: device.devFS.sources,
      packagesPath: packagesFilePath,
    );
    final Status devFSStatus = globals.logger.startProgress(
      'Syncing files to device ${device.device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    final UpdateFSReport report = await device.devFS.update(
      mainPath: mainPath,
      target: target,
      bundle: assetBundle,
      firstBuildTime: firstBuildTime,
      bundleFirstUpload: isFirstUpload,
      generator: device.generator,
      fullRestart: fullRestart,
      dillOutputPath: dillOutputPath,
      projectRootPath: projectRootPath,
      pathToReload: getReloadPath(fullRestart: fullRestart),
      invalidatedFiles: invalidatedFiles,
      trackWidgetCreation: true,
    );
    devFSStatus.stop();
    globals.printTrace('Synced ${getSizeAsMB(report.syncedBytes)}.');
    return report;
  }

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async {
    if (device.device is ChromeDevice) {
      final Chrome chrome = await ChromeLauncher.connectedInstance;
      final ChromeTab chromeTab = await chrome.chromeConnection.getTab((ChromeTab chromeTab) {
        return !chromeTab.url.startsWith('chrome-extension');
      });
      if (chromeTab == null) {
        throwToolExit('Failed to connect to Chrome instance.');
      }
      _wipConnection = await chromeTab.connect();
    }
    appStartedCompleter?.complete();
    connectionInfoCompleter?.complete(DebugConnectionInfo());
    if (stayResident) {
      await waitForAppToFinish();
    } else {
      await stopEchoingDeviceLog();
      await exitApp();
    }
    await cleanupAtFinish();
    return 0;
  }
}

class _DwdsResidentWebRunner extends ResidentWebRunner {
  _DwdsResidentWebRunner(
    FlutterDevice device, {
    String target,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    @required this.urlTunneller,
    bool stayResident = true,
    @required List<String> dartDefines,
  }) : super(
          device,
          flutterProject: flutterProject,
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
          dartDefines: dartDefines,
        );

  UrlTunneller urlTunneller;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    firstBuildTime = DateTime.now();
    final ApplicationPackage package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      TargetPlatform.web_javascript,
      applicationBinary: null,
    );
    if (package == null) {
      globals.printError('This application is not configured to build on the web.');
      globals.printError('To add web support to a project, run `flutter create .`.');
      return 1;
    }
    if (!globals.fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message +=
            '\nConsider using the -t option to specify the Dart file to start.';
      }
      globals.printError(message);
      return 1;
    }
    final String modeName = debuggingOptions.buildInfo.friendlyModeName;
    globals.printStatus(
      'Launching ${fsUtils.getDisplayPath(target)} '
      'on ${device.device.name} in $modeName mode...',
    );
    Status buildStatus;
    bool statusActive = false;
    try {
      // dwds does not handle uncaught exceptions from its servers. To work
      // around this, we need to catch all uncaught exceptions and determine if
      // they are fatal or not.
      buildStatus = globals.logger.startProgress('Building application for the web...', timeout: null);
      statusActive = true;
      final int result = await asyncGuard(() async {
        _webFs = await webFsFactory(
          target: target,
          flutterProject: flutterProject,
          buildInfo: debuggingOptions.buildInfo,
          initializePlatform: debuggingOptions.initializePlatform,
          hostname: debuggingOptions.hostname,
          port: debuggingOptions.port,
          urlTunneller: urlTunneller,
          skipDwds: !_enableDwds,
          dartDefines: dartDefines,
        );
        // When connecting to a browser, update the message with a seemsSlow notification
        // to handle the case where we fail to connect.
        buildStatus.stop();
        statusActive = false;
        if (supportsServiceProtocol) {
          buildStatus = globals.logger.startProgress(
            'Attempting to connect to browser instance..',
            timeout: const Duration(seconds: 30),
          );
          statusActive = true;
        }
        await device.device.startApp(
          package,
          mainPath: target,
          debuggingOptions: debuggingOptions,
          platformArgs: <String, Object>{
            'uri': _webFs.uri,
          },
        );
        if (_enableDwds) {
          final bool useDebugExtension = device.device is WebServerDevice && debuggingOptions.startPaused;
          _connectionResult = await _webFs.connect(useDebugExtension);
          unawaited(_connectionResult.debugConnection.onDone.whenComplete(_cleanupAndExit));
        }
        if (statusActive) {
          buildStatus.stop();
          statusActive = false;
        }
        appStartedCompleter?.complete();
        return attach(
          connectionInfoCompleter: connectionInfoCompleter,
          appStartedCompleter: appStartedCompleter,
        );
      });
      return result;
    } on VersionSkew {
      // Thrown if an older build daemon is already running.
      throwToolExit(
          'Another build daemon is already running with an older version.\n'
          'Try exiting other Flutter processes in this project and try again.');
    } on OptionsSkew {
      // Thrown if a build daemon is already running with different configuration.
      throwToolExit(
          'Another build daemon is already running with different configuration.\n'
          'Exit other Flutter processes running in this project and try again.');
    } on WebSocketException {
      throwToolExit('Failed to connect to WebSocket.');
    } on BuildException {
      throwToolExit('Failed to build application for the Web.');
    } on ChromeDebugException catch (err, stackTrace) {
      throwToolExit(
          'Failed to establish connection with Chrome. Try running the application again.\n'
          'If this problem persists, please file an issue with the details below:\n$err\n$stackTrace');
    } on AppConnectionException {
      throwToolExit(
          'Failed to establish connection with the application instance in Chrome.\n'
          'This can happen if the websocket connection used by the web tooling is '
          'unabled to correctly establish a connection, for example due to a firewall.');
    } on MissingPortFile {
      throwToolExit(
          'Failed to connect to build daemon.\nThe daemon either failed to '
          'start or was killed by another process.');
    } on SocketException catch (err) {
      throwToolExit(err.toString());
    } on StateError catch (err) {
      final String message = err.toString();
      if (message.contains('Unable to start build daemon')) {
        throwToolExit('Failed to start build daemon. The process might have '
            'exited unexpectedly during startup. Try running the application '
            'again.');
      }
      rethrow;
    } finally {
      if (statusActive) {
        buildStatus.stop();
      }
    }
    return 1;
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pause = false,
    String reason,
    bool benchmarkMode = false,
  }) async {
    final Stopwatch timer = Stopwatch()..start();
    final Status status = globals.logger.startProgress(
      'Performing hot restart...',
      timeout: supportsServiceProtocol
          ? timeoutConfiguration.fastOperation
          : timeoutConfiguration.slowOperation,
      progressId: 'hot.restart',
    );
    final bool success = await _webFs.recompile();
    if (!success) {
      status.stop();
      return OperationResult(1, 'Failed to recompile application.');
    }
    if (supportsServiceProtocol) {
      // Send an event for only recompilation.
      final Duration recompileDuration = timer.elapsed;
      flutterUsage.sendTiming('hot', 'web-recompile', recompileDuration);
      try {
        final vmservice.Response reloadResponse = fullRestart
          ? await _vmService.callServiceExtension('fullReload')
          : await _vmService.callServiceExtension('hotRestart');
        final String verb = fullRestart ? 'Restarted' : 'Reloaded';
        globals.printStatus(
            '$verb application in ${getElapsedAsMilliseconds(timer.elapsed)}.');

        // Send timing analytics for full restart and for refresh.
        final bool wasSuccessful = reloadResponse.type == 'Success';
        if (!wasSuccessful) {
          return OperationResult(1, reloadResponse.toString());
        }
        if (!fullRestart) {
          flutterUsage.sendTiming('hot', 'web-restart', timer.elapsed);
          flutterUsage.sendTiming('hot', 'web-refresh', timer.elapsed - recompileDuration);
        }
        return OperationResult.ok;
      } on vmservice.RPCError {
        return OperationResult(1, 'Page requires refresh.');
      } finally {
        status.stop();
        HotEvent(
          'restart',
          targetPlatform: getNameForTargetPlatform(TargetPlatform.web_javascript),
          sdkName: await device.device.sdkNameAndVersion,
          emulator: false,
          fullRestart: true,
          reason: reason,
        ).send();
      }
    }
    // Allows browser refresh hot restart on non-debug builds.
    if (device.device is ChromeDevice && !isRunningDebug) {
      try {
        final Chrome chrome = await ChromeLauncher.connectedInstance;
        final ChromeTab chromeTab = await chrome.chromeConnection.getTab((ChromeTab chromeTab) {
          return chromeTab.url.contains(debuggingOptions.hostname);
        });
        final WipConnection wipConnection = await chromeTab.connect();
        await wipConnection.sendCommand('Page.reload');
        status.stop();
        return OperationResult.ok;
      } catch (err) {
        // Ignore error and continue with posted message;
      }
    }
    status.stop();
    globals.printStatus('Recompile complete. Page requires refresh.');
    return OperationResult.ok;
  }

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  }) async {
    Uri websocketUri;
    if (supportsServiceProtocol) {
      // Cleanup old subscriptions. These will throw if there isn't anything
      // listening, which is fine because that is what we want to ensure.
      try {
        await _vmService.streamCancel('Stdout');
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      try {
        await _vmService.streamListen('Stdout');
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      _stdOutSub = _vmService.onStdoutEvent.listen((vmservice.Event log) {
        final String message = utf8.decode(base64.decode(log.bytes)).trim();
        globals.printStatus(message);
      });
      unawaited(_vmService.registerService('reloadSources', 'FlutterTools'));
      websocketUri = Uri.parse(_connectionResult.debugConnection.uri);
      // Always run main after connecting because start paused doesn't work yet.
      if (!debuggingOptions.startPaused || !supportsServiceProtocol) {
        _connectionResult.appConnection.runMain();
      } else {
        StreamSubscription<void> resumeSub;
        resumeSub = _connectionResult.debugConnection.vmService.onDebugEvent
            .listen((vmservice.Event event) {
          if (event.type == vmservice.EventKind.kResume) {
            _connectionResult.appConnection.runMain();
            resumeSub.cancel();
          }
        });
      }
    }
    if (websocketUri != null) {
      globals.printStatus('Debug service listening on $websocketUri');
    }
    connectionInfoCompleter?.complete(DebugConnectionInfo(wsUri: websocketUri));

    if (stayResident) {
      await waitForAppToFinish();
    } else {
      await stopEchoingDeviceLog();
      await exitApp();
    }
    await cleanupAtFinish();
    return 0;
  }
}
