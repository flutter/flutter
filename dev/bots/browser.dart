// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_devicelab/framework/browser.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// Runs Chrome, opens the given `appUrl`, and returns the result reported by the
/// app.
///
/// The app is served from the `appDirectory`. Typically, the app is built
/// using `flutter build web` and served from `build/web`.
///
/// The launched app is expected to report the result by sending an HTTP POST
/// request to "/test-result" containing result data as plain text body of the
/// request. This function has no opinion about what that string contains.
Future<String> evalTestAppInChrome({
  required String appUrl,
  required String appDirectory,
  int serverPort = 8080,
  int browserDebugPort = 8081,
}) async {
  io.HttpServer? server;
  Chrome? chrome;
  try {
    final Completer<String> resultCompleter = Completer<String>();
    server = await io.HttpServer.bind('localhost', serverPort);
    final Cascade cascade = Cascade()
      .add((Request request) async {
        if (request.requestedUri.path.endsWith('/test-result')) {
          resultCompleter.complete(await request.readAsString());
          return Response.ok('Test results received');
        }
        return Response.notFound('');
      })
      .add(createStaticHandler(appDirectory));
    shelf_io.serveRequests(server, cascade.handler);
    final io.Directory userDataDirectory = io.Directory.systemTemp.createTempSync('flutter_chrome_user_data.');
    chrome = await Chrome.launch(ChromeOptions(
      headless: true,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
      windowHeight: 500,
      windowWidth: 500,
    ), onError: resultCompleter.completeError);
    return await resultCompleter.future;
  } finally {
    chrome?.stop();
    await server?.close();
  }
}

/// Runs Firefox with the given options.
class Firefox {
  Firefox._(this._process);

  final io.Process _process;

  static Future<Firefox> launch(FirefoxOptions options, {void Function(String)? onError}) async {
    final List<String> args = <String>[
      '-headless',
      '--marionette',
      '--remote-debugging-port=${options.debugPort}',
      '--profile=${options.userDataDirectory}',
      '--window-size=${options.windowWidth},${options.windowHeight}',
      options.url,
    ];

    final io.Process process = await io.Process.start('firefox', args);

    // Listen for errors
    process.stderr.transform(const Utf8Decoder()).listen((String error) {
      if (onError != null) {
        onError(error);
      }
    });

    return Firefox._(process);
  }

  void stop() {
    _process.kill();
  }
}

class FirefoxOptions {
  const FirefoxOptions({
    required this.url,
    required this.userDataDirectory,
    this.debugPort = 9222,
    this.headless = true,
    this.windowWidth = 1024,
    this.windowHeight = 768,
  });

  final String url;
  final String userDataDirectory;
  final int debugPort;
  final bool headless;
  final int windowWidth;
  final int windowHeight;
}

Future<String> evalTestAppInFirefox({
  required String appUrl,
  required String appDirectory,
  int serverPort = 8080,
  int browserDebugPort = 8081,
}) async {
  io.HttpServer? server;
  Firefox? firefox;
  try {
    final Completer<String> resultCompleter = Completer<String>();
    server = await io.HttpServer.bind('localhost', serverPort);
    final Cascade cascade = Cascade()
      .add((Request request) async {
        if (request.requestedUri.path.endsWith('/test-result')) {
          resultCompleter.complete(await request.readAsString());
          return Response.ok('Test results received');
        }
        return Response.notFound('');
      })
      .add(createStaticHandler(appDirectory));
    shelf_io.serveRequests(server, cascade.handler);
    final io.Directory userDataDirectory = io.Directory.systemTemp.createTempSync('flutter_firefox_user_data.');
    firefox = await Firefox.launch(FirefoxOptions(
      headless: true,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
      windowHeight: 500,
      windowWidth: 500,
    ), onError: resultCompleter.completeError);
    return await resultCompleter.future;
  } finally {
    firefox?.stop();
    await server?.close();
  }
}

typedef ServerRequestListener = void Function(Request);

class AppServer {
  AppServer._(this._server, this.browser, this.onBrowserError);

  static Future<AppServer> start({
    required String appUrl,
    required String appDirectory,
    required String cacheControl,
    int serverPort = 8080,
    int browserDebugPort = 8081,
    bool headless = true,
    List<Handler>? additionalRequestHandlers,
  }) async {
    io.HttpServer server;
    Chrome chrome;
    server = await io.HttpServer.bind('localhost', serverPort);
    final Handler staticHandler = createStaticHandler(appDirectory, defaultDocument: 'index.html');
    Cascade cascade = Cascade();
    if (additionalRequestHandlers != null) {
      for (final Handler handler in additionalRequestHandlers) {
        cascade = cascade.add(handler);
      }
    }
    cascade = cascade.add((Request request) async {
      final Response response = await staticHandler(request);
      return response.change(headers: <String, Object>{
        'cache-control': cacheControl,
      });
    });
    shelf_io.serveRequests(server, cascade.handler);
    final io.Directory userDataDirectory = io.Directory.systemTemp.createTempSync('flutter_chrome_user_data.');
    final Completer<String> chromeErrorCompleter = Completer<String>();
    chrome = await Chrome.launch(ChromeOptions(
      headless: headless,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
    ), onError: chromeErrorCompleter.complete);
    return AppServer._(server, chrome, chromeErrorCompleter.future);
  }

  static Future<AppServer> startFirefox({
    required String appUrl,
    required String appDirectory,
    required String cacheControl,
    int serverPort = 8080,
    int browserDebugPort = 8081,
    bool headless = true,
    List<Handler>? additionalRequestHandlers,
  }) async {
    final io.HttpServer server = await io.HttpServer.bind('localhost', serverPort);
    final Handler staticHandler = createStaticHandler(appDirectory, defaultDocument: 'index.html');
    Cascade cascade = Cascade();
    if (additionalRequestHandlers != null) {
      for (final Handler handler in additionalRequestHandlers) {
        cascade = cascade.add(handler);
      }
    }
    cascade = cascade.add((Request request) async {
      final Response response = await staticHandler(request);
      return response.change(headers: <String, Object>{
        'cache-control': cacheControl,
      });
    });
    shelf_io.serveRequests(server, cascade.handler);
    final io.Directory userDataDirectory = io.Directory.systemTemp.createTempSync('flutter_firefox_user_data.');
    final Completer<String> browserErrorCompleter = Completer<String>();
    final Firefox firefox = await Firefox.launch(FirefoxOptions(
      headless: headless,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
    ), onError: browserErrorCompleter.complete);
    return AppServer._(server, firefox, browserErrorCompleter.future);
  }

  final Future<String> onBrowserError;
  final io.HttpServer _server;
  final dynamic browser;

  Future<void> stop() async {
    if (browser is Chrome) {
      (browser as Chrome).stop();
    } else if (browser is Firefox) {
      (browser as Firefox).stop();
    }
    await _server.close();
  }
}
