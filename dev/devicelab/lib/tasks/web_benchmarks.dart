// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json, utf8;
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../framework/browser.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';
import 'web_benchmarks_comparison.dart';

/// The port at which the local benchmark server is served.
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

/// Deletes a directory with retry logic to handle file locks on various platforms.
Future<void> deleteDirectoryWithRetry(
  io.Directory dir, {
  int maxAttempts = 10,
  Duration delay = const Duration(milliseconds: 500),
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      return;
    } on io.FileSystemException catch (e) {
      if (attempt == maxAttempts) {
        print('Warning: Failed to delete directory ${dir.path} after $maxAttempts attempts: $e');
      } else {
        await Future<void>.delayed(delay);
      }
    }
  }
}

Future<TaskResult> runWebBenchmark(
  WebBenchmarkOptions benchmarkOptions, {
  List<String>? targetBenchmarks,
  String? filterPattern,
  bool? clean,
  bool? noBuild,
  String? localWebSdk,
  String? localEngineSrcPath,
  bool? verbose,
  Map<String, String>? environment,
}) async {
  environment ??= io.Platform.environment;

  final BenchmarkFilter benchmarkFilter;
  try {
    benchmarkFilter = BenchmarkFilter.parse(
      targetBenchmarks: targetBenchmarks,
      filterPattern: filterPattern,
      environment: environment,
    );
  } on Exception catch (e) {
    return TaskResult.failure(e.toString());
  }

  final bool effectiveNoBuild = noBuild ?? false;
  final bool effectiveVerbose = verbose ?? false;
  final bool effectiveClean =
      !effectiveNoBuild && (clean ?? environment['BENCHMARK_CLEAN']?.toLowerCase() != 'false');

  if (!effectiveVerbose) {
    // Reduce logging level. Otherwise, package:webkit_inspection_protocol is way too spammy.
    Logger.root.level = Level.INFO;
  }
  final String macrobenchmarksDirectory = path.join(
    flutterDirectory.path,
    'dev',
    'benchmarks',
    'macrobenchmarks',
  );

  io.HttpServer? server;
  Chrome? chrome;
  Future<Chrome>? whenChromeIsReady;
  io.Process? flutterRunProcess;
  String? userDataDir;

  var isCleaningUp = false;
  final cleanupCompleter = Completer<void>();

  Future<void> performCleanup() async {
    if (isCleaningUp) {
      return cleanupCompleter.future;
    }
    isCleaningUp = true;
    try {
      // 1. Close Shelf server
      try {
        await server?.close(force: true);
      } catch (e) {
        print('Warning: Error closing server: $e');
      }

      // 2. Stop or disconnect Chrome (in DDC mode Chrome is managed by flutterRunProcess)
      void cleanChrome(Chrome c) {
        if (benchmarkOptions.useDdc) {
          c.disconnect();
        } else {
          c.stop();
        }
      }

      final currentChrome = chrome;
      final readyFuture = whenChromeIsReady;
      if (currentChrome != null) {
        try {
          cleanChrome(currentChrome);
        } catch (e) {
          final action = benchmarkOptions.useDdc ? 'disconnecting' : 'stopping';
          print('Warning: Error $action Chrome: $e');
        }
      } else if (readyFuture != null) {
        try {
          var cleanedUp = false;
          unawaited(
            readyFuture.then((Chrome readyChrome) {
              if (!cleanedUp) {
                cleanedUp = true;
                cleanChrome(readyChrome);
              }
            }, onError: (_) {}),
          );

          final Chrome readyChrome = await readyFuture.timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Chrome ready timeout during cleanup'),
          );
          if (!cleanedUp) {
            cleanedUp = true;
            cleanChrome(readyChrome);
          }
        } catch (e) {
          final action = benchmarkOptions.useDdc ? 'disconnecting' : 'stopping';
          print('Warning: Error $action Chrome: $e');
        }
      }

      // 3. Stop flutter run process if present
      final process = flutterRunProcess;
      if (process != null) {
        try {
          process.stdin.write('q');
          await process.stdin.flush();
        } catch (_) {
          // Stdin pipe may already be closed if Chrome process was killed
        }
        await process.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            process.kill();
            return 0;
          },
        );
      }

      // 4. Clean up temporary directory
      final dirPath = userDataDir;
      if (dirPath != null) {
        await deleteDirectoryWithRetry(io.Directory(dirPath));
      }
    } finally {
      cleanupCompleter.complete();
    }
  }

  StreamSubscription<io.ProcessSignal>? sigintSub;
  StreamSubscription<io.ProcessSignal>? sigtermSub;

  try {
    sigintSub = io.ProcessSignal.sigint.watch().listen((io.ProcessSignal signal) async {
      print('\nReceived SIGINT. Cleaning up benchmark processes and temporary directories...');
      await performCleanup();
      io.exit(130);
    });
  } catch (e) {
    print('Warning: Unable to watch SIGINT signal: $e');
  }

  if (!io.Platform.isWindows) {
    try {
      sigtermSub = io.ProcessSignal.sigterm.watch().listen((io.ProcessSignal signal) async {
        print('\nReceived SIGTERM. Cleaning up benchmark processes and temporary directories...');
        await performCleanup();
        io.exit(143);
      });
    } catch (e) {
      print('Warning: Unable to watch SIGTERM signal: $e');
    }
  }

  try {
    return await inDirectory(macrobenchmarksDirectory, () async {
      if (effectiveClean) {
        await flutter('clean');
      }

      server = await io.HttpServer.bind('localhost', benchmarkServerPort);

      // DDC runs the benchmarks suite with 'flutter run', attaching to its
      // Chrome instance instead of starting a new one.
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
            '--web-browser-flag=--disable-background-networking',
            '--web-browser-flag=--disable-sync',
            '--web-browser-flag=--disable-client-side-phishing-detection',
            '--web-browser-flag=--disable-notifications',
            ...kGcmDisabledFlags.map((String flag) => '--web-browser-flag=$flag'),
            '--web-browser-flag=--headless=new',
            '--web-browser-flag=--no-sandbox',
            '--web-browser-flag=--password-store=basic',
            if (io.Platform.isMacOS) '--web-browser-flag=--use-mock-keychain',
            '--dart-define=FLUTTER_WEB_ENABLE_PROFILING=true',
            '--dart-define=BENCHMARK_SERVER_PORT=${server!.port}',
            if (!benchmarkOptions.withHotReload) '--no-web-experimental-hot-reload',
            '--no-web-resources-cdn',
            '-t',
            'lib/web_benchmarks.dart',
          ],
        );
        flutterRunProcess!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
          String line,
        ) {
          if (!ddcAppReady.isCompleted && line.startsWith('Debug service listening on')) {
            ddcAppReady.complete();
          }
          print('[CHROME STDOUT]: $line');
        });
        flutterRunProcess!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
          String line,
        ) {
          print('[CHROME STDERR]: $line');
        });
        // Wait for the app to load in DDC's Chrome instance before trying to
        // connect the debugger.
        await ddcAppReady.future;
      } else if (!effectiveNoBuild) {
        await evalFlutter(
          'build',
          options: <String>[
            'web',
            '--no-tree-shake-icons', // local engine builds are frequently out of sync with the Dart Kernel version
            if (benchmarkOptions.useWasm) ...<String>['--wasm', '--no-strip-wasm'],
            '--dart-define=FLUTTER_WEB_ENABLE_PROFILING=true',
            '--${benchmarkOptions.buildMode}',
            '--no-web-resources-cdn',
            if (localWebSdk != null) '--local-web-sdk=$localWebSdk',
            if (localEngineSrcPath != null) '--local-engine-src-path=$localEngineSrcPath',
            '-t',
            'lib/web_benchmarks.dart',
          ],
        );
      }
      final profileData = Completer<List<Map<String, dynamic>>>();
      final collectedProfiles = <Map<String, dynamic>>[];
      List<String>? benchmarks;
      late Iterator<String> benchmarkIterator;

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
              if (!profileData.isCompleted) {
                profileData.completeError(
                  Exception(
                    'Browser returned benchmark results from a wrong benchmark.\n'
                    'Requested to run benchmark ${benchmarkIterator.current}, but '
                    'got results for $benchmarkName.',
                  ),
                );
              }
              unawaited(server!.close());
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
            unawaited(server!.close());
            // Keep the stack trace as a string. It's thrown in the browser, not this Dart VM.
            if (!profileData.isCompleted) {
              profileData.completeError('${errorDetails['error']}\n${errorDetails['stackTrace']}');
            }
            return Response.ok('', headers: requestHeaders);
          } else if (request.requestedUri.path.endsWith('/next-benchmark')) {
            if (benchmarks == null) {
              try {
                final List<String> allBenchmarks = (json.decode(requestContents) as List<Object?>)
                    .cast<String>();
                benchmarks = benchmarkFilter.filter(allBenchmarks);
                benchmarkIterator = benchmarks!.iterator;
              } catch (e, stackTrace) {
                final String errorMessage = e is FormatException ? e.message : e.toString();
                print('[ERROR] $errorMessage');
                if (!profileData.isCompleted) {
                  profileData.completeError(e, stackTrace);
                }
                // Do NOT call server.close() here; let outer cleanup handle server shutdown.
                return Response.internalServerError(body: errorMessage, headers: requestHeaders);
              }
            }
            if (benchmarkIterator.moveNext()) {
              final String nextBenchmark = benchmarkIterator.current;
              // The page reloads as soon as it receives the next benchmark
              // name. Collect the previous benchmarks' detached documents first
              // so their /dev/shm segments do not accumulate across reloads
              // (see Chrome.collectGarbage).
              await chrome!.collectGarbage();
              print('Launching benchmark "$nextBenchmark"');
              return Response.ok(nextBenchmark, headers: requestHeaders);
            } else {
              if (!profileData.isCompleted) {
                profileData.complete(collectedProfiles);
              }
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
          if (!profileData.isCompleted) {
            profileData.completeError(error, stackTrace);
          }
          return Response.internalServerError(body: '$error', headers: requestHeaders);
        }
      });
      // Macrobenchmarks using 'flutter build' serve files from their local build directory alongside the orchestration logic.
      if (!benchmarkOptions.useDdc) {
        cascade = cascade.add(
          createBuildDirectoryHandler(path.join(macrobenchmarksDirectory, 'build', 'web')),
        );
      }

      shelf_io.serveRequests(server!, cascade.handler);

      final String dartToolDirectory = path.join(macrobenchmarksDirectory, '.dart_tool');
      final dartToolDir = io.Directory(dartToolDirectory);
      if (!dartToolDir.existsSync()) {
        dartToolDir.createSync(recursive: true);
      }
      userDataDir = dartToolDir.createTempSync('flutter_chrome_user_data.').path;

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
            if (!profileData.isCompleted) {
              profileData.completeError(Exception(error));
            }
          },
          workingDirectory: cwd,
        );
      } else {
        whenChromeIsReady = Chrome.launch(
          options,
          onError: (String error) {
            if (!profileData.isCompleted) {
              profileData.completeError(Exception(error));
            }
          },
          workingDirectory: cwd,
        );
      }
      unawaited(whenChromeIsReady?.then((Chrome c) => chrome = c, onError: (_) {}));

      print('Waiting for the benchmark to report benchmark profile.');
      final List<Map<String, Object?>> profiles;
      try {
        profiles = await profileData.future;
      } catch (e) {
        return TaskResult.failure(e.toString());
      }
      return processBenchmarkProfiles(profiles, benchmarkOptions);
    });
  } finally {
    await sigintSub?.cancel();
    await sigtermSub?.cancel();
    await performCleanup();
  }
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

/// Standard curated fast smoke-test benchmarks.
const List<String> kSmokeTestBenchmarks = <String>['draw_rect', 'bench_card_infinite_scroll'];

/// Filters benchmarks based on an exact list of targets or a regular expression pattern.
///
/// If [targetBenchmarks] is provided, only the exact benchmarks listed will be run. If
/// [targetBenchmarks] is null, all benchmarks are considered candidates (unless further filtered).
/// If a filter pattern is provided, it is parsed as a [RegExp] and only benchmarks matching
/// the pattern will be run.
///
/// Target benchmarks and a filter pattern are mutually exclusive. Specifying both (whether
/// through arguments, environment variables, or a mix of the two) throws an [Exception]
/// instead of combining them.
///
/// Example target lists: `['scroll_perf', 'build_perf']`
/// Example filter patterns: `skwasm` (matches any benchmark name containing 'skwasm'),
/// `^scroll_` (matches names starting with 'scroll_').
class BenchmarkFilter {
  /// Creates a filter from already-parsed values.
  ///
  /// Throws an [Exception] if both [targetBenchmarks] (after trimming and dropping empty
  /// entries) and [compiledFilter] are provided.
  BenchmarkFilter({List<String>? targetBenchmarks, this.compiledFilter})
    : targetBenchmarks = _parseTargetBenchmarks(targetBenchmarks) {
    if (this.targetBenchmarks != null && compiledFilter != null) {
      throw _targetsAndFilterConflict(this.targetBenchmarks!, compiledFilter!.pattern);
    }
  }

  /// Creates a filter from raw arguments, falling back to the environment.
  ///
  /// [targetBenchmarks] falls back to the comma-separated `BENCHMARK_TARGETS` environment
  /// variable, and [filterPattern] falls back to the `BENCHMARK_FILTER` environment variable.
  /// Empty values are treated as unset.
  ///
  /// Throws an [Exception] if both target benchmarks and a filter pattern end up specified
  /// (from arguments, environment variables, or one of each), or if the filter pattern is not
  /// a valid regular expression.
  factory BenchmarkFilter.parse({
    List<String>? targetBenchmarks,
    String? filterPattern,
    Map<String, String>? environment,
  }) {
    environment ??= const <String, String>{};
    final List<String>? effectiveTargets = _parseTargetBenchmarks(
      targetBenchmarks ?? environment['BENCHMARK_TARGETS']?.split(','),
    );
    final String? rawFilterPattern = filterPattern ?? environment['BENCHMARK_FILTER'];
    final String? effectiveFilterPattern = (rawFilterPattern?.isEmpty ?? true)
        ? null
        : rawFilterPattern;

    if (effectiveTargets != null && effectiveFilterPattern != null) {
      throw _targetsAndFilterConflict(effectiveTargets, effectiveFilterPattern);
    }

    RegExp? compiledFilter;
    if (effectiveFilterPattern != null) {
      try {
        compiledFilter = RegExp(effectiveFilterPattern);
      } on FormatException catch (e) {
        throw Exception('Invalid filterPattern "$effectiveFilterPattern": ${e.message}');
      }
    }

    return BenchmarkFilter(targetBenchmarks: effectiveTargets, compiledFilter: compiledFilter);
  }

  final List<String>? targetBenchmarks;
  final RegExp? compiledFilter;

  static Exception _targetsAndFilterConflict(List<String> targets, String pattern) {
    return Exception(
      'Cannot combine target benchmarks with a filter pattern; specify only one.\n'
      '  Target benchmarks (--benchmark / BENCHMARK_TARGETS): [${targets.join(', ')}]\n'
      '  Filter pattern (--filter / BENCHMARK_FILTER): "$pattern"',
    );
  }

  List<String> filter(List<String> allBenchmarks) {
    final Set<String> availableSet = allBenchmarks.toSet();

    Iterable<String> filtered = allBenchmarks;
    // Strict validation: fail fast if ANY target benchmark is missing/misspelled
    if (targetBenchmarks != null && targetBenchmarks!.isNotEmpty) {
      final Set<String> targetSet = targetBenchmarks!.toSet();
      final Set<String> missing = targetSet.difference(availableSet);
      if (missing.isNotEmpty) {
        throw Exception(
          'Unrecognized target benchmark(s): [${missing.join(', ')}].\n'
          'Available benchmarks: [${allBenchmarks.join(', ')}]',
        );
      }
      filtered = targetSet;
    } else if (compiledFilter != null) {
      filtered = filtered.where(compiledFilter!.hasMatch);
    }

    final List<String> result = filtered.toList();
    if (result.isEmpty) {
      throw Exception(
        'No benchmarks matched the requested filter.\n'
        '  Target benchmarks: $targetBenchmarks\n'
        '  Filter pattern: ${compiledFilter?.pattern}\n'
        '  Available benchmarks: [${allBenchmarks.join(', ')}]',
      );
    }
    return result;
  }
}

/// Parses a list of target benchmarks from an iterable of strings.
/// Splits comma-separated values, trims whitespace, and removes empty strings.
List<String>? _parseTargetBenchmarks(Iterable<String>? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final List<String> result = raw
      .expand((String b) => b.split(','))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();
  return result.isEmpty ? null : result;
}

TaskResult processBenchmarkProfiles(
  List<Map<String, Object?>> profiles,
  WebBenchmarkOptions benchmarkOptions,
) {
  if (profiles.isEmpty) {
    return TaskResult.failure('No benchmark profiles were collected.');
  }

  final taskResult = <String, Object?>{};
  final benchmarkScoreKeys = <String>[];

  for (final profile in profiles) {
    final Object? nameValue = profile['name'];
    final String? benchmarkName = nameValue is String ? nameValue : null;
    if (benchmarkName == null || benchmarkName.isEmpty) {
      return TaskResult.failure('Benchmark name is empty');
    }

    final String webRendererName;
    if (benchmarkOptions.useWasm) {
      webRendererName = benchmarkOptions.forceSingleThreadedSkwasm ? 'skwasm_st' : 'skwasm';
    } else {
      webRendererName = 'canvaskit';
    }
    final namespace = '$benchmarkName.$webRendererName';
    final Object? rawScoreKeys = profile['scoreKeys'];
    final List<String> scoreKeys = rawScoreKeys is List<Object?>
        ? rawScoreKeys.whereType<String>().toList()
        : <String>[];
    if (scoreKeys.isEmpty) {
      return TaskResult.failure('No metrics in benchmark "$benchmarkName"');
    }
    for (final scoreKey in scoreKeys) {
      if (scoreKey.isEmpty) {
        return TaskResult.failure('Received an empty metric name in benchmark "$benchmarkName".');
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
}

Future<TaskResult> runWebBenchmarkFromArgs(
  WebBenchmarkOptions options,
  List<String> rawArgs,
) async {
  final argParser = ArgParser()
    ..addMultiOption(
      'benchmark',
      help:
          'Target benchmark names to run (comma-separated or multiple flags). '
          'Cannot be combined with --filter.',
    )
    ..addOption(
      'filter',
      help: 'Regex pattern to filter benchmark names. Cannot be combined with --benchmark.',
    )
    ..addFlag('clean', defaultsTo: true, help: 'Whether to run flutter clean before building');

  // Report unknown flags as a task failure.
  final ArgResults args;
  try {
    args = argParser.parse(rawArgs);
  } on ArgParserException catch (e) {
    return TaskResult.failure(e.message);
  }

  final rawBenchmarks = args['benchmark'] as List<String>?;
  final List<String>? targetBenchmarks = _parseTargetBenchmarks(rawBenchmarks);

  final filterPattern = args['filter'] as String?;
  final bool? clean = args.wasParsed('clean') ? args['clean'] as bool : null;

  return runWebBenchmark(
    options,
    targetBenchmarks: targetBenchmarks,
    filterPattern: filterPattern,
    clean: clean,
  );
}

/// Builds the argument parser for the standalone local web benchmark runner
/// (`bin/run_local_web_benchmark.dart`).
ArgParser buildBenchmarkArgParser() {
  return ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this help message.')
    ..addMultiOption(
      'benchmark',
      help:
          'Target benchmark names to run (comma-separated or multiple flags). '
          'Cannot be combined with --smoke-test or --filter.',
    )
    ..addFlag(
      'smoke-test',
      negatable: false,
      help:
          'Run the curated fast smoke-test benchmarks (${kSmokeTestBenchmarks.join(', ')}). '
          'Cannot be combined with --benchmark or --filter.',
    )
    ..addOption(
      'filter',
      help:
          'Regex pattern to filter benchmark names. '
          'Cannot be combined with --benchmark or --smoke-test.',
    )
    ..addOption('baseline', help: 'Path to a baseline JSON results file to compare against.')
    ..addOption('results-file', help: 'Path where the JSON benchmark results will be written.')
    ..addOption(
      'renderer',
      allowed: <String>['canvaskit', 'skwasm', 'skwasm_st'],
      defaultsTo: 'canvaskit',
      help: 'Web renderer to use.',
    )
    ..addOption(
      'regression-threshold',
      help:
          'Percentage regression threshold (e.g. 5.0 for 5%). Requires --baseline. '
          'Fails with exit code 1 if exceeded.',
    )
    ..addFlag(
      'clean',
      negatable: false,
      help: 'Run flutter clean before compiling (defaults to false for fast local iteration).',
    )
    ..addFlag(
      'no-build',
      negatable: false,
      help: 'Skip compilation and reuse the existing build artifacts.',
    )
    ..addOption('local-engine-src-path', help: 'Path to a local engine src directory.')
    ..addOption(
      'local-web-sdk',
      help: 'Local engine web SDK build to compile against (e.g. wasm_release).',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging and Chrome stdout.',
    );
}

/// Runs the standalone local web benchmark CLI with [rawArgs] and returns the
/// process exit code:
///
///  * 0: success.
///  * 1: one or more metrics exceeded `--regression-threshold`.
///  * 2: usage error (invalid flags, unreadable baseline, missing build
///    artifacts, unwritable results file, or no metrics to compare).
///  * 3: benchmark or infrastructure failure.
Future<int> runBenchmarkCli(List<String> rawArgs) async {
  void printError(String message) => io.stderr.writeln(message);

  final ArgParser parser = buildBenchmarkArgParser();
  final ArgResults args;
  try {
    args = parser.parse(rawArgs);
  } on ArgParserException catch (e) {
    printError('${e.message}\n\nUsage:\n${parser.usage}');
    return 2;
  }

  if (args['help'] as bool) {
    print('Usage:\n${parser.usage}');
    return 0;
  }

  final smokeTest = args['smoke-test'] as bool;
  final List<String>? benchmarks = _parseTargetBenchmarks(args['benchmark'] as List<String>);
  if (args.wasParsed('benchmark') && benchmarks == null) {
    printError('--benchmark cannot be empty.');
    return 2;
  }
  if (benchmarks != null && smokeTest) {
    printError('Cannot use --benchmark and --smoke-test together.');
    return 2;
  }
  final List<String>? targetBenchmarks = smokeTest ? kSmokeTestBenchmarks : benchmarks;
  final filterPattern = args['filter'] as String?;
  try {
    // Validate the selectors upfront so that mistakes are reported before
    // anything is built.
    BenchmarkFilter.parse(targetBenchmarks: targetBenchmarks, filterPattern: filterPattern);
  } on Exception catch (e) {
    printError('$e');
    return 2;
  }

  // Resolve user-provided paths against the original working directory, since
  // the working directory is switched to dev/devicelab before running.
  final String initialCwd = io.Directory.current.path;
  String? absolutePath(String? value) => value == null ? null : path.absolute(value);
  final String? baselinePath = absolutePath(args['baseline'] as String?);
  final String? resultsPath = absolutePath(args['results-file'] as String?);
  final String? localEngineSrcPath = absolutePath(args['local-engine-src-path'] as String?);
  final localWebSdk = args['local-web-sdk'] as String?;

  if (baselinePath != null &&
      resultsPath != null &&
      path.canonicalize(baselinePath) == path.canonicalize(resultsPath)) {
    printError('--baseline and --results-file cannot be the same file.');
    return 2;
  }

  final noBuild = args['no-build'] as bool;
  final clean = args['clean'] as bool;
  if (clean && noBuild) {
    printError('Cannot use --clean and --no-build together.');
    return 2;
  }

  if (localEngineSrcPath != null && localWebSdk == null) {
    printError('--local-engine-src-path requires --local-web-sdk.');
    return 2;
  }

  final regressionThresholdArg = args['regression-threshold'] as String?;
  double? regressionThreshold;
  if (regressionThresholdArg != null) {
    if (baselinePath == null) {
      printError('--regression-threshold requires --baseline.');
      return 2;
    }
    regressionThreshold = double.tryParse(regressionThresholdArg);
    if (regressionThreshold == null || regressionThreshold < 0 || !regressionThreshold.isFinite) {
      printError('--regression-threshold must be a non-negative number.');
      return 2;
    }
  }

  Map<String, dynamic>? baseline;
  if (baselinePath != null) {
    try {
      final Object? decoded = json.decode(io.File(baselinePath).readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object mapping metric names to values.');
      }
      baseline = decoded;
    } on Exception catch (e) {
      printError('Failed to read baseline file $baselinePath: $e');
      return 2;
    }
  }

  final String? flutterRootEnv = io.Platform.environment['FLUTTER_ROOT'];
  final String flutterRoot;
  if (flutterRootEnv != null && flutterRootEnv.isNotEmpty) {
    flutterRoot = flutterRootEnv;
  } else if (io.Directory(path.join(initialCwd, 'dev', 'devicelab')).existsSync()) {
    flutterRoot = initialCwd;
  } else {
    flutterRoot = flutterDirectory.path;
  }

  final renderer = args['renderer'] as String;
  final bool useWasm = renderer == 'skwasm' || renderer == 'skwasm_st';
  if (noBuild) {
    final String artifactPath = path.join(
      flutterRoot,
      'dev',
      'benchmarks',
      'macrobenchmarks',
      'build',
      'web',
      useWasm ? 'main.dart.wasm' : 'main.dart.js',
    );
    if (!io.File(artifactPath).existsSync()) {
      printError(
        'Build artifacts for renderer "$renderer" were not found (expected $artifactPath). '
        'Run without --no-build to build them.',
      );
      return 2;
    }
  }

  final verbose = args['verbose'] as bool;
  StreamSubscription<LogRecord>? logSubscription;
  if (verbose) {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen((LogRecord record) {
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });
  }

  try {
    // runWebBenchmark locates the macrobenchmarks app relative to
    // dev/devicelab (see flutterDirectory).
    cd(path.join(flutterRoot, 'dev', 'devicelab'));

    final TaskResult taskResult;
    try {
      taskResult = await runWebBenchmark(
        (
          useWasm: useWasm,
          forceSingleThreadedSkwasm: renderer == 'skwasm_st',
          useDdc: false,
          withHotReload: false,
          buildMode: 'profile',
        ),
        clean: clean,
        noBuild: noBuild,
        localWebSdk: localWebSdk,
        localEngineSrcPath: localEngineSrcPath,
        targetBenchmarks: targetBenchmarks,
        filterPattern: filterPattern,
        verbose: verbose,
      );
    } catch (e) {
      printError('Benchmark run failed: $e');
      return 3;
    }
    if (!taskResult.succeeded) {
      printError('Benchmark run failed: ${taskResult.message}');
      return 3;
    }
    final Map<String, dynamic>? data = taskResult.data;
    if (data == null || data.isEmpty) {
      printError('Benchmark run completed without reporting any metrics.');
      return 3;
    }

    if (resultsPath != null) {
      try {
        final resultsFile = io.File(resultsPath);
        resultsFile.parent.createSync(recursive: true);
        resultsFile.writeAsStringSync(json.encode(data));
      } on io.FileSystemException catch (e) {
        printError('Failed to write results file $resultsPath: $e');
        return 2;
      }
    }

    if (baseline == null) {
      final List<String> metricKeys =
          data.keys.where((String key) => key.endsWith('.average') && data[key] is num).toList()
            ..sort();
      for (final key in metricKeys) {
        print('$key: ${data[key]}');
      }
      return 0;
    }

    // Only compare the metrics present in both the current run and the
    // baseline, since either may have run a different set of benchmarks.
    final BenchmarkComparison comparison;
    try {
      comparison = compareResults(
        current: data,
        baseline: <String, dynamic>{
          for (final MapEntry<String, dynamic> entry in baseline.entries)
            if (data.containsKey(entry.key)) entry.key: entry.value,
        },
        regressionThreshold: regressionThreshold,
        failOnMissingBaseline: false,
      );
    } on FormatException catch (e) {
      printError('Invalid metric values for comparison: ${e.message}');
      return 2;
    }

    final bool hasOverlap = comparison.metrics.any(
      (MetricComparison metric) => metric.baseline != null && metric.current != null,
    );
    if (!hasOverlap) {
      printError('The current results and the baseline have no metrics in common.');
      return 2;
    }

    print(formatAnsiSummaryTable(comparison));
    if (comparison.hasRegressions) {
      printError(
        'FAILED: 1 or more metrics exceeded the regression threshold of $regressionThreshold%.',
      );
      return 1;
    }
    return 0;
  } finally {
    cd(initialCwd);
    await logSubscription?.cancel();
    if (verbose) {
      Logger.root.level = Level.INFO;
    }
  }
}
