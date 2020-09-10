// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
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
import '../build_system/targets/web.dart';
import '../cache.dart';
import '../dart/language_version.dart';
import '../dart/pub.dart';
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
import '../vmservice.dart';
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
    @required UrlTunneller urlTunneller,
    bool machine = false,
  }) {
    return _ResidentWebRunner(
      device,
      target: target,
      flutterProject: flutterProject,
      debuggingOptions: debuggingOptions,
      ipv6: ipv6,
      stayResident: stayResident,
      urlTunneller: urlTunneller,
      machine: machine,
    );
  }
}

const String kExitMessage = 'Failed to establish connection with the application '
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
    bool machine = false,
  }) : super(
          <FlutterDevice>[device],
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
          machine: machine,
        );

  FlutterDevice get device => flutterDevices.first;
  final FlutterProject flutterProject;
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

  @override
  bool get supportsWriteSkSL => false;

  bool get _enableDwds => debuggingEnabled;

  ConnectionResult _connectionResult;
  StreamSubscription<vmservice.Event> _stdOutSub;
  StreamSubscription<vmservice.Event> _stdErrSub;
  StreamSubscription<vmservice.Event> _extensionEventSub;
  bool _exited = false;
  WipConnection _wipConnection;
  ChromiumLauncher _chromiumLauncher;

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
    await _stdErrSub?.cancel();
    await _extensionEventSub?.cancel();
    await device.device.stopApp(null);
    try {
      _generatedEntrypointDirectory?.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort to clean up temp dirs.
      globals.printTrace(
        'Failed to clean up temp directory: ${_generatedEntrypointDirectory.path}',
      );
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
        '  To hot restart changes while running, press "r" or "R".';
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
    if (device.device is! WebServerDevice) {
      globals.printStatus('For a more detailed help message, press "h". $quitMessage');
    }
  }

  @override
  Future<void> debugDumpApp() async {
    try {
      await _vmService
        ?.flutterDebugDumpApp(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpRenderTree() async {
    try {
      await _vmService
        ?.flutterDebugDumpRenderTree(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpLayerTree() async {
    try {
      await _vmService
        ?.flutterDebugDumpLayerTree(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    try {
      await _vmService
        ?.flutterDebugDumpSemanticsTreeInTraversalOrder(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePlatform() async {
    try {
      final String currentPlatform = await _vmService
        ?.flutterPlatformOverride(
          isolateId: null,
        );
      final String platform = nextPlatform(currentPlatform, featureFlags);
      await _vmService
        ?.flutterPlatformOverride(
            platform: platform,
            isolateId: null,
          );
      globals.printStatus('Switched operating system to $platform');
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleBrightness() async {
    try {
      final Brightness currentBrightness = await _vmService
        ?.flutterBrightnessOverride(
          isolateId: null,
        );
      Brightness next;
      if (currentBrightness == Brightness.light) {
        next = Brightness.dark;
      } else if (currentBrightness == Brightness.dark) {
        next = Brightness.light;
      }
      next = await _vmService
        ?.flutterBrightnessOverride(
            brightness: next,
            isolateId: null,
          );
      globals.logger.printStatus('Changed brightness to $next.');
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
      await _vmService
        ?.flutterDebugDumpSemanticsTreeInInverseHitTestOrder(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleDebugPaintSizeEnabled() async {
    try {
      await _vmService
        ?.flutterToggleDebugPaintSizeEnabled(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    try {
      await _vmService
        ?.flutterToggleDebugCheckElevationsEnabled(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugTogglePerformanceOverlayOverride() async {
    try {
      await _vmService
        ?.flutterTogglePerformanceOverlayOverride(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleWidgetInspector() async {
    try {
      await _vmService
        ?.flutterToggleWidgetInspector(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleInvertOversizedImages() async {
    try {
      await _vmService
        ?.flutterToggleInvertOversizedImages(
          isolateId: null,
        );
    } on vmservice.RPCError {
      return;
    }
  }

  @override
  Future<void> debugToggleProfileWidgetBuilds() async {
    try {
      await _vmService
        ?.flutterToggleProfileWidgetBuilds(
          isolateId: null,
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
    @required this.urlTunneller,
    bool machine = false,
  }) : super(
          device,
          flutterProject: flutterProject,
          target: target ?? globals.fs.path.join('lib', 'main.dart'),
          debuggingOptions: debuggingOptions,
          ipv6: ipv6,
          stayResident: stayResident,
          machine: machine,
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
      buildInfo: debuggingOptions.buildInfo,
      applicationBinary: null,
    );
    if (package == null) {
      globals.printStatus('This application is not configured to build on the web.');
      globals.printStatus('To add web support to a project, run `flutter create .`.');
    }
    if (!globals.fs.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null) {
        message +=
            '\nConsider using the -t option to specify the Dart file to start.';
      }
      globals.printError(message);
      appFailedToStart();
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

    if (device.device is ChromiumDevice) {
      _chromiumLauncher = (device.device as ChromiumDevice).chromeLauncher;
    }

    try {
      return await asyncGuard(() async {
        // Ensure dwds resources are cached. If the .packages file is missing then
        // the client.js script cannot be located by the injected handler in dwds.
        // This will result in a NoSuchMethodError thrown by injected_handler.darts
        await pub.get(
          context: PubContext.pubGet,
          directory: globals.fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools'),
          generateSyntheticPackage: false,
        );

        final ExpressionCompiler expressionCompiler =
          debuggingOptions.webEnableExpressionEvaluation
              ? WebExpressionCompiler(device.generator)
              : null;

        device.devFS = WebDevFS(
          hostname: effectiveHostname,
          port: hostPort,
          packagesFilePath: packagesFilePath,
          urlTunneller: urlTunneller,
          useSseForDebugProxy: debuggingOptions.webUseSseForDebugProxy,
          useSseForDebugBackend: debuggingOptions.webUseSseForDebugBackend,
          buildInfo: debuggingOptions.buildInfo,
          enableDwds: _enableDwds,
          entrypoint: globals.fs.file(target).uri,
          expressionCompiler: expressionCompiler,
          chromiumLauncher: _chromiumLauncher,
          nullAssertions: debuggingOptions.nullAssertions,
        );
        final Uri url = await device.devFS.create();
        if (debuggingOptions.buildInfo.isDebug) {
          final UpdateFSReport report = await _updateDevFS(fullRestart: true);
          if (!report.success) {
            globals.printError('Failed to compile application.');
            appFailedToStart();
            return 1;
          }
          device.generator.accept();
          cacheInitialDillCompilation();
        } else {
          await buildWeb(
            flutterProject,
            target,
            debuggingOptions.buildInfo,
            debuggingOptions.initializePlatform,
            false,
            kNoneWorker,
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
      appFailedToStart();
      throwToolExit(kExitMessage);
    } on ChromeDebugException {
      appFailedToStart();
      throwToolExit(kExitMessage);
    } on AppConnectionException {
      appFailedToStart();
      throwToolExit(kExitMessage);
    } on SocketException {
      appFailedToStart();
      throwToolExit(kExitMessage);
    } on Exception {
      appFailedToStart();
      rethrow;
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

    if (debuggingOptions.buildInfo.isDebug) {
      await runSourceGenerators();
      // Full restart is always false for web, since the extra recompile is wasteful.
      final UpdateFSReport report = await _updateDevFS(fullRestart: false);
      if (report.success) {
        device.generator.accept();
      } else {
        status.stop();
        await device.generator.reject();
        return OperationResult(1, 'Failed to recompile application.');
      }
    } else {
      try {
        await buildWeb(
          flutterProject,
          target,
          debuggingOptions.buildInfo,
          debuggingOptions.initializePlatform,
          false,
          kNoneWorker,
        );
      } on ToolExit {
        return OperationResult(1, 'Failed to recompile application.');
      }
    }

    try {
      if (!deviceIsDebuggable) {
        globals.printStatus('Recompile complete. Page requires refresh.');
      } else if (isRunningDebug) {
        await _vmService.callMethod('hotRestart');
      } else {
        // On non-debug builds, a hard refresh is required to ensure the
        // up to date sources are loaded.
        await _wipConnection?.sendCommand('Page.reload', <String, Object>{
          'ignoreCache': !debuggingOptions.buildInfo.isDebug,
        });
      }
    } on Exception catch (err) {
      return OperationResult(1, err.toString(), fatal: true);
    } finally {
      status.stop();
    }

    final String elapsed = getElapsedAsMilliseconds(timer.elapsed);
    globals.printStatus('Restarted application in $elapsed.');

    // Don't track restart times for dart2js builds or web-server devices.
    if (debuggingOptions.buildInfo.isDebug && deviceIsDebuggable) {
      globals.flutterUsage.sendTiming('hot', 'web-incremental-restart', timer.elapsed);
      HotEvent(
        'restart',
        targetPlatform: getNameForTargetPlatform(TargetPlatform.web_javascript),
        sdkName: await device.device.sdkNameAndVersion,
        emulator: false,
        fullRestart: true,
        reason: reason,
        overallTimeInMs: timer.elapsed.inMilliseconds,
        nullSafety: usageNullSafety,
      ).send();
    }
    return OperationResult.ok;
  }

  // Flutter web projects need to include a generated main entrypoint to call the
  // appropriate bootstrap method and inject plugins.
  // Keep this in sync with build_system/targets/web.dart.
  Future<Uri> _generateEntrypoint(Uri mainUri, PackageConfig packageConfig) async {
    File result = _generatedEntrypointDirectory?.childFile('web_entrypoint.dart');
    if (_generatedEntrypointDirectory == null) {
      _generatedEntrypointDirectory ??= globals.fs.systemTempDirectory.createTempSync('flutter_tools.')
        ..createSync();
      result = _generatedEntrypointDirectory.childFile('web_entrypoint.dart');

      final bool hasWebPlugins = (await findPlugins(flutterProject))
        .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
      await injectPlugins(flutterProject, checkProjects: true);

      final Uri generatedUri = globals.fs.currentDirectory
        .childDirectory('lib')
        .childFile('generated_plugin_registrant.dart')
        .absolute.uri;
      final Uri generatedImport = packageConfig.toPackageUri(generatedUri);
      Uri importedEntrypoint = packageConfig.toPackageUri(mainUri);
      // Special handling for entrypoints that are not under lib, such as test scripts.
      if (importedEntrypoint == null) {
        final String parent = globals.fs.file(mainUri).parent.path;
        flutterDevices.first.generator.addFileSystemRoot(parent);
        flutterDevices.first.generator.addFileSystemRoot(globals.fs.directory('test').absolute.path);
        importedEntrypoint = Uri(
          scheme: 'org-dartlang-app',
          path: '/' + mainUri.pathSegments.last,
        );
      }

      final String entrypoint = <String>[
        determineLanguageVersion(
          globals.fs.file(mainUri),
          packageConfig[flutterProject.manifest.appName],
        ),
        '// Flutter web bootstrap script for $importedEntrypoint.',
        '',
        "import 'dart:ui' as ui;",
        "import 'dart:async';",
        '',
        "import '$importedEntrypoint' as entrypoint;",
        if (hasWebPlugins)
          "import 'package:flutter_web_plugins/flutter_web_plugins.dart';",
        if (hasWebPlugins)
          "import '$generatedImport';",
        '',
        'typedef _UnaryFunction = dynamic Function(List<String> args);',
        'typedef _NullaryFunction = dynamic Function();',
        'Future<void> main() async {',
        if (hasWebPlugins)
          '  registerPlugins(webPluginRegistry);',
        '  await ui.webOnlyInitializePlatform();',
        '  if (entrypoint.main is _UnaryFunction) {',
        '    return (entrypoint.main as _UnaryFunction)(<String>[]);',
        '  }',
        '  return (entrypoint.main as _NullaryFunction)();',
        '}',
        '',
      ].join('\n');
      result.writeAsStringSync(entrypoint);
    }
    return result.absolute.uri;
  }

  Future<UpdateFSReport> _updateDevFS({bool fullRestart = false}) async {
    final bool isFirstUpload = !assetBundle.wasBuiltOnce();
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      globals.printTrace('Updating assets');
      final int result = await assetBundle.build(packagesPath: debuggingOptions.buildInfo.packagesPath);
      if (result != 0) {
        return UpdateFSReport(success: false);
      }
    }
    final InvalidationResult invalidationResult = await projectFileInvalidator.findInvalidated(
      lastCompiled: device.devFS.lastCompiled,
      urisToMonitor: device.devFS.sources,
      packagesPath: packagesFilePath,
      packageConfig: device.devFS.lastPackageConfig,
    );
    final Status devFSStatus = globals.logger.startProgress(
      'Syncing files to device ${device.device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    final UpdateFSReport report = await device.devFS.update(
      mainUri: await _generateEntrypoint(
        globals.fs.file(mainPath).absolute.uri,
        invalidationResult.packageConfig,
      ),
      target: target,
      bundle: assetBundle,
      firstBuildTime: firstBuildTime,
      bundleFirstUpload: isFirstUpload,
      generator: device.generator,
      fullRestart: fullRestart,
      dillOutputPath: dillOutputPath,
      projectRootPath: projectRootPath,
      pathToReload: getReloadPath(fullRestart: fullRestart, swap: false),
      invalidatedFiles: invalidationResult.uris,
      packageConfig: invalidationResult.packageConfig,
      trackWidgetCreation: debuggingOptions.buildInfo.trackWidgetCreation,
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
    if (_chromiumLauncher != null) {
      final Chromium chrome = await _chromiumLauncher.connectedInstance;
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

      void onLogEvent(vmservice.Event event)  {
        final String message = processVmServiceMessage(event);
        globals.printStatus(message);
      }

      _stdOutSub = _vmService.onStdoutEvent.listen(onLogEvent);
      _stdErrSub = _vmService.onStderrEvent.listen(onLogEvent);
      _extensionEventSub =
          _vmService.onExtensionEvent.listen(printStructuredErrorLog);
      try {
        await _vmService.streamListen(vmservice.EventStreams.kStdout);
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      try {
        await _vmService.streamListen(vmservice.EventStreams.kStderr);
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      try {
        await _vmService.streamListen(vmservice.EventStreams.kIsolate);
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      try {
        await _vmService.streamListen(vmservice.EventStreams.kExtension);
      } on vmservice.RPCError {
        // It is safe to ignore this error because we expect an error to be
        // thrown if we're not already subscribed.
      }
      unawaited(_vmService.registerService('reloadSources', 'FlutterTools'));
      _vmService.registerServiceCallback('reloadSources', (Map<String, Object> params) async {
        final bool pause = params['pause'] as bool ?? false;
        await restart(benchmarkMode: false, pause: pause, fullRestart: false);
        return <String, Object>{'type': 'Success'};
      });

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
      if (debuggingOptions.vmserviceOutFile != null) {
        globals.fs.file(debuggingOptions.vmserviceOutFile)
          ..createSync(recursive: true)
          ..writeAsStringSync(websocketUri.toString());
      }
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
  bool get supportsCanvasKit => supportsServiceProtocol;

  @override
  Future<bool> toggleCanvaskit() async {
    final WebDevFS webDevFS = device.devFS as WebDevFS;
    webDevFS.webAssetServer.canvasKitRendering = !webDevFS.webAssetServer.canvasKitRendering;
    await _wipConnection?.sendCommand('Page.reload');
    return webDevFS.webAssetServer.canvasKitRendering;
  }

  @override
  Future<void> exitApp() async {
    await device.exitApps();
    appFinished();
  }
}
