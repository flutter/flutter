// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/browser.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

final String bat = Platform.isWindows ? '.bat' : '';
final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', 'flutter$bat');


// Run a web service worker test. The expectations are currently stored here
// instead of in the application. This is not run on CI due to the requirement
// of having a headful chrome instance.
Future<void> main() async {
  await _runWebServiceWorkerTest('lib/service_worker_test.dart');
}

Future<void> _runWebServiceWorkerTest(String target, {
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  final String appBuildDirectory = path.join(testAppDirectory, 'build', 'web');

  // Build the app.
  await Process.run(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await Process.run(
    flutter,
    <String>[
      'build',
      'web',
      '--release',
      ...additionalArguments,
      '-t',
      target,
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
  final List<Uri> requests = <Uri>[];
  final List<Map<String, String>> headers = <Map<String, String>>[];
  await runRecordingServer(
    appUrl: 'http://localhost:8080/',
    appDirectory: appBuildDirectory,
    requests: requests,
    headers: headers,
    browserDebugPort: null,
  );

  final List<String> requestedPaths = requests.map((Uri uri) => uri.toString()).toList();
  final List<String> expectedPaths = <String>[
    // Initial page load
    '',
    'main.dart.js',
    'assets/FontManifest.json',
    'flutter_service_worker.js',
    'manifest.json',
    'favicon.ico',
    // Service worker install.
    'main.dart.js',
    'index.html',
    'assets/LICENSE',
    'assets/AssetManifest.json',
    'assets/FontManifest.json',
    '',
    // Second page load all cached.
  ];
  print('requests: $requestedPaths');
  // The exact order isn't important or deterministic.
  for (final String path in requestedPaths) {
    if (!expectedPaths.remove(path)) {
      print('unexpected service worker request: $path');
      exit(1);
    }
  }
  if (expectedPaths.isNotEmpty) {
    print('Missing service worker requests from expected paths: $expectedPaths');
    exit(1);
  }
}

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
  final Completer<void> completer = Completer<void>();
  Directory userDataDirectory;
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
    userDataDirectory = Directory.systemTemp.createTempSync('chrome_user_data_');
    chrome = await Chrome.launch(ChromeOptions(
      headless: false,
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
    userDataDirectory.deleteSync(recursive: true);
  }
}
