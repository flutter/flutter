// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:async/async.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as p; // ignore: package_path_import
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/src/runner/browser/browser_manager.dart';
import 'package:test/src/runner/browser/default_settings.dart';
import 'package:test/src/runner/executable_settings.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/util/stack_trace_mapper.dart';
import 'package:test_core/src/runner/configuration.dart';
import 'package:test_core/src/runner/platform.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/suite.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart';

// TODO(jonahwilliams): remove shelf and test dependencies.
class FlutterWebPlatform extends PlatformPlugin {
  FlutterWebPlatform._(this._server, this._config, this._root) {
    // Look up the location of the testing resources.
    final Map<String, Uri> packageMap = PackageMap(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
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
        'lib',
        'dart.js',
      ));

  Future<shelf.Response> _handleStaticArtifact(shelf.Request request) async {
    if (request.requestedUri.path.contains('require.js')) {
      return shelf.Response.ok(
        requireJs.openRead(),
        headers: <String, String>{'Content-Type': 'text/javascript'},
      );
    } else if (request.requestedUri.path.contains('Ahem.ttf')) {
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
    } else {
      return shelf.Response.notFound('Not Found');
    }
  }

  final OneOffHandler _webSocketHandler = OneOffHandler();
  final PathHandler _jsHandler = PathHandler();
  final AsyncMemoizer<void> _closeMemo = AsyncMemoizer<void>();
  final String _root;
  final Map<Runtime, ExecutableSettings> _browserSettings =
      Map<Runtime, ExecutableSettings>.from(defaultSettings);

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
  Future<RunnerSuite> load(String path, SuitePlatform platform,
      SuiteConfiguration suiteConfig, Object message) async {
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
      'debug': _config.pauseAfterLoad.toString()
    });

    printTrace('Serving tests at $hostUrl');

    final Future<BrowserManager> future = BrowserManager.start(
      browser,
      hostUrl,
      completer.future,
      _browserSettings[browser],
      debug: _config.pauseAfterLoad,
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
        }).toList();
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
