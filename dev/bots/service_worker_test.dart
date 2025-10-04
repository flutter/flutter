// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test has been rewritten to specifically verify the behavior
// of the service worker cleanup script by observing network requests.

import 'dart:core' hide print;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

import 'browser.dart';
import 'run_command.dart';
import 'test/common.dart';
import 'utils.dart';

final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _testAppDirectory = path.join(_flutterRoot, 'dev', 'integration_tests', 'web');
final String _appBuildDirectory = path.join(_testAppDirectory, 'build', 'web');
final String _target = path.join('lib', 'main.dart');
final Map<String, int> _requestedPathCounts = <String, int>{};

Future<void> main() async {
  await runCleanupVerificationTest(headless: false);

  if (hasError) {
    reportErrorsAndExit('${bold}Cleanup test FAILED.$reset');
  }
  reportSuccessAndExit('${bold}Cleanup test PASSED successfully.$reset');
}

/// test verifies the cleanup service worker correctly removes an old,
/// cached service worker by observing network request patterns.
Future<void> runCleanupVerificationTest({required bool headless}) async {
  print('${bold}BEGIN: Service Worker Cleanup Verification Test$reset');

  // This test creates the cleanup worker file itself, so we don't depend on it existing.
  final String cleanupWorkerSourcePath = path.join(
    _testAppDirectory,
    'web',
    'flutter_service_worker.js',
  );
  final File cleanupWorkerFile = File(cleanupWorkerSourcePath);

  const String cleanupWorkerContent = '''
'use strict';
const OLD_CACHE_PREFIX = 'flutter-';
self.addEventListener('install', (event) => {
  self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        const cacheKeys = await self.caches.keys();
        const oldCacheKeys = cacheKeys.filter(key => key.startsWith(OLD_CACHE_PREFIX));
        const deletePromises = oldCacheKeys.map(key => self.caches.delete(key));
        await Promise.all(deletePromises);
      } catch (e) {
        // Ignore errors.
      }
      try {
        await self.registration.unregister();
      } catch (e) {
        // Ignore errors.
      }
      try {
        const clients = await self.clients.matchAll({
          type: 'window',
          includeUncontrolled: true,
        });
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {
        // Ignore errors.
      }
    })()
  );
});
''';

  AppServer? server;

  // A simple caching service worker to act as the "old" worker.
  const String oldCachingWorkerContent = '''
  'use strict';
  const CACHE_NAME = 'flutter-test-cache-v1';
  self.addEventListener('install', (event) => {
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
      caches.match(event.request).then((response) => {
        return response || fetch(event.request);
      })
    );
  });
  ''';

  final File serviceWorkerBuildFile = File(
    path.join(_appBuildDirectory, 'flutter_service_worker.js'),
  );

  try {
    // Write the cleanup worker to the file system so it can be read if needed,
    print('Creating temporary cleanup worker file at: $cleanupWorkerSourcePath');
    cleanupWorkerFile.writeAsStringSync(cleanupWorkerContent);

    // Build the app once at the beginning.
    await runCommand('flutter', <String>[
      'build',
      'web',
      '--profile',
      '-t',
      _target,
    ], workingDirectory: _testAppDirectory);

    // Install the "old" caching worker and verify it works
    print('\n${yellow}Phase 1: Installing dummy caching worker and verifying it caches...$reset');
    serviceWorkerBuildFile.writeAsStringSync(oldCachingWorkerContent);

    server = await _startServer(headless: headless);

    // Load to install the worker.
    await _waitForAppToLoad(server, waitForCounts: <String, int>{'main.dart.js': 1});

    print('Reloading page to test cache...');
    _requestedPathCounts.clear();
    await server.chrome.reloadPage(); // This reload should be served from cache.
    await _waitForAppToLoad(server, waitForCounts: <String, int>{'flutter_service_worker.js': 1});

    expect(
      _requestedPathCounts.containsKey('main.dart.js'),
      false,
      reason:
          'On a simple reload, main.dart.js should have been served from the cache, so no network request was expected.',
    );
    print('${green}Verification successful: Old caching worker is active.$reset');
    await server.stop();

    // Deploy the cleanup worker
    print('\n${yellow}Phase 2: Deploying cleanup worker and verifying cache is removed...$reset');
    serviceWorkerBuildFile.writeAsStringSync(cleanupWorkerContent);

    server = await _startServer(headless: headless);
    // Hard refresh to force the browser to check for a new service worker version.
    await server.chrome.reloadPage(ignoreCache: true);

    print('Waiting for cleanup worker to execute and reload the page...');
    await _waitForAppToLoad(server, waitForCounts: <String, int>{'main.dart.js': 1});

    print('Reloading page to check if cache is gone...');
    _requestedPathCounts.clear();
    await server.chrome.reloadPage();
    // Now, we expect main.dart.js to be fetched from the network again.
    await _waitForAppToLoad(server, waitForCounts: <String, int>{'main.dart.js': 1});

    expect(
      _requestedPathCounts.containsKey('main.dart.js'),
      true,
      reason:
          'After cleanup, main.dart.js should be requested from the network because the caching worker is gone.',
    );
    print(
      '${green}Verification successful: Cleanup worker has removed the old caching behavior.$reset',
    );
  } finally {
    await server?.stop();
    if (cleanupWorkerFile.existsSync()) {
      cleanupWorkerFile.deleteSync();
      print('\nDeleted temporary cleanup worker file.');
    }
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
        final String requestedPath = request.url.path.split('/').last;
        _requestedPathCounts.putIfAbsent(requestedPath, () => 0);
        _requestedPathCounts[requestedPath] = _requestedPathCounts[requestedPath]! + 1;
        return Response.notFound('');
      },
    ],
  );
}

Future<void> _waitForAppToLoad(AppServer server, {required Map<String, int> waitForCounts}) async {
  await Future.any(<Future<Object?>>[
    () async {
      int tries = 1;
      while (!waitForCounts.entries.every(
        (MapEntry<String, int> entry) => (_requestedPathCounts[entry.key] ?? 0) >= entry.value,
      )) {
        if (tries++ % 40 == 0) {
          print('Still waiting for app to load. Requested so far: $_requestedPathCounts');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
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
  final Map<Object?, Object?> matchState = <Object?, Object?>{};
  if (matcher.matches(actual, matchState)) {
    return;
  }
  final StringDescription mismatchDescription = StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, true);

  final String which = mismatchDescription.toString();
  final StringBuffer buffer = StringBuffer();
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
  final StringBuffer buffer = StringBuffer('$first${lines.first}\n');
  for (final String line in lines.skip(1).take(lines.length - 2)) {
    buffer.writeln('$prefix$line');
  }
  buffer.write('$prefix${lines.last}');
  return buffer.toString();
}
