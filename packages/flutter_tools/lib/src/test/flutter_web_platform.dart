// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p; // ignore: package_path_import
import 'package:pool/pool.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_core/src/runner/configuration.dart';
import 'package:test_core/src/runner/environment.dart';
import 'package:test_core/src/runner/platform.dart';
import 'package:test_core/src/runner/plugin/platform_helpers.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/suite.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../web/chrome.dart';
import 'test_compiler.dart';
import 'test_config.dart';

class FlutterWebPlatform extends PlatformPlugin {
  FlutterWebPlatform._(this._server, this._config, this._root, {
    FlutterProject flutterProject,
    String shellPath,
    this.updateGoldens,
  }) {
    final shelf.Cascade cascade = shelf.Cascade()
        .add(_webSocketHandler.handler)
        .add(packagesDirHandler())
        .add(_jsHandler.handler)
        .add(createStaticHandler(
          globals.fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools'),
          serveFilesOutsidePath: true,
        ))
        .add(createStaticHandler(
          _config.suiteDefaults.precompiledPath,
          serveFilesOutsidePath: true,
        ))
        .add(_handleStaticArtifact)
        .add(_goldenFileHandler)
        .add(_wrapperHandler)
        .add(createStaticHandler(
          p.join(p.current, 'test'),
          serveFilesOutsidePath: true,
        ))
        .add(_packageFilesHandler);
    _server.mount(cascade.handler);

    _testGoldenComparator = TestGoldenComparator(
      shellPath,
      () => TestCompiler(BuildMode.debug, false, flutterProject, <String>[]),
    );
  }

  static Future<FlutterWebPlatform> start(String root, {
    FlutterProject flutterProject,
    String shellPath,
    bool updateGoldens = false,
    bool pauseAfterLoad = false,
  }) async {
    final shelf_io.IOServer server =
        shelf_io.IOServer(await HttpMultiServer.loopback(0));
    return FlutterWebPlatform._(
      server,
      Configuration.current.change(pauseAfterLoad: pauseAfterLoad),
      root,
      flutterProject: flutterProject,
      shellPath: shellPath,
      updateGoldens: updateGoldens,
    );
  }

  final Future<PackageConfig> _packagesFuture = loadPackageConfigWithLogging(
    globals.fs.file(globalPackagesPath),
    logger: globals.logger,
  );

  final Future<PackageConfig> _flutterToolsPackageMap = loadPackageConfigWithLogging(
    globals.fs.file(globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      '.packages',
    )),
    logger: globals.logger,
  );

  /// Uri of the test package.
  Future<Uri> get testUri async => (await _flutterToolsPackageMap)['test']?.packageUriRoot;

  /// The test runner configuration.
  final Configuration _config;

  @visibleForTesting
  Configuration get config => _config;

  /// The underlying server.
  final shelf.Server _server;

  @visibleForTesting
  shelf.Server get server => _server;

  /// The URL for this server.
  Uri get url => _server.url;

  /// The ahem text file.
  File get ahem => globals.fs.file(globals.fs.path.join(
        Cache.flutterRoot,
        'packages',
        'flutter_tools',
        'static',
        'Ahem.ttf',
      ));

  /// The require js binary.
  File get requireJs => globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'kernel',
        'amd',
        'require.js',
      ));

  /// The ddc to dart stack trace mapper.
  File get stackTraceMapper => globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js',
      ));

  /// The precompiled dart sdk.
  File get dartSdk => globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));

  /// The precompiled test javascript.
  Future<File> get testDartJs async => globals.fs.file(globals.fs.path.join(
    (await testUri).toFilePath(),
    'dart.js',
  ));

  Future<File> get testHostDartJs async => globals.fs.file(globals.fs.path.join(
    (await testUri).toFilePath(),
    'src',
    'runner',
    'browser',
    'static',
    'host.dart.js',
  ));

  Future<shelf.Response> _handleStaticArtifact(shelf.Request request) async {
    if (request.requestedUri.path.contains('require.js')) {
      return shelf.Response.ok(
        requireJs.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path.contains('ahem.ttf')) {
      return shelf.Response.ok(ahem.openRead());
    } else if (request.requestedUri.path.contains('dart_sdk.js')) {
      return shelf.Response.ok(
        dartSdk.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path
        .contains('stack_trace_mapper.dart.js')) {
      return shelf.Response.ok(
        stackTraceMapper.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path.contains('static/dart.js')) {
      return shelf.Response.ok(
        (await testDartJs).openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path.contains('host.dart.js')) {
      return shelf.Response.ok(
        (await testHostDartJs).openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else {
      return shelf.Response.notFound('Not Found');
    }
  }

  FutureOr<shelf.Response> _packageFilesHandler(shelf.Request request) async {
    if (request.requestedUri.pathSegments.first == 'packages') {
      final PackageConfig packageConfig = await _packagesFuture;
      final Uri fileUri = packageConfig.resolve(Uri(
        scheme: 'package',
        pathSegments: request.requestedUri.pathSegments.skip(1),
      ));
      if (fileUri != null) {
        final String dirname = p.dirname(fileUri.toFilePath());
        final String basename = p.basename(fileUri.toFilePath());
        final shelf.Handler handler = createStaticHandler(dirname);
        final shelf.Request modifiedRequest = shelf.Request(
          request.method,
          request.requestedUri.replace(path: basename),
          protocolVersion: request.protocolVersion,
          headers: request.headers,
          handlerPath: request.handlerPath,
          url: request.url.replace(path: basename),
          encoding: request.encoding,
          context: request.context,
        );
        return handler(modifiedRequest);
      }
    }
    return shelf.Response.notFound('Not Found');
  }

  final bool updateGoldens;
  TestGoldenComparator _testGoldenComparator;

  Future<shelf.Response> _goldenFileHandler(shelf.Request request) async {
    if (request.url.path.contains('flutter_goldens')) {
      final Map<String, Object> body = json.decode(await request.readAsString()) as Map<String, Object>;
      final Uri goldenKey = Uri.parse(body['key'] as String);
      final Uri testUri = Uri.parse(body['testUri'] as String);
      final num width = body['width'] as num;
      final num height = body['height'] as num;
      Uint8List bytes;

      try {
        final ChromeTab chromeTab = await _browserManager._browser.chromeConnection.getTab((ChromeTab tab) {
          return tab.url.contains(_browserManager._browser.url);
        });
        final WipConnection connection = await chromeTab.connect();
        final WipResponse response = await connection.sendCommand('Page.captureScreenshot', <String, Object>{
          // Clip the screenshot to include only the element.
          // Prior to taking a screenshot, we are calling `window.render()` in
          // `_matchers_web.dart` to only render the element on screen. That
          // will make sure that the element will always be displayed on the
          // origin of the screen.
          'clip': <String, Object>{
            'x': 0.0,
            'y': 0.0,
            'width': width.toDouble(),
            'height': height.toDouble(),
            'scale': 1.0,
          }
        });
        bytes = base64.decode(response.result['data'] as String);
      } on WipError catch (ex) {
        globals.printError('Caught WIPError: $ex');
        return shelf.Response.ok('WIP error: $ex');
      } on FormatException catch (ex) {
        globals.printError('Caught FormatException: $ex');
        return shelf.Response.ok('Caught exception: $ex');
      }

      if (bytes == null) {
        return shelf.Response.ok('Unknown error, bytes is null');
      }

      final String errorMessage = await _testGoldenComparator.compareGoldens(testUri, bytes, goldenKey, updateGoldens);
      return shelf.Response.ok(errorMessage ?? 'true');
    } else {
      return shelf.Response.notFound('Not Found');
    }
  }

  final OneOffHandler _webSocketHandler = OneOffHandler();
  final PathHandler _jsHandler = PathHandler();
  final AsyncMemoizer<void> _closeMemo = AsyncMemoizer<void>();
  final String _root;

  bool get _closed => _closeMemo.hasRun;

  BrowserManager _browserManager;

  // A handler that serves wrapper files used to bootstrap tests.
  shelf.Response _wrapperHandler(shelf.Request request) {
    final String path = globals.fs.path.fromUri(request.url);
    if (path.endsWith('.html')) {
      final String test = globals.fs.path.withoutExtension(path) + '.dart';
      final String scriptBase = htmlEscape.convert(globals.fs.path.basename(test));
      final String link = '<link rel="x-dart-test" href="$scriptBase">';
      return shelf.Response.ok('''
        <!DOCTYPE html>
        <html>
        <head>
          <title>${htmlEscape.convert(test)} Test</title>
          $link
          <script src="static/dart.js"></script>
        </head>
        </html>
      ''', headers: <String, String>{'Content-Type': 'text/html'});
    }
    globals.printTrace('Did not find anything for request: ${request.url}');
    return shelf.Response.notFound('Not found.');
  }

  /// Allows only one test suite (typically one test file) to be loaded and run
  /// at any given point in time. Loading more than one file at a time is known
  /// to lead to flaky tests.
  final Pool _suiteLock = Pool(1);

  @override
  Future<RunnerSuite> load(
    String path,
    SuitePlatform platform,
    SuiteConfiguration suiteConfig,
    Object message,
  ) async {
    if (_closed) {
      throw StateError('Load called on a closed FlutterWebPlatform');
    }
    final PoolResource lockResource = await _suiteLock.request();

    final Runtime browser = platform.runtime;
    try {
      _browserManager = await _launchBrowser(browser);
    } on Error catch (_) {
      await _suiteLock.close();
      rethrow;
    }

    if (_closed) {
      throw StateError('Load called on a closed FlutterWebPlatform');
    }

    final Uri suiteUrl = url.resolveUri(globals.fs.path.toUri(globals.fs.path.withoutExtension(
            globals.fs.path.relative(path, from: globals.fs.path.join(_root, 'test'))) +
        '.html'));
    final RunnerSuite suite = await _browserManager.load(path, suiteUrl, suiteConfig, message, onDone: () async {
      await _browserManager.close();
      _browserManager = null;
      lockResource.release();
    });
    if (_closed) {
      throw StateError('Load called on a closed FlutterWebPlatform');
    }
    return suite;
  }

  @override
  StreamChannel<dynamic> loadChannel(String path, SuitePlatform platform) =>
      throw UnimplementedError();

  /// Returns the [BrowserManager] for [runtime], which should be a browser.
  ///
  /// If no browser manager is running yet, starts one.
  Future<BrowserManager> _launchBrowser(Runtime browser) {
    if (_browserManager != null) {
      throw StateError('Another browser is currently running.');
    }

    final Completer<WebSocketChannel> completer =
        Completer<WebSocketChannel>.sync();
    final String path =
        _webSocketHandler.create(webSocketHandler(completer.complete));
    final Uri webSocketUrl = url.replace(scheme: 'ws').resolve(path);
    final Uri hostUrl = url
      .resolve('static/index.html')
      .replace(queryParameters: <String, String>{
        'managerUrl': webSocketUrl.toString(),
        'debug': _config.pauseAfterLoad.toString(),
      });

    globals.printTrace('Serving tests at $hostUrl');

    return BrowserManager.start(
      browser,
      hostUrl,
      completer.future,
      headless: !_config.pauseAfterLoad,
    );
  }

  @override
  Future<void> closeEphemeral() async {
    if (_browserManager != null) {
      await _browserManager.close();
    }
  }

  @override
  Future<void> close() => _closeMemo.runOnce(() async {
    await Future.wait<void>(<Future<dynamic>>[
      if (_browserManager != null)
        _browserManager.close(),
      _server.close(),
      _testGoldenComparator.close(),
    ]);
  });
}

class OneOffHandler {
  /// A map from URL paths to handlers.
  final Map<String, shelf.Handler> _handlers = <String, shelf.Handler>{};

  /// The counter of handlers that have been activated.
  int _counter = 0;

  /// The actual [shelf.Handler] that dispatches requests.
  shelf.Handler get handler => _onRequest;

  /// Creates a new one-off handler that forwards to [handler].
  ///
  /// Returns a string that's the URL path for hitting this handler, relative to
  /// the URL for the one-off handler itself.
  ///
  /// [handler] will be unmounted as soon as it receives a request.
  String create(shelf.Handler handler) {
    final String path = _counter.toString();
    _handlers[path] = handler;
    _counter++;
    return path;
  }

  /// Dispatches [request] to the appropriate handler.
  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    final List<String> components = p.url.split(request.url.path);
    if (components.isEmpty) {
      return shelf.Response.notFound(null);
    }
    final String path = components.removeAt(0);
    final FutureOr<shelf.Response> Function(shelf.Request) handler =
        _handlers.remove(path);
    if (handler == null) {
      return shelf.Response.notFound(null);
    }
    return handler(request.change(path: path));
  }
}

class PathHandler {
  /// A trie of path components to handlers.
  final _Node _paths = _Node();

  /// The shelf handler.
  shelf.Handler get handler => _onRequest;

  /// Returns middleware that nests all requests beneath the URL prefix
  /// [beneath].
  static shelf.Middleware nestedIn(String beneath) {
    return (FutureOr<shelf.Response> Function(shelf.Request) handler) {
      final PathHandler pathHandler = PathHandler()..add(beneath, handler);
      return pathHandler.handler;
    };
  }

  /// Routes requests at or under [path] to [handler].
  ///
  /// If [path] is a parent or child directory of another path in this handler,
  /// the longest matching prefix wins.
  void add(String path, shelf.Handler handler) {
    _Node node = _paths;
    for (final String component in p.url.split(path)) {
      node = node.children.putIfAbsent(component, () => _Node());
    }
    node.handler = handler;
  }

  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    shelf.Handler handler;
    int handlerIndex;
    _Node node = _paths;
    final List<String> components = p.url.split(request.url.path);
    for (int i = 0; i < components.length; i++) {
      node = node.children[components[i]];
      if (node == null) {
        break;
      }
      if (node.handler == null) {
        continue;
      }
      handler = node.handler;
      handlerIndex = i;
    }

    if (handler == null) {
      return shelf.Response.notFound('Not found.');
    }

    return handler(
        request.change(path: p.url.joinAll(components.take(handlerIndex + 1))));
  }
}

/// A trie node.
class _Node {
  shelf.Handler handler;
  final Map<String, _Node> children = <String, _Node>{};
}

class BrowserManager {
  /// Creates a new BrowserManager that communicates with [browser] over
  /// [webSocket].
  BrowserManager._(this._browser, this._runtime, WebSocketChannel webSocket) {
    // The duration should be short enough that the debugging console is open as
    // soon as the user is done setting breakpoints, but long enough that a test
    // doing a lot of synchronous work doesn't trigger a false positive.
    //
    // Start this canceled because we don't want it to start ticking until we
    // get some response from the iframe.
    _timer = RestartableTimer(const Duration(seconds: 3), () {
      for (final RunnerSuiteController controller in _controllers) {
        controller.setDebugging(true);
      }
    })
      ..cancel();

    // Whenever we get a message, no matter which child channel it's for, we know
    // the browser is still running code which means the user isn't debugging.
    _channel = MultiChannel<dynamic>(
      webSocket.cast<String>().transform(jsonDocument).changeStream((Stream<Object> stream) {
        return stream.map((Object message) {
          if (!_closed) {
            _timer.reset();
          }
          for (final RunnerSuiteController controller in _controllers) {
            controller.setDebugging(false);
          }

          return message;
        });
      }),
    );

    _environment = _loadBrowserEnvironment();
    _channel.stream.listen(_onMessage, onDone: close);
  }

  /// The browser instance that this is connected to via [_channel].
  final Chromium _browser;

  // TODO(nweiz): Consider removing the duplication between this and
  // [_browser.name].
  /// The [Runtime] for [_browser].
  final Runtime _runtime;

  /// The channel used to communicate with the browser.
  ///
  /// This is connected to a page running `static/host.dart`.
  MultiChannel<dynamic> _channel;

  /// The ID of the next suite to be loaded.
  ///
  /// This is used to ensure that the suites can be referred to consistently
  /// across the client and server.
  int _suiteID = 0;

  /// Whether the channel to the browser has closed.
  bool _closed = false;

  /// The completer for [_BrowserEnvironment.displayPause].
  ///
  /// This will be `null` as long as the browser isn't displaying a pause
  /// screen.
  CancelableCompleter<dynamic> _pauseCompleter;

  /// The controller for [_BrowserEnvironment.onRestart].
  final StreamController<dynamic> _onRestartController =
      StreamController<dynamic>.broadcast();

  /// The environment to attach to each suite.
  Future<_BrowserEnvironment> _environment;

  /// Controllers for every suite in this browser.
  ///
  /// These are used to mark suites as debugging or not based on the browser's
  /// pings.
  final Set<RunnerSuiteController> _controllers = <RunnerSuiteController>{};

  // A timer that's reset whenever we receive a message from the browser.
  //
  // Because the browser stops running code when the user is actively debugging,
  // this lets us detect whether they're debugging reasonably accurately.
  RestartableTimer _timer;

  final AsyncMemoizer<dynamic> _closeMemoizer = AsyncMemoizer<dynamic>();

  /// Starts the browser identified by [runtime] and has it connect to [url].
  ///
  /// [url] should serve a page that establishes a WebSocket connection with
  /// this process. That connection, once established, should be emitted via
  /// [future]. If [debug] is true, starts the browser in debug mode, with its
  /// debugger interfaces on and detected.
  ///
  /// The browser will start in headless mode if [headless] is true.
  ///
  /// The [settings] indicate how to invoke this browser's executable.
  ///
  /// Returns the browser manager, or throws an [ApplicationException] if a
  /// connection fails to be established.
  static Future<BrowserManager> start(
    Runtime runtime,
    Uri url,
    Future<WebSocketChannel> future, {
    bool debug = false,
    bool headless = true,
  }) async {
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      browserFinder: findChromeExecutable,
      fileSystem: globals.fs,
      operatingSystemUtils: globals.os,
      platform: globals.platform,
      processManager: globals.processManager,
      logger: globals.logger,
    );
    final Chromium chrome =
      await chromiumLauncher.launch(url.toString(), headless: headless);

    final Completer<BrowserManager> completer = Completer<BrowserManager>();

    unawaited(chrome.onExit.then((int browserExitCode) {
      throwToolExit('${runtime.name} exited with code $browserExitCode before connecting.');
    }).catchError((dynamic error, StackTrace stackTrace) {
      if (completer.isCompleted) {
        return;
      }
      completer.completeError(error, stackTrace);
    }));
    unawaited(future.then((WebSocketChannel webSocket) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(BrowserManager._(chrome, runtime, webSocket));
    }).catchError((dynamic error, StackTrace stackTrace) {
      chrome.close();
      if (completer.isCompleted) {
        return;
      }
      completer.completeError(error, stackTrace);
    }));

    return completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
      chrome.close();
      throwToolExit('Timed out waiting for ${runtime.name} to connect.');
      return;
    });
  }

  /// Loads [_BrowserEnvironment].
  Future<_BrowserEnvironment> _loadBrowserEnvironment() async {
    return _BrowserEnvironment(
        this, null, _browser.chromeConnection.url, _onRestartController.stream);
  }

  /// Tells the browser to load a test suite from the URL [url].
  ///
  /// [url] should be an HTML page with a reference to the JS-compiled test
  /// suite. [path] is the path of the original test suite file, which is used
  /// for reporting. [suiteConfig] is the configuration for the test suite.
  ///
  /// If [mapper] is passed, it's used to map stack traces for errors coming
  /// from this test suite.
  Future<RunnerSuite> load(
    String path,
    Uri url,
    SuiteConfiguration suiteConfig,
    Object message, {
      Future<void> Function() onDone,
    }
  ) async {
    url = url.replace(fragment: Uri.encodeFull(jsonEncode(<String, Object>{
      'metadata': suiteConfig.metadata.serialize(),
      'browser': _runtime.identifier,
    })));

    final int suiteID = _suiteID++;
    RunnerSuiteController controller;
    void closeIframe() {
      if (_closed) {
        return;
      }
      _controllers.remove(controller);
      _channel.sink
          .add(<String, Object>{'command': 'closeSuite', 'id': suiteID});
    }

    // The virtual channel will be closed when the suite is closed, in which
    // case we should unload the iframe.
    final VirtualChannel<dynamic> virtualChannel = _channel.virtualChannel();
    final int suiteChannelID = virtualChannel.id;
    final StreamChannel<dynamic> suiteChannel = virtualChannel.transformStream(
      StreamTransformer<dynamic, dynamic>.fromHandlers(handleDone: (EventSink<dynamic> sink) {
        closeIframe();
        sink.close();
        onDone();
      }),
    );

    _channel.sink.add(<String, Object>{
      'command': 'loadSuite',
      'url': url.toString(),
      'id': suiteID,
      'channel': suiteChannelID,
    });

    try {
      controller = deserializeSuite(path, SuitePlatform(Runtime.chrome),
        suiteConfig, await _environment, suiteChannel, message);

      _controllers.add(controller);
      return await controller.suite;
    // Not limiting to catching Exception because the exception is rethrown.
    } catch (_) { // ignore: avoid_catches_without_on_clauses
      closeIframe();
      rethrow;
    }
  }

  /// An implementation of [Environment.displayPause].
  CancelableOperation<dynamic> _displayPause() {
    if (_pauseCompleter != null) {
      return _pauseCompleter.operation;
    }
    _pauseCompleter = CancelableCompleter<dynamic>(onCancel: () {
      _channel.sink.add(<String, String>{'command': 'resume'});
      _pauseCompleter = null;
    });
    _pauseCompleter.operation.value.whenComplete(() {
      _pauseCompleter = null;
    });
    _channel.sink.add(<String, String>{'command': 'displayPause'});

    return _pauseCompleter.operation;
  }

  /// The callback for handling messages received from the host page.
  void _onMessage(dynamic message) {
    switch (message['command'] as String) {
      case 'ping':
        break;
      case 'restart':
        _onRestartController.add(null);
        break;
      case 'resume':
        if (_pauseCompleter != null) {
          _pauseCompleter.complete();
        }
        break;
      default:
        // Unreachable.
        assert(false);
        break;
    }
  }

  /// Closes the manager and releases any resources it owns, including closing
  /// the browser.
  Future<dynamic> close() {
    return _closeMemoizer.runOnce(() {
      _closed = true;
      _timer.cancel();
      if (_pauseCompleter != null) {
        _pauseCompleter.complete();
      }
      _pauseCompleter = null;
      _controllers.clear();
      return _browser.close();
    });
  }
}

/// An implementation of [Environment] for the browser.
///
/// All methods forward directly to [BrowserManager].
class _BrowserEnvironment implements Environment {
  _BrowserEnvironment(
    this._manager,
    this.observatoryUrl,
    this.remoteDebuggerUrl,
    this.onRestart,
  );

  final BrowserManager _manager;

  @override
  final bool supportsDebugging = true;

  @override
  final Uri observatoryUrl;

  @override
  final Uri remoteDebuggerUrl;

  @override
  final Stream<dynamic> onRestart;

  @override
  CancelableOperation<dynamic> displayPause() => _manager._displayPause();
}

/// Helper class to start golden file comparison in a separate process.
///
/// Golden file comparator is configured using flutter_test_config.dart and that
/// file can contain arbitrary Dart code that depends on dart:ui. Thus it has to
/// be executed in a `flutter_tester` environment. This helper class generates a
/// Dart file configured with flutter_test_config.dart to perform the comparison
/// of golden files.
class TestGoldenComparator {
  /// Creates a [TestGoldenComparator] instance.
  TestGoldenComparator(this.shellPath, this.compilerFactory)
      : tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_web_platform.');

  final String shellPath;
  final Directory tempDir;
  final TestCompiler Function() compilerFactory;

  TestCompiler _compiler;
  TestGoldenComparatorProcess _previousComparator;
  Uri _previousTestUri;

  Future<void> close() async {
    tempDir.deleteSync(recursive: true);
    await _compiler?.dispose();
    await _previousComparator?.close();
  }

  /// Start golden comparator in a separate process. Start one file per test file
  /// to reduce the overhead of starting `flutter_tester`.
  Future<TestGoldenComparatorProcess> _processForTestFile(Uri testUri) async {
    if (testUri == _previousTestUri) {
      return _previousComparator;
    }

    final String bootstrap = TestGoldenComparatorProcess.generateBootstrap(testUri);
    final Process process = await _startProcess(bootstrap);
    unawaited(_previousComparator?.close());
    _previousComparator = TestGoldenComparatorProcess(process);
    _previousTestUri = testUri;

    return _previousComparator;
  }

  Future<Process> _startProcess(String testBootstrap) async {
    // Prepare the Dart file that will talk to us and start the test.
    final File listenerFile = (await tempDir.createTemp('listener')).childFile('listener.dart');
    await listenerFile.writeAsString(testBootstrap);

    // Lazily create the compiler
    _compiler = _compiler ?? compilerFactory();
    final String output = await _compiler.compile(listenerFile.uri);
    final List<String> command = <String>[
      shellPath,
      '--disable-observatory',
      '--non-interactive',
      '--packages=$globalPackagesPath',
      output,
    ];

    final Map<String, String> environment = <String, String>{
      // Chrome is the only supported browser currently.
      'FLUTTER_TEST_BROWSER': 'chrome',
    };
    return globals.processManager.start(command, environment: environment);
  }

  Future<String> compareGoldens(Uri testUri, Uint8List bytes, Uri goldenKey, bool updateGoldens) async {
    final File imageFile = await (await tempDir.createTemp('image')).childFile('image').writeAsBytes(bytes);

    final TestGoldenComparatorProcess process = await _processForTestFile(testUri);
    process.sendCommand(imageFile, goldenKey, updateGoldens);

    final Map<String, dynamic> result = await process.getResponse().timeout(const Duration(seconds: 20));

    if (result == null) {
      return 'unknown error';
    } else {
      return (result['success'] as bool) ? null : ((result['message'] as String) ?? 'does not match');
    }
  }
}

/// Represents a `flutter_tester` process started for golden comparison. Also
/// handles communication with the child process.
class TestGoldenComparatorProcess {
  /// Creates a [TestGoldenComparatorProcess] backed by [process].
  TestGoldenComparatorProcess(this.process) {
    // Pipe stdout and stderr to printTrace and printError.
    // Also parse stdout as a stream of JSON objects.
    streamIterator = StreamIterator<Map<String, dynamic>>(
      process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .where((String line) {
          globals.printTrace('<<< $line');
          return line.isNotEmpty && line[0] == '{';
        })
        .map<dynamic>(jsonDecode)
        .cast<Map<String, dynamic>>());

    process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .forEach((String line) {
          globals.printError('<<< $line');
        });
  }

  final Process process;
  StreamIterator<Map<String, dynamic>> streamIterator;

  Future<void> close() async {
    await process.stdin.close();
    process.kill();
  }

  void sendCommand(File imageFile, Uri goldenKey, bool updateGoldens) {
    final Object command = jsonEncode(<String, dynamic>{
      'imageFile': imageFile.path,
      'key': goldenKey.toString(),
      'update': updateGoldens,
    });
    globals.printTrace('Preparing to send command: $command');
    process.stdin.writeln(command);
  }

  Future<Map<String, dynamic>> getResponse() async {
    final bool available = await streamIterator.moveNext();
    assert(available);
    return streamIterator.current;
  }

  static String generateBootstrap(Uri testUri) {
    final File testConfigFile = findTestConfigFile(globals.fs.file(testUri));
    // Generate comparator process for the file.
    return '''
import 'dart:convert'; // ignore: dart_convert_import
import 'dart:io'; // ignore: dart_io_import

import 'package:flutter_test/flutter_test.dart';

${testConfigFile != null ? "import '${Uri.file(testConfigFile.path)}' as test_config;" : ""}

void main() async {
  LocalFileComparator comparator = LocalFileComparator(Uri.parse('$testUri'));
  goldenFileComparator = comparator;

  ${testConfigFile != null ? 'test_config.main(() async {' : ''}
  final commands = stdin
    .transform<String>(utf8.decoder)
    .transform<String>(const LineSplitter())
    .map<Object>(jsonDecode);
  await for (final Object command in commands) {
    if (command is Map<String, dynamic>) {
      File imageFile = File(command['imageFile']);
      Uri goldenKey = Uri.parse(command['key']);
      bool update = command['update'];

      final bytes = await File(imageFile.path).readAsBytes();
      if (update) {
        await goldenFileComparator.update(goldenKey, bytes);
        print(jsonEncode({'success': true}));
      } else {
        try {
          bool success = await goldenFileComparator.compare(bytes, goldenKey);
          print(jsonEncode({'success': success}));
        } on Exception catch (ex) {
          print(jsonEncode({'success': false, 'message': '\$ex'}));
        }
      }
    } else {
      print('object type is not right');
    }
  }
  ${testConfigFile != null ? '});' : ''}
}
    ''';
  }
}
