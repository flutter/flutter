// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json, utf8;
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../framework/browser.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

/// The port at which the local benchmark server is served.
/// This is hard-coded and must be the same as the port used for DDC's benchmark at `flutter/dev/benchmarks/macrobenchmarks/lib/web_benchmarks_ddc.dart`.
const int benchmarkServerPort = 9999;

/// The port at which Chrome listens for a debug connection.
const int chromeDebugPort = 10000;

/// The port at which the benchmark's app is being served.
const int benchmarksAppPort = 10001;

/// The port at which SafariDriver listens during local cross-browser runs.
const int safariDriverPort = 10002;

typedef WebBenchmarkOptions = ({
  bool useWasm,
  bool forceSingleThreadedSkwasm,
  bool useDdc,
  bool withHotReload,
  String buildMode,
});

enum _BenchmarkBrowser { chrome, safari, firefox }

List<String>? _parseBenchmarkFilter(String? rawFilter) {
  if (rawFilter == null || rawFilter.trim().isEmpty) {
    return null;
  }
  return rawFilter
      .split(',')
      .map((String benchmark) => benchmark.trim())
      .where((String benchmark) => benchmark.isNotEmpty)
      .toList();
}

_BenchmarkBrowser _readBenchmarkBrowser() {
  final String rawBrowser = io.Platform.environment['WEB_BENCHMARK_BROWSER'] ?? 'chrome';
  return switch (rawBrowser.toLowerCase()) {
    'chrome' => _BenchmarkBrowser.chrome,
    'safari' => _BenchmarkBrowser.safari,
    'firefox' => _BenchmarkBrowser.firefox,
    _ => throw ArgumentError.value(
      rawBrowser,
      'WEB_BENCHMARK_BROWSER',
      'Expected chrome, safari, or firefox',
    ),
  };
}

Future<TaskResult> runWebBenchmark(WebBenchmarkOptions benchmarkOptions) async {
  // Reduce logging level. Otherwise, package:webkit_inspection_protocol is way too spammy.
  Logger.root.level = Level.INFO;
  final List<String>? benchmarkFilter = _parseBenchmarkFilter(
    io.Platform.environment['WEB_BENCHMARKS'],
  );
  final _BenchmarkBrowser benchmarkBrowser = _readBenchmarkBrowser();
  final useChromeTracing = benchmarkBrowser == _BenchmarkBrowser.chrome;
  if (benchmarkOptions.useDdc && benchmarkBrowser != _BenchmarkBrowser.chrome) {
    throw UnsupportedError('DDC web benchmarks still require Chrome.');
  }
  final String macrobenchmarksDirectory = path.join(
    flutterDirectory.path,
    'dev',
    'benchmarks',
    'macrobenchmarks',
  );
  return inDirectory(macrobenchmarksDirectory, () async {
    await flutter('clean');
    // DDC runs the benchmarks suite with 'flutter run', attaching to its
    // Chrome instance instead of starting a new one.
    io.Process? flutterRunProcess;
    if (benchmarkOptions.useDdc) {
      final ddcAppReady = Completer<void>();
      flutterRunProcess = await startFlutter(
        'run',
        options: <String>[
          '-d',
          'chrome',
          '--web-port',
          '$benchmarksAppPort',
          '--web-browser-debug-port',
          '$chromeDebugPort',
          '--web-launch-url',
          'http://localhost:$benchmarksAppPort/index.html',
          '--debug',
          '--web-run-headless',
          '--no-web-enable-expression-evaluation',
          '--web-browser-flag=--disable-popup-blocking',
          '--web-browser-flag=--bwsi',
          '--web-browser-flag=--no-first-run',
          '--web-browser-flag=--no-default-browser-check',
          '--web-browser-flag=--disable-default-apps',
          '--web-browser-flag=--disable-translate',
          '--web-browser-flag=--disable-background-timer-throttling',
          '--web-browser-flag=--disable-backgrounding-occluded-windows',
          '--web-browser-flag=--disable-renderer-backgrounding',
          '--web-browser-flag=--headless=new',
          '--web-browser-flag=--no-sandbox',
          '--dart-define=FLUTTER_WEB_ENABLE_PROFILING=true',
          if (benchmarkOptions.withHotReload)
            '--web-experimental-hot-reload'
          else
            '--no-web-experimental-hot-reload',
          '--no-web-resources-cdn',
          'lib/web_benchmarks_ddc.dart',
        ],
      );
      flutterRunProcess.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
        String line,
      ) {
        if (!ddcAppReady.isCompleted && line.startsWith('Debug service listening on')) {
          ddcAppReady.complete();
        }
        print('[CHROME STDOUT]: $line');
      });
      flutterRunProcess.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
        String line,
      ) {
        print('[CHROME STDERR]: $line');
      });
      // Wait for the app to load in DDC's Chrome instance before trying to
      // connect the debugger.
      await ddcAppReady.future;
    } else {
      await evalFlutter(
        'build',
        options: <String>[
          'web',
          '--no-tree-shake-icons', // local engine builds are frequently out of sync with the Dart Kernel version
          if (benchmarkOptions.useWasm) ...<String>['--wasm', '--no-strip-wasm'],
          '--dart-define=FLUTTER_WEB_ENABLE_PROFILING=true',
          '--${benchmarkOptions.buildMode}',
          '--no-web-resources-cdn',
          '-t',
          'lib/web_benchmarks.dart',
        ],
      );
    }
    final profileData = Completer<List<Map<String, dynamic>>>();
    final collectedProfiles = <Map<String, dynamic>>[];
    List<String>? benchmarks;
    late Iterator<String> benchmarkIterator;

    // This future fixes a race condition between the web-page loading and
    // asking to run a benchmark, and us connecting to Chrome's DevTools port.
    // Sometime one wins. Other times, the other wins.
    Future<Chrome>? whenChromeIsReady;
    Chrome? chrome;
    _LaunchedBenchmarkBrowser? launchedBrowser;
    late io.HttpServer server;
    var cascade = Cascade();
    List<Map<String, dynamic>>? latestPerformanceTrace;
    final requestHeaders = <String, List<String>>{
      'Access-Control-Allow-Headers': <String>[
        'Accept',
        'Access-Control-Allow-Headers',
        'Access-Control-Allow-Methods',
        'Access-Control-Allow-Origin',
        'Content-Type',
        'Origin',
      ],
      'Access-Control-Allow-Methods': <String>['Post'],
      'Access-Control-Allow-Origin': <String>['http://localhost:$benchmarksAppPort'],
    };

    cascade = cascade.add((Request request) async {
      final String requestContents = await request.readAsString();
      try {
        if (useChromeTracing) {
          chrome ??= await whenChromeIsReady;
        }
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: requestHeaders);
        }
        if (request.requestedUri.path.endsWith('/profile-data')) {
          final profile = json.decode(requestContents) as Map<String, dynamic>;
          final benchmarkName = profile['name'] as String;
          if (benchmarkName != benchmarkIterator.current) {
            profileData.completeError(
              Exception(
                'Browser returned benchmark results from a wrong benchmark.\n'
                'Requested to run benchmark ${benchmarkIterator.current}, but '
                'got results for $benchmarkName.',
              ),
            );
            unawaited(server.close());
          }

          // Trace data is null when the benchmark is not frame-based, such as RawRecorder.
          if (latestPerformanceTrace != null) {
            final BlinkTraceSummary traceSummary = BlinkTraceSummary.fromJson(
              latestPerformanceTrace!,
            )!;
            profile['totalUiFrame.average'] = traceSummary.averageTotalUIFrameTime.inMicroseconds;
            profile['scoreKeys'] ??= <dynamic>[]; // using dynamic for consistency with JSON
            (profile['scoreKeys'] as List<dynamic>).add('totalUiFrame.average');
            latestPerformanceTrace = null;
          }
          collectedProfiles.add(profile);
          return Response.ok('Profile received', headers: requestHeaders);
        } else if (request.requestedUri.path.endsWith('/start-performance-tracing')) {
          if (!useChromeTracing) {
            return Response.ok('Performance tracing skipped', headers: requestHeaders);
          }
          latestPerformanceTrace = null;
          await chrome!.beginRecordingPerformance(request.requestedUri.queryParameters['label']!);
          return Response.ok('Started performance tracing', headers: requestHeaders);
        } else if (request.requestedUri.path.endsWith('/stop-performance-tracing')) {
          if (!useChromeTracing) {
            return Response.ok('Performance tracing skipped', headers: requestHeaders);
          }
          latestPerformanceTrace = await chrome!.endRecordingPerformance();
          return Response.ok('Stopped performance tracing', headers: requestHeaders);
        } else if (request.requestedUri.path.endsWith('/on-error')) {
          final errorDetails = json.decode(requestContents) as Map<String, dynamic>;
          unawaited(server.close());
          // Keep the stack trace as a string. It's thrown in the browser, not this Dart VM.
          profileData.completeError('${errorDetails['error']}\n${errorDetails['stackTrace']}');
          return Response.ok('', headers: requestHeaders);
        } else if (request.requestedUri.path.endsWith('/next-benchmark')) {
          if (benchmarks == null) {
            final List<String> availableBenchmarks = (json.decode(requestContents) as List<dynamic>)
                .cast<String>();
            if (benchmarkFilter != null) {
              final List<String> missingBenchmarks = benchmarkFilter
                  .where((String benchmark) => !availableBenchmarks.contains(benchmark))
                  .toList();
              if (missingBenchmarks.isNotEmpty) {
                throw ArgumentError.value(
                  missingBenchmarks.join(', '),
                  'WEB_BENCHMARKS',
                  'Unknown benchmark(s)',
                );
              }
              benchmarks = availableBenchmarks
                  .where((String benchmark) => benchmarkFilter.contains(benchmark))
                  .toList();
            } else {
              benchmarks = availableBenchmarks;
            }
            benchmarkIterator = benchmarks!.iterator;
          }
          if (benchmarkIterator.moveNext()) {
            final String nextBenchmark = benchmarkIterator.current;
            print('Launching benchmark "$nextBenchmark"');
            return Response.ok(nextBenchmark, headers: requestHeaders);
          } else {
            profileData.complete(collectedProfiles);
            return Response.notFound('Finished running benchmarks.', headers: requestHeaders);
          }
        } else if (request.requestedUri.path.endsWith('/print-to-console')) {
          // A passthrough used by
          // `dev/benchmarks/macrobenchmarks/lib/web_benchmarks.dart`
          // to print information.
          final message = requestContents;
          print('[APP] $message');
          return Response.ok('Reported.', headers: requestHeaders);
        } else {
          return Response.notFound(
            'This request is not handled by the profile-data handler.',
            headers: requestHeaders,
          );
        }
      } catch (error, stackTrace) {
        profileData.completeError(error, stackTrace);
        return Response.internalServerError(body: '$error', headers: requestHeaders);
      }
    });
    // Macrobenchmarks using 'flutter build' serve files from their local build directory alongside the orchestration logic.
    if (!benchmarkOptions.useDdc) {
      cascade = cascade.add(
        createBuildDirectoryHandler(path.join(macrobenchmarksDirectory, 'build', 'web')),
      );
    }

    server = await io.HttpServer.bind('localhost', benchmarkServerPort);
    try {
      shelf_io.serveRequests(server, cascade.handler);

      final String dartToolDirectory = path.join('$macrobenchmarksDirectory/.dart_tool');
      final String userDataDir = io.Directory(
        dartToolDirectory,
      ).createTempSync('flutter_chrome_user_data.').path;

      // TODO(yjbanov): temporarily disables headful Chrome until we get
      //                devicelab hardware that is able to run it. Our current
      //                GCE VMs can only run in headless mode.
      //                See: https://github.com/flutter/flutter/issues/50164
      final isUncalibratedSmokeTest = io.Platform.environment['CALIBRATED'] != 'true';
      // final bool isUncalibratedSmokeTest =
      //     io.Platform.environment['UNCALIBRATED_SMOKE_TEST'] == 'true';
      final urlParams = benchmarkOptions.forceSingleThreadedSkwasm ? '?force_st=true' : '';
      // DDC apps are served from a different port from the orchestration server.
      final int appServingPort = benchmarkOptions.useDdc ? benchmarksAppPort : benchmarkServerPort;
      final options = ChromeOptions(
        url: 'http://localhost:$appServingPort/index.html$urlParams',
        userDataDirectory: userDataDir,
        headless: isUncalibratedSmokeTest,
        debugPort: chromeDebugPort,
        enableWasmGC: benchmarkOptions.useWasm,
      );

      if (benchmarkBrowser == _BenchmarkBrowser.chrome) {
        print('Launching Chrome.');

        if (benchmarkOptions.useDdc) {
          // DDC reuses the existing Chrome connection spawned via 'flutter run'.
          whenChromeIsReady = Chrome.connect(
            flutterRunProcess!,
            options,
            onError: (String error) {
              profileData.completeError(Exception(error));
            },
            workingDirectory: cwd,
          );
        } else {
          whenChromeIsReady = Chrome.launch(
            options,
            onError: (String error) {
              profileData.completeError(Exception(error));
            },
            workingDirectory: cwd,
          );
        }
      } else {
        launchedBrowser = await _LaunchedBenchmarkBrowser.launch(
          benchmarkBrowser,
          options,
          onError: (String error) {
            profileData.completeError(Exception(error));
          },
          workingDirectory: cwd,
        );
      }

      print('Waiting for the benchmark to report benchmark profile.');
      final taskResult = <String, dynamic>{};
      final benchmarkScoreKeys = <String>[];
      final List<Map<String, dynamic>> profiles = await profileData.future;

      print('Received profile data');
      for (final profile in profiles) {
        final benchmarkName = profile['name'] as String;
        if (benchmarkName.isEmpty) {
          throw 'Benchmark name is empty';
        }

        final String webRendererName;
        if (benchmarkOptions.useWasm) {
          webRendererName = benchmarkOptions.forceSingleThreadedSkwasm ? 'skwasm_st' : 'skwasm';
        } else {
          webRendererName = 'canvaskit';
        }
        final namespace = '$benchmarkName.$webRendererName';
        final scoreKeys = List<String>.from(profile['scoreKeys'] as List<dynamic>);
        if (scoreKeys.isEmpty) {
          throw 'No score keys in benchmark "$benchmarkName"';
        }
        for (final scoreKey in scoreKeys) {
          if (scoreKey.isEmpty) {
            throw 'Score key is empty in benchmark "$benchmarkName". '
                'Received [${scoreKeys.join(', ')}]';
          }
          benchmarkScoreKeys.add('$namespace.$scoreKey');
        }

        for (final String key in profile.keys) {
          if (key == 'name' || key == 'scoreKeys') {
            continue;
          }
          taskResult['$namespace.$key'] = profile[key];
        }
      }
      return TaskResult.success(taskResult, benchmarkScoreKeys: benchmarkScoreKeys);
    } finally {
      unawaited(server.close());
      chrome?.stop();
      await launchedBrowser?.stop();
      if (flutterRunProcess != null) {
        // Sending a SIGINT/SIGTERM to the process here isn't reliable because [process] is
        // the shell (flutter is a shell script) and doesn't pass the signal on.
        // Sending a `q` is an instruction to quit using the console runner.
        flutterRunProcess.stdin.write('q');
        await flutterRunProcess.stdin.flush();
        // Give the process a couple of seconds to exit and run shutdown hooks
        // before sending kill signal.
        await flutterRunProcess.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            flutterRunProcess!.kill(io.ProcessSignal.sigint);
            return 0;
          },
        );
      }
    }
  });
}

class _LaunchedBenchmarkBrowser {
  _LaunchedBenchmarkBrowser._({this.process, this.safariSession});

  static Future<_LaunchedBenchmarkBrowser> launch(
    _BenchmarkBrowser browser,
    ChromeOptions options, {
    required ChromeErrorCallback onError,
    required String workingDirectory,
  }) async {
    return switch (browser) {
      _BenchmarkBrowser.chrome => throw ArgumentError('Use Chrome.launch for Chrome benchmarks.'),
      _BenchmarkBrowser.safari => _launchSafari(
        options,
        onError: onError,
        workingDirectory: workingDirectory,
      ),
      _BenchmarkBrowser.firefox => _launchFirefox(
        options,
        onError: onError,
        workingDirectory: workingDirectory,
      ),
    };
  }

  final io.Process? process;
  final _SafariWebDriverSession? safariSession;
  bool _isStopped = false;

  Future<void> stop() async {
    _isStopped = true;
    await safariSession?.stop();
    process?.kill();
  }

  static Future<_LaunchedBenchmarkBrowser> _launchFirefox(
    ChromeOptions options, {
    required ChromeErrorCallback onError,
    required String workingDirectory,
  }) async {
    final String? url = options.url;
    final String? userDataDirectory = options.userDataDirectory;
    if (url == null || userDataDirectory == null) {
      throw ArgumentError('Firefox benchmarks require a URL and user data directory.');
    }
    final String executable = _findFirefoxExecutable();
    final args = <String>[
      '--new-instance',
      '--profile',
      userDataDirectory,
      '--width',
      '${options.windowWidth}',
      '--height',
      '${options.windowHeight}',
      url,
    ];
    print('Launching Firefox: $executable ${args.join(' ')}');
    final io.Process process = await io.Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
    );
    final launched = _LaunchedBenchmarkBrowser._(process: process);
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      print('[FIREFOX STDOUT]: $line');
    });
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      print('[FIREFOX STDERR]: $line');
    });
    unawaited(
      process.exitCode.then((int exitCode) {
        if (!launched._isStopped) {
          onError('Firefox process exited prematurely with exit code $exitCode');
        }
      }),
    );
    return launched;
  }

  static Future<_LaunchedBenchmarkBrowser> _launchSafari(
    ChromeOptions options, {
    required ChromeErrorCallback onError,
    required String workingDirectory,
  }) async {
    final String? url = options.url;
    if (url == null) {
      throw ArgumentError('Safari benchmarks require a URL.');
    }
    if (!io.Platform.isMacOS) {
      throw UnsupportedError('Safari benchmarks are only supported on macOS.');
    }
    print('Launching Safari via safaridriver.');
    final _SafariWebDriverSession session = await _SafariWebDriverSession.start(
      url,
      onError: onError,
      workingDirectory: workingDirectory,
    );
    return _LaunchedBenchmarkBrowser._(safariSession: session);
  }
}

String _findFirefoxExecutable() {
  const macOSFirefoxPath = '/Applications/Firefox.app/Contents/MacOS/firefox';
  if (io.File(macOSFirefoxPath).existsSync()) {
    return macOSFirefoxPath;
  }
  return 'firefox';
}

class _SafariWebDriverSession {
  _SafariWebDriverSession._(this._driverProcess, this._sessionId, this._onError) {
    unawaited(
      _driverProcess.exitCode.then((int exitCode) {
        if (!_isStopped) {
          _onError('safaridriver exited prematurely with exit code $exitCode');
        }
      }),
    );
  }

  static Future<_SafariWebDriverSession> start(
    String url, {
    required ChromeErrorCallback onError,
    required String workingDirectory,
  }) async {
    final io.Process driverProcess = await io.Process.start(_findSafariDriverExecutable(), <String>[
      '--port',
      '$safariDriverPort',
    ], workingDirectory: workingDirectory);
    driverProcess.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      print('[SAFARIDRIVER STDOUT]: $line');
    });
    driverProcess.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      print('[SAFARIDRIVER STDERR]: $line');
    });

    try {
      await _waitForWebDriverStatus();
      final String sessionId = await _createSession();
      final session = _SafariWebDriverSession._(driverProcess, sessionId, onError);
      await session._navigate(url);
      return session;
    } catch (_) {
      driverProcess.kill();
      rethrow;
    }
  }

  final io.Process _driverProcess;
  final String _sessionId;
  final ChromeErrorCallback _onError;
  bool _isStopped = false;

  Future<void> stop() async {
    _isStopped = true;
    try {
      await _webdriverRequest('DELETE', '/session/$_sessionId');
    } catch (error) {
      print('Failed to stop Safari WebDriver session: $error');
    }
    _driverProcess.kill();
  }

  static Future<void> _waitForWebDriverStatus() async {
    final stopwatch = Stopwatch()..start();
    Object? lastError;
    while (stopwatch.elapsed < const Duration(seconds: 10)) {
      try {
        await _webdriverRequest('GET', '/status');
        return;
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    throw StateError('safaridriver did not become ready: $lastError');
  }

  static Future<String> _createSession() async {
    final Map<String, dynamic> response = await _webdriverRequest(
      'POST',
      '/session',
      body: <String, dynamic>{
        'capabilities': <String, dynamic>{
          'alwaysMatch': <String, dynamic>{'browserName': 'safari'},
        },
      },
    );
    final value = response['value'] as Map<String, dynamic>;
    return value['sessionId'] as String;
  }

  Future<void> _navigate(String url) async {
    await _webdriverRequest(
      'POST',
      '/session/$_sessionId/url',
      body: <String, dynamic>{'url': url},
    );
  }

  static Future<Map<String, dynamic>> _webdriverRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Uri uri = Uri.parse('http://localhost:$safariDriverPort$path');
    final client = io.HttpClient();
    try {
      final io.HttpClientRequest request = await client.openUrl(method, uri);
      request.headers.contentType = io.ContentType.json;
      if (body != null) {
        request.write(json.encode(body));
      }
      final io.HttpClientResponse response = await request.close();
      final String responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw io.HttpException(
          'WebDriver $method $path failed with ${response.statusCode}: $responseBody',
          uri: uri,
        );
      }
      if (responseBody.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}

String _findSafariDriverExecutable() {
  const candidates = <String>[
    '/usr/bin/safaridriver',
    '/System/Cryptexes/App/usr/bin/safaridriver',
  ];
  for (final candidate in candidates) {
    if (io.File(candidate).existsSync()) {
      return candidate;
    }
  }
  return 'safaridriver';
}

Handler createBuildDirectoryHandler(String buildDirectoryPath) {
  final Handler childHandler = createStaticHandler(buildDirectoryPath);
  return (Request request) async {
    final Response response = await childHandler(request);
    final String? mimeType = response.mimeType;

    // Provide COOP/COEP headers so that the browser loads the page as
    // crossOriginIsolated. This will make sure that we get high-resolution
    // timers for our benchmark measurements.
    if (mimeType == 'text/html' || mimeType == 'text/javascript') {
      return response.change(
        headers: <String, String>{
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        },
      );
    } else {
      return response;
    }
  };
}
