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

typedef WebBenchmarkOptions = ({
  bool useWasm,
  bool forceSingleThreadedSkwasm,
  bool useDdc,
  bool withHotReload,
  String buildMode,
});

Future<TaskResult> runWebBenchmark(WebBenchmarkOptions benchmarkOptions) async {
  // Reduce logging level. Otherwise, package:webkit_inspection_protocol is way too spammy.
  Logger.root.level = Level.INFO;
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
        if (line.startsWith('This app is linked to the debug service')) {
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
        chrome ??= await whenChromeIsReady;
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
          latestPerformanceTrace = null;
          await chrome!.beginRecordingPerformance(request.requestedUri.queryParameters['label']!);
          return Response.ok('Started performance tracing', headers: requestHeaders);
        } else if (request.requestedUri.path.endsWith('/stop-performance-tracing')) {
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
            benchmarks = (json.decode(requestContents) as List<dynamic>).cast<String>();
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
