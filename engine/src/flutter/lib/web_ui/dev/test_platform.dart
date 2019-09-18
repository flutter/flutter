// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:image/image.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:pool/pool.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:typed_data/typed_buffers.dart';
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

import 'chrome_installer.dart';
import 'environment.dart' as env;
import 'goldens.dart';

/// The port number Chrome exposes for debugging.
const int _kChromeDevtoolsPort = 12345;
const int _kMaxScreenshotWidth = 1024;
const int _kMaxScreenshotHeight = 1024;
const double _kMaxDiffRateFailure = 1.0/100000; // 0.001%

class BrowserPlatform extends PlatformPlugin {
  /// Starts the server.
  ///
  /// [root] is the root directory that the server should serve. It defaults to
  /// the working directory.
  static Future<BrowserPlatform> start({String root}) async {
    var server = shelf_io.IOServer(await HttpMultiServer.loopback(0));
    return BrowserPlatform._(
        server,
        Configuration.current,
        p.fromUri(await Isolate.resolvePackageUri(
            Uri.parse('package:test/src/runner/browser/static/favicon.ico'))),
        root: root);
  }

  /// The test runner configuration.
  final Configuration _config;

  /// The underlying server.
  final shelf.Server _server;

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

  BrowserPlatform._(this._server, Configuration config, String faviconPath,
      {String root})
      : _config = config,
        _root = root == null ? p.current : root,
        _http = config.pubServeUrl == null ? null : HttpClient() {
    var cascade = shelf.Cascade().add(_webSocketHandler.handler);

    if (_config.pubServeUrl == null) {
      // We server static files from here (JS, HTML, etc)
      final String staticFilePath =
          config.suiteDefaults.precompiledPath ?? _root;
      cascade = cascade
          .add(_screeshotHandler)
          .add(packagesDirHandler())
          .add(_jsHandler.handler)
          .add(createStaticHandler(staticFilePath,
              // Precompiled directories often contain symlinks
              serveFilesOutsidePath:
                  config.suiteDefaults.precompiledPath != null))
          .add(_wrapperHandler);
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
    if (!request.requestedUri.path.endsWith('/screenshot')) {
      return shelf.Response.notFound(
          'This request is not handled by the screenshot handler');
    }

    final String payload = await request.readAsString();
    final Map<String, dynamic> requestData = json.decode(payload);
    final String filename = requestData['filename'];
    final bool write = requestData['write'];
    final Map<String, dynamic> region = requestData['region'];
    final String result = await _diffScreenshot(filename, write, region);
    return shelf.Response.ok(json.encode(result));
  }

  Future<String> _diffScreenshot(String filename, bool write, [ Map<String, dynamic> region ]) async {
    const String _kGoldensDirectory = 'test/golden_files';

    // Bail out fast if golden doesn't exist, and user doesn't want to create it.
    final File file = File(p.join(_kGoldensDirectory, filename));
    if (!file.existsSync() && !write) {
      return '''
Golden file $filename does not exist.

To automatically create this file call matchGoldenFile('$filename', write: true).
''';
    }

    final wip.ChromeConnection chromeConnection =
        wip.ChromeConnection('localhost', _kChromeDevtoolsPort);
    final wip.ChromeTab chromeTab = await chromeConnection.getTab(
        (wip.ChromeTab chromeTab) => chromeTab.url.contains('localhost'));
    final wip.WipConnection wipConnection = await chromeTab.connect();

    Map<String, dynamic> captureScreenshotParameters = null;
    if (region != null) {
      captureScreenshotParameters = {
        'format': 'png',
        'clip': {
          'x': region['x'],
          'y': region['y'],
          'width': region['width'],
          'height': region['height'],
          'scale': 1, // This is NOT the DPI of the page, instead it's the "zoom level".
        },
      };
    }
    // To tweak DPI we need to send an additional Emulation.setDeviceMetricsOverride. See:
    // https://chromedevtools.github.io/devtools-protocol/tot/Emulation
    final wip.WipResponse response =
        await wipConnection.sendCommand('Page.captureScreenshot', captureScreenshotParameters);

    // Compare screenshots
    final Image screenshot = decodePng(base64.decode(response.result['data']));

    if (write) {
      // Don't even bother with the comparison, just write and return
      file.writeAsBytesSync(encodePng(screenshot), flush: true);
      return 'Golden file $filename was updated. You can remove "write: true" in the call to matchGoldenFile.';
    }

    ImageDiff diff = ImageDiff(golden: decodeNamedImage(file.readAsBytesSync(), filename), other: screenshot);

    if (diff.rate > 0) { // Images are different, so produce some debug info
      final File failedFile = File(p.join(file.parent.path, '${p.basenameWithoutExtension(file.path)}.out.png'));
      failedFile.writeAsBytesSync(encodePng(screenshot), flush: true);

      final File failedDiff = File(p.join(file.parent.path, '${p.basenameWithoutExtension(file.path)}.diff.png'));
      failedDiff.writeAsBytesSync(encodePng(diff.diff), flush:true);

      final String printableDiffFilesInfo = getPrintableDiffFilesInfo(diff.rate, _kMaxDiffRateFailure, filename, failedFile.path, failedDiff.path);

      if (diff.rate < _kMaxDiffRateFailure) { // Warn user
        print('[WARN] Golden file ${file.path} is slightly different from the image generated by this test!\n${printableDiffFilesInfo}');
        return 'OK'; // But test success!
      } else {
        // TODO(yjbanov): do not fail Cirrus builds. They currently fail because Chrome produces
        //                different pictures. We need to pin Chrome versions and use a fuzzy image
        //                comparator.
        if (Platform.environment['CIRRUS_CI'] == 'true') {
          return 'OK';
        }
        // Fail test
        return 'Golden file ${file.path} is too different from the image generated by the test!\n${printableDiffFilesInfo}';
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

    if (_closed) return null;
    Uri suiteUrl = url.resolveUri(
        p.toUri(p.withoutExtension(p.relative(path, from: _root)) + '.html'));

    if (_closed) return null;

    var browserManager = await _browserManagerFor(browser);
    if (_closed || browserManager == null) return null;

    var suite = await browserManager.load(path, suiteUrl, suiteConfig, message);
    if (_closed) return null;
    return suite;
  }

  StreamChannel loadChannel(String path, SuitePlatform platform) =>
      throw UnimplementedError();

  Future<BrowserManager> _browserManager;

  /// Returns the [BrowserManager] for [runtime], which should be a browser.
  ///
  /// If no browser manager is running yet, starts one.
  Future<BrowserManager> _browserManagerFor(Runtime browser) {
    if (_browserManager != null) return _browserManager;

    var completer = Completer<WebSocketChannel>.sync();
    var path = _webSocketHandler.create(webSocketHandler(completer.complete));
    var webSocketUrl = url.replace(scheme: 'ws').resolve(path);
    var hostUrl = (_config.pubServeUrl == null ? url : _config.pubServeUrl)
        .resolve('packages/web_engine_tester/static/index.html')
        .replace(queryParameters: {
      'managerUrl': webSocketUrl.toString(),
      'debug': _config.pauseAfterLoad.toString()
    });

    var future = BrowserManager.start(browser, hostUrl, completer.future,
        debug: _config.pauseAfterLoad);

    // Store null values for browsers that error out so we know not to load them
    // again.
    _browserManager = future.catchError((_) => null);

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

  final _closeMemo = AsyncMemoizer();
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
    if (components.isEmpty) return shelf.Response.notFound(null);

    var path = components.removeAt(0);
    var handler = _handlers.remove(path);
    if (handler == null) return shelf.Response.notFound(null);
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
      if (node == null) break;
      if (node.handler == null) continue;
      handler = node.handler;
      handlerIndex = i;
    }

    if (handler == null) return shelf.Response.notFound('Not found.');

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
  final _onRestartController = StreamController.broadcast();

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
    }).catchError((error, StackTrace stackTrace) {
      if (completer.isCompleted) return;
      completer.completeError(error, stackTrace);
    });

    future.then((webSocket) {
      if (completer.isCompleted) return;
      completer.complete(BrowserManager._(browser, runtime, webSocket));
    }).catchError((error, StackTrace stackTrace) {
      browser.close();
      if (completer.isCompleted) return;
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
    return Chrome(url, debug: debug);
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
    _channel = MultiChannel(
        webSocket.cast<String>().transform(jsonDocument).changeStream((stream) {
      return stream.map((message) {
        if (!_closed) _timer.reset();
        for (var controller in _controllers) {
          controller.setDebugging(false);
        }

        return message;
      });
    }));

    _environment = _loadBrowserEnvironment();
    _channel.stream
        .listen((message) => _onMessage(message as Map), onDone: close);
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
        fragment: Uri.encodeFull(jsonEncode({
      'metadata': suiteConfig.metadata.serialize(),
      'browser': _runtime.identifier
    })));

    var suiteID = _suiteID++;
    RunnerSuiteController controller;
    closeIframe() {
      if (_closed) return;
      _controllers.remove(controller);
      _channel.sink.add({'command': 'closeSuite', 'id': suiteID});
    }

    // The virtual channel will be closed when the suite is closed, in which
    // case we should unload the iframe.
    var virtualChannel = _channel.virtualChannel();
    var suiteChannelID = virtualChannel.id;
    var suiteChannel = virtualChannel
        .transformStream(StreamTransformer.fromHandlers(handleDone: (sink) {
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
          '$path.js.map',
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
    if (_pauseCompleter != null) return _pauseCompleter.operation;

    _pauseCompleter = CancelableCompleter(onCancel: () {
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
        if (_pauseCompleter != null) _pauseCompleter.complete();
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
        if (_pauseCompleter != null) _pauseCompleter.complete();
        _pauseCompleter = null;
        _controllers.clear();
        return _browser.close();
      });
  final _closeMemoizer = AsyncMemoizer();
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

/// An interface for running browser instances.
///
/// This is intentionally coarse-grained: browsers are controlled primary from
/// inside a single tab. Thus this interface only provides support for closing
/// the browser and seeing if it closes itself.
///
/// Any errors starting or running the browser process are reported through
/// [onExit].
abstract class Browser {
  String get name;

  /// The Observatory URL for this browser.
  ///
  /// This will return `null` for browsers that aren't running the Dart VM, or
  /// if the Observatory URL can't be found.
  Future<Uri> get observatoryUrl => null;

  /// The remote debugger URL for this browser.
  ///
  /// This will return `null` for browsers that don't support remote debugging,
  /// or if the remote debugging URL can't be found.
  Future<Uri> get remoteDebuggerUrl => null;

  /// The underlying process.
  ///
  /// This will fire once the process has started successfully.
  Future<Process> get _process => _processCompleter.future;
  final _processCompleter = Completer<Process>();

  /// Whether [close] has been called.
  var _closed = false;

  /// A future that completes when the browser exits.
  ///
  /// If there's a problem starting or running the browser, this will complete
  /// with an error.
  Future get onExit => _onExitCompleter.future;
  final _onExitCompleter = Completer();

  /// Standard IO streams for the underlying browser process.
  final _ioSubscriptions = <StreamSubscription>[];

  /// Creates a new browser.
  ///
  /// This is intended to be called by subclasses. They pass in [startBrowser],
  /// which asynchronously returns the browser process. Any errors in
  /// [startBrowser] (even those raised asynchronously after it returns) are
  /// piped to [onExit] and will cause the browser to be killed.
  Browser(Future<Process> startBrowser()) {
    // Don't return a Future here because there's no need for the caller to wait
    // for the process to actually start. They should just wait for the HTTP
    // request instead.
    runZoned(() async {
      var process = await startBrowser();
      _processCompleter.complete(process);

      var output = Uint8Buffer();
      drainOutput(Stream<List<int>> stream) {
        try {
          _ioSubscriptions
              .add(stream.listen(output.addAll, cancelOnError: true));
        } on StateError catch (_) {}
      }

      // If we don't drain the stdout and stderr the process can hang.
      drainOutput(process.stdout);
      drainOutput(process.stderr);

      var exitCode = await process.exitCode;

      // This hack dodges an otherwise intractable race condition. When the user
      // presses Control-C, the signal is sent to the browser and the test
      // runner at the same time. It's possible for the browser to exit before
      // the [Browser.close] is called, which would trigger the error below.
      //
      // A negative exit code signals that the process exited due to a signal.
      // However, it's possible that this signal didn't come from the user's
      // Control-C, in which case we do want to throw the error. The only way to
      // resolve the ambiguity is to wait a brief amount of time and see if this
      // browser is actually closed.
      if (!_closed && exitCode < 0) {
        await Future.delayed(Duration(milliseconds: 200));
      }

      if (!_closed && exitCode != 0) {
        var outputString = utf8.decode(output);
        var message = '$name failed with exit code $exitCode.';
        if (outputString.isNotEmpty) {
          message += '\nStandard output:\n$outputString';
        }

        throw Exception(message);
      }

      _onExitCompleter.complete();
    }, onError: (error, StackTrace stackTrace) {
      // Ignore any errors after the browser has been closed.
      if (_closed) return;

      // Make sure the process dies even if the error wasn't fatal.
      _process.then((process) => process.kill());

      if (stackTrace == null) stackTrace = Trace.current();
      if (_onExitCompleter.isCompleted) return;
      _onExitCompleter.completeError(
          Exception('Failed to run $name: ${getErrorMessage(error)}.'),
          stackTrace);
    });
  }

  /// Kills the browser process.
  ///
  /// Returns the same [Future] as [onExit], except that it won't emit
  /// exceptions.
  Future close() async {
    _closed = true;

    // If we don't manually close the stream the test runner can hang.
    // For example this happens with Chrome Headless.
    // See SDK issue: https://github.com/dart-lang/sdk/issues/31264
    for (var stream in _ioSubscriptions) {
      unawaited(stream.cancel());
    }

    (await _process).kill();

    // Swallow exceptions. The user should explicitly use [onExit] for these.
    return onExit.catchError((_) {});
  }
}

/// A class for running an instance of Chrome.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Chrome extends Browser {
  @override
  final name = 'Chrome';

  @override
  final Future<Uri> remoteDebuggerUrl;

  static String version;

  /// Starts a new instance of Chrome open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Chrome(Uri url, {bool debug = false}) {
    assert(version != null);
    var remoteDebuggerCompleter = Completer<Uri>.sync();
    return Chrome._(() async {
      final ChromeInstallation installation = await getOrInstallChrome(version, infoLog: _DevNull());

      final bool isChromeNoSandbox = Platform.environment['CHROME_NO_SANDBOX'] == 'true';
      var dir = createTempDir();
      var args = [
        '--user-data-dir=$dir',
        url.toString(),
        if (!debug) '--headless',
        if (isChromeNoSandbox) '--no-sandbox',
        '--window-size=$_kMaxScreenshotWidth,$_kMaxScreenshotHeight', // When headless, this is the actual size of the viewport
        '--disable-extensions',
        '--disable-popup-blocking',
        '--bwsi',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-default-apps',
        '--disable-translate',
        '--remote-debugging-port=$_kChromeDevtoolsPort',
      ];

      final Process process = await Process.start(installation.executable, args);

      remoteDebuggerCompleter.complete(getRemoteDebuggerUrl(
          Uri.parse('http://localhost:$_kChromeDevtoolsPort')));

      unawaited(process.exitCode
          .then((_) => Directory(dir).deleteSync(recursive: true)));

      return process;
    }, remoteDebuggerCompleter.future);
  }

  Chrome._(Future<Process> startBrowser(), this.remoteDebuggerUrl)
      : super(startBrowser);
}

/// A string sink that swallows all input.
class _DevNull implements StringSink {
  @override
  void write(Object obj) {
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
  }

  @override
  void writeCharCode(int charCode) {
  }

  @override
  void writeln([Object obj = ""]) {
  }
}
