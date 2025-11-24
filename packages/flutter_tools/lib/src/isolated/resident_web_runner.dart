// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vmservice;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../application_package.dart';
import '../base/async_guard.dart';
import '../base/command_help.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/language_version.dart';
import '../devfs.dart';
import '../device.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../hook_runner.dart' show hookRunner;
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../vmservice.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web/file_generators/flutter_service_worker_js.dart';
import '../web/file_generators/main_dart.dart' as main_dart;
import '../web/web_device.dart';
import '../web/web_runner.dart';
import 'devfs_web.dart';
import 'web_expression_compiler.dart';

/// Injectable factory to create a [ResidentWebRunner].
class DwdsWebRunnerFactory extends WebRunnerFactory {
  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String? target,
    required bool stayResident,
    required FlutterProject flutterProject,
    required DebuggingOptions debuggingOptions,
    UrlTunneller? urlTunneller,
    required Logger logger,
    required Terminal terminal,
    required Platform platform,
    required OutputPreferences outputPreferences,
    required FileSystem fileSystem,
    required SystemClock systemClock,
    required Analytics analytics,
    bool machine = false,
  }) {
    return ResidentWebRunner(
      device,
      target: target,
      flutterProject: flutterProject,
      debuggingOptions: debuggingOptions,
      stayResident: stayResident,
      urlTunneller: urlTunneller,
      machine: machine,
      analytics: analytics,
      systemClock: systemClock,
      fileSystem: fileSystem,
      logger: logger,
      terminal: terminal,
      platform: platform,
      outputPreferences: outputPreferences,
    );
  }
}

const kExitMessage =
    'Failed to establish connection with the application '
    'instance in Chrome.\nThis can happen if the websocket connection used by the '
    'web tooling is unable to correctly establish a connection, for example due to a firewall.';

const kNoClientConnectedMessage = 'Recompile complete. No client connected.';

class ResidentWebRunner extends ResidentRunner {
  ResidentWebRunner(
    FlutterDevice device, {
    String? target,
    bool stayResident = true,
    bool machine = false,
    String? projectRootPath,
    required this.flutterProject,
    required DebuggingOptions debuggingOptions,
    required FileSystem fileSystem,
    required Logger logger,
    required Terminal terminal,
    required Platform platform,
    required OutputPreferences outputPreferences,
    required SystemClock systemClock,
    required Analytics analytics,
    UrlTunneller? urlTunneller,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _platform = platform,
       _systemClock = systemClock,
       _analytics = analytics,
       _urlTunneller = urlTunneller,
       super(
         <FlutterDevice>[device],
         target: target ?? fileSystem.path.join('lib', 'main.dart'),
         debuggingOptions: debuggingOptions,
         stayResident: stayResident,
         machine: machine,
         commandHelp: CommandHelp(
           logger: logger,
           terminal: terminal,
           platform: platform,
           outputPreferences: outputPreferences,
         ),
         dartBuilder: hookRunner,
         projectRootPath: projectRootPath,
       );

  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final SystemClock _systemClock;
  final Analytics _analytics;
  final UrlTunneller? _urlTunneller;

  @override
  Logger get logger => _logger;

  @override
  FileSystem get fileSystem => _fileSystem;

  FlutterDevice? get flutterDevice => flutterDevices.first;
  final FlutterProject flutterProject;

  // Mapping from service name to service method.
  final _registeredMethodsForService = <String, String>{};

  // Used with the new compiler to generate a bootstrap file containing plugins
  // and platform initialization.
  Directory? _generatedEntrypointDirectory;

  // Only non-wasm debug builds of the web support the service protocol.
  @override
  late final bool supportsServiceProtocol =
      !debuggingOptions.webUseWasm && isRunningDebug && _deviceIsDebuggable;

  /// Device is debuggable if not a WebServer device, or if running with
  /// --start-paused or using DWDS WebSocket connection (WebServer device).
  late final bool _deviceIsDebuggable =
      flutterDevice!.device is! WebServerDevice ||
      debuggingOptions.startPaused ||
      useDwdsWebSocketConnection;

  late final useDwdsWebSocketConnection = flutterDevice!.device is! ChromiumDevice;

  @override
  // Web uses a different plugin registry.
  bool get generateDartPluginRegistry => false;

  @override
  bool get reloadIsRestart =>
      debuggingOptions.webUseWasm ||
      // Web behavior when not using the DDC library bundle format is to restart
      // when a reload is issued. We can't use `canHotReload` to signal this
      // since we still want a reload command to succeed, but to do a hot
      // restart.
      debuggingOptions.buildInfo.ddcModuleFormat != DdcModuleFormat.ddc ||
      !debuggingOptions.buildInfo.canaryFeatures;

  @override
  bool get supportsDetach => stopAppDuringCleanup;

  ConnectionResult? _connectionResult;
  StreamSubscription<vmservice.Event>? _stdOutSub;
  StreamSubscription<vmservice.Event>? _stdErrSub;
  StreamSubscription<vmservice.Event>? _serviceSub;
  StreamSubscription<vmservice.Event>? _extensionEventSub;
  var _exited = false;
  WipConnection? _wipConnection;
  ChromiumLauncher? _chromiumLauncher;

  FlutterVmService get _vmService {
    if (_instance != null) {
      return _instance!;
    }
    final vmservice.VmService? service = _connectionResult?.vmService;
    final Uri websocketUri = Uri.parse(_connectionResult!.debugConnection!.uri);
    final Uri httpUri = _httpUriFromWebsocketUri(websocketUri);
    return _instance ??= FlutterVmService(service!, wsAddress: websocketUri, httpAddress: httpUri);
  }

  FlutterVmService? _instance;

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
    await _serviceSub?.cancel();
    await _extensionEventSub?.cancel();

    if (stopAppDuringCleanup) {
      await flutterDevice!.device!.stopApp(null);
    }

    _registeredMethodsForService.clear();
    try {
      _generatedEntrypointDirectory?.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort to clean up temp dirs.
      _logger.printTrace(
        'Failed to clean up temp directory: ${_generatedEntrypointDirectory!.path}',
      );
    }
    _exited = true;
  }

  Future<void> _cleanupAndExit() async {
    await _cleanup();
    appFinished();
  }

  @override
  Future<void> stopEchoingDeviceLog() async {
    // Do nothing for ResidentWebRunner
    await flutterDevice!.stopEchoingDeviceLog();
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    String? route,
  }) async {
    final ApplicationPackage? package = await ApplicationPackageFactory.instance!
        .getPackageForPlatform(
          TargetPlatform.web_javascript,
          buildInfo: debuggingOptions.buildInfo,
        );
    if (package == null) {
      _logger.printStatus('This application is not configured to build on the web.');
      _logger.printStatus('To add web support to a project, run `flutter create .`.');
    }
    final String modeName = debuggingOptions.buildInfo.mode.friendlyName;
    _logger.printStatus(
      'Launching ${getDisplayPath(target, _fileSystem)} '
      'on ${flutterDevice!.device!.displayName} in $modeName mode...',
    );
    if (flutterDevice!.device is ChromiumDevice) {
      _chromiumLauncher = (flutterDevice!.device! as ChromiumDevice).chromeLauncher;
    }

    try {
      return await asyncGuard(() async {
        final WebDevServerConfig originalConfig =
            debuggingOptions.webDevServerConfig ?? const WebDevServerConfig();

        final int resolvedPort = await resolvePort(originalConfig.port, globals.os);

        final WebDevServerConfig updatedConfig = originalConfig.copyWith(port: resolvedPort);
        final ExpressionCompiler? expressionCompiler =
            debuggingOptions.webEnableExpressionEvaluation
            ? WebExpressionCompiler(flutterDevice!.generator!, fileSystem: _fileSystem)
            : null;

        flutterDevice!.devFS = WebDevFS(
          webDevServerConfig: updatedConfig,
          packagesFilePath: packagesFilePath,
          urlTunneller: _urlTunneller,
          useSseForDebugProxy: debuggingOptions.webUseSseForDebugProxy,
          useSseForDebugBackend: debuggingOptions.webUseSseForDebugBackend,
          useSseForInjectedClient: debuggingOptions.webUseSseForInjectedClient,
          buildInfo: debuggingOptions.buildInfo,
          enableDwds: supportsServiceProtocol,
          ddsConfig: DartDevelopmentServiceConfiguration(
            enable: debuggingOptions.enableDds,
            port: debuggingOptions.ddsPort,
            serveDevTools: debuggingOptions.enableDevTools,
            devToolsServerAddress: debuggingOptions.devToolsServerAddress,
          ),
          entrypoint: _fileSystem.file(target).uri,
          expressionCompiler: expressionCompiler,
          chromiumLauncher: _chromiumLauncher,
          nativeNullAssertions: debuggingOptions.nativeNullAssertions,
          ddcModuleSystem: debuggingOptions.buildInfo.ddcModuleFormat == DdcModuleFormat.ddc,
          canaryFeatures: debuggingOptions.buildInfo.canaryFeatures,
          webRenderer: debuggingOptions.webRenderer,
          isWasm: debuggingOptions.webUseWasm,
          useLocalCanvasKit: debuggingOptions.buildInfo.useLocalCanvasKit,
          rootDirectory: fileSystem.directory(projectRootPath),
          useDwdsWebSocketConnection: useDwdsWebSocketConnection,
          fileSystem: fileSystem,
          logger: logger,
          platform: _platform,
        );
        Uri url = await flutterDevice!.devFS!.create();
        if (updatedConfig.https?.certKeyPath != null && updatedConfig.https?.certPath != null) {
          url = url.replace(scheme: 'https');
        }
        if (debuggingOptions.buildInfo.isDebug && !debuggingOptions.webUseWasm) {
          await runSourceGenerators();
          final UpdateFSReport report = await _updateDevFS(fullRestart: true, resetCompiler: true);
          if (!report.success) {
            _logger.printError('Failed to compile application.');
            appFailedToStart();
            return 1;
          }
          flutterDevice!.generator!.accept();
          cacheInitialDillCompilation();
        } else {
          final webBuilder = WebBuilder(
            logger: _logger,
            processManager: globals.processManager,
            buildSystem: globals.buildSystem,
            fileSystem: _fileSystem,
            flutterVersion: globals.flutterVersion,
            analytics: globals.analytics,
          );
          await webBuilder.buildWeb(
            flutterProject,
            target,
            debuggingOptions.buildInfo,
            ServiceWorkerStrategy.none,
            compilerConfigs: <WebCompilerConfig>[_compilerConfig],
          );
        }
        final webDevFS = flutterDevice!.devFS! as WebDevFS;
        final bool useDebugExtension =
            flutterDevice!.device is WebServerDevice && debuggingOptions.startPaused;
        // Listen for connected apps early and then await this `Future` later
        // when we attach.
        final Future<ConnectionResult?>? connectDebug = supportsServiceProtocol
            ? webDevFS.connect(useDebugExtension)
            : null;
        await flutterDevice!.device!.startApp(
          package,
          mainPath: target,
          debuggingOptions: debuggingOptions,
          platformArgs: <String, Object>{'uri': url.toString()},
        );
        return attach(
          connectionInfoCompleter: connectionInfoCompleter,
          appStartedCompleter: appStartedCompleter,
          connectDebug: connectDebug,
        );
      });
    } on WebSocketException catch (error, stackTrace) {
      appFailedToStart();
      _logger.printError('$error', stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    } on ChromeDebugException catch (error, stackTrace) {
      appFailedToStart();
      _logger.printError('$error', stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    } on AppConnectionException catch (error, stackTrace) {
      appFailedToStart();
      _logger.printError('$error', stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    } on SocketException catch (error, stackTrace) {
      appFailedToStart();
      _logger.printError('$error', stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    } on HttpException catch (error, stackTrace) {
      appFailedToStart();
      _logger.printError('$error', stackTrace: stackTrace);
      throwToolExit(kExitMessage);
    } on Exception {
      appFailedToStart();
      rethrow;
    }
  }

  WebCompilerConfig get _compilerConfig {
    if (debuggingOptions.webUseWasm) {
      return WasmCompilerConfig(
        optimizationLevel: 0,
        stripWasm: false,
        renderer: debuggingOptions.webRenderer,
      );
    }
    return JsCompilerConfig.run(
      nativeNullAssertions: debuggingOptions.nativeNullAssertions,
      renderer: debuggingOptions.webRenderer,
    );
  }

  /// Handles the no clients available scenario gracefully.
  OperationResult _handleNoClientsAvailable(Status status) {
    status.stop();
    _logger.printStatus(kNoClientConnectedMessage);
    return OperationResult.ok;
  }

  @override
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool? pause = false,
    String? reason,
    bool benchmarkMode = false,
  }) async {
    final DateTime start = _systemClock.now();
    final Status status;
    if (debuggingOptions.buildInfo.ddcModuleFormat != DdcModuleFormat.ddc ||
        !debuggingOptions.buildInfo.canaryFeatures) {
      // Triggering hot reload performed hot restart for the old module formats
      // historically. Keep that behavior and only perform hot reload when the
      // new module format is used.
      fullRestart = true;
    }
    if (fullRestart) {
      status = _logger.startProgress('Performing hot restart...', progressId: 'hot.restart');
    } else {
      status = _logger.startProgress('Performing hot reload...', progressId: 'hot.reload');
    }

    final String targetPlatform = getNameForTargetPlatform(TargetPlatform.web_javascript);
    final String sdkName = await flutterDevice!.device!.sdkNameAndVersion;

    // Will be null if there is no report.
    final UpdateFSReport? report;
    if (debuggingOptions.buildInfo.isDebug && !debuggingOptions.webUseWasm) {
      await runSourceGenerators();
      // Don't reset the resident compiler for web, since the extra recompile is
      // wasteful.
      report = await _updateDevFS(fullRestart: fullRestart, resetCompiler: false);
      if (report.success) {
        flutterDevice!.generator!.accept();
      } else {
        status.stop();
        await flutterDevice!.generator!.reject();
        if (report.hotReloadRejected) {
          // We cannot capture the reason why the reload was rejected as it may
          // contain user information.
          HotEvent(
            'reload-reject',
            targetPlatform: targetPlatform,
            sdkName: sdkName,
            emulator: false,
            fullRestart: fullRestart,
          ).send();
          _analytics.send(
            Event.hotRunnerInfo(
              label: 'reload-reject',
              targetPlatform: targetPlatform,
              sdkName: sdkName,
              emulator: false,
              fullRestart: fullRestart,
            ),
          );
        }
        return OperationResult(1, 'Failed to recompile application.');
      }
    } else {
      report = null;
      try {
        final webBuilder = WebBuilder(
          logger: _logger,
          processManager: globals.processManager,
          buildSystem: globals.buildSystem,
          fileSystem: _fileSystem,
          flutterVersion: globals.flutterVersion,
          analytics: globals.analytics,
        );
        await webBuilder.buildWeb(
          flutterProject,
          target,
          debuggingOptions.buildInfo,
          ServiceWorkerStrategy.none,
          compilerConfigs: <WebCompilerConfig>[_compilerConfig],
        );
      } on ToolExit {
        return OperationResult(1, 'Failed to recompile application.');
      }
    }

    if (_connectionResult == null) {
      return _handleNoClientsAvailable(status);
    }

    // Both will be null when not assigned.
    Duration? reloadDuration;
    Duration? reassembleDuration;
    try {
      if (!_deviceIsDebuggable) {
        _logger.printStatus('Recompile complete. Page requires refresh.');
      } else if (isRunningDebug) {
        if (fullRestart) {
          // If the hot-restart service extension method is registered, then use
          // it. Otherwise, default to calling "hotRestart" without a namespace.
          final String hotRestartMethod =
              _registeredMethodsForService['hotRestart'] ?? 'hotRestart';

          try {
            await _vmService.service.callMethod(hotRestartMethod);
          } on vmservice.RPCError catch (e) {
            // DWDS throws an RPC error with kIsolateCannotReload code when there are no
            // browser clients currently connected during a hot restart operation.

            // TODO(61757): Remove this temporary workaround once vm_service is fixed.
            // There's a bug in vm_service where it re-encodes RPCErrors as kServerError
            // instead of preserving the original error code. Until that's fixed, we need
            // to check for both kIsolateCannotReload and kServerError for this method.
            if (e.callingMethod == hotRestartMethod &&
                (e.code == vmservice.RPCErrorKind.kIsolateCannotReload.code ||
                    e.code == vmservice.RPCErrorKind.kServerError.code)) {
              return _handleNoClientsAvailable(status);
            }
            // Re-throw other RPC errors
            rethrow;
          }
        } else {
          final DateTime reloadStart = _systemClock.now();
          final vmservice.VM vm = await _vmService.service.getVM();
          final String hotReloadMethod =
              _registeredMethodsForService['reloadSources'] ?? 'reloadSources';

          // Check if there are any isolates available
          if (vm.isolates == null || vm.isolates!.isEmpty) {
            _logger.printTrace('No isolates available for hot reload');
            return _handleNoClientsAvailable(status);
          }

          vmservice.ReloadReport report;
          try {
            report = await _vmService.service.reloadSources(vm.isolates!.first.id!);
          } on vmservice.RPCError catch (e) {
            // DWDS throws an RPC error with kIsolateCannotReload code when there are no
            // browser clients currently connected during a hot reload operation.
            if (e.callingMethod == hotReloadMethod &&
                e.code == vmservice.RPCErrorKind.kIsolateCannotReload.code) {
              return _handleNoClientsAvailable(status);
            }
            // Re-throw other RPC errors
            rethrow;
          }

          reloadDuration = _systemClock.now().difference(reloadStart);
          final contents = ReloadReportContents.fromReloadReport(report);
          final bool success = contents.success ?? false;
          if (!success) {
            // Rejections happen at compile-time for the web, so in theory,
            // nothing should go wrong here. However, if DWDS or the DDC runtime
            // has some internal error, we should still surface it to make
            // debugging easier.
            var reloadFailedMessage = 'Hot reload failed:';
            _logger.printError(reloadFailedMessage);
            for (final ReasonForCancelling reason in contents.notices) {
              reloadFailedMessage += reason.toString();
              _logger.printError(reason.toString());
            }
            return OperationResult(1, reloadFailedMessage);
          }
          String? failedReassemble;
          final DateTime reassembleStart = _systemClock.now();
          await _vmService
              .flutterReassemble(isolateId: null)
              .then(
                (Object? o) => o,
                onError: (Object error, StackTrace stackTrace) {
                  failedReassemble = 'Reassembling failed: $error\n$stackTrace';
                  _logger.printError(failedReassemble!);
                },
              );
          reassembleDuration = _systemClock.now().difference(reassembleStart);
          if (failedReassemble != null) {
            return OperationResult(1, failedReassemble!);
          }
        }
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

    final Duration elapsed = _systemClock.now().difference(start);
    final String elapsedMS = getElapsedAsMilliseconds(elapsed);
    _logger.printStatus('${fullRestart ? 'Restarted' : 'Reloaded'} application in $elapsedMS.');

    if (fullRestart) {
      for (final FlutterDevice? device in flutterDevices) {
        unawaited(device?.handleHotRestart());
      }
    }

    // Don't track restart times for dart2js builds or web-server devices.
    if (debuggingOptions.buildInfo.isDebug && _deviceIsDebuggable) {
      if (fullRestart) {
        _analytics.send(
          Event.timing(
            workflow: 'hot',
            variableName: 'web-incremental-restart',
            elapsedMilliseconds: elapsed.inMilliseconds,
          ),
        );
        HotEvent(
          'restart',
          targetPlatform: targetPlatform,
          sdkName: sdkName,
          emulator: false,
          fullRestart: true,
          reason: reason,
          overallTimeInMs: elapsed.inMilliseconds,
          syncedBytes: report?.syncedBytes,
          invalidatedSourcesCount: report?.invalidatedSourcesCount,
          transferTimeInMs: report?.transferDuration.inMilliseconds,
          compileTimeInMs: report?.compileDuration.inMilliseconds,
          findInvalidatedTimeInMs: report?.findInvalidatedDuration.inMilliseconds,
          scannedSourcesCount: report?.scannedSourcesCount,
        ).send();
        _analytics.send(
          Event.hotRunnerInfo(
            label: 'restart',
            targetPlatform: targetPlatform,
            sdkName: sdkName,
            emulator: false,
            fullRestart: true,
            reason: reason,
            overallTimeInMs: elapsed.inMilliseconds,
            syncedBytes: report?.syncedBytes,
            invalidatedSourcesCount: report?.invalidatedSourcesCount,
            transferTimeInMs: report?.transferDuration.inMilliseconds,
            compileTimeInMs: report?.compileDuration.inMilliseconds,
            findInvalidatedTimeInMs: report?.findInvalidatedDuration.inMilliseconds,
            scannedSourcesCount: report?.scannedSourcesCount,
          ),
        );
      } else {
        _analytics.send(
          Event.timing(
            workflow: 'hot',
            variableName: 'reload',
            elapsedMilliseconds: elapsed.inMilliseconds,
          ),
        );
        HotEvent(
          'reload',
          targetPlatform: targetPlatform,
          sdkName: sdkName,
          emulator: false,
          fullRestart: false,
          reason: reason,
          overallTimeInMs: elapsed.inMilliseconds,
          syncedBytes: report?.syncedBytes,
          invalidatedSourcesCount: report?.invalidatedSourcesCount,
          transferTimeInMs: report?.transferDuration.inMilliseconds,
          compileTimeInMs: report?.compileDuration.inMilliseconds,
          findInvalidatedTimeInMs: report?.findInvalidatedDuration.inMilliseconds,
          scannedSourcesCount: report?.scannedSourcesCount,
          reassembleTimeInMs: reassembleDuration?.inMilliseconds,
          reloadVMTimeInMs: reloadDuration?.inMilliseconds,
        ).send();
        _analytics.send(
          Event.hotRunnerInfo(
            label: 'reload',
            targetPlatform: targetPlatform,
            sdkName: sdkName,
            emulator: false,
            fullRestart: false,
            reason: reason,
            overallTimeInMs: elapsed.inMilliseconds,
            syncedBytes: report?.syncedBytes,
            invalidatedSourcesCount: report?.invalidatedSourcesCount,
            transferTimeInMs: report?.transferDuration.inMilliseconds,
            compileTimeInMs: report?.compileDuration.inMilliseconds,
            findInvalidatedTimeInMs: report?.findInvalidatedDuration.inMilliseconds,
            scannedSourcesCount: report?.scannedSourcesCount,
            reassembleTimeInMs: reassembleDuration?.inMilliseconds,
            reloadVMTimeInMs: reloadDuration?.inMilliseconds,
          ),
        );
      }
    }
    return OperationResult.ok;
  }

  // Flutter web projects need to include a generated main entrypoint to call the
  // appropriate bootstrap method and inject plugins.
  // Keep this in sync with build_system/targets/web.dart.
  Future<Uri> _generateEntrypoint(Uri mainUri, PackageConfig? packageConfig) async {
    File? result = _generatedEntrypointDirectory?.childFile('web_entrypoint.dart');
    if (_generatedEntrypointDirectory == null) {
      _generatedEntrypointDirectory ??= _fileSystem.systemTempDirectory.createTempSync(
        'flutter_tools.',
      )..createSync();
      result = _generatedEntrypointDirectory!.childFile('web_entrypoint.dart');

      // Generates the generated_plugin_registrar
      await injectBuildTimePluginFilesForWebPlatform(
        flutterProject,
        destination: _generatedEntrypointDirectory!,
      );
      // The below works because `injectBuildTimePluginFiles` is configured to write
      // the web_plugin_registrant.dart file alongside the generated main.dart
      const generatedImport = 'web_plugin_registrant.dart';

      Uri? importedEntrypoint = packageConfig!.toPackageUri(mainUri);
      // Special handling for entrypoints that are not under lib, such as test scripts.
      if (importedEntrypoint == null) {
        final String parent = _fileSystem.file(mainUri).parent.path;
        flutterDevices.first.generator!
          ..addFileSystemRoot(parent)
          ..addFileSystemRoot(_fileSystem.directory('test').absolute.path);
        importedEntrypoint = Uri(scheme: 'org-dartlang-app', path: '/${mainUri.pathSegments.last}');
      }
      final LanguageVersion languageVersion = determineLanguageVersion(
        _fileSystem.file(mainUri),
        packageConfig[flutterProject.manifest.appName],
        Cache.flutterRoot!,
      );

      final String entrypoint = main_dart.generateMainDartFile(
        importedEntrypoint.toString(),
        languageVersion: languageVersion,
        pluginRegistrantEntrypoint: generatedImport,
      );

      result.writeAsStringSync(entrypoint);
    }
    return result!.absolute.uri;
  }

  Future<UpdateFSReport> _updateDevFS({
    required bool fullRestart,
    required bool resetCompiler,
  }) async {
    final bool isFirstUpload = !assetBundle.wasBuiltOnce();
    final bool rebuildBundle = assetBundle.needsBuild();
    if (rebuildBundle) {
      _logger.printTrace('Updating assets');
      final int result = await assetBundle.build(
        flutterHookResult: await dartBuilder?.runHooks(
          targetPlatform: TargetPlatform.web_javascript,
          environment: environment,
          logger: _logger,
        ),
        packageConfigPath: debuggingOptions.buildInfo.packageConfigPath,
        targetPlatform: TargetPlatform.web_javascript,
      );
      if (result != 0) {
        return UpdateFSReport();
      }
    }
    final InvalidationResult invalidationResult = await projectFileInvalidator.findInvalidated(
      lastCompiled: flutterDevice!.devFS!.lastCompiled,
      urisToMonitor: flutterDevice!.devFS!.sources,
      packagesPath: packagesFilePath,
      packageConfig:
          flutterDevice!.devFS!.lastPackageConfig ?? debuggingOptions.buildInfo.packageConfig,
    );
    final Status devFSStatus = _logger.startProgress(
      'Waiting for connection from debug service on '
      '${flutterDevice!.device!.displayName}...',
    );
    final UpdateFSReport report = await flutterDevice!.devFS!.update(
      mainUri: await _generateEntrypoint(
        _fileSystem.file(mainPath).absolute.uri,
        invalidationResult.packageConfig,
      ),
      target: target,
      bundle: assetBundle,
      bundleFirstUpload: isFirstUpload,
      generator: flutterDevice!.generator!,
      fullRestart: fullRestart,
      resetCompiler: resetCompiler,
      dillOutputPath: dillOutputPath,
      pathToReload: getReloadPath(resetCompiler: resetCompiler, swap: false),
      invalidatedFiles: invalidationResult.uris!,
      packageConfig: invalidationResult.packageConfig!,
      trackWidgetCreation: debuggingOptions.buildInfo.trackWidgetCreation,
      shaderCompiler: flutterDevice!.developmentShaderCompiler,
    );
    devFSStatus.stop();
    _logger.printTrace('Synced ${getSizeAsPlatformMB(report.syncedBytes)}.');
    return report;
  }

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    Future<ConnectionResult?>? connectDebug,
    bool needsFullRestart = true,
  }) async {
    if (_chromiumLauncher != null) {
      final Chromium chrome = await _chromiumLauncher!.connectedInstance;
      final ChromeTab? chromeTab = await getChromeTabGuarded(
        chrome.chromeConnection,
        (ChromeTab chromeTab) {
          return !chromeTab.url.startsWith('chrome-extension');
        },
        retryFor: const Duration(seconds: 5),
        onIoError: (Object error, StackTrace stackTrace) {
          // We were unable to unable to communicate with Chrome.
          _logger.printError(error.toString(), stackTrace: stackTrace);
        },
      );
      if (chromeTab == null) {
        appFailedToStart();
        throwToolExit('Failed to connect to Chrome instance.');
      }
      _wipConnection = await chromeTab.connect();
    }
    if (supportsServiceProtocol) {
      assert(connectDebug != null);
      unawaited(
        connectDebug!.then((connectionResult) async {
          _connectionResult = connectionResult;
          final DebugConnection debugConnection = connectionResult!.debugConnection!;
          unawaited(debugConnection.onDone.whenComplete(_cleanupAndExit));

          void onLogEvent(vmservice.Event event) {
            final String message = processVmServiceMessage(event);
            _logger.printStatus(message);
          }

          // This flag is needed to manage breakpoints properly.
          if (debuggingOptions.startPaused && debuggingOptions.debuggingEnabled) {
            try {
              final vmservice.Response result = await _vmService.service.setFlag(
                'pause_isolates_on_start',
                'true',
              );
              if (result is! vmservice.Success) {
                _logger.printError('setFlag failure: $result');
              }
            } on Exception catch (e) {
              _logger.printError(
                'Failed to set pause_isolates_on_start=true, proceeding. '
                'Error: $e',
              );
            }
          }

          _stdOutSub = _vmService.service.onStdoutEvent.listen(onLogEvent);
          _stdErrSub = _vmService.service.onStderrEvent.listen(onLogEvent);
          _serviceSub = _vmService.service.onServiceEvent.listen(_onServiceEvent);
          try {
            await _vmService.service.streamListen(vmservice.EventStreams.kStdout);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're already subscribed.
          }
          try {
            await _vmService.service.streamListen(vmservice.EventStreams.kStderr);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're already subscribed.
          }
          try {
            await _vmService.service.streamListen(vmservice.EventStreams.kService);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're already subscribed.
          }
          try {
            await _vmService.service.streamListen(vmservice.EventStreams.kIsolate);
          } on vmservice.RPCError {
            // It is safe to ignore this error because we expect an error to be
            // thrown if we're not already subscribed.
          }
          final Device device = flutterDevice!.device!;
          await setUpVmService(
            reloadSources: (String isolateId, {bool? force, bool? pause}) async {
              await restart(pause: pause);
            },
            device: device,
            flutterProject: flutterProject,
            printStructuredErrorLogMethod: printStructuredErrorLog,
            vmService: _vmService.service,
          );

          final Uri websocketUri = Uri.parse(debugConnection.uri);
          flutterDevice!.vmService = _vmService;
          if (debugConnection.devToolsUri != null) {
            (flutterDevice!.device! as WebDevice).devToolsUri = Uri.parse(
              debugConnection.devToolsUri!,
            );
          }

          // Run main immediately if the app is not started paused or if there
          // is no debugger attached. Otherwise, runMain when a resume event
          // is received.
          if (!debuggingOptions.startPaused || !supportsServiceProtocol) {
            _connectionResult!.appConnection!.runMain();
          } else {
            late StreamSubscription<void> resumeSub;
            resumeSub = _vmService.service.onDebugEvent.listen((vmservice.Event event) {
              if (event.type == vmservice.EventKind.kResume) {
                _connectionResult!.appConnection!.runMain();
                resumeSub.cancel();
              }
            });
          }

          if (debuggingOptions.vmserviceOutFile != null) {
            _fileSystem.file(debuggingOptions.vmserviceOutFile)
              ..createSync(recursive: true)
              ..writeAsStringSync(websocketUri.toString());
          }
          // TODO(bkonyi): consider removing this log message and using only the standard VM
          // service message instead.
          _logger.printStatus('Debug service listening on $websocketUri');
          printDebuggerList();
          connectionInfoCompleter?.complete(
            DebugConnectionInfo(
              wsUri: websocketUri,
              devToolsUri: Uri.tryParse(debugConnection.devToolsUri ?? ''),
              dtdUri: Uri.tryParse(debugConnection.dtdUri ?? ''),
            ),
          );
        }),
      );
    } else {
      connectionInfoCompleter?.complete(DebugConnectionInfo());
    }

    appStartedCompleter?.complete();
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
    if (stopAppDuringCleanup) {
      await flutterDevice!.exitApps();
    }
    appFinished();
  }

  void _onServiceEvent(vmservice.Event e) {
    if (e.kind == vmservice.EventKind.kServiceRegistered) {
      final String serviceName = e.service!;
      _registeredMethodsForService[serviceName] = e.method!;
    }

    if (e.kind == vmservice.EventKind.kServiceUnregistered) {
      final String serviceName = e.service!;
      _registeredMethodsForService.remove(serviceName);
    }
  }
}

Uri _httpUriFromWebsocketUri(Uri websocketUri) {
  const wsPath = '/ws';
  String path = websocketUri.path;
  if (path.endsWith(wsPath)) {
    path = path.substring(0, path.length - wsPath.length);
  }
  return websocketUri.replace(scheme: 'http', path: path);
}
