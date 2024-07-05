// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show File, HttpClient, HttpClientRequest, HttpClientResponse, Process, RawSocket, SocketDirection, SocketException;
import 'dart:math' as math;
import 'package:path/path.dart' as path;

import '../browser.dart';
import '../run_command.dart';
import '../service_worker_test.dart';
import '../test.dart';
import '../utils.dart';

const List<String> _kAllBuildModes = <String>['debug', 'profile', 'release'];

/// Coarse-grained integration tests running on the Web.
Future<void> webLongRunningTestsRunner(String flutterRoot) async {

  final String engineVersionFile = path.join(flutterRoot, 'bin', 'internal', 'engine.version');
  final String engineRealmFile = path.join(flutterRoot, 'bin', 'internal', 'engine.realm');
  final String engineVersion = File(engineVersionFile).readAsStringSync().trim();
  final String engineRealm = File(engineRealmFile).readAsStringSync().trim();
  if (engineRealm.isNotEmpty) {
    return;
  }
  final List<ShardRunner> tests = <ShardRunner>[
    for (final String buildMode in _kAllBuildModes) ...<ShardRunner>[
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('test_driver', 'failure.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        // This test intentionally fails and prints stack traces in the browser
        // logs. To avoid confusion, silence browser output.
        silenceBrowserOutput: true,
      ),
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('integration_test', 'example_test.dart'),
        driver: path.join('test_driver', 'integration_test.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        expectWriteResponseFile: true,
        expectResponseFileContent: 'null',
      ),
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('integration_test', 'extended_test.dart'),
        driver: path.join('test_driver', 'extended_integration_test.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        expectWriteResponseFile: true,
        expectResponseFileContent: '''
{
  "screenshots": [
    {
      "screenshotName": "platform_name",
      "bytes": []
    },
    {
      "screenshotName": "platform_name_2",
      "bytes": []
    }
  ]
}''',
      ),
    ],

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'debug', renderer: 'canvaskit'),
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'profile', renderer: 'html'),
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'debug', renderer: 'html'),
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'release', renderer: 'html'),

    // This test is only known to work in debug mode.
    () => _runWebE2eTest('scroll_wheel_integration', buildMode: 'debug', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    // These tests have been extremely flaky, so we are temporarily disabling them until we figure out how to make them more robust.
    // See https://github.com/flutter/flutter/issues/143834
    // () => _runWebE2eTest('text_editing_integration', buildMode: 'debug', renderer: 'canvaskit'),
    // () => _runWebE2eTest('text_editing_integration', buildMode: 'profile', renderer: 'html'),
    // () => _runWebE2eTest('text_editing_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'debug', renderer: 'html'),
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('capabilities_integration_canvaskit', buildMode: 'debug', renderer: 'auto'),
    () => _runWebE2eTest('capabilities_integration_canvaskit', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('capabilities_integration_html', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    // CacheWidth and CacheHeight are only currently supported in CanvasKit mode, so we don't run the test in HTML mode.
    () => _runWebE2eTest('cache_width_cache_height_integration', buildMode: 'debug', renderer: 'auto'),
    () => _runWebE2eTest('cache_width_cache_height_integration', buildMode: 'profile', renderer: 'canvaskit'),

    () => _runWebTreeshakeTest(),

    () => _runFlutterDriverWebTest(
      testAppDirectory: path.join(flutterRoot, 'examples', 'hello_world'),
      target: 'test_driver/smoke_web_engine.dart',
      buildMode: 'profile',
      renderer: 'auto',
    ),
    () => _runGalleryE2eWebTest('debug'),
    () => _runGalleryE2eWebTest('debug', canvasKit: true),
    () => _runGalleryE2eWebTest('profile'),
    () => _runGalleryE2eWebTest('profile', canvasKit: true),
    () => _runGalleryE2eWebTest('release'),
    () => _runGalleryE2eWebTest('release', canvasKit: true),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withoutFlutterJs),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJs),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsShort),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsEntrypointLoadedEvent),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsTrustedTypesOn),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsNonceOn),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withoutFlutterJs),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJs),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsShort),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsEntrypointLoadedEvent),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsTrustedTypesOn),
    () => runWebServiceWorkerTestWithGeneratedEntrypoint(headless: true),
    () => runWebServiceWorkerTestWithBlockedServiceWorkers(headless: true),
    () => runWebServiceWorkerTestWithCustomServiceWorkerVersion(headless: true),
    () => _runWebStackTraceTest('profile', 'lib/stack_trace.dart'),
    () => _runWebStackTraceTest('release', 'lib/stack_trace.dart'),
    () => _runWebStackTraceTest('profile', 'lib/framework_stack_trace.dart'),
    () => _runWebStackTraceTest('release', 'lib/framework_stack_trace.dart'),
    () => _runWebDebugTest('lib/stack_trace.dart'),
    () => _runWebDebugTest('lib/framework_stack_trace.dart'),
    () => _runWebDebugTest('lib/web_directory_loading.dart'),
    () => _runWebDebugTest('lib/web_resources_cdn_test.dart',
      additionalArguments: <String>[
        '--dart-define=TEST_FLUTTER_ENGINE_VERSION=$engineVersion',
      ]),
    () => _runWebDebugTest('test/test.dart'),
    () => _runWebDebugTest('lib/null_safe_main.dart'),
    () => _runWebDebugTest('lib/web_define_loading.dart',
      additionalArguments: <String>[
        '--dart-define=test.valueA=Example,A',
        '--dart-define=test.valueB=Value',
      ]
    ),
    () => _runWebReleaseTest('lib/web_define_loading.dart',
      additionalArguments: <String>[
        '--dart-define=test.valueA=Example,A',
        '--dart-define=test.valueB=Value',
      ]
    ),
    () => _runWebDebugTest('lib/sound_mode.dart'),
    () => _runWebReleaseTest('lib/sound_mode.dart'),
    () => runFlutterWebTest(
      'html',
      path.join(flutterRoot, 'packages', 'integration_test'),
      <String>['test/web_extension_test.dart'],
      false,
    ),
    () => runFlutterWebTest(
      'canvaskit',
      path.join(flutterRoot, 'packages', 'integration_test'),
      <String>['test/web_extension_test.dart'],
      false,
    ),
    () => runFlutterWebTest(
      'skwasm',
      path.join(flutterRoot, 'packages', 'integration_test'),
      <String>['test/web_extension_test.dart'],
      true,
    ),
  ];

  // Shuffling mixes fast tests with slow tests so shards take roughly the same
  // amount of time to run.
  tests.shuffle(math.Random(0));

  await _ensureChromeDriverIsRunning();
  await runShardRunnerIndexOfTotalSubshard(tests);
  await _stopChromeDriver();
}

/// Runs one of the `dev/integration_tests/web_e2e_tests` tests.
Future<void> _runWebE2eTest(
  String name, {
  required String buildMode,
  required String renderer,
}) async {
  await _runFlutterDriverWebTest(
    target: path.join('test_driver', '$name.dart'),
    buildMode: buildMode,
    renderer: renderer,
    testAppDirectory: path.join(flutterRoot, 'dev', 'integration_tests', 'web_e2e_tests'),
  );
}

Future<void> _runFlutterDriverWebTest({
  required String target,
  required String buildMode,
  required String renderer,
  required String testAppDirectory,
  String? driver,
  bool expectFailure = false,
  bool silenceBrowserOutput = false,
  bool expectWriteResponseFile = false,
  String expectResponseFileContent = '',
}) async {
  printProgress('${green}Running integration tests $target in $buildMode mode.$reset');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  final String responseFile =
      path.join(testAppDirectory, 'build', 'integration_response_data.json');
  if (File(responseFile).existsSync()) {
    File(responseFile).deleteSync();
  }
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
      'drive',
      if (driver != null) '--driver=$driver',
      '--target=$target',
      '--browser-name=chrome',
      '-d',
      'web-server',
      '--$buildMode',
      '--web-renderer=$renderer',
    ],
    expectNonZeroExit: expectFailure,
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
    removeLine: (String line) {
      if (!silenceBrowserOutput) {
        return false;
      }
      if (line.trim().startsWith('[INFO]')) {
        return true;
      }
      return false;
    },
  );
  if (expectWriteResponseFile) {
    if (!File(responseFile).existsSync()) {
      foundError(<String>[
        '$bold${red}Command did not write the response file but expected response file written.$reset',
      ]);
    } else {
      final String response = File(responseFile).readAsStringSync();
      if (response != expectResponseFileContent) {
        foundError(<String>[
          '$bold${red}Command write the response file with $response but expected response file with $expectResponseFileContent.$reset',
        ]);
      }
    }
  }
}

// Compiles a sample web app and checks that its JS doesn't contain certain
// debug code that we expect to be tree shaken out.
//
// The app is compiled in `--profile` mode to prevent the compiler from
// minifying the symbols.
Future<void> _runWebTreeshakeTest() async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web_e2e_tests');
  final String target = path.join('lib', 'treeshaking_main.dart');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      'build',
      'web',
      '--target=$target',
      '--profile',
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  final File mainDartJs = File(path.join(testAppDirectory, 'build', 'web', 'main.dart.js'));
  final String javaScript = mainDartJs.readAsStringSync();

  // Check that we're not looking at minified JS. Otherwise this test would result in false positive.
  expect(javaScript.contains('RootElement'), true);

  const String word = 'debugFillProperties';
  int count = 0;
  int pos = javaScript.indexOf(word);
  final int contentLength = javaScript.length;
  while (pos != -1) {
    count += 1;
    pos += word.length;
    if (pos >= contentLength || count > 100) {
      break;
    }
    pos = javaScript.indexOf(word, pos);
  }

  // The following are classes from `timeline.dart` that should be treeshaken
  // off unless the app (typically a benchmark) uses methods that need them.
  expect(javaScript.contains('AggregatedTimedBlock'), false);
  expect(javaScript.contains('AggregatedTimings'), false);
  expect(javaScript.contains('_BlockBuffer'), false);
  expect(javaScript.contains('_StringListChain'), false);
  expect(javaScript.contains('_Float64ListChain'), false);

  const int kMaxExpectedDebugFillProperties = 11;
  if (count > kMaxExpectedDebugFillProperties) {
    throw Exception(
      'Too many occurrences of "$word" in compiled JavaScript.\n'
      'Expected no more than $kMaxExpectedDebugFillProperties, but found $count.'
    );
  }
}

/// Exercises the old gallery in a browser for a long period of time, looking
/// for memory leaks and dangling pointers.
///
/// This is not a performance test.
///
/// If [canvasKit] is set to true, runs the test in CanvasKit mode.
///
/// The test is written using `package:integration_test` (despite the "e2e" in
/// the name, which is there for historic reasons).
Future<void> _runGalleryE2eWebTest(String buildMode, { bool canvasKit = false }) async {
  printProgress('${green}Running flutter_gallery integration test in --$buildMode using ${canvasKit ? 'CanvasKit' : 'HTML'} renderer.$reset');
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
      'drive',
      if (canvasKit)
        '--dart-define=FLUTTER_WEB_USE_SKIA=true',
      if (!canvasKit)
        '--dart-define=FLUTTER_WEB_USE_SKIA=false',
      if (!canvasKit)
        '--dart-define=FLUTTER_WEB_AUTO_DETECT=false',
      '--driver=test_driver/transitions_perf_e2e_test.dart',
      '--target=test_driver/transitions_perf_e2e.dart',
      '--browser-name=chrome',
      '-d',
      'web-server',
      '--$buildMode',
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

Future<void> _runWebStackTraceTest(String buildMode, String entrypoint) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  final String appBuildDirectory = path.join(testAppDirectory, 'build', 'web');

  // Build the app.
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      'build',
      'web',
      '--$buildMode',
      '-t',
      entrypoint,
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  // Run the app.
  final int serverPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final int browserDebugPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:$serverPort/index.html',
    appDirectory: appBuildDirectory,
    serverPort: serverPort,
    browserDebugPort: browserDebugPort,
  );

  if (!result.contains('--- TEST SUCCEEDED ---')) {
    foundError(<String>[
      result,
      '${red}Web stack trace integration test failed.$reset',
    ]);
  }
}

/// Debug mode is special because `flutter build web` doesn't build in debug mode.
///
/// Instead, we use `flutter run --debug` and sniff out the standard output.
Future<void> _runWebDebugTest(String target, {
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  bool success = false;
  final Map<String, String> environment = <String, String>{
    'FLUTTER_WEB': 'true',
  };
  adjustEnvironmentToEnableFlutterAsserts(environment);
  final CommandResult result = await runCommand(
    flutter,
    <String>[
      'run',
      '--debug',
      '-d',
      'chrome',
      '--web-run-headless',
      '--dart-define=FLUTTER_WEB_USE_SKIA=false',
      '--dart-define=FLUTTER_WEB_AUTO_DETECT=false',
      ...additionalArguments,
      '-t',
      target,
    ],
    outputMode: OutputMode.capture,
    outputListener: (String line, Process process) {
      if (line.contains('--- TEST SUCCEEDED ---')) {
        success = true;
      }
      if (success || line.contains('--- TEST FAILED ---')) {
        process.stdin.add('q'.codeUnits);
      }
    },
    workingDirectory: testAppDirectory,
    environment: environment,
  );

  if (!success) {
    foundError(<String>[
      result.flattenedStdout!,
      result.flattenedStderr!,
      '${red}Web stack trace integration test failed.$reset',
    ]);
  }
}

/// Run a web integration test in release mode.
Future<void> _runWebReleaseTest(String target, {
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  final String appBuildDirectory = path.join(testAppDirectory, 'build', 'web');

  // Build the app.
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
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

  // Run the app.
  final int serverPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final int browserDebugPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:$serverPort/index.html',
    appDirectory: appBuildDirectory,
    serverPort: serverPort,
    browserDebugPort: browserDebugPort,
  );

  if (!result.contains('--- TEST SUCCEEDED ---')) {
    foundError(<String>[
      result,
      '${red}Web release mode test failed.$reset',
    ]);
  }
}

// The `chromedriver` process created by this test.
//
// If an existing chromedriver is already available on port 4444, the existing
// process is reused and this variable remains null.
Command? _chromeDriver;

Future<bool> _isChromeDriverRunning() async {
  try {
    final RawSocket socket = await RawSocket.connect('localhost', 4444);
    socket.shutdown(SocketDirection.both);
    await socket.close();
    return true;
  } on SocketException {
    return false;
  }
}

Future<void> _stopChromeDriver() async {
  if (_chromeDriver == null) {
    return;
  }
  print('Stopping chromedriver');
  _chromeDriver!.process.kill();
}

Future<void> _ensureChromeDriverIsRunning() async {
  // If we cannot connect to ChromeDriver, assume it is not running. Launch it.
  if (!await _isChromeDriverRunning()) {
    printProgress('Starting chromedriver');
    // Assume chromedriver is in the PATH.
    _chromeDriver = await startCommand(
      // TODO(ianh): this is the only remaining consumer of startCommand other than runCommand
      // and it doesn't use most of startCommand's features; we could simplify this a lot by
      // inlining the relevant parts of startCommand here.
      'chromedriver',
      <String>['--port=4444'],
    );
    while (!await _isChromeDriverRunning()) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      print('Waiting for chromedriver to start up.');
    }
  }

  final HttpClient client = HttpClient();
  final Uri chromeDriverUrl = Uri.parse('http://localhost:4444/status');
  final HttpClientRequest request = await client.getUrl(chromeDriverUrl);
  final HttpClientResponse response = await request.close();
  final Map<String, dynamic> webDriverStatus = json.decode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
  client.close();
  final bool webDriverReady = (webDriverStatus['value'] as Map<String, dynamic>)['ready'] as bool;
  if (!webDriverReady) {
    throw Exception('WebDriver not available.');
  }
}
