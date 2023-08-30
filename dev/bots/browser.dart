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

typedef ServerRequestListener = void Function(Request);

// A class representing an application server.
class AppServer {
  // Private constructor to initialize the server and related components.
  AppServer._(this._server, this.chrome, this.onChromeError);

  // Start the application server with specified configurations.
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

    // Bind the HTTP server to a specific port on localhost.
    server = await io.HttpServer.bind('localhost', serverPort);

    // Create a static request handler for serving files from the app directory.
    final Handler staticHandler = createStaticHandler(appDirectory, defaultDocument: 'index.html');

    // Create a Cascade for handling requests in a chain of handlers.
    Cascade cascade = Cascade();

    // Add additional request handlers if provided.
    if (additionalRequestHandlers != null) {
      for (final Handler handler in additionalRequestHandlers) {
        cascade = cascade.add(handler);
      }
    }

    // Add a final handler that applies cache control and serves static files.
    cascade = cascade.add((Request request) async {
      final Response response = await staticHandler(request);
      return response.change(headers: <String, Object>{
        'cache-control': cacheControl,
      });
    });

    // Serve requests using the cascade handler.
    shelf_io.serveRequests(server, cascade.handler);

    // Create a temporary user data directory for the Chrome instance.
    final io.Directory userDataDirectory = io.Directory.systemTemp.createTempSync('flutter_chrome_user_data.');

    // Create a completer to capture Chrome error.
    final Completer<String> chromeErrorCompleter = Completer<String>();

    // Launch Chrome browser with specified options.
    chrome = await Chrome.launch(ChromeOptions(
      headless: headless,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
    ), onError: chromeErrorCompleter.complete);

    // Return an instance of AppServer with initialized components.
    return AppServer._(server, chrome, chromeErrorCompleter.future);
  }

  // Future that completes with an error message if Chrome encounters an error.
  final Future<String> onChromeError;

  // HTTP server instance.
  final io.HttpServer _server;

  // Chrome browser instance.
  final Chrome chrome;

  // Stop the server and associated components.
  Future<void> stop() async {
    chrome.stop();  // Stop the Chrome instance.
    await _server.close();  // Close the HTTP server.
  }
}

