// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
final String _targetPath = path.join(_testAppDirectory, _target);

// Run a web service worker test as a standalone Dart program.
Future<void> main() async {
  await runWebServiceWorkerTest(headless: false);
}

Future<void> _setAppVersion(int version) async {
  final File targetFile = File(_targetPath);
  await targetFile.writeAsString(
    (await targetFile.readAsString()).replaceFirst(
      RegExp(r'CLOSE\?version=\d+'),
      'CLOSE?version=$version',
    )
  );
}

Future<void> _rebuildApp({ required int version }) async {
  await _setAppVersion(version);
  await runCommand(
    _flutter,
    <String>[ 'clean' ],
    workingDirectory: _testAppDirectory,
  );
  await runCommand(
    _flutter,
    <String>['build', 'web', '--profile', '-t', _target],
    workingDirectory: _testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

/// A drop-in replacement for `package:test` expect that can run outside the
/// test zone.
void expect(Object? actual, Object? expected) {
  final Matcher matcher = wrapMatcher(expected);
  final Map<Object, Object> matchState = <Object, Object>{};
  if (matcher.matches(actual, matchState)) {
    return;
  }
  final StringDescription mismatchDescription = StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, true);
  throw TestFailure(mismatchDescription.toString());
}

Future<void> runWebServiceWorkerTest({
  required bool headless,
}) async {
  await _rebuildApp(version: 1);

  final Map<String, int> requestedPathCounts = <String, int>{};
  void expectRequestCounts(Map<String, int> expectedCounts) {
    expect(requestedPathCounts, expectedCounts);
    requestedPathCounts.clear();
  }

  AppServer? server;
  Future<void> waitForAppToLoad(Map<String, int> waitForCounts) async {
    print('Waiting for app to load $waitForCounts');
    await Future.any(<Future<Object?>>[
      () async {
        while (!waitForCounts.entries.every((MapEntry<String, int> entry) => (requestedPathCounts[entry.key] ?? 0) >= entry.value)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }(),
      server!.onChromeError.then((String error) {
        throw Exception('Chrome error: $error');
      }),
    ]);
  }

  String? reportedVersion;

  Future<void> startAppServer({
    required String cacheControl,
  }) async {
    final int serverPort = await findAvailablePort();
    final int browserDebugPort = await findAvailablePort();
    server = await AppServer.start(
      headless: headless,
      cacheControl: cacheControl,
      // TODO(yjbanov): use a better port disambiguation strategy than trying
      //                to guess what ports other tests use.
      appUrl: 'http://localhost:$serverPort/index.html',
      serverPort: serverPort,
      browserDebugPort: browserDebugPort,
      appDirectory: _appBuildDirectory,
      additionalRequestHandlers: <Handler>[
        (Request request) {
          final String requestedPath = request.url.path;
          requestedPathCounts.putIfAbsent(requestedPath, () => 0);
          requestedPathCounts[requestedPath] = requestedPathCounts[requestedPath]! + 1;
          if (requestedPath == 'CLOSE') {
            reportedVersion = request.url.queryParameters['version'];
            return Response.ok('OK');
          }
          return Response.notFound('');
        },
      ],
    );
  }

  try {
    //////////////////////////////////////////////////////
    // Caching server
    //////////////////////////////////////////////////////
    print('With cache: test first page load');
    await startAppServer(cacheControl: 'max-age=3600');
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 1,
    });

    expectRequestCounts(<String, int>{
      '': 1,
      // Even though the server is caching index.html is downloaded twice,
      // once by the initial page load, and once by the service worker.
      // Other resources are loaded once only by the service worker.
      'index.html': 2,
      'main.dart.js': 1,
      'flutter_service_worker.js': 1,
      'assets/FontManifest.json': 1,
      'assets/NOTICES': 1,
      'assets/AssetManifest.json': 1,
      'CLOSE': 1,
      // In headless mode Chrome does not load 'manifest.json' and 'favicon.ico'.
      if (!headless)
        ...<String, int>{
          'manifest.json': 1,
          'favicon.ico': 1,
        }
    });
    expect(reportedVersion, '1');
    reportedVersion = null;

    print('With cache: test page reload');
    await server!.chrome.reloadPage();
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 1,
    });

    expectRequestCounts(<String, int>{
      'flutter_service_worker.js': 1,
      'CLOSE': 1,
    });
    expect(reportedVersion, '1');
    reportedVersion = null;

    print('With cache: test page reload after rebuild');
    await _rebuildApp(version: 2);

    // Since we're caching, we need to ignore cache when reloading the page.
    await server!.chrome.reloadPage(ignoreCache: true);
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 2,
    });
    expectRequestCounts(<String, int>{
      'index.html': 2,
      'flutter_service_worker.js': 2,
      '': 1,
      'main.dart.js': 1,
      'assets/NOTICES': 1,
      'assets/AssetManifest.json': 1,
      'assets/FontManifest.json': 1,
      'CLOSE': 1,
      if (!headless)
        'favicon.ico': 1,
    });

    expect(reportedVersion, '2');
    reportedVersion = null;
    await server!.stop();


    //////////////////////////////////////////////////////
    // Non-caching server
    //////////////////////////////////////////////////////
    print('No cache: test first page load');
    await _rebuildApp(version: 3);
    await startAppServer(cacheControl: 'max-age=0');
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 1,
    });

    expectRequestCounts(<String, int>{
      '': 1,
      'index.html': 2,
      // We still download some resources multiple times if the server is non-caching.
      'main.dart.js': 2,
      'assets/FontManifest.json': 2,
      'flutter_service_worker.js': 1,
      'assets/NOTICES': 1,
      'assets/AssetManifest.json': 1,
      'CLOSE': 1,
      // In headless mode Chrome does not load 'manifest.json' and 'favicon.ico'.
      if (!headless)
        ...<String, int>{
          'manifest.json': 1,
          'favicon.ico': 1,
        }
    });

    expect(reportedVersion, '3');
    reportedVersion = null;

    print('No cache: test page reload');
    await server!.chrome.reloadPage();
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 1,
    });

    expectRequestCounts(<String, int>{
      'flutter_service_worker.js': 1,
      'CLOSE': 1,
      if (!headless)
        'manifest.json': 1,
    });
    expect(reportedVersion, '3');
    reportedVersion = null;

    print('No cache: test page reload after rebuild');
    await _rebuildApp(version: 4);

    // TODO(yjbanov): when running Chrome with DevTools protocol, for some
    // reason a hard refresh is still required. This works without a hard
    // refresh when running Chrome manually as normal. At the time of writing
    // this test I wasn't able to figure out what's wrong with the way we run
    // Chrome from tests.
    await server!.chrome.reloadPage(ignoreCache: true);
    await waitForAppToLoad(<String, int>{
      'CLOSE': 1,
      'flutter_service_worker.js': 1,
    });
    expectRequestCounts(<String, int>{
      '': 1,
      'index.html': 2,
      'flutter_service_worker.js': 2,
      'main.dart.js': 2,
      'assets/NOTICES': 1,
      'assets/AssetManifest.json': 1,
      'assets/FontManifest.json': 2,
      'CLOSE': 1,
      if (!headless)
        ...<String, int>{
          'manifest.json': 1,
          'favicon.ico': 1,
        }
    });

    expect(reportedVersion, '4');
    reportedVersion = null;
  } finally {
    await _setAppVersion(1);
    await server?.stop();
  }
}
