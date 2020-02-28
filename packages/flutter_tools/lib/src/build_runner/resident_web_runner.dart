// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../compile.dart';
import '../convert.dart';
import '../devfs.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/web_device.dart';
import '../web/web_runner.dart';
import 'devfs_web.dart';

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
    return _ResidentWebRunner(
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

const String kExitMessage =  'Failed to establish connection with the application '
  'instance in Chrome.\nThis can happen if the websocket connection used by the '
  'web tooling is unable to correctly establish a connection, for example due to a firewall.';

/// A hot-runner which handles browser specific delegation.
abstract class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    FlutterDevice device, {
    String target,
    @required this.flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    bool stayResident = true,
    @required this.dartDefines,
  }) : super(
          <FlutterDevice>[device],
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
        );

  FlutterDevice get device => flutterDevices.first;
  final FlutterProject flutterProject;
  final List<String> dartDefines;
  DateTime firstBuildTime;

  // Used with the new compiler to generate a bootstrap file containing plugins
  // and platform initialization.
  Directory _generatedEntrypointDirectory;

  // Only the debug builds of the web support the service protocol.
  @override
  bool get supportsServiceProtocol => isRunningDebug && deviceIsDebuggable;

  @override
  bool get debuggingEnabled => isRunningDebug && deviceIsDebuggable;

  /// WebServer device is debuggable when running with --start-paused.
  bool get deviceIsDebuggable => device.device is! WebServerDevice || debuggingOptions.startPaused;

  bool get _enableDwds => debuggingEnabled;

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
    await device.device.stopApp(null);
    try {
      _generatedEntrypointDirectory?.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort to clean up temp dirs.
      globals.printTrace(
        'Failed to clean up temp directory: ${_generatedEntrypointDirectory.path}',
      );
    }
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
        "Warning: Flutter's support for web development is not stable yet and hasn't");
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
  Future<void> stopEchoingDeviceLog() async {
    // Do nothing for ResidentWebRunner
    await device.stopEchoingDeviceLog();
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

class _ResidentWebRunner extends ResidentWebRunner {
  _ResidentWebRunner(
    FlutterDevice device, {
    String target,
    @required FlutterProject flutterProject,
    @required bool ipv6,
    @required DebuggingOptions debuggingOptions,
    bool stayResident = true,
    @required List<String> dartDefines,
    @required this.urlTunneller,
  }) : super(
          device,
          flutterProject: flutterProject,
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
          dartDefines: dartDefines,
        );

  final UrlTunneller urlTunneller;

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
      'Launching ${globals.fsUtils.getDisplayPath(target)} '
      'on ${device.device.name} in $modeName mode...',
    );
    final String effectiveHostname = debuggingOptions.hostname ?? 'localhost';
    final int hostPort = debuggingOptions.port == null
        ? await globals.os.findFreePort()
        : int.tryParse(debuggingOptions.port);

    try {
      return await asyncGuard(() async {
        device.devFS = WebDevFS(
          hostname: effectiveHostname,
          port: hostPort,
          packagesFilePath: packagesFilePath,
          urlTunneller: urlTunneller,
          buildMode: debuggingOptions.buildInfo.mode,
          enableDwds: _enableDwds,
          entrypoint: globals.fs.file(target).uri,
        );
        final Uri url = await device.devFS.create();
        if (debuggingOptions.buildInfo.isDebug) {
          final UpdateFSReport report = await _updateDevFS(fullRestart: true);
          if (!report.success) {
            globals.printError('Failed to compile application.');
            return 1;
          }
          device.generator.accept();
        } else {
          await buildWeb(
            flutterProject,
            target,
            debuggingOptions.buildInfo,
            debuggingOptions.initializePlatform,
            dartDefines,
            false,
          );
        }
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
      });
    } on WebSocketException {
      throwToolExit(kExitMessage);
    } on ChromeDebugException {
      throwToolExit(kExitMessage);
    } on AppConnectionException {
      throwToolExit(kExitMessage);
    } on SocketException {
      throwToolExit(kExitMessage);
    }
    return 0;
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

    String reloadModules;
    if (debuggingOptions.buildInfo.isDebug) {
      // Full restart is always false for web, since the extra recompile is wasteful.
      final UpdateFSReport report = await _updateDevFS(fullRestart: false);
      if (report.success) {
        device.generator.accept();
      } else {
        status.stop();
        await device.generator.reject();
        return OperationResult(1, 'Failed to recompile application.');
      }
      reloadModules = report.invalidatedModules
        .map((String module) => '"$module"')
        .join(',');
    } else {
      try {
        await buildWeb(
          flutterProject,
          target,
          debuggingOptions.buildInfo,
          debuggingOptions.initializePlatform,
          dartDefines,
          false,
        );
      } on ToolExit {
        return OperationResult(1, 'Failed to recompile application.');
      }
    }

    Duration transferMarker;
    try {
      if (!deviceIsDebuggable) {
        globals.printStatus('Recompile complete. Page requires refresh.');
      } else if (!debuggingOptions.buildInfo.isDebug) {
        // On non-debug builds, a hard refresh is required to ensure the
        // up to date sources are loaded.
        await _wipConnection?.sendCommand('Page.reload', <String, Object>{
          'ignoreCache': !debuggingOptions.buildInfo.isDebug,
        });
      } else {
        transferMarker = timer.elapsed;
        await _wipConnection?.debugger?.sendCommand(
          'Runtime.evaluate', params: <String, Object>{
            'expression': 'window.\$hotReloadHook([$reloadModules])',
            'awaitPromise': true,
            'returnByValue': true,
          },
        );
      }
    } on WipError catch (err) {
      globals.printError(err.toString());
      return OperationResult(1, err.toString());
    } finally {
      status.stop();
    }

    final String elapsed = getElapsedAsMilliseconds(timer.elapsed);
    globals.printStatus('Restarted application in $elapsed.');

    // Don't track restart times for dart2js builds or web-server devices.
    if (debuggingOptions.buildInfo.isDebug && deviceIsDebuggable) {
      flutterUsage.sendTiming('hot', 'web-incremental-restart', timer.elapsed);
      HotEvent(
        'restart',
        targetPlatform: getNameForTargetPlatform(TargetPlatform.web_javascript),
        sdkName: await device.device.sdkNameAndVersion,
        emulator: false,
        fullRestart: true,
        reason: reason,
        overallTimeInMs: timer.elapsed.inMilliseconds,
        transferTimeInMs: timer.elapsed.inMilliseconds - transferMarker.inMilliseconds
      ).send();
    }
    return OperationResult.ok;
  }

  // Flutter web projects need to include a generated main entrypoint to call the
  // appropriate bootstrap method and inject plugins.
  // Keep this in sync with build_system/targets/web.dart.
  Future<String> _generateEntrypoint(String main, String packagesPath) async {
    File result = _generatedEntrypointDirectory?.childFile('web_entrypoint.dart');
    if (_generatedEntrypointDirectory == null) {
      _generatedEntrypointDirectory ??= globals.fs.systemTempDirectory.createTempSync('flutter_tools.')
        ..createSync();
      result = _generatedEntrypointDirectory.childFile('web_entrypoint.dart');

      final bool hasWebPlugins = findPlugins(flutterProject)
        .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
      await injectPlugins(flutterProject, checkProjects: true);

      final PackageUriMapper packageUriMapper = PackageUriMapper(main, packagesPath, null, null);
      final String generatedPath = globals.fs.currentDirectory
        .childDirectory('lib')
        .childFile('generated_plugin_registrant.dart')
        .absolute.path;
      final Uri generatedImport = packageUriMapper.map(generatedPath);
      final String importedEntrypoint = packageUriMapper.map(main).toString() ?? 'file://$main';

      final String entrypoint = <String>[
        'import "$importedEntrypoint" as entrypoint;',
        'import "dart:ui" as ui;',
        if (hasWebPlugins)
          'import "package:flutter_web_plugins/flutter_web_plugins.dart";',
        if (hasWebPlugins)
          'import "$generatedImport";',
        'Future<void> main() async {',
        if (hasWebPlugins)
          '  registerPlugins(webPluginRegistry);',
        '  await ui.webOnlyInitializePlatform();',
        '  entrypoint.main();',
        '}',
      ].join('\n');
      result.writeAsStringSync(entrypoint);
    }
    return result.path;
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
      mainPath: await _generateEntrypoint(mainPath, packagesFilePath),
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
    Uri websocketUri;
    if (supportsServiceProtocol) {
      final WebDevFS webDevFS = device.devFS as WebDevFS;
      final bool useDebugExtension = device.device is WebServerDevice && debuggingOptions.startPaused;
      _connectionResult = await webDevFS.connect(useDebugExtension);
      unawaited(_connectionResult.debugConnection.onDone.whenComplete(_cleanupAndExit));

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
      _vmService.registerServiceCallback('reloadSources', (Map<String, Object> params) async {
        final bool pause = params['pause'] as bool ?? false;
        await restart(benchmarkMode: false, pause: pause, fullRestart: false);
        return <String, Object>{'type': 'Success'};
      });
      // Note: can't register our own hot restart hook. Would be fixed by moving
      // to DWDS digests.

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
    appStartedCompleter?.complete();
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

  @override
  Future<void> exitApp() async {
    await device.exitApps();
    appFinished();
  }
}
