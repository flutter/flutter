// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core' hide print;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

import 'browser.dart';
import 'run_command.dart';
import 'test/common.dart';
import 'utils.dart';

final String _bat = Platform.isWindows ? '.bat' : '';
final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _flutter = path.join(_flutterRoot, 'bin', 'flutter$_bat');
final String _testAppDirectory = path.join(_flutterRoot, 'dev', 'integration_tests', 'web');
final String _appBuildDirectory = path.join(_testAppDirectory, 'build', 'web');
final String _target = path.join('lib', 'service_worker_test.dart');
final Set<String> _requestedPaths = <String>{};

Future<void> main() async {
  await runServiceWorkerCleanupTest(headless: false);

  if (hasError) {
    reportErrorsAndExit('${bold}Cleanup test FAILED.$reset');
  }
  reportSuccessAndExit('${bold}Cleanup test PASSED successfully.$reset');
}

Future<void> runServiceWorkerCleanupTest({required bool headless}) async {
  print('${bold}BEGIN: Service Worker Cleanup Verification Test$reset');

  AppServer? server;

  const oldCachingWorkerContent = '''
'use strict';
const CACHE_NAME = 'flutter-app-cache';
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(['/', 'index.html', 'main.dart.js']);
    }).then(() => self.skipWaiting())
  );
});
self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
  ''';

  final serviceWorkerBuildFile = File(path.join(_appBuildDirectory, 'flutter_service_worker.js'));

  try {
    await runCommand(_flutter, <String>['clean'], workingDirectory: _testAppDirectory);
    await runCommand(
      _flutter,
      <String>['build', 'web', '--no-web-resources-cdn', '--profile', '-t', _target],
      workingDirectory: _testAppDirectory,
      environment: <String, String>{'FLUTTER_WEB': 'true'},
    );
    print('\n${yellow}Phase 1: Installing dummy caching worker and verifying it caches...$reset');
    final String cleanupWorkerContent = serviceWorkerBuildFile.readAsStringSync();
    serviceWorkerBuildFile.writeAsStringSync(oldCachingWorkerContent);

    server = await _startServer(headless: headless);
    await _waitForAppToRequest(server, 'flutter_service_worker.js');
    await _waitForAppToRequest(server, 'main.dart.js');
    _requestedPaths.clear();
    print('== RELOADING PAGE ==');
    await server.chrome.reloadPage();
    await _waitForAppToRequest(server, 'CLOSE');

    expect(
      _requestedPaths,
      isNot(contains('main.dart.js')),
      reason:
          'On a simple reload, main.dart.js should have been served from the cache, so no network request was expected.',
    );
    print('${green}Verification successful: Old caching worker is active.$reset');
    await server.stop();

    print('\n${yellow}Phase 2: Deploying cleanup worker and verifying cache is removed...$reset');
    serviceWorkerBuildFile.writeAsStringSync(cleanupWorkerContent);

    _requestedPaths.clear();
    server = await _startServer(headless: headless);
    await _waitForAppToRequest(server, 'flutter_service_worker.js');
    await _waitForAppToRequest(server, 'main.dart.js');
    _requestedPaths.clear();
    print('== RELOADING PAGE ==');
    await server.chrome.reloadPage();
    await _waitForAppToRequest(server, 'main.dart.js');

    expect(
      _requestedPaths,
      contains('main.dart.js'),
      reason:
          'After cleanup, main.dart.js should be requested from the network because the caching worker is gone.',
    );
    print(
      '${green}Verification successful: Cleanup worker has removed the old caching behavior.$reset',
    );
  } finally {
    await server?.stop();
    print('\n${bold}END: Service Worker Cleanup Verification Test$reset');
  }
}

Future<AppServer> _startServer({required bool headless}) async {
  final int serverPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final int browserDebugPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  return AppServer.start(
    headless: headless,
    appDirectory: _appBuildDirectory,
    serverPort: serverPort,
    browserDebugPort: browserDebugPort,
    appUrl: 'http://localhost:$serverPort/index.html',
    cacheControl: 'max-age=0',
    additionalRequestHandlers: <Handler>[
      (Request request) {
        final String path = request.url.path.split('/').last;
        print('(requested path: $path)');
        _requestedPaths.add(path);
        return Response.notFound('');
      },
    ],
  );
}

Future<void> _waitForAppToRequest(AppServer server, String file) async {
  print('Waiting for app to request "$file"');
  await Future.any(<Future<Object?>>[
    () async {
      var tries = 1;
      while (!_requestedPaths.contains(file)) {
        if (tries++ % 40 == 0) {
          print('-- Still waiting for app to request "$file". Requested so far: $_requestedPaths');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      print('++ App has requested "$file"');
    }(),
    server.onChromeError.then((String error) {
      throw Exception('Chrome error: $error');
    }),
  ]);
}

/// A drop-in replacement for `package:test`'s `expect` that can run
/// outside the standard test runner environment.
void expect(Object? actual, Object? expected, {String? reason}) {
  final Matcher matcher = wrapMatcher(expected);
  final matchState = <Object?, Object?>{};
  if (matcher.matches(actual, matchState)) {
    return;
  }
  final mismatchDescription = StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, true);

  final which = mismatchDescription.toString();
  final buffer = StringBuffer();
  buffer.writeln(_indent(_prettyPrint(expected), first: 'Expected: '));
  buffer.writeln(_indent(_prettyPrint(actual), first: '  Actual: '));
  if (which.isNotEmpty) {
    buffer.writeln(_indent(which, first: '   Which: '));
  }
  if (reason != null) {
    buffer.writeln(_indent(reason, first: '  Reason: '));
  }
  foundError(<String>[buffer.toString(), StackTrace.current.toString()]);
}

/// Returns a pretty-printed representation of [value].
String _prettyPrint(Object? value) => StringDescription().addDescriptionOf(value).toString();

/// Indents each line of a [text] string.
String _indent(String text, {required String first}) {
  final String prefix = ' ' * first.length;
  final List<String> lines = text.split('\n');
  if (lines.length == 1) {
    return '$first$text';
  }
  final buffer = StringBuffer('$first${lines.first}\n');
  for (final String line in lines.skip(1).take(lines.length - 2)) {
    buffer.writeln('$prefix$line');
  }
  buffer.write('$prefix${lines.last}');
  return buffer.toString();
}
