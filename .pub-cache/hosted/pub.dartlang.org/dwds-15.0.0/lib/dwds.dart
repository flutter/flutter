// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'data/build_result.dart';
import 'src/connections/app_connection.dart';
import 'src/connections/debug_connection.dart';
import 'src/events.dart';
import 'src/handlers/dev_handler.dart';
import 'src/handlers/injector.dart';
import 'src/handlers/socket_connections.dart';
import 'src/loaders/strategy.dart';
import 'src/readers/asset_reader.dart';
import 'src/servers/devtools.dart';
import 'src/servers/extension_backend.dart';
import 'src/services/expression_compiler.dart';
import 'src/utilities/sdk_configuration.dart';

export 'src/connections/app_connection.dart' show AppConnection;
export 'src/connections/debug_connection.dart' show DebugConnection;
export 'src/debugging/metadata/provider.dart'
    show MetadataProvider, AbsoluteImportUriException;
export 'src/events.dart' show DwdsEvent;
export 'src/handlers/dev_handler.dart' show AppConnectionException;
export 'src/handlers/socket_connections.dart';
export 'src/loaders/build_runner_require.dart'
    show BuildRunnerRequireStrategyProvider;
export 'src/loaders/frontend_server_require.dart'
    show FrontendServerRequireStrategyProvider;
export 'src/loaders/legacy.dart' show LegacyStrategy;
export 'src/loaders/require.dart' show RequireStrategy;
export 'src/loaders/strategy.dart' show LoadStrategy, ReloadConfiguration;
export 'src/readers/asset_reader.dart' show AssetReader, UrlEncoder;
export 'src/readers/frontend_server_asset_reader.dart'
    show FrontendServerAssetReader;
export 'src/readers/proxy_server_asset_reader.dart' show ProxyServerAssetReader;
export 'src/servers/devtools.dart';
export 'src/services/chrome_debug_exception.dart' show ChromeDebugException;
export 'src/services/expression_compiler.dart'
    show ExpressionCompilationResult, ExpressionCompiler, ModuleInfo;
export 'src/services/expression_compiler_service.dart'
    show ExpressionCompilerService;
export 'src/utilities/sdk_configuration.dart'
    show SdkConfiguration, SdkConfigurationProvider;

typedef ConnectionProvider = Future<ChromeConnection> Function();

/// The Dart Web Debug Service.
class Dwds {
  static final _logger = Logger('DWDS');
  final Middleware middleware;
  final Handler handler;
  final DevTools _devTools;
  final DevHandler _devHandler;
  final AssetReader _assetReader;
  final bool _enableDebugging;

  Dwds._(
    this.middleware,
    this._devTools,
    this._devHandler,
    this._assetReader,
    this._enableDebugging,
  ) : handler = _devHandler.handler;

  Stream<AppConnection> get connectedApps => _devHandler.connectedApps;

  Stream<DwdsEvent> get events => eventStream;

  StreamController<DebugConnection> get extensionDebugConnections =>
      _devHandler.extensionDebugConnections;

  Future<void> stop() async {
    await _devTools?.close();
    await _devHandler.close();
    await _assetReader.close();
  }

  Future<DebugConnection> debugConnection(AppConnection appConnection) async {
    if (!_enableDebugging) throw StateError('Debugging is not enabled.');
    final appDebugServices = await _devHandler.loadAppServices(appConnection);
    await appDebugServices.chromeProxyService.isInitialized;
    return DebugConnection(appDebugServices);
  }

  static Future<Dwds> start({
    @required AssetReader assetReader,
    @required Stream<BuildResult> buildResults,
    @required ConnectionProvider chromeConnection,
    @required LoadStrategy loadStrategy,
    @required bool enableDebugging,
    // TODO(annagrin): make expressionCompiler argument required
    // [issue 881](https://github.com/dart-lang/webdev/issues/881)
    ExpressionCompiler expressionCompiler,
    bool enableDebugExtension,
    String hostname,
    bool useSseForDebugProxy,
    bool useSseForDebugBackend,
    bool useSseForInjectedClient,
    UrlEncoder urlEncoder,
    bool spawnDds,
    // TODO(elliette): DevTools is inconsistently capitalized throughout this
    // file. Change all occurances of devtools/Devtools to devTools/DevTools.
    bool enableDevtoolsLaunch,
    DevtoolsLauncher devtoolsLauncher,
    bool launchDevToolsInNewWindow,
    SdkConfigurationProvider sdkConfigurationProvider,
    bool emitDebugEvents,
  }) async {
    hostname ??= 'localhost';
    enableDebugging ??= true;
    enableDebugExtension ??= false;
    useSseForDebugProxy ??= true;
    useSseForDebugBackend ??= true;
    useSseForInjectedClient ??= true;
    enableDevtoolsLaunch ??= true;
    launchDevToolsInNewWindow ??= true;
    spawnDds ??= true;
    globalLoadStrategy = loadStrategy;
    emitDebugEvents ??= true;

    sdkConfigurationProvider ??= DefaultSdkConfigurationProvider();

    DevTools devTools;
    Future<String> extensionUri;
    ExtensionBackend extensionBackend;
    if (enableDebugExtension) {
      final handler = useSseForDebugBackend
          ? SseSocketHandler(SseHandler(Uri.parse('/\$debug'),
              // Proxy servers may actively kill long standing connections.
              // Allow for clients to reconnect in a short window. Making the
              // window too long may cause issues if the user closes a debug
              // session and initites a new one during the keepAlive window.
              keepAlive: const Duration(seconds: 5)))
          : WebSocketSocketHandler();

      extensionBackend = await ExtensionBackend.start(handler, hostname);
      extensionUri = Future.value(Uri(
              scheme: useSseForDebugBackend ? 'http' : 'ws',
              host: extensionBackend.hostname,
              port: extensionBackend.port,
              path: r'$debug')
          .toString());
      if (urlEncoder != null) extensionUri = urlEncoder(await extensionUri);
    }

    final serveDevTools = devtoolsLauncher != null;
    if (serveDevTools) {
      devTools = await devtoolsLauncher(hostname);
      final uri =
          Uri(scheme: 'http', host: devTools.hostname, port: devTools.port);
      _logger.info('Serving DevTools at $uri\n');
    }

    final injected = DwdsInjector(
      loadStrategy,
      useSseForInjectedClient: useSseForInjectedClient,
      extensionUri: extensionUri,
      enableDevtoolsLaunch: enableDevtoolsLaunch,
      emitDebugEvents: emitDebugEvents,
    );

    final devHandler = DevHandler(
      chromeConnection,
      buildResults,
      devTools,
      assetReader,
      loadStrategy,
      hostname,
      extensionBackend,
      urlEncoder,
      useSseForDebugProxy,
      useSseForInjectedClient,
      serveDevTools,
      expressionCompiler,
      injected,
      spawnDds,
      launchDevToolsInNewWindow,
      sdkConfigurationProvider,
    );

    return Dwds._(
      injected.middleware,
      devTools,
      devHandler,
      assetReader,
      enableDebugging,
    );
  }
}
