// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dwds/dwds.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web/web_device.dart';
import '../web/web_flutter_device.dart';
import 'devfs_web.dart';

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
  static const _kHttpsScheme = 'https';
  static const _kChromeExtensionPrefix = 'chrome-extension';
  static const _kPageReloadMethod = 'Page.reload';
  static const _kIgnoreCacheParam = 'ignoreCache';

  final FlutterProject _flutterProject;
  final Map<String, Object?> _platformArgs;
  final UrlTunneller? _urlTunneller;
  final Map<String, String> _webDefines;

  WipConnection? _wipConnection;

  /// Whether the tool launches (and therefore owns a DevTools protocol
  /// connection to) a Chromium instance for this run.
  bool get _toolLaunchesChromium =>
      device is ChromiumDevice && _platformArgs[_kNoLaunchChromeArg] != true;

  @override
  bool get supportsColdRestart => true;

  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    final ToolContext(:FileSystem fs, :Logger logger) = toolContext;
    final Device targetDevice = device!;
    package = await coldRunner.applicationPackageFactory.getPackageForPlatform(
      TargetPlatform.web_javascript,
      buildInfo: coldRunner.debuggingOptions.buildInfo,
    );
    if (package == null) {
      logger.printStatus('This application is not configured to build on the web.');
      logger.printStatus('To add web support to a project, run `flutter create .`.');
    }
    final String modeName = coldRunner.debuggingOptions.buildInfo.mode.friendlyName;
    logger.printStatus(
      'Launching ${getDisplayPath(coldRunner.target, fs)} '
      'on ${targetDevice.displayName} in $modeName mode...',
    );

    final ChromiumLauncher? chromiumLauncher = targetDevice is ChromiumDevice
        ? targetDevice.chromeLauncher
        : null;

    try {
      final WebDebugConfig(
        :WebDevServerConfig? devServerConfig,
        :bool useSseForDebugProxy,
        :bool useSseForDebugBackend,
        :bool useSseForInjectedClient,
        :WebRendererMode renderer,
        :bool useWasm,
        :bool crossOriginIsolation,
      ) = coldRunner.debuggingOptions.webConfig;

      final WebDevServerConfig serverConfig = devServerConfig ?? const WebDevServerConfig();
      validatePort(serverConfig.port);

      developmentShaderCompiler.configureCompiler(TargetPlatform.web_javascript);

      devFS ??= WebDevFS(
        webDevServerConfig: serverConfig,
        packagesFilePath: coldRunner.packagesFilePath,
        urlTunneller: _urlTunneller,
        useSseForDebugProxy: useSseForDebugProxy,
        useSseForDebugBackend: useSseForDebugBackend,
        useSseForInjectedClient: useSseForInjectedClient,
        buildInfo: coldRunner.debuggingOptions.buildInfo,
        enableDwds: false,
        ddsConfig: DartDevelopmentServiceConfiguration(
          enable: coldRunner.debuggingOptions.enableDds,
          port: coldRunner.debuggingOptions.ddsPort,
          serveDevTools: coldRunner.debuggingOptions.enableDevTools,
          devToolsServerAddress: coldRunner.debuggingOptions.devToolsServerAddress,
        ),
        entrypoint: fs.file(coldRunner.mainPath).uri,
        expressionCompiler: null,
        chromiumLauncher: chromiumLauncher,
        nativeNullAssertions: coldRunner.debuggingOptions.nativeNullAssertions,
        webRenderer: renderer,
        isWasm: useWasm,
        useLocalCanvasKit: coldRunner.debuggingOptions.buildInfo.useLocalCanvasKit,
        rootDirectory: fs.directory(coldRunner.projectRootPath),
        useDwdsWebSocketConnection: !_toolLaunchesChromium,
        webCrossOriginIsolation: crossOriginIsolation,
        toolContext: toolContext,
        webDefines: _webDefines,
      );
      Uri url = await devFS!.create();
      if (serverConfig.https?.certKeyPath != null && serverConfig.https?.certPath != null) {
        url = url.replace(scheme: _kHttpsScheme);
      }

      await _buildWeb(coldRunner);

      (devFS! as WebDevFS).markReady();
      final LaunchResult result = await targetDevice.startApp(
        package,
        mainPath: coldRunner.target,
        route: route,
        debuggingOptions: coldRunner.debuggingOptions,
        platformArgs: <String, Object?>{..._platformArgs, _kUriArg: url.toString()},
      );
      if (!result.started) {
        logger.printError('Error running application on ${targetDevice.displayName}.');
        return 1;
      }

      if (chromiumLauncher != null && _toolLaunchesChromium) {
        final Chromium chrome = await chromiumLauncher.connectedInstance;
        final ChromeTab? chromeTab = await getChromeTabGuarded(
          chrome.chromeConnection,
          (ChromeTab chromeTab) => !chromeTab.url.startsWith(_kChromeExtensionPrefix),
          retryFor: const Duration(seconds: 5),
          onIoError: (Object error, StackTrace stackTrace) {
            logger.printError(error.toString(), stackTrace: stackTrace);
          },
        );
        if (chromeTab == null) {
          throwToolExit('Failed to connect to Chrome instance.');
        }
        _wipConnection = await chromeTab.connect();
      }
      return 0;
    } on Exception catch (error, stackTrace) {
      if (error is WebSocketException ||
          error is ChromeDebugException ||
          error is SocketException ||
          error is HttpException) {
        logger.printError(error.toString(), stackTrace: stackTrace);
        throwToolExit(kExitMessage);
      }
      rethrow;
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
      toolContext.logger.printStatus('Recompile complete. Page requires refresh.');
    }
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

  @override
  Future<void> dispose() async {
    await _wipConnection?.close();
  }
}
