// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/browser.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// This server runs a release web application and verifies that the service worker
/// caches files correctly, by checking the request resources over HTTP.
///
/// When it receives a request for `CLOSE` the server will be torn down.
///
/// Expects a path to the `build/web` directory produced from `flutter build web`.
Future<void> runRecordingServer({
  @required String appUrl,
  @required String appDirectory,
  @required List<Uri> requests,
  @required List<Map<String, String>> headers,
  int serverPort = 8080,
  int browserDebugPort = 8081,
}) async {
  Chrome chrome;
  HttpServer server;
  Completer<void> completer = Completer<void>();
  try {
    server = await HttpServer.bind('localhost', serverPort);
    final Cascade cascade = Cascade()
      .add((Request request) async {
        if (request.url.toString().contains('CLOSE')) {
          completer.complete();
          return Response.notFound('');
        }
        requests.add(request.url);
        headers.add(request.headers);
        return Response.notFound('');
      })
      .add(createStaticHandler(appDirectory, defaultDocument: 'index.html'));
    shelf_io.serveRequests(server, cascade.handler);
    final Directory userDataDirectory = Directory.systemTemp.createTempSync('chrome_user_data_');
    chrome = await Chrome.launch(ChromeOptions(
      headless: true,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
      windowHeight: 500,
      windowWidth: 500,
    ), onError: completer.completeError);
    await completer.future;

    chrome.stop();
    completer = Completer<void>();
    chrome = await Chrome.launch(ChromeOptions(
      headless: true,
      debugPort: browserDebugPort,
      url: appUrl,
      userDataDirectory: userDataDirectory.path,
      windowHeight: 500,
      windowWidth: 500,
    ), onError: completer.completeError);
    await completer.future;
  } finally {
    chrome?.stop();
    await server?.close();
  }
}
