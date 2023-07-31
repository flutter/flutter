// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:dwds/dwds.dart';
import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds/src/utilities/sdk_configuration.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:frontend_server_common/src/resident_runner.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webdriver/io.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'logging.dart';
import 'server.dart';
import 'utilities.dart';

final _exeExt = Platform.isWindows ? '.exe' : '';

const isRPCError = TypeMatcher<RPCError>();
const isSentinelException = TypeMatcher<SentinelException>();

final Matcher throwsRPCError = throwsA(isRPCError);
final Matcher throwsSentinelException = throwsA(isSentinelException);

enum CompilationMode { buildDaemon, frontendServer }

enum IndexBaseMode { noBase, base }

enum NullSafety { weak, sound }

class TestContext {
  String appUrl;
  WipConnection tabConnection;
  WipConnection extensionConnection;
  TestServer testServer;
  BuildDaemonClient daemonClient;
  ResidentWebRunner webRunner;
  WebDriver webDriver;
  Process chromeDriver;
  AppConnection appConnection;
  DebugConnection debugConnection;
  WebkitDebugger webkitDebugger;
  Client client;
  ExpressionCompilerService ddcService;
  int port;
  Directory _outputDir;
  File _entryFile;
  Uri _packageConfigFile;
  Uri _projectDirectory;
  String _entryContents;

  /// Null safety mode for the frontend server.
  ///
  /// Note: flutter's frontend server is always launched with
  /// the null safety setting inferred from project configurations
  /// or the source code. We skip this inference and just set it
  /// here to the desired value manually.
  ///
  /// Note: build_runner-based setups ignore this setting and read
  /// this value from the ddc debug metadata and pass it to the
  /// expression compiler worker initialiation API.
  ///
  /// TODO(annagrin): Currently setting sound null safety for frontend
  /// server tests fails due to missing sound SDK JavaScript and maps.
  /// Issue: https://github.com/dart-lang/webdev/issues/1591
  NullSafety nullSafety;
  final _logger = logging.Logger('Context');

  /// Top level directory in which we run the test server..
  String workingDirectory;

  /// The path to build and serve.
  String pathToServe;

  /// The path part of the application URL.
  String path;

  TestContext(
      {String directory,
      String entry,
      this.path = 'hello_world/index.html',
      this.pathToServe = 'example'}) {
    final relativeDirectory = p.join('..', 'fixtures', '_test');

    final relativeEntry = p.join(
        '..', 'fixtures', '_test', 'example', 'append_body', 'main.dart');

    workingDirectory = p.normalize(p
        .absolute(directory ?? p.relative(relativeDirectory, from: p.current)));

    DartUri.currentDirectory = workingDirectory;

    // package_config.json is located in <project directory>/.dart_tool/package_config
    _projectDirectory = p.toUri(workingDirectory);
    _packageConfigFile =
        p.toUri(p.join(workingDirectory, '.dart_tool/package_config.json'));

    final entryFilePath = p.normalize(
        p.absolute(entry ?? p.relative(relativeEntry, from: p.current)));

    _logger.info('Serving: $pathToServe/$path');
    _logger.info('Project: $_projectDirectory');
    _logger.info('Packages: $_packageConfigFile');
    _logger.info('Entry: $entryFilePath');

    _entryFile = File(entryFilePath);
    _entryContents = _entryFile.readAsStringSync();
  }

  Future<void> setUp({
    ReloadConfiguration reloadConfiguration,
    bool serveDevTools,
    bool enableDebugExtension,
    bool autoRun,
    bool enableDebugging,
    bool useSse,
    bool spawnDds,
    String hostname,
    bool waitToDebug,
    UrlEncoder urlEncoder,
    bool restoreBreakpoints,
    CompilationMode compilationMode,
    NullSafety nullSafety,
    bool enableExpressionEvaluation,
    bool verboseCompiler,
    SdkConfigurationProvider sdkConfigurationProvider,
  }) async {
    reloadConfiguration ??= ReloadConfiguration.none;
    serveDevTools ??= false;
    enableDebugExtension ??= false;
    autoRun ??= true;
    enableDebugging ??= true;
    waitToDebug ??= false;
    compilationMode ??= CompilationMode.buildDaemon;
    enableExpressionEvaluation ??= false;
    spawnDds ??= true;
    verboseCompiler ??= false;
    sdkConfigurationProvider ??= DefaultSdkConfigurationProvider();
    nullSafety ??= NullSafety.weak;

    try {
      configureLogWriter();

      client = IOClient(HttpClient()
        ..maxConnectionsPerHost = 200
        ..idleTimeout = const Duration(seconds: 30)
        ..connectionTimeout = const Duration(seconds: 30));

      final systemTempDir = Directory.systemTemp;
      _outputDir = systemTempDir.createTempSync('foo bar');

      final chromeDriverPort = await findUnusedPort();
      final chromeDriverUrlBase = 'wd/hub';
      try {
        chromeDriver = await Process.start('chromedriver$_exeExt',
            ['--port=$chromeDriverPort', '--url-base=$chromeDriverUrlBase']);
        // On windows this takes a while to boot up, wait for the first line
        // of stdout as a signal that it is ready.
        final stdOutLines = chromeDriver.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        final stdErrLines = chromeDriver.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        stdOutLines
            .listen((line) => _logger.finest('ChromeDriver stdout: $line'));
        stdErrLines
            .listen((line) => _logger.warning('ChromeDriver stderr: $line'));

        await stdOutLines.first;
      } catch (e) {
        throw StateError(
            'Could not start ChromeDriver. Is it installed?\nError: $e');
      }

      await Process.run(dartPath, ['pub', 'upgrade'],
          workingDirectory: workingDirectory);

      ExpressionCompiler expressionCompiler;
      AssetReader assetReader;
      Handler assetHandler;
      Stream<BuildResults> buildResults;
      RequireStrategy requireStrategy;
      String basePath = '';

      port = await findUnusedPort();
      switch (compilationMode) {
        case CompilationMode.buildDaemon:
          {
            final options = [
              if (enableExpressionEvaluation) ...[
                '--define',
                'build_web_compilers|ddc=generate-full-dill=true',
              ],
              '--verbose',
            ];
            daemonClient =
                await connectClient(workingDirectory, options, (log) {
              final record = log.toLogRecord();
              final name =
                  record.loggerName == '' ? '' : '${record.loggerName}: ';
              _logger.log(record.level, '$name${record.message}', record.error,
                  record.stackTrace);
            });
            daemonClient.registerBuildTarget(
                DefaultBuildTarget((b) => b..target = pathToServe));
            daemonClient.startBuild();

            await daemonClient.buildResults
                .firstWhere((results) => results.results
                    .any((result) => result.status == BuildStatus.succeeded))
                .timeout(const Duration(seconds: 60));

            final assetServerPort = daemonPort(workingDirectory);
            assetHandler = proxyHandler(
                'http://localhost:$assetServerPort/$pathToServe/',
                client: client);
            assetReader =
                ProxyServerAssetReader(assetServerPort, root: pathToServe);

            if (enableExpressionEvaluation) {
              ddcService = ExpressionCompilerService(
                'localhost',
                port,
                assetHandler,
                verbose: verboseCompiler,
                sdkConfigurationProvider: sdkConfigurationProvider,
              );
              expressionCompiler = ddcService;
            }

            requireStrategy = BuildRunnerRequireStrategyProvider(
              assetHandler,
              reloadConfiguration,
              assetReader,
            ).strategy;

            buildResults = daemonClient.buildResults;
          }
          break;
        case CompilationMode.frontendServer:
          {
            _logger.warning('Index: $path');

            final entry = p.toUri(_entryFile.path
                .substring(_projectDirectory.toFilePath().length + 1));

            webRunner = ResidentWebRunner(
              entry,
              urlEncoder,
              _projectDirectory,
              _packageConfigFile,
              [_projectDirectory],
              'org-dartlang-app',
              _outputDir.path,
              nullSafety == NullSafety.sound,
              verboseCompiler,
            );

            final assetServerPort = await findUnusedPort();
            await webRunner.run(
                hostname, assetServerPort, p.join(pathToServe, path));

            if (enableExpressionEvaluation) {
              expressionCompiler = webRunner.expressionCompiler;
            }

            basePath = webRunner.devFS.assetServer.basePath;
            assetReader = webRunner.devFS.assetServer;
            assetHandler = webRunner.devFS.assetServer.handleRequest;

            requireStrategy = FrontendServerRequireStrategyProvider(
                    reloadConfiguration, assetReader, () async => {}, basePath)
                .strategy;

            buildResults = const Stream<BuildResults>.empty();
          }
          break;
        default:
          throw Exception('Unsupported compilation mode: $compilationMode');
      }

      final debugPort = await findUnusedPort();
      // If the environment variable DWDS_DEBUG_CHROME is set to the string true
      // then Chrome will be launched with a UI rather than headless.
      // If the extension is enabled, then Chrome will be launched with a UI
      // since headless Chrome does not support extensions.
      final headless = Platform.environment['DWDS_DEBUG_CHROME'] != 'true' &&
          !enableDebugExtension;
      final capabilities = Capabilities.chrome
        ..addAll({
          Capabilities.chromeOptions: {
            'args': [
              'remote-debugging-port=$debugPort',
              if (enableDebugExtension) '--load-extension=debug_extension/web',
              if (headless) '--headless'
            ]
          }
        });
      webDriver = await createDriver(
          spec: WebDriverSpec.JsonWire,
          desired: capabilities,
          uri: Uri.parse(
              'http://127.0.0.1:$chromeDriverPort/$chromeDriverUrlBase/'));
      final connection = ChromeConnection('localhost', debugPort);

      testServer = await TestServer.start(
        hostname,
        port,
        assetHandler,
        assetReader,
        requireStrategy,
        pathToServe,
        buildResults,
        () async => connection,
        serveDevTools,
        enableDebugExtension,
        autoRun,
        enableDebugging,
        useSse,
        urlEncoder,
        restoreBreakpoints,
        expressionCompiler,
        spawnDds,
        ddcService,
      );

      appUrl = basePath.isEmpty
          ? 'http://localhost:$port/$path'
          : 'http://localhost:$port/$basePath/$path';

      await webDriver.get(appUrl);
      final tab = await connection.getTab((t) => t.url == appUrl);
      tabConnection = await tab.connect();
      await tabConnection.runtime.enable();
      await tabConnection.debugger.enable();

      if (enableDebugExtension) {
        final extensionTab = await _fetchDartDebugExtensionTab(connection);
        extensionConnection = await extensionTab.connect();
        await extensionConnection.runtime.enable();
      }

      appConnection = await testServer.dwds.connectedApps.first;
      if (enableDebugging && !waitToDebug) {
        await startDebugging();
      }
    } catch (e) {
      await tearDown();
      rethrow;
    }
  }

  Future<void> startDebugging() async {
    debugConnection = await testServer.dwds.debugConnection(appConnection);
    webkitDebugger = WebkitDebugger(WipDebugger(tabConnection));
  }

  Future<void> tearDown() async {
    await webDriver?.quit(closeSession: true);
    chromeDriver?.kill();
    DartUri.currentDirectory = p.current;
    _entryFile.writeAsStringSync(_entryContents);
    await daemonClient?.close();
    await ddcService?.stop();
    await webRunner?.stop();
    await testServer?.stop();
    client?.close();
    await _outputDir?.delete(recursive: true);
    stopLogWriter();

    // clear the state for next setup
    webDriver = null;
    chromeDriver = null;
    daemonClient = null;
    ddcService = null;
    webRunner = null;
    testServer = null;
    client = null;
    _outputDir = null;
  }

  Future<void> changeInput() async {
    _entryFile.writeAsStringSync(
        _entryContents.replaceAll('Hello World!', 'Gary is awesome!'));

    // Wait for the build.
    await daemonClient.buildResults.firstWhere((results) => results.results
        .any((result) => result.status == BuildStatus.succeeded));

    // Allow change to propagate to the browser.
    // Windows, or at least Travis on Windows, seems to need more time.
    final delay = Platform.isWindows
        ? const Duration(seconds: 5)
        : const Duration(seconds: 2);
    await Future.delayed(delay);
  }

  Future<ChromeTab> _fetchDartDebugExtensionTab(
      ChromeConnection connection) async {
    final extensionTabs = (await connection.getTabs()).where((tab) {
      return tab.isChromeExtension;
    });
    for (var tab in extensionTabs) {
      final tabConnection = await tab.connect();
      final response =
          await tabConnection.runtime.evaluate('window.isDartDebugExtension');
      if (response.value == true) {
        return tab;
      }
    }
    throw StateError('No extension installed.');
  }

  /// Finds the line number in [scriptRef] matching [breakpointId].
  ///
  /// A breakpoint ID is found by looking for a line that ends with a comment
  /// of exactly this form: `// Breakpoint: <id>`.
  ///
  /// Throws if it can't find the matching line.
  Future<int> findBreakpointLine(
      String breakpointId, String isolateId, ScriptRef scriptRef) async {
    final script = await debugConnection.vmService
        .getObject(isolateId, scriptRef.id) as Script;
    final lines = LineSplitter.split(script.source).toList();
    final lineNumber =
        lines.indexWhere((l) => l.endsWith('// Breakpoint: $breakpointId'));
    if (lineNumber == -1) {
      throw StateError('Unable to find breakpoint in ${scriptRef.uri} with id '
          '$breakpointId');
    }
    return lineNumber + 1;
  }
}
