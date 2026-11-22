// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:dwds/dwds.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vmservice;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../application_package.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../cache.dart';
import '../compile.dart';
import '../context/tool_context.dart';
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
import '../web/web_device.dart';
import '../web/web_flutter_device.dart';
import 'devfs_web.dart';
import 'mustache_template.dart';
import 'web_expression_compiler.dart';

const kExitMessage =
    'Failed to establish connection with the application '
    'instance in Chrome.\nThis can happen if the websocket connection used by the '
    'web tooling is unable to correctly establish a connection, for example due to a firewall.';

/// Default [WebFlutterDeviceFactory] backed by [WebDevFS] and DWDS.
class DwdsWebFlutterDeviceFactory implements WebFlutterDeviceFactory {
  const DwdsWebFlutterDeviceFactory();

  @override
  FlutterDevice createWebFlutterDevice(
    Device device, {
    required BuildInfo buildInfo,
    required DevelopmentShaderCompiler developmentShaderCompiler,
    required FlutterProject flutterProject,
    required ResidentCompiler? generator,
    required TargetPlatform targetPlatform,
    required ToolContext toolContext,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    UrlTunneller? urlTunneller,
    String? userIdentifier,
    Map<String, String> webDefines = const <String, String>{},
  }) {
    return WebFlutterDevice(
      device,
      buildInfo: buildInfo,
      developmentShaderCompiler: developmentShaderCompiler,
      flutterProject: flutterProject,
      generator: generator,
      platformArgs: platformArgs,
      targetPlatform: targetPlatform,
      toolContext: toolContext,
      urlTunneller: urlTunneller,
      userIdentifier: userIdentifier,
      webDefines: webDefines,
    );
  }
}

/// A [FlutterDevice] that serves and controls a Flutter web application.
class WebFlutterDevice extends FlutterDevice {
  WebFlutterDevice(
    super.device, {
    required super.buildInfo,
    required super.developmentShaderCompiler,
    required this._flutterProject,
    required super.generator,
    required super.targetPlatform,
    required super.toolContext,
    this._platformArgs = const <String, Object?>{},
    this._urlTunneller,
    super.userIdentifier,
    this._webDefines = const <String, String>{},
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

  final FlutterProject _flutterProject;
  final Map<String, Object?> _platformArgs;
  final UrlTunneller? _urlTunneller;
  final Map<String, String> _webDefines;

  WipConnection? _wipConnection;
  Future<ConnectionResult?>? _connectDebug;
  ConnectionResult? _connectionResult;
  Directory? _generatedEntrypointDirectory;
  StreamSubscription<vmservice.Event>? _stdOutSub;
  StreamSubscription<vmservice.Event>? _stdErrSub;
  StreamSubscription<vmservice.Event>? _serviceSub;
  StreamSubscription<vmservice.Event>? _resumeSub;
  final _registeredMethodsForService = <String, String>{};
  var _resetCompilerOnNextUpdate = false;
  var _appStarted = false;
  var _detached = false;

  FileSystem get _fs => toolContext.fs;
  Logger get _logger => toolContext.logger;

  /// Whether the tool launches (and therefore owns a DevTools protocol
  /// connection to) a Chromium instance for this run.
  bool get _toolLaunchesChromium =>
      device is ChromiumDevice && _platformArgs[_kNoLaunchChromeArg] != true;

  /// Whether DWDS connects via WebSocket rather than the Chrome DevTools
  /// protocol.
  @visibleForTesting
  bool get useDwdsWebSocketConnection => !_toolLaunchesChromium;

  @override
  bool get defersServiceProtocolConnection => true;

  @override
  bool get alwaysReloadSources => true;

  @override
  String get hotRestartTimingVariableName => _kWebIncrementalRestartVariable;

  @override
  bool get supportsColdRestart => true;

  @override
  void onDetach() {
    _detached = true;
  }

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    final ToolContext(:FileSystem fs, :Logger logger) = toolContext;
    final Device targetDevice = device!;
    await _prepareLaunch(
      applicationPackageFactory: hotRunner.applicationPackageFactory,
      buildInfo: hotRunner.debuggingOptions.buildInfo,
      target: hotRunner.target,
    );

    final ChromiumLauncher? chromiumLauncher = targetDevice is ChromiumDevice
        ? targetDevice.chromeLauncher
        : null;
    final ExpressionCompiler? expressionCompiler =
        hotRunner.debuggingOptions.webConfig.enableExpressionEvaluation
        ? WebExpressionCompiler(generator!, fileSystem: fs)
        : null;

    final Uri url = await _createAndStartWebDevFS(
      chromiumLauncher: chromiumLauncher,
      enableDwds: hotRunner.supportsServiceProtocol,
      expressionCompiler: expressionCompiler,
      isWasm: false,
      runner: hotRunner,
    );

    await hotRunner.runSourceGenerators();
    _resetCompilerOnNextUpdate = true;
    final UpdateFSReport report = await hotRunner.updateDevFS(fullRestart: true);
    sendDdcCompileAnalytics(
      deprecatedJsInterop: hotRunner.debuggingOptions.buildInfo.deprecatedJsInterop,
      command: _kRunCommandName,
      succeeded: report.success,
      analytics: hotRunner.analytics,
    );
    if (!report.success) {
      logger.printError('Failed to compile application.');
      return 1;
    }
    generator!.accept();
    hotRunner.cacheInitialDillCompilation();

    final webDevFS = devFS! as WebDevFS;
    final bool useDebugExtension =
        targetDevice is WebServerDevice && hotRunner.debuggingOptions.startPaused;
    // Subscribe to connected apps before marking the server ready so early
    // browser connections are not dropped.
    _connectDebug = hotRunner.supportsServiceProtocol ? webDevFS.connect(useDebugExtension) : null;
    webDevFS.markReady();

    return _startBrowserAndConnectTab(
      chromiumLauncher: chromiumLauncher,
      debuggingOptions: hotRunner.debuggingOptions,
      route: route,
      target: hotRunner.target,
      url: url,
    );
  }

  @override
  void attachDeferredConnection({
    required HotRunner hotRunner,
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
  }) {
    if (!hotRunner.supportsServiceProtocol) {
      connectionInfoCompleter?.complete(DebugConnectionInfo());
      return;
    }
    final ToolContext(:FlutterVersion flutterVersion, :Logger logger) = toolContext;
    final DebuggingOptions debuggingOptions = hotRunner.debuggingOptions;
    assert(_connectDebug != null);
    unawaited(
      _connectDebug!.then((ConnectionResult? connectionResult) async {
        _connectionResult = connectionResult;
        final DebugConnection debugConnection = connectionResult!.debugConnection!;
        unawaited(debugConnection.onDone.whenComplete(hotRunner.exit));

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
        }

        void onLogEvent(vmservice.Event event) {
          final String message = processVmServiceMessage(event);
          logger.printStatus(message);
        }

        _stdOutSub = service.service.onStdoutEvent.listen(onLogEvent);
        _stdErrSub = service.service.onStderrEvent.listen(onLogEvent);
        _serviceSub = service.service.onServiceEvent.listen(_onServiceEvent);
        for (final streamId in <String>[
          vmservice.EventStreams.kStdout,
          vmservice.EventStreams.kStderr,
          vmservice.EventStreams.kService,
          vmservice.EventStreams.kIsolate,
        ]) {
          try {
            await service.service.streamListen(streamId);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're already subscribed.
          }
        }

        final Device targetDevice = device!;
        await setUpVmService(
          reloadSources: (String isolateId, {bool? force, bool? pause}) async {
            await hotRunner.restart(pause: pause ?? false);
          },
          device: targetDevice,
          flutterProject: _flutterProject,
          flutterVersion: flutterVersion,
          printStructuredErrorLogMethod: hotRunner.printStructuredErrorLog,
          vmService: service.service,
        );

        vmService = service;
        if (targetDevice is WebDevice && debugConnection.devToolsUri != null) {
          targetDevice.devToolsUri = Uri.parse(debugConnection.devToolsUri!);
        }

        if (!debuggingOptions.startPaused || !hotRunner.supportsServiceProtocol) {
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

        hotRunner.writeVmServiceFile();
        logger.printStatus('Debug service listening on $websocketUri');
        final connectionInfo = DebugConnectionInfo(
          wsUri: websocketUri,
          devToolsUri: debugConnection.devToolsUri?.toUri(),
          dtdUri: debugConnection.dtdUri?.toUri(),
        );
        hotRunner.printDebuggerList(connectionInfo: connectionInfo);
        connectionInfoCompleter?.complete(connectionInfo);
      }),
    );
  }

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

  @override
  Future<bool?> performHotRestart() async {
    if (_connectionResult == null) {
      return false;
    }
    final String hotRestartMethod =
        _registeredMethodsForService[_kHotRestartMethod] ?? _kHotRestartMethod;
    try {
      await vmService!.service.callMethod(hotRestartMethod);
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

  @override
  Future<List<Future<vmservice.ReloadReport>>?> reloadDeviceSources(
    String entryPath, {
    bool? pause = false,
  }) async {
    if (_connectionResult == null) {
      return null;
    }
    final FlutterVmService service = vmService!;
    final vmservice.VM vm = await service.service.getVM();
    if (vm.isolates == null || vm.isolates!.isEmpty) {
      _logger.printTrace('No isolates available for hot reload');
      return null;
    }
    final String hotReloadMethod =
        _registeredMethodsForService[_kHotReloadMethod] ?? _kHotReloadMethod;
    final vmservice.ReloadReport reloadReport;
    try {
      reloadReport = await service.service.reloadSources(vm.isolates!.first.id!);
    } on vmservice.RPCError catch (e) {
      if (e.callingMethod == hotReloadMethod &&
          e.code == vmservice.RPCErrorKind.kIsolateCannotReload.code) {
        return null;
      }
      rethrow;
    }
    return <Future<vmservice.ReloadReport>>[Future<vmservice.ReloadReport>.value(reloadReport)];
  }

  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    final Device targetDevice = device!;
    await _prepareLaunch(
      applicationPackageFactory: coldRunner.applicationPackageFactory,
      buildInfo: coldRunner.debuggingOptions.buildInfo,
      target: coldRunner.target,
    );

    final ChromiumLauncher? chromiumLauncher = targetDevice is ChromiumDevice
        ? targetDevice.chromeLauncher
        : null;

    try {
      final Uri url = await _createAndStartWebDevFS(
        chromiumLauncher: chromiumLauncher,
        enableDwds: false,
        expressionCompiler: null,
        isWasm: coldRunner.debuggingOptions.webConfig.useWasm,
        runner: coldRunner,
      );

      await _buildWeb(coldRunner);

      (devFS! as WebDevFS).markReady();
      return await _startBrowserAndConnectTab(
        chromiumLauncher: chromiumLauncher,
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

  @override
  Future<void> restartCold({required ColdRunner coldRunner}) async {
    await _buildWeb(coldRunner);
    final WipConnection? wipConnection = _wipConnection;
    if (wipConnection != null) {
      await wipConnection.sendCommand(_kPageReloadMethod, <String, Object>{
        _kIgnoreCacheParam: !coldRunner.debuggingOptions.buildInfo.isDebug,
      });
    } else {
      _logger.printStatus('Recompile complete. Page requires refresh.');
    }
  }

  @override
  Future<void> exitApps({
    @visibleForTesting Duration timeoutDelay = const Duration(seconds: 10),
  }) async {
    if (!_appStarted || _detached) {
      return;
    }
    _appStarted = false;
    await super.exitApps();
  }

  @override
  Future<void> stopEchoingDeviceLog() async {
    await _stdOutSub?.cancel();
    _stdOutSub = null;
    await _stdErrSub?.cancel();
    _stdErrSub = null;
    await super.stopEchoingDeviceLog();
  }

  @override
  Future<void> dispose() async {
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

  Future<void> _prepareLaunch({
    required ApplicationPackageFactory applicationPackageFactory,
    required BuildInfo buildInfo,
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

  Future<Uri> _createAndStartWebDevFS({
    required ChromiumLauncher? chromiumLauncher,
    required bool enableDwds,
    required ExpressionCompiler? expressionCompiler,
    required bool isWasm,
    required ResidentRunner runner,
  }) async {
    final DebuggingOptions debuggingOptions = runner.debuggingOptions;
    final WebDebugConfig(
      :WebDevServerConfig? devServerConfig,
      :bool useSseForDebugProxy,
      :bool useSseForDebugBackend,
      :bool useSseForInjectedClient,
      :WebRendererMode renderer,
      :bool crossOriginIsolation,
    ) = debuggingOptions.webConfig;

    final WebDevServerConfig serverConfig = devServerConfig ?? const WebDevServerConfig();
    validatePort(serverConfig.port);

    developmentShaderCompiler.configureCompiler(TargetPlatform.web_javascript);

    devFS ??= WebDevFS(
      webDevServerConfig: serverConfig,
      packagesFilePath: runner.packagesFilePath,
      urlTunneller: _urlTunneller,
      useSseForDebugProxy: useSseForDebugProxy,
      useSseForDebugBackend: useSseForDebugBackend,
      useSseForInjectedClient: useSseForInjectedClient,
      buildInfo: debuggingOptions.buildInfo,
      enableDwds: enableDwds,
      ddsConfig: DartDevelopmentServiceConfiguration(
        enable: debuggingOptions.enableDds,
        port: debuggingOptions.ddsPort,
        serveDevTools: debuggingOptions.enableDevTools,
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
      ),
      entrypoint: _fs.file(runner.mainPath).uri,
      expressionCompiler: expressionCompiler,
      chromiumLauncher: chromiumLauncher,
      nativeNullAssertions: debuggingOptions.nativeNullAssertions,
      webRenderer: renderer,
      isWasm: isWasm,
      useLocalCanvasKit: debuggingOptions.buildInfo.useLocalCanvasKit,
      rootDirectory: _fs.directory(runner.projectRootPath),
      useDwdsWebSocketConnection: !_toolLaunchesChromium,
      webCrossOriginIsolation: crossOriginIsolation,
      toolContext: toolContext,
      webDefines: _webDefines,
    );
    Uri url = await devFS!.create();
    if (serverConfig.https?.certKeyPath != null && serverConfig.https?.certPath != null) {
      url = url.replace(scheme: _kHttpsScheme);
    }
    return url;
  }

  Future<int> _startBrowserAndConnectTab({
    required ChromiumLauncher? chromiumLauncher,
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

    if (chromiumLauncher != null && _toolLaunchesChromium) {
      final Chromium chrome = await chromiumLauncher.connectedInstance;
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

  // Flutter web projects need to include a generated main entrypoint to call the
  // appropriate bootstrap method and inject plugins.
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
        templateRenderer: const MustacheTemplateRenderer(),
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

  Future<void> _buildWeb(ColdRunner coldRunner) async {
    final DebuggingOptions debuggingOptions = coldRunner.debuggingOptions;
    final WebCompilerConfig compilerConfig = debuggingOptions.webConfig.useWasm
        ? WasmCompilerConfig(renderer: debuggingOptions.webConfig.renderer)
        : JsCompilerConfig.run(
            nativeNullAssertions: debuggingOptions.nativeNullAssertions,
            renderer: debuggingOptions.webConfig.renderer,
            deprecatedJsInterop: debuggingOptions.buildInfo.deprecatedJsInterop,
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
      debuggingOptions.buildInfo,
      compilerConfigs: <WebCompilerConfig>[compilerConfig],
      webDefines: _webDefines,
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
