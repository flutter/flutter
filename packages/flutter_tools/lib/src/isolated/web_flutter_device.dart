// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dds/dds.dart';
import 'package:dwds/dwds.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vmservice;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../application_package.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/template.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../dart/language_version.dart';
import '../dart/package_map.dart';
import '../devfs.dart';
import '../device.dart';
import '../flutter_plugins.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../version.dart';
import '../vmservice.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web/file_generators/main_dart.dart' as main_dart;
import '../web/web_debug_config.dart';
import '../web/web_device.dart';
import 'devfs_web.dart';
import 'web_expression_compiler.dart';

/// Error message reported when the tool cannot establish a debug connection to
/// the running web application instance.
const kExitMessage =
    'Failed to establish connection with the application '
    'instance in Chrome.\nThis can happen if the websocket connection used by the '
    'web tooling is unable to correctly establish a connection, for example due to a firewall.';

/// A [FlutterDevice] that serves and controls a Flutter web application via
/// [WebDevFS], DWDS, and optionally the Chrome DevTools Protocol.
class WebFlutterDevice extends FlutterDevice {
  /// Creates a web-backed [FlutterDevice] for [device].
  ///
  /// Uses [_webConfig] as the single source of truth for web compiler, dev
  /// server, and Wasm configuration. Injects [_templateRenderer] for generating
  /// web plugin registrants without coupling this library to a concrete
  /// template engine, and forwards optional [_urlTunneller] and [_platformArgs]
  /// to [WebDevFS] and [Device.startApp].
  WebFlutterDevice(
    super.device, {
    required super.buildInfo,
    required super.developmentShaderCompiler,
    required this._flutterProject,
    required super.generator,
    required super.targetPlatform,
    required this._templateRenderer,
    required super.toolContext,
    this._platformArgs = const <String, Object?>{},
    this._urlTunneller,
    super.userIdentifier,
    this._webConfig = const WebDebugConfig(),
  });

  static const _kNoLaunchChromeArg = 'no-launch-chrome';
  static const _kUriArg = 'uri';
  static const _kHttpScheme = 'http';
  static const _kHttpsScheme = 'https';
  static const _kChromeExtensionPrefix = 'chrome-extension';
  static const _kPageReloadMethod = 'Page.reload';
  static const _kIgnoreCacheParam = 'ignoreCache';
  static const _kWebEntrypointFileName = 'web_entrypoint.dart';
  static const _kWebPluginRegistrantFileName = 'web_plugin_registrant.dart';
  static const _kOrgDartlangAppScheme = 'org-dartlang-app';
  static const _kMainDillPath = 'main.dart.dill';
  static const _kIncrementalDillPath = 'main.dart.incremental.dill';
  static const _kHotReloadMethod = 'reloadSources';
  static const _kHotRestartMethod = 'hotRestart';
  static const _kPauseIsolatesOnStartFlag = 'pause_isolates_on_start';
  static const _kWsPathSuffix = '/ws';
  static const _kRunCommandName = 'run';
  static const _kWebIncrementalRestartVariable = 'web-incremental-restart';
  static const _kDwdsScreenshotMethod = 'ext.dwds.screenshot';
  static const _kScreenshotDataKey = 'data';

  final FlutterProject _flutterProject;
  final Map<String, Object?> _platformArgs;
  final TemplateRenderer _templateRenderer;
  final UrlTunneller? _urlTunneller;
  final WebDebugConfig _webConfig;

  late Uri _launchUrl;
  WipConnection? _wipConnection;
  Future<ConnectionResult?>? _connectDebug;
  Directory? _generatedEntrypointDirectory;
  StreamSubscription<vmservice.Event>? _serviceSub;
  StreamSubscription<vmservice.Event>? _resumeSub;
  final _registeredMethodsForService = <String, String>{};
  var _resetCompilerOnNextUpdate = false;
  var _appStarted = false;
  var _disposed = false;

  FileSystem get _fs => toolContext.fs;
  Logger get _logger => toolContext.logger;

  ChromiumLauncher? get _chromiumLauncher {
    final Device? targetDevice = device;
    return targetDevice is ChromiumDevice ? targetDevice.chromeLauncher : null;
  }

  /// Whether the tool launches (and therefore owns a DevTools protocol
  /// connection to) a Chromium instance for this run.
  bool get _toolLaunchesChromium =>
      device is ChromiumDevice && _platformArgs[_kNoLaunchChromeArg] != true;

  /// Whether DWDS connects via WebSocket rather than the Chrome DevTools
  /// protocol.
  @visibleForTesting
  bool get useDwdsWebSocketConnection => !_toolLaunchesChromium;

  /// Web applications establish their DWDS VM Service connection only after the
  /// browser loads the served app, unlike native devices that return a URI from
  /// [Device.startApp].
  @override
  bool get defersServiceProtocolConnection => true;

  /// Web hot reload always invokes DWDS `reloadSources` even when no Dart
  /// source files changed so incremental updates and asset changes stay in
  /// sync.
  @override
  bool get alwaysReloadSources => true;

  /// Reports web incremental restarts under their dedicated timing metric name.
  @override
  String get hotRestartTimingVariableName => _kWebIncrementalRestartVariable;

  /// Cold web builds (profile, release, and Wasm) can be rebuilt and reloaded
  /// in the browser without restarting the tool.
  @override
  bool get supportsColdRestart => true;

  /// The Flutter performance overlay is not supported on web targets.
  @override
  bool get supportsPerformanceOverlay => false;

  /// Web targets capture screenshots via the DWDS `ext.dwds.screenshot` RPC
  /// instead of a native device screenshot command.
  @override
  bool get supportsVmServiceScreenshot => true;

  /// Captures a PNG screenshot through DWDS's `ext.dwds.screenshot` method.
  @override
  Future<Uint8List?> takeVmServiceScreenshot() async {
    final vmservice.Response? response = await vmService!.callMethodWrapper(_kDwdsScreenshotMethod);
    if (response == null) {
      return null;
    }
    final data = response.json![_kScreenshotDataKey] as String;
    return base64.decode(data);
  }

  /// Wasm web builds are ahead-of-time compiled and do not expose a Dart VM
  /// debug runtime.
  @override
  bool get supportsDebugRuntime => !_webConfig.useWasm;

  /// Profile web builds are compiled with dart2js/dart2wasm and do not expose
  /// the VM Service protocol.
  @override
  bool get supportsProfileServiceProtocol => false;

  /// Web uses its own generated `web_plugin_registrant.dart` rather than the
  /// shared native `dart_plugin_registrant.dart`.
  @override
  bool get usesSharedDartPluginRegistry => false;

  /// Shaders cannot be evicted during web hot reload because
  /// `ext.ui.window.reinitializeShader` is unsupported by the web engine
  /// (https://github.com/flutter/flutter/issues/137265).
  @override
  bool get supportsShaderReload => false;

  /// DWDS does not implement `getIsolatePauseEvent`, so hot reload skips the
  /// pre-reassemble pause-event lookup.
  @override
  bool get supportsIsolatePauseEventLookup => false;

  /// Debug JS web builds always use [HotRunner] (even when `--no-hot` disables
  /// hot reload), while Wasm, profile, and release builds use [ColdRunner].
  @override
  bool usesHotRunner({required bool hotMode}) => buildInfo.isDebug && !_webConfig.useWasm;

  /// DevTools are only supported for debug JS web builds and are served by DWDS
  /// rather than `device.dds`.
  @override
  bool launchDevToolsInBrowser() => buildInfo.isDebug && !_webConfig.useWasm;

  /// Matches the DDC front-end flags used by the resident compiler when looking
  /// up the cached initial dill.
  @override
  List<String> extraFrontEndOptionsForCache(BuildInfo buildInfo) => ddcFrontEndOptions(buildInfo);

  /// DWDS dispatches service extension RPCs directly on the connection without
  /// requiring a Flutter view or isolate ID lookup.
  @override
  Future<void> invokeExtensionRpcOnFirstView(
    String method, {
    required Map<String, Object?> params,
  }) async {
    await vmService!.callMethodWrapper(method, args: params);
  }

  /// Web serves assets directly over HTTP via [WebDevFS] and does not need a
  /// VM Service `setAssetDirectory` call.
  @override
  Future<void> confirmAssetDirectory(List<FlutterView> views) async {}

  /// Resolves the web application package, starts [WebDevFS] (with an optional
  /// [WebExpressionCompiler]), and marks the next DevFS update to reset the
  /// compiler before [HotRunner] runs source generators and the initial build.
  @override
  Future<void> prepareHotLaunch({required HotRunner hotRunner}) async {
    await _prepareLaunch(
      applicationPackageFactory: hotRunner.applicationPackageFactory,
      target: hotRunner.target,
    );

    final ExpressionCompiler? expressionCompiler = _webConfig.enableExpressionEvaluation
        ? WebExpressionCompiler(generator!, fileSystem: _fs)
        : null;

    _launchUrl = await _createAndStartWebDevFS(
      enableDwds: hotRunner.supportsServiceProtocol,
      expressionCompiler: expressionCompiler,
      runner: hotRunner,
    );
    _resetCompilerOnNextUpdate = true;
  }

  /// Records DDC initial-compile analytics for deprecated JS interop tracking.
  @override
  void onInitialDevFSUpdate(UpdateFSReport report, {required Analytics analytics}) {
    sendDdcCompileAnalytics(
      deprecatedJsInterop: buildInfo.deprecatedJsInterop,
      command: _kRunCommandName,
      succeeded: report.success,
      analytics: analytics,
    );
  }

  /// Subscribes to DWDS connections, marks [WebDevFS] ready to serve requests,
  /// and launches the target browser at the prepared launch URL.
  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    final webDevFS = devFS! as WebDevFS;
    final bool useDebugExtension =
        device is WebServerDevice && hotRunner.debuggingOptions.startPaused;
    // Subscribe to connected apps before marking the server ready so early
    // browser connections are not dropped.
    _connectDebug = hotRunner.supportsServiceProtocol ? webDevFS.connect(useDebugExtension) : null;
    webDevFS.markReady();

    return _startBrowserAndConnectTab(
      debuggingOptions: hotRunner.debuggingOptions,
      route: route,
      target: hotRunner.target,
      url: _launchUrl,
    );
  }

  /// Attaches to the asynchronous DWDS [ConnectionResult] once the browser
  /// connects, wires [WebDeviceLogReader] and VM Service subscriptions in the
  /// expected stream order, registers tool services, starts or gates
  /// `runMain()`, and invokes [onConnected] / [onDisconnected].
  @override
  void attachDeferredConnection({
    required HotRunner hotRunner,
    required void Function(DebugConnectionInfo) onConnected,
    required void Function() onDisconnected,
    ReloadSources? reloadSources,
  }) {
    if (!hotRunner.supportsServiceProtocol) {
      onConnected(DebugConnectionInfo());
      return;
    }
    final ToolContext(:FlutterVersion flutterVersion, :Logger logger) = toolContext;
    final DebuggingOptions debuggingOptions = hotRunner.debuggingOptions;
    assert(_connectDebug != null);
    unawaited(
      _connectDebug!.then((ConnectionResult? connectionResult) async {
        if (_disposed) {
          return;
        }
        final DebugConnection debugConnection = connectionResult!.debugConnection!;
        unawaited(
          debugConnection.onDone.whenComplete(() {
            if (!_disposed) {
              onDisconnected();
            }
          }),
        );

        final Uri websocketUri = Uri.parse(debugConnection.uri);
        final service = FlutterVmService(
          connectionResult.vmService,
          wsAddress: websocketUri,
          httpAddress: _httpUriFromWebsocketUri(websocketUri),
        );

        if (debuggingOptions.startPaused && debuggingOptions.debuggingEnabled) {
          try {
            final vmservice.Response result = await service.service.setFlag(
              _kPauseIsolatesOnStartFlag,
              'true',
            );
            if (result is! vmservice.Success) {
              logger.printError('setFlag failure: $result');
            }
          } on Exception catch (e) {
            logger.printError(
              'Failed to set $_kPauseIsolatesOnStartFlag=true, proceeding. '
              'Error: $e',
            );
          }
          if (_disposed) {
            return;
          }
        }

        final Device targetDevice = device!;
        // Start echoing and bind the VM Service to WebDeviceLogReader before
        // subscribing to Service and Isolate streams to preserve the expected
        // streamListen order (Stdout, Stderr, Service, Isolate, Extension).
        await startEchoingDeviceLog(debuggingOptions);
        if (_disposed) {
          await dispose();
          return;
        }
        await (await targetDevice.getLogReader(app: package)).provideVmService(service);
        if (_disposed) {
          await dispose();
          return;
        }

        _serviceSub = service.service.onServiceEvent.listen(_onServiceEvent);
        for (final streamId in <String>[
          vmservice.EventStreams.kService,
          vmservice.EventStreams.kIsolate,
        ]) {
          try {
            await service.service.streamListen(streamId);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're already subscribed.
          }
          if (_disposed) {
            await dispose();
            return;
          }
        }

        await setUpVmService(
          reloadSources: reloadSources,
          device: targetDevice,
          flutterProject: _flutterProject,
          flutterVersion: flutterVersion,
          printStructuredErrorLogMethod: hotRunner.printStructuredErrorLog,
          vmService: service.service,
        );
        if (_disposed) {
          await dispose();
          return;
        }

        vmService = service;
        if (targetDevice is WebDevice && debugConnection.devToolsUri != null) {
          targetDevice.devToolsUri = Uri.parse(debugConnection.devToolsUri!);
        }

        if (!debuggingOptions.startPaused) {
          connectionResult.appConnection!.runMain();
        } else {
          _resumeSub = service.service.onDebugEvent.listen((vmservice.Event event) {
            if (event.kind == vmservice.EventKind.kResume ||
                event.type == vmservice.EventKind.kResume) {
              connectionResult.appConnection!.runMain();
              unawaited(_resumeSub?.cancel());
              _resumeSub = null;
            }
          });
        }

        logger.printStatus('Debug service listening on $websocketUri');
        onConnected(
          DebugConnectionInfo(
            wsUri: websocketUri,
            devToolsUri: debugConnection.devToolsUri?.toUri(),
            dtdUri: debugConnection.dtdUri?.toUri(),
          ),
        );
      }),
    );
  }

  /// Translates web transport, Chrome DevTools, DWDS, timeout, and DDS
  /// startup exceptions into user-facing [ToolExit] errors.
  @override
  Never handleConnectionException(Exception error, StackTrace stackTrace) {
    if (error is WebSocketException ||
        error is ChromeDebugException ||
        error is AppConnectionException ||
        error is SocketException ||
        error is HttpException) {
      _logger.printError(error.toString(), stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    }
    if (error is TimeoutException) {
      _logger.printError(
        'Failed to establish connection with the web debug service: $error',
        stackTrace: stackTrace,
      );
      throwToolExit('Failed to connect to the web debug service.');
    }
    if (error is DartDevelopmentServiceException) {
      if (error.errorCode != DartDevelopmentServiceException.failedToStartError) {
        _logger.printError(error.message, stackTrace: stackTrace);
      }
      throwToolExit(kExitMessage);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  /// Generates the synthetic web bootstrap entrypoint and syncs compiled
  /// output to [WebDevFS], resetting the compiler only on the initial build.
  @override
  Future<UpdateFSReport> updateDevFS({
    required Uri mainUri,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    required String pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) async {
    final bool resetCompiler = _resetCompilerOnNextUpdate;
    _resetCompilerOnNextUpdate = false;
    final Status devFSStatus = _logger.startProgress(
      'Waiting for connection from debug service on ${device!.displayName}...',
    );
    final UpdateFSReport report;
    try {
      report = await devFS!.update(
        mainUri: await _generateEntrypoint(mainUri, packageConfig),
        target: target,
        bundle: bundle,
        bundleFirstUpload: bundleFirstUpload,
        generator: generator!,
        fullRestart: fullRestart,
        resetCompiler: resetCompiler,
        dillOutputPath: dillOutputPath,
        pathToReload: resetCompiler ? _kMainDillPath : _kIncrementalDillPath,
        invalidatedFiles: invalidatedFiles,
        packageConfig: packageConfig,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        shaderCompiler: developmentShaderCompiler,
      );
    } finally {
      devFSStatus.stop();
    }
    _logger.printTrace('Synced ${getSizeAsPlatformMB(report.syncedBytes)}.');
    return report;
  }

  /// Invokes DWDS's registered `hotRestart` service method instead of the
  /// native VM isolate restart flow, returning `false` when no browser client
  /// is currently connected.
  @override
  Future<bool?> performHotRestart() async {
    final FlutterVmService? service = vmService;
    if (service == null) {
      return false;
    }
    final String hotRestartMethod =
        _registeredMethodsForService[_kHotRestartMethod] ?? _kHotRestartMethod;
    try {
      await service.service.callMethod(hotRestartMethod);
    } on vmservice.RPCError catch (e) {
      // DWDS throws kIsolateCannotReload (or kServerError due to
      // https://github.com/dart-lang/sdk/issues/61757) when no browser
      // clients are connected during a hot restart.
      if (e.callingMethod == hotRestartMethod &&
          (e.code == vmservice.RPCErrorKind.kIsolateCannotReload.code ||
              e.code == vmservice.RPCErrorKind.kServerError.code)) {
        return false;
      }
      rethrow;
    }
    return true;
  }

  /// Reloads the web isolate via DWDS `reloadSources` without a `rootLibUri`,
  /// returning `null` when no browser client or isolate is connected.
  @override
  Future<List<Future<vmservice.ReloadReport>>?> reloadDeviceSources(
    String entryPath, {
    bool? pause = false,
  }) async {
    final FlutterVmService? service = vmService;
    if (service == null) {
      return null;
    }
    final vmservice.VM vm = await service.service.getVM();
    if (vm.isolates == null || vm.isolates!.isEmpty) {
      _logger.printTrace('No isolates available for hot reload');
      return null;
    }
    final vmservice.ReloadReport reloadReport;
    try {
      reloadReport = await service.service.reloadSources(vm.isolates!.first.id!);
    } on vmservice.RPCError catch (e) {
      if (e.callingMethod == _kHotReloadMethod &&
          e.code == vmservice.RPCErrorKind.kIsolateCannotReload.code) {
        return null;
      }
      rethrow;
    }
    return <Future<vmservice.ReloadReport>>[Future<vmservice.ReloadReport>.value(reloadReport)];
  }

  /// Starts [WebDevFS] without DWDS, compiles the web bundle with [WebBuilder],
  /// marks the server ready, and launches the browser for cold web runs.
  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    await _prepareLaunch(
      applicationPackageFactory: coldRunner.applicationPackageFactory,
      target: coldRunner.target,
    );

    try {
      final Uri url = await _createAndStartWebDevFS(
        enableDwds: false,
        expressionCompiler: null,
        runner: coldRunner,
      );

      await _buildWeb(coldRunner);

      (devFS! as WebDevFS).markReady();
      return await _startBrowserAndConnectTab(
        debuggingOptions: coldRunner.debuggingOptions,
        route: route,
        target: coldRunner.target,
        url: url,
      );
    } on ToolExit {
      rethrow;
    } on Exception catch (error, stackTrace) {
      handleConnectionException(error, stackTrace);
    }
  }

  /// Rebuilds the cold web bundle and triggers a Chrome DevTools `Page.reload`
  /// when connected to a tool-launched Chromium tab.
  @override
  Future<void> restartCold({required ColdRunner coldRunner}) async {
    await _buildWeb(coldRunner);
    final WipConnection? wipConnection = _wipConnection;
    if (wipConnection != null) {
      await wipConnection.sendCommand(_kPageReloadMethod, <String, Object>{
        _kIgnoreCacheParam: !buildInfo.isDebug,
      });
    } else {
      _logger.printStatus('Recompile complete. Page requires refresh.');
    }
  }

  /// Stops the launched browser application at most once, avoiding duplicate
  /// `stopApp` calls during runner cleanup.
  @override
  Future<void> exitApps({
    @visibleForTesting Duration timeoutDelay = const Duration(seconds: 10),
  }) async {
    if (!_appStarted) {
      return;
    }
    _appStarted = false;
    // FlutterDevice.exitApps annotates timeoutDelay @visibleForTesting in
    // resident_runner.dart and does not use it.
    await super.exitApps();
  }

  /// Marks this device disposed, cancels log and VM Service subscriptions,
  /// closes any Chrome DevTools tab connection, and deletes the temporary
  /// generated entrypoint directory.
  @override
  Future<void> dispose() async {
    _disposed = true;
    await stopEchoingDeviceLog();
    await _serviceSub?.cancel();
    _serviceSub = null;
    await _resumeSub?.cancel();
    _resumeSub = null;
    _registeredMethodsForService.clear();
    await _wipConnection?.close();
    _wipConnection = null;
    final Directory? entrypointDirectory = _generatedEntrypointDirectory;
    _generatedEntrypointDirectory = null;
    if (entrypointDirectory != null) {
      try {
        entrypointDirectory.deleteSync(recursive: true);
      } on FileSystemException {
        _logger.printTrace('Failed to clean up temp directory: ${entrypointDirectory.path}');
      }
    }
  }

  void _onServiceEvent(vmservice.Event e) {
    if (e.kind == vmservice.EventKind.kServiceRegistered) {
      _registeredMethodsForService[e.service!] = e.method!;
    }
    if (e.kind == vmservice.EventKind.kServiceUnregistered) {
      _registeredMethodsForService.remove(e.service);
    }
  }

  /// Resolves the web [ApplicationPackage], warns when the project lacks a
  /// `web/` directory, and logs the launch banner.
  Future<void> _prepareLaunch({
    required ApplicationPackageFactory applicationPackageFactory,
    required String target,
  }) async {
    final ToolContext(:FileSystem fs, :Logger logger) = toolContext;
    package = await applicationPackageFactory.getPackageForPlatform(
      TargetPlatform.web_javascript,
      buildInfo: buildInfo,
    );
    if (package == null) {
      logger.printStatus('This application is not configured to build on the web.');
      logger.printStatus('To add web support to a project, run `flutter create .`.');
    }
    logger.printStatus(
      'Launching ${getDisplayPath(target, fs)} '
      'on ${device!.displayName} in ${buildInfo.mode.friendlyName} mode...',
    );
  }

  /// Validates the configured port, creates [WebDevFS] if not already injected
  /// by tests, starts the HTTP/HTTPS server, and returns the serving URL.
  Future<Uri> _createAndStartWebDevFS({
    required bool enableDwds,
    required ExpressionCompiler? expressionCompiler,
    required ResidentRunner runner,
  }) async {
    final DebuggingOptions debuggingOptions = runner.debuggingOptions;
    final WebDevServerConfig serverConfig =
        _webConfig.devServerConfig ?? const WebDevServerConfig();
    validatePort(serverConfig.port);

    developmentShaderCompiler.configureCompiler(TargetPlatform.web_javascript);

    devFS ??= WebDevFS(
      packagesFilePath: runner.packagesFilePath,
      urlTunneller: _urlTunneller,
      buildInfo: buildInfo,
      enableDwds: enableDwds,
      ddsConfig: DartDevelopmentServiceConfiguration(
        enable: debuggingOptions.enableDds,
        port: debuggingOptions.ddsPort,
        serveDevTools: debuggingOptions.enableDevTools,
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
      ),
      entrypoint: _fs.file(runner.mainPath).uri,
      expressionCompiler: expressionCompiler,
      chromiumLauncher: _chromiumLauncher,
      useLocalCanvasKit: buildInfo.useLocalCanvasKit,
      rootDirectory: _fs.directory(runner.projectRootPath),
      useDwdsWebSocketConnection: useDwdsWebSocketConnection,
      toolContext: toolContext,
      webConfig: _webConfig,
    );
    Uri url = await devFS!.create();
    if (serverConfig.https?.certKeyPath != null && serverConfig.https?.certPath != null) {
      url = url.replace(scheme: _kHttpsScheme);
    }
    return url;
  }

  /// Starts [device] at [url] and, when the tool launched Chromium, connects to
  /// the active browser tab over the Chrome DevTools Protocol.
  Future<int> _startBrowserAndConnectTab({
    required DebuggingOptions debuggingOptions,
    required String? route,
    required String target,
    required Uri url,
  }) async {
    final Device targetDevice = device!;
    final LaunchResult result = await targetDevice.startApp(
      package,
      mainPath: target,
      route: route,
      debuggingOptions: debuggingOptions,
      platformArgs: <String, Object?>{..._platformArgs, _kUriArg: url.toString()},
    );
    if (!result.started) {
      _logger.printError('Error running application on ${targetDevice.displayName}.');
      return 1;
    }
    _appStarted = true;

    final ChromiumLauncher? launcher = _chromiumLauncher;
    if (launcher != null && _toolLaunchesChromium) {
      final Chromium chrome = await launcher.connectedInstance;
      final ChromeTab? chromeTab = await getChromeTabGuarded(
        chrome.chromeConnection,
        (ChromeTab chromeTab) => !chromeTab.url.startsWith(_kChromeExtensionPrefix),
        retryFor: const Duration(seconds: 5),
        onIoError: (Object error, StackTrace stackTrace) {
          _logger.printError(error.toString(), stackTrace: stackTrace);
        },
      );
      if (chromeTab == null) {
        throwToolExit('Failed to connect to Chrome instance.');
      }
      _wipConnection = await chromeTab.connect();
    }
    return 0;
  }

  /// Generates the temporary web bootstrap entrypoint and plugin registrant
  /// needed to initialize the Flutter web engine.
  // Keep this in sync with build_system/targets/web.dart.
  Future<Uri> _generateEntrypoint(Uri mainUri, PackageConfig? packageConfig) async {
    final ToolContext(:Cache cache, :FileSystem fs, :Logger logger) = toolContext;
    File? result = _generatedEntrypointDirectory?.childFile(_kWebEntrypointFileName);
    if (_generatedEntrypointDirectory == null) {
      _generatedEntrypointDirectory = fs.systemTempDirectory.createTempSync('flutter_tools.')
        ..createSync();
      result = _generatedEntrypointDirectory!.childFile(_kWebEntrypointFileName);

      await injectBuildTimePluginFilesForWebPlatform(
        _flutterProject,
        destination: _generatedEntrypointDirectory!,
        logger: logger,
        templateRenderer: _templateRenderer,
      );

      Uri? importedEntrypoint = packageConfig!.toPackageUriForWorkspace(mainUri);
      // Special handling for entrypoints that are not under lib, such as test scripts.
      if (importedEntrypoint == null) {
        final String parent = fs.file(mainUri).parent.path;
        generator!
          ..addFileSystemRoot(parent)
          ..addFileSystemRoot(fs.directory('test').absolute.path);
        importedEntrypoint = Uri(
          scheme: _kOrgDartlangAppScheme,
          host: '',
          path: '/${mainUri.pathSegments.last}',
        );
      }
      final LanguageVersion languageVersion = determineLanguageVersion(
        fs.file(mainUri),
        packageConfig[_flutterProject.manifest.appName],
        cache.flutterRoot,
      );

      final String entrypoint = main_dart.generateMainDartFile(
        importedEntrypoint.toString(),
        languageVersion: languageVersion,
        pluginRegistrantEntrypoint: _kWebPluginRegistrantFileName,
      );

      result.writeAsStringSync(entrypoint);
    }
    return result!.absolute.uri;
  }

  /// Compiles the project for cold web execution (profile, release, or Wasm)
  /// using [_webConfig] as the sole configuration source.
  Future<void> _buildWeb(ColdRunner coldRunner) async {
    final WebDebugConfig(
      :bool nativeNullAssertions,
      :WebRendererMode renderer,
      :bool useWasm,
      :Map<String, String> webDefines,
    ) = _webConfig;
    final WebCompilerConfig compilerConfig = useWasm
        ? WasmCompilerConfig(renderer: renderer)
        : JsCompilerConfig.run(
            nativeNullAssertions: nativeNullAssertions,
            renderer: renderer,
            deprecatedJsInterop: buildInfo.deprecatedJsInterop,
          );
    final webBuilder = WebBuilder(
      analytics: coldRunner.analytics,
      buildSystem: coldRunner.buildSystem,
      buildTargets: coldRunner.buildTargets,
      featureFlags: coldRunner.featureFlags,
      toolContext: toolContext,
    );
    await webBuilder.buildWeb(
      _flutterProject,
      coldRunner.target,
      buildInfo,
      compilerConfigs: <WebCompilerConfig>[compilerConfig],
      webDefines: webDefines,
    );
  }
}

Uri _httpUriFromWebsocketUri(Uri websocketUri) {
  String path = websocketUri.path;
  if (path.endsWith(WebFlutterDevice._kWsPathSuffix)) {
    path = path.substring(0, path.length - WebFlutterDevice._kWsPathSuffix.length);
  }
  return websocketUri.replace(scheme: WebFlutterDevice._kHttpScheme, path: path);
}
