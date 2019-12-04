// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:async/async.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as p; // ignore: package_path_import
import 'package:pool/pool.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/backend.dart'; // ignore: deprecated_member_use
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/util/stack_trace_mapper.dart';
import 'package:test_core/src/runner/configuration.dart';
import 'package:test_core/src/runner/environment.dart';
import 'package:test_core/src/runner/platform.dart';
import 'package:test_core/src/runner/plugin/platform_helpers.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/suite.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../web/chrome.dart';

class FlutterWebPlatform extends PlatformPlugin {
  FlutterWebPlatform._(this._server, this._config, this._root) {
    // Look up the location of the testing resources.
    final Map<String, Uri> packageMap = PackageMap(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      '.packages',
    )).map;
    testUri = packageMap['test'];
    final shelf.Cascade cascade = shelf.Cascade()
        .add(_webSocketHandler.handler)
        .add(packagesDirHandler())
        .add(_jsHandler.handler)
        .add(createStaticHandler(
          fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools'),
          serveFilesOutsidePath: true,
        ))
        .add(createStaticHandler(_config.suiteDefaults.precompiledPath,
            serveFilesOutsidePath: true))
        .add(_handleStaticArtifact)
        .add(_wrapperHandler);
    _server.mount(cascade.handler);
  }

  static Future<FlutterWebPlatform> start(String root) async {
    final shelf_io.IOServer server =
        shelf_io.IOServer(await HttpMultiServer.loopback(0));
    return FlutterWebPlatform._(
      server,
      Configuration.current,
      root,
    );
  }

  Uri testUri;

  /// The test runner configuration.
  final Configuration _config;

  /// The underlying server.
  final shelf.Server _server;

  /// The URL for this server.
  Uri get url => _server.url;

  /// The ahem text file.
  File get ahem => fs.file(fs.path.join(
        Cache.flutterRoot,
        'packages',
        'flutter_tools',
        'static',
        'Ahem.ttf',
      ));

  /// The require js binary.
  File get requireJs => fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'amd',
        'require.js',
      ));

  /// The ddc to dart stack trace mapper.
  File get stackTraceMapper => fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js',
      ));

  /// The precompiled dart sdk.
  File get dartSdk => fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));

  /// The precompiled test javascript.
  File get testDartJs => fs.file(fs.path.join(
        testUri.toFilePath(),
        'dart.js',
      ));

  File get testHostDartJs => fs.file(fs.path.join(
        testUri.toFilePath(),
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
        testDartJs.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path.contains('host.dart.js')) {
      return shelf.Response.ok(
        testHostDartJs.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else {
      return shelf.Response.notFound('Not Found');
    }
  }

  final OneOffHandler _webSocketHandler = OneOffHandler();
  final PathHandler _jsHandler = PathHandler();
  final AsyncMemoizer<void> _closeMemo = AsyncMemoizer<void>();
  final String _root;

  bool get _closed => _closeMemo.hasRun;

  // A map from browser identifiers to futures that will complete to the
  // [BrowserManager]s for those browsers, or `null` if they failed to load.
  final Map<Runtime, Future<BrowserManager>> _browserManagers =
      <Runtime, Future<BrowserManager>>{};

  // Mappers for Dartifying stack traces, indexed by test path.
  final Map<String, StackTraceMapper> _mappers = <String, StackTraceMapper>{};

  // A handler that serves wrapper files used to bootstrap tests.
  shelf.Response _wrapperHandler(shelf.Request request) {
    final String path = fs.path.fromUri(request.url);
    if (path.endsWith('.html')) {
      final String test = fs.path.withoutExtension(path) + '.dart';
      final String scriptBase = htmlEscape.convert(fs.path.basename(test));
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
    printTrace('Did not find anything for request: ${request.url}');
    return shelf.Response.notFound('Not found.');
  }

  @override
  Future<RunnerSuite> load(
    String path,
    SuitePlatform platform,
    SuiteConfiguration suiteConfig,
    Object message,
  ) async {
    if (_closed) {
      return null;
    }
    final Runtime browser = platform.runtime;
    final BrowserManager browserManager = await _browserManagerFor(browser);
    if (_closed || browserManager == null) {
      return null;
    }

    final Uri suiteUrl = url.resolveUri(fs.path.toUri(fs.path.withoutExtension(
            fs.path.relative(path, from: fs.path.join(_root, 'test'))) +
        '.html'));
    final RunnerSuite suite = await browserManager
        .load(path, suiteUrl, suiteConfig, message, mapper: _mappers[path]);
    if (_closed) {
      return null;
    }
    return suite;
  }

  @override
  StreamChannel<dynamic> loadChannel(String path, SuitePlatform platform) =>
      throw UnimplementedError();

  /// Returns the [BrowserManager] for [runtime], which should be a browser.
  ///
  /// If no browser manager is running yet, starts one.
  Future<BrowserManager> _browserManagerFor(Runtime browser) {
    final Future<BrowserManager> managerFuture = _browserManagers[browser];
    if (managerFuture != null) {
      return managerFuture;
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

    printTrace('Serving tests at $hostUrl');

    final Future<BrowserManager> future = BrowserManager.start(
      browser,
      hostUrl,
      completer.future,
    );

    // Store null values for browsers that error out so we know not to load them
    // again.
    _browserManagers[browser] = future.catchError((dynamic _) => null);

    return future;
  }

  @override
  Future<void> closeEphemeral() {
    final List<Future<BrowserManager>> managers =
        _browserManagers.values.toList();
    _browserManagers.clear();
    return Future.wait(managers.map((Future<BrowserManager> manager) async {
      final BrowserManager result = await manager;
      if (result == null) {
        return;
      }
      await result.close();
    }));
  }

  @override
  Future<void> close() => _closeMemo.runOnce(() async {
    final List<Future<dynamic>> futures = _browserManagers.values
      .map<Future<dynamic>>((Future<BrowserManager> future) async {
        final BrowserManager result = await future;
        if (result == null) {
          return;
        }
        await result.close();
      })
      .toList();
    futures.add(_server.close());
    await Future.wait<void>(futures);
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
    for (String component in p.url.split(path)) {
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
      for (RunnerSuiteController controller in _controllers) {
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
          for (RunnerSuiteController controller in _controllers) {
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
  final Chrome _browser;

  // TODO(nweiz): Consider removing the duplication between this and
  // [_browser.name].
  /// The [Runtime] for [_browser].
  final Runtime _runtime;

  /// The channel used to communicate with the browser.
  ///
  /// This is connected to a page running `static/host.dart`.
  MultiChannel<dynamic> _channel;

  /// A pool that ensures that limits the number of initial connections the
  /// manager will wait for at once.
  ///
  /// This isn't the *total* number of connections; any number of iframes may be
  /// loaded in the same browser. However, the browser can only load so many at
  /// once, and we want a timeout in case they fail so we only wait for so many
  /// at once.
  // The number 1 is chosen to disallow multiple iframes in the same browser. This
  // is because in some environments, such as Cirrus CI, tests end up stuck and
  // time out eventually. The exact reason for timeouts is unknown, but the
  // hypothesis is that we were the first ones to attempt to run DDK-compiled
  // tests concurrently in the browser. DDK is known to produce an order of
  // magnitude bigger and somewhat slower code, which may overload the browser.
  final Pool _pool = Pool(1);

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
  /// The [settings] indicate how to invoke this browser's executable.
  ///
  /// Returns the browser manager, or throws an [ApplicationException] if a
  /// connection fails to be established.
  static Future<BrowserManager> start(
    Runtime runtime,
    Uri url,
    Future<WebSocketChannel> future, {
    bool debug = false,
  }) async {
    final Chrome chrome =
        await chromeLauncher.launch(url.toString(), headless: true);

    final Completer<BrowserManager> completer = Completer<BrowserManager>();

    unawaited(chrome.onExit.then((void _) {
      throwToolExit('${runtime.name} exited before connecting.');
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
        this, null, _browser.remoteDebuggerUri, _onRestartController.stream);
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
    StackTraceMapper mapper,
  }) async {
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
      }),
    );

    return await _pool.withResource<RunnerSuite>(() async {
      _channel.sink.add(<String, Object>{
        'command': 'loadSuite',
        'url': url.toString(),
        'id': suiteID,
        'channel': suiteChannelID,
      });

      try {
        controller = deserializeSuite(path, SuitePlatform(Runtime.chrome),
            suiteConfig, await _environment, suiteChannel, message);
        controller.channel('test.browser.mapper').sink.add(mapper?.serialize());

        _controllers.add(controller);
        return await controller.suite;
      } catch (_) {
        closeIframe();
        rethrow;
      }
    });
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
