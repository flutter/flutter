// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:image/image.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/runner_suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/stack_trace_mapper.dart'; // ignore: implementation_imports
import 'package:test_api/src/utils.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/plugin/platform_helpers.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/environment.dart'; // ignore: implementation_imports

import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/configuration.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/load_exception.dart'; // ignore: implementation_imports
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

import 'browser.dart';
import 'common.dart';
import 'environment.dart' as env;
import 'goldens.dart';
import 'supported_browsers.dart';

class BrowserPlatform extends PlatformPlugin {
  /// Starts the server.
  ///
  /// [root] is the root directory that the server should serve. It defaults to
  /// the working directory.
  static Future<BrowserPlatform> start(String name,
      {String root, bool doUpdateScreenshotGoldens: false}) async {
    assert(SupportedBrowsers.instance.supportedBrowserNames.contains(name));
    var server = shelf_io.IOServer(await HttpMultiServer.loopback(0));
    return BrowserPlatform._(
      name,
      server,
      Configuration.current,
      p.fromUri(await Isolate.resolvePackageUri(
          Uri.parse('package:test/src/runner/browser/static/favicon.ico'))),
      root: root,
      doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
    );
  }

  /// The test runner configuration.
  final Configuration _config;

  /// The underlying server.
  final shelf.Server _server;

  /// Name for the running browser. Not final on purpose can be mutated later.
  String browserName;

  /// A randomly-generated secret.
  ///
  /// This is used to ensure that other users on the same system can't snoop
  /// on data being served through this server.
  final _secret = Uri.encodeComponent(randomBase64(24));

  /// The URL for this server.
  Uri get url => _server.url.resolve(_secret + '/');

  /// A [OneOffHandler] for servicing WebSocket connections for
  /// [BrowserManager]s.
  ///
  /// This is one-off because each [BrowserManager] can only connect to a single
  /// WebSocket,
  final OneOffHandler _webSocketHandler = OneOffHandler();

  /// A [PathHandler] used to serve compiled JS.
  final PathHandler _jsHandler = PathHandler();

  /// The root directory served statically by this server.
  final String _root;

  /// The HTTP client to use when caching JS files in `pub serve`.
  final HttpClient _http;

  /// Whether [close] has been called.
  bool get _closed => _closeMemo.hasRun;

  /// Whether to update screenshot golden files.
  final bool doUpdateScreenshotGoldens;

  BrowserPlatform._(
      String name, this._server, Configuration config, String faviconPath,
      {String root, this.doUpdateScreenshotGoldens})
      : this.browserName = name,
        _config = config,
        _root = root == null ? p.current : root,
        _http = config.pubServeUrl == null ? null : HttpClient() {
    var cascade = shelf.Cascade().add(_webSocketHandler.handler);

    if (_config.pubServeUrl == null) {
      // We server static files from here (JS, HTML, etc)
      final String staticFilePath =
          config.suiteDefaults.precompiledPath ?? _root;
      cascade = cascade
          .add(packagesDirHandler())
          .add(_jsHandler.handler)
          .add(createStaticHandler(staticFilePath,
              // Precompiled directories often contain symlinks
              serveFilesOutsidePath:
                  config.suiteDefaults.precompiledPath != null))
          .add(_wrapperHandler);
      // Screenshot tests are only enabled in chrome for now.
      if (name == 'chrome') {
        cascade = cascade.add(_screeshotHandler);
      }
    }

    var pipeline = shelf.Pipeline()
        .addMiddleware(PathHandler.nestedIn(_secret))
        .addHandler(cascade.handler);

    _server.mount(shelf.Cascade()
        .add(createFileHandler(faviconPath))
        .add(pipeline)
        .handler);
  }

  Future<shelf.Response> _screeshotHandler(shelf.Request request) async {
    if (browserName != 'chrome') {
      throw Exception('Screenshots tests are only available in Chrome.');
    }

    if (!request.requestedUri.path.endsWith('/screenshot')) {
      return shelf.Response.notFound(
          'This request is not handled by the screenshot handler');
    }

    final String payload = await request.readAsString();
    final Map<String, dynamic> requestData =
        json.decode(payload) as Map<String, dynamic>;
    final String filename = requestData['filename'] as String;
    final bool write = requestData['write'] as bool;
    final double maxDiffRate = requestData.containsKey('maxdiffrate')
        ? (requestData['maxdiffrate'] as num)
            .toDouble() // can be parsed as either int or double
        : kMaxDiffRateFailure;
    final Map<String, dynamic> region =
        requestData['region'] as Map<String, dynamic>;
    final PixelComparison pixelComparison = PixelComparison.values.firstWhere(
        (value) => value.toString() == requestData['pixelComparison']);
    final String result = await _diffScreenshot(
        filename, write, maxDiffRate, region, pixelComparison);
    return shelf.Response.ok(json.encode(result));
  }

  Future<String> _diffScreenshot(
      String filename,
      bool write,
      double maxDiffRateFailure,
      Map<String, dynamic> region,
      PixelComparison pixelComparison) async {
    if (doUpdateScreenshotGoldens) {
      write = true;
    }

    String goldensDirectory;
    if (filename.startsWith('__local__')) {
      filename = filename.substring('__local__/'.length);
      goldensDirectory = p.join(
        env.environment.webUiRootDir.path,
        'test',
        'golden_files',
      );
    } else {
      await fetchGoldens();
      goldensDirectory = p.join(
        env.environment.webUiGoldensRepositoryDirectory.path,
        'engine',
        'web',
      );
    }

    // Bail out fast if golden doesn't exist, and user doesn't want to create it.
    final File file = File(p.join(
      goldensDirectory,
      filename,
    ));
    if (!file.existsSync() && !write) {
      return '''
Golden file $filename does not exist.

To automatically create this file call matchGoldenFile('$filename', write: true).
''';
    }

    final wip.ChromeConnection chromeConnection =
        wip.ChromeConnection('localhost', kDevtoolsPort);
    final wip.ChromeTab chromeTab = await chromeConnection.getTab(
        (wip.ChromeTab chromeTab) => chromeTab.url.contains('localhost'));
    final wip.WipConnection wipConnection = await chromeTab.connect();

    Map<String, dynamic> captureScreenshotParameters = null;
    if (region != null) {
      captureScreenshotParameters = <String, dynamic>{
        'format': 'png',
        'clip': <String, dynamic>{
          'x': region['x'],
          'y': region['y'],
          'width': region['width'],
          'height': region['height'],
          'scale':
              1, // This is NOT the DPI of the page, instead it's the "zoom level".
        },
      };
    }

    // Setting hardware-independent screen parameters:
    // https://chromedevtools.github.io/devtools-protocol/tot/Emulation
    await wipConnection
        .sendCommand('Emulation.setDeviceMetricsOverride', <String, dynamic>{
      'width': kMaxScreenshotWidth,
      'height': kMaxScreenshotHeight,
      'deviceScaleFactor': 1,
      'mobile': false,
    });
    final wip.WipResponse response = await wipConnection.sendCommand(
        'Page.captureScreenshot', captureScreenshotParameters);

    // Compare screenshots
    final Image screenshot =
        decodePng(base64.decode(response.result['data'] as String));

    if (write) {
      // Don't even bother with the comparison, just write and return
      print('Updating screenshot golden: $file');
      file.writeAsBytesSync(encodePng(screenshot), flush: true);
      if (doUpdateScreenshotGoldens) {
        // Do not fail tests when bulk-updating screenshot goldens.
        return 'OK';
      } else {
        return 'Golden file $filename was updated. You can remove "write: true" in the call to matchGoldenFile.';
      }
    }

    ImageDiff diff = ImageDiff(
      golden: decodeNamedImage(file.readAsBytesSync(), filename),
      other: screenshot,
      pixelComparison: pixelComparison,
    );

    if (diff.rate > 0) {
      // Images are different, so produce some debug info
      final String testResultsPath = isCirrus
          ? p.join(
              Platform.environment['CIRRUS_WORKING_DIR'],
              'test_results',
            )
          : p.join(
              env.environment.webUiDartToolDir.path,
              'test_results',
            );
      Directory(testResultsPath).createSync(recursive: true);
      final String basename = p.basenameWithoutExtension(file.path);

      final File actualFile =
          File(p.join(testResultsPath, '$basename.actual.png'));
      actualFile.writeAsBytesSync(encodePng(screenshot), flush: true);

      final File diffFile = File(p.join(testResultsPath, '$basename.diff.png'));
      diffFile.writeAsBytesSync(encodePng(diff.diff), flush: true);

      final File expectedFile =
          File(p.join(testResultsPath, '$basename.expected.png'));
      file.copySync(expectedFile.path);

      final File reportFile =
          File(p.join(testResultsPath, '$basename.report.html'));
      reportFile.writeAsStringSync('''
Golden file $filename did not match the image generated by the test.

<table>
  <tr>
    <th>Expected</th>
    <th>Diff</th>
    <th>Actual</th>
  </tr>
  <tr>
    <td>
      <img src="$basename.expected.png">
    </td>
    <td>
      <img src="$basename.diff.png">
    </td>
    <td>
      <img src="$basename.actual.png">
    </td>
  </tr>
</table>
''');

      final StringBuffer message = StringBuffer();
      message.writeln(
          'Golden file $filename did not match the image generated by the test.');
      message.writeln(getPrintableDiffFilesInfo(diff.rate, maxDiffRateFailure));
      message
          .writeln('You can view the test report in your browser by opening:');

      // Cirrus cannot serve HTML pages generated by build jobs, so we
      // archive all the files so that they can be downloaded and inspected
      // locally.
      if (isCirrus) {
        final String taskId = Platform.environment['CIRRUS_TASK_ID'];
        final String baseArtifactsUrl =
            'https://api.cirrus-ci.com/v1/artifact/task/$taskId/web_engine_test/test_results';
        final String cirrusReportUrl = '$baseArtifactsUrl/$basename.report.zip';
        message.writeln(cirrusReportUrl);

        await Process.run(
          'zip',
          <String>[
            '$basename.report.zip',
            '$basename.report.html',
            '$basename.expected.png',
            '$basename.diff.png',
            '$basename.actual.png',
          ],
          workingDirectory: testResultsPath,
        );
      } else {
        final String localReportPath = '$testResultsPath/$basename.report.html';
        message.writeln(localReportPath);
      }

      message.writeln(
          'To update the golden file call matchGoldenFile(\'$filename\', write: true).');
      message.writeln('Golden file: ${expectedFile.path}');
      message.writeln('Actual file: ${actualFile.path}');

      if (diff.rate < maxDiffRateFailure) {
        // Issue a warning but do not fail the test.
        print('WARNING:');
        print(message);
        return 'OK';
      } else {
        // Fail test
        return '$message';
      }
    }
    return 'OK';
  }

  /// A handler that serves wrapper files used to bootstrap tests.
  shelf.Response _wrapperHandler(shelf.Request request) {
    var path = p.fromUri(request.url);

    if (path.endsWith('.html')) {
      var test = p.withoutExtension(path) + '.dart';

      // Link to the Dart wrapper.
      var scriptBase = htmlEscape.convert(p.basename(test));
      var link = '<link rel="x-dart-test" href="$scriptBase">';

      return shelf.Response.ok('''
        <!DOCTYPE html>
        <html>
        <head>
          <title>${htmlEscape.convert(test)} Test</title>
          $link
          <script src="packages/test/dart.js"></script>
        </head>
        </html>
      ''', headers: {'Content-Type': 'text/html'});
    }

    return shelf.Response.notFound('Not found.');
  }

  /// Loads the test suite at [path] on the platform [platform].
  ///
  /// This will start a browser to load the suite if one isn't already running.
  /// Throws an [ArgumentError] if `platform.platform` isn't a browser.
  Future<RunnerSuite> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Object message) async {
    if (suiteConfig.precompiledPath == null) {
      throw Exception('This test platform only supports precompiled JS.');
    }
    var browser = platform.runtime;
    assert(suiteConfig.runtimes.contains(browser.identifier));

    if (!browser.isBrowser) {
      throw ArgumentError('$browser is not a browser.');
    }

    var htmlPath = p.withoutExtension(path) + '.html';
    if (File(htmlPath).existsSync() &&
        !File(htmlPath).readAsStringSync().contains('packages/test/dart.js')) {
      throw LoadException(
          path,
          '"${htmlPath}" must contain <script src="packages/test/dart.js">'
          '</script>.');
    }

    if (_closed) {
      return null;
    }
    Uri suiteUrl = url.resolveUri(
        p.toUri(p.withoutExtension(p.relative(path, from: _root)) + '.html'));

    if (_closed) {
      return null;
    }

    var browserManager = await _browserManagerFor(browser);
    if (_closed || browserManager == null) {
      return null;
    }

    var suite = await browserManager.load(path, suiteUrl, suiteConfig, message);
    if (_closed) {
      return null;
    }
    return suite;
  }

  StreamChannel loadChannel(String path, SuitePlatform platform) =>
      throw UnimplementedError();

  Future<BrowserManager> _browserManager;

  /// Returns the [BrowserManager] for [runtime], which should be a browser.
  ///
  /// If no browser manager is running yet, starts one.
  Future<BrowserManager> _browserManagerFor(Runtime browser) {
    if (_browserManager != null) {
      return _browserManager;
    }

    var completer = Completer<WebSocketChannel>.sync();
    var path = _webSocketHandler.create(webSocketHandler(completer.complete));
    var webSocketUrl = url.replace(scheme: 'ws').resolve(path);
    var hostUrl = (_config.pubServeUrl == null ? url : _config.pubServeUrl)
        .resolve('packages/web_engine_tester/static/index.html')
        .replace(queryParameters: <String, dynamic>{
      'managerUrl': webSocketUrl.toString(),
      'debug': _config.pauseAfterLoad.toString()
    });

    var future = BrowserManager.start(browser, hostUrl, completer.future,
        debug: _config.pauseAfterLoad);

    // Store null values for browsers that error out so we know not to load them
    // again.
    _browserManager = future.catchError((dynamic _) => null);

    return future;
  }

  /// Close all the browsers that the server currently has open.
  ///
  /// Note that this doesn't close the server itself. Browser tests can still be
  /// loaded, they'll just spawn new browsers.
  Future<void> closeEphemeral() async {
    final BrowserManager result = await _browserManager;
    if (result != null) {
      await result.close();
    }
  }

  /// Closes the server and releases all its resources.
  ///
  /// Returns a [Future] that completes once the server is closed and its
  /// resources have been fully released.
  Future<void> close() {
    return _closeMemo.runOnce(() async {
      final List<Future<void>> futures = <Future<void>>[];
      futures.add(Future<void>.microtask(() async {
        final BrowserManager result = await _browserManager;
        if (result != null) {
          await result.close();
        }
      }));
      futures.add(_server.close());

      await Future.wait(futures);

      if (_config.pubServeUrl != null) {
        _http.close();
      }
    });
  }

  final AsyncMemoizer<dynamic> _closeMemo = AsyncMemoizer<dynamic>();
}

/// A Shelf handler that provides support for one-time handlers.
///
/// This is useful for handlers that only expect to be hit once before becoming
/// invalid and don't need to have a persistent URL.
class OneOffHandler {
  /// A map from URL paths to handlers.
  final _handlers = Map<String, shelf.Handler>();

  /// The counter of handlers that have been activated.
  var _counter = 0;

  /// The actual [shelf.Handler] that dispatches requests.
  shelf.Handler get handler => _onRequest;

  /// Creates a new one-off handler that forwards to [handler].
  ///
  /// Returns a string that's the URL path for hitting this handler, relative to
  /// the URL for the one-off handler itself.
  ///
  /// [handler] will be unmounted as soon as it receives a request.
  String create(shelf.Handler handler) {
    var path = _counter.toString();
    _handlers[path] = handler;
    _counter++;
    return path;
  }

  /// Dispatches [request] to the appropriate handler.
  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    var components = p.url.split(request.url.path);
    if (components.isEmpty) {
      return shelf.Response.notFound(null);
    }

    var path = components.removeAt(0);
    var handler = _handlers.remove(path);
    if (handler == null) {
      return shelf.Response.notFound(null);
    }
    return handler(request.change(path: path));
  }
}

/// A handler that routes to sub-handlers based on exact path prefixes.
class PathHandler {
  /// A trie of path components to handlers.
  final _paths = _Node();

  /// The shelf handler.
  shelf.Handler get handler => _onRequest;

  /// Returns middleware that nests all requests beneath the URL prefix
  /// [beneath].
  static shelf.Middleware nestedIn(String beneath) {
    return (handler) {
      var pathHandler = PathHandler()..add(beneath, handler);
      return pathHandler.handler;
    };
  }

  /// Routes requests at or under [path] to [handler].
  ///
  /// If [path] is a parent or child directory of another path in this handler,
  /// the longest matching prefix wins.
  void add(String path, shelf.Handler handler) {
    var node = _paths;
    for (var component in p.url.split(path)) {
      node = node.children.putIfAbsent(component, () => _Node());
    }
    node.handler = handler;
  }

  FutureOr<shelf.Response> _onRequest(shelf.Request request) {
    shelf.Handler handler;
    int handlerIndex;
    var node = _paths;
    var components = p.url.split(request.url.path);
    for (var i = 0; i < components.length; i++) {
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
  final children = Map<String, _Node>();
}

/// A class that manages the connection to a single running browser.
///
/// This is in charge of telling the browser which test suites to load and
/// converting its responses into [Suite] objects.
class BrowserManager {
  /// The browser instance that this is connected to via [_channel].
  final Browser _browser;

  /// The [Runtime] for [_browser].
  final Runtime _runtime;

  /// The channel used to communicate with the browser.
  ///
  /// This is connected to a page running `static/host.dart`.
  MultiChannel _channel;

  /// A pool that ensures that limits the number of initial connections the
  /// manager will wait for at once.
  ///
  /// This isn't the *total* number of connections; any number of iframes may be
  /// loaded in the same browser. However, the browser can only load so many at
  /// once, and we want a timeout in case they fail so we only wait for so many
  /// at once.
  final _pool = Pool(8);

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
  CancelableCompleter _pauseCompleter;

  /// The controller for [_BrowserEnvironment.onRestart].
  final _onRestartController = StreamController<dynamic>.broadcast();

  /// The environment to attach to each suite.
  Future<_BrowserEnvironment> _environment;

  /// Controllers for every suite in this browser.
  ///
  /// These are used to mark suites as debugging or not based on the browser's
  /// pings.
  final _controllers = Set<RunnerSuiteController>();

  // A timer that's reset whenever we receive a message from the browser.
  //
  // Because the browser stops running code when the user is actively debugging,
  // this lets us detect whether they're debugging reasonably accurately.
  RestartableTimer _timer;

  /// Starts the browser identified by [runtime] and has it connect to [url].
  ///
  /// [url] should serve a page that establishes a WebSocket connection with
  /// this process. That connection, once established, should be emitted via
  /// [future]. If [debug] is true, starts the browser in debug mode, with its
  /// debugger interfaces on and detected.
  ///
  /// The [settings] indicate how to invoke this browser's executable.
  ///
  /// Returns the browser manager, or throws an [Exception] if a
  /// connection fails to be established.
  static Future<BrowserManager> start(
      Runtime runtime, Uri url, Future<WebSocketChannel> future,
      {bool debug = false}) {
    var browser = _newBrowser(url, runtime, debug: debug);

    var completer = Completer<BrowserManager>();

    browser.onExit.then((_) {
      throw Exception('${runtime.name} exited before connecting.');
    }).catchError((dynamic error, StackTrace stackTrace) {
      if (completer.isCompleted) {
        return;
      }
      completer.completeError(error, stackTrace);
    });

    future.then((webSocket) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(BrowserManager._(browser, runtime, webSocket));
    }).catchError((dynamic error, StackTrace stackTrace) {
      browser.close();
      if (completer.isCompleted) {
        return;
      }
      completer.completeError(error, stackTrace);
    });

    return completer.future.timeout(Duration(seconds: 30), onTimeout: () {
      browser.close();
      throw Exception('Timed out waiting for ${runtime.name} to connect.');
    });
  }

  /// Starts the browser identified by [browser] using [settings] and has it load [url].
  ///
  /// If [debug] is true, starts the browser in debug mode.
  static Browser _newBrowser(Uri url, Runtime browser, {bool debug = false}) {
    return SupportedBrowsers.instance.getBrowser(browser, url, debug: debug);
  }

  /// Creates a new BrowserManager that communicates with [browser] over
  /// [webSocket].
  BrowserManager._(this._browser, this._runtime, WebSocketChannel webSocket) {
    // The duration should be short enough that the debugging console is open as
    // soon as the user is done setting breakpoints, but long enough that a test
    // doing a lot of synchronous work doesn't trigger a false positive.
    //
    // Start this canceled because we don't want it to start ticking until we
    // get some response from the iframe.
    _timer = RestartableTimer(Duration(seconds: 3), () {
      for (var controller in _controllers) {
        controller.setDebugging(true);
      }
    })
      ..cancel();

    // Whenever we get a message, no matter which child channel it's for, we the
    // know browser is still running code which means the user isn't debugging.
    _channel = MultiChannel<dynamic>(
        webSocket.cast<String>().transform(jsonDocument).changeStream((stream) {
      return stream.map((message) {
        if (!_closed) {
          _timer.reset();
        }
        for (var controller in _controllers) {
          controller.setDebugging(false);
        }

        return message;
      });
    }));

    _environment = _loadBrowserEnvironment();
    _channel.stream
        .listen((dynamic message) => _onMessage(message as Map), onDone: close);
  }

  /// Loads [_BrowserEnvironment].
  Future<_BrowserEnvironment> _loadBrowserEnvironment() async {
    return _BrowserEnvironment(this, await _browser.observatoryUrl,
        await _browser.remoteDebuggerUrl, _onRestartController.stream);
  }

  /// Tells the browser the load a test suite from the URL [url].
  ///
  /// [url] should be an HTML page with a reference to the JS-compiled test
  /// suite. [path] is the path of the original test suite file, which is used
  /// for reporting. [suiteConfig] is the configuration for the test suite.
  Future<RunnerSuite> load(String path, Uri url, SuiteConfiguration suiteConfig,
      Object message) async {
    url = url.replace(
        fragment: Uri.encodeFull(jsonEncode(<String, dynamic>{
      'metadata': suiteConfig.metadata.serialize(),
      'browser': _runtime.identifier
    })));

    var suiteID = _suiteID++;
    RunnerSuiteController controller;
    void closeIframe() {
      if (_closed) {
        return;
      }
      _controllers.remove(controller);
      _channel.sink.add({'command': 'closeSuite', 'id': suiteID});
    }

    // The virtual channel will be closed when the suite is closed, in which
    // case we should unload the iframe.
    var virtualChannel = _channel.virtualChannel();
    var suiteChannelID = virtualChannel.id;
    var suiteChannel = virtualChannel.transformStream(
        StreamTransformer<dynamic, dynamic>.fromHandlers(handleDone: (sink) {
      closeIframe();
      sink.close();
    }));

    return await _pool.withResource<RunnerSuite>(() async {
      _channel.sink.add({
        'command': 'loadSuite',
        'url': url.toString(),
        'id': suiteID,
        'channel': suiteChannelID
      });

      try {
        controller = deserializeSuite(path, currentPlatform(_runtime),
            suiteConfig, await _environment, suiteChannel, message);

        final String mapPath = p.join(
          env.environment.webUiRootDir.path,
          'build',
          '$path.browser_test.dart.js.map',
        );
        final JSStackTraceMapper mapper = JSStackTraceMapper(
          await File(mapPath).readAsString(),
          mapUrl: p.toUri(mapPath),
          packageResolver: await PackageResolver.current.asSync,
          sdkRoot: p.toUri(sdkDir),
        );

        controller.channel('test.browser.mapper').sink.add(mapper.serialize());

        _controllers.add(controller);
        return await controller.suite;
      } catch (_) {
        closeIframe();
        rethrow;
      }
    });
  }

  /// An implementation of [Environment.displayPause].
  CancelableOperation _displayPause() {
    if (_pauseCompleter != null) {
      return _pauseCompleter.operation;
    }

    _pauseCompleter = CancelableCompleter<void>(onCancel: () {
      _channel.sink.add({'command': 'resume'});
      _pauseCompleter = null;
    });

    _pauseCompleter.operation.value.whenComplete(() {
      _pauseCompleter = null;
    });

    _channel.sink.add({'command': 'displayPause'});

    return _pauseCompleter.operation;
  }

  /// The callback for handling messages received from the host page.
  void _onMessage(Map message) {
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
  Future close() => _closeMemoizer.runOnce(() {
        _closed = true;
        _timer.cancel();
        if (_pauseCompleter != null) {
          _pauseCompleter.complete();
        }
        _pauseCompleter = null;
        _controllers.clear();
        return _browser.close();
      });
  final AsyncMemoizer<dynamic> _closeMemoizer = AsyncMemoizer<dynamic>();
}

/// An implementation of [Environment] for the browser.
///
/// All methods forward directly to [BrowserManager].
class _BrowserEnvironment implements Environment {
  final BrowserManager _manager;

  final supportsDebugging = true;

  final Uri observatoryUrl;

  final Uri remoteDebuggerUrl;

  final Stream onRestart;

  _BrowserEnvironment(this._manager, this.observatoryUrl,
      this.remoteDebuggerUrl, this.onRestart);

  CancelableOperation displayPause() => _manager._displayPause();
}

bool get isCirrus => Platform.environment['CIRRUS_CI'] == 'true';
