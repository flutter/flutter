// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import 'package:flutter_devicelab/framework/browser.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// The port number used by the local benchmark server.
const int benchmarkServerPort = 9999;
const int chromeDebugPort = 10000;

Future<TaskResult> runWebBenchmark({ @required bool useCanvasKit }) async {
  // Reduce logging level. Otherwise, package:webkit_inspection_protocol is way too spammy.
  Logger.root.level = Level.INFO;
  final String macrobenchmarksDirectory = path.join(flutterDirectory.path, 'dev', 'benchmarks', 'macrobenchmarks');
  return inDirectory(macrobenchmarksDirectory, () async {
    await evalFlutter('build', options: <String>[
      'web',
      '--dart-define=FLUTTER_WEB_ENABLE_PROFILING=true',
      '--web-renderer=${useCanvasKit ? 'canvaskit' : 'html'}',
      '--profile',
      '-t',
      'lib/web_benchmarks.dart',
    ]);
    final Completer<List<Map<String, dynamic>>> profileData = Completer<List<Map<String, dynamic>>>();
    final List<Map<String, dynamic>> collectedProfiles = <Map<String, dynamic>>[];
    List<String> benchmarks;
    Iterator<String> benchmarkIterator;

    // This future fixes a race condition between the web-page loading and
    // asking to run a benchmark, and us connecting to Chrome's DevTools port.
    // Sometime one wins. Other times, the other wins.
    Future<Chrome> whenChromeIsReady;
    Chrome chrome;
    io.HttpServer server;
    Cascade cascade = Cascade();
    List<Map<String, dynamic>> latestPerformanceTrace;
    cascade = cascade.add((Request request) async {
      try {
        chrome ??= await whenChromeIsReady;
        if (request.requestedUri.path.endsWith('/profile-data')) {
          final Map<String, dynamic> profile = json.decode(await request.readAsString()) as Map<String, dynamic>;
          final String benchmarkName = profile['name'] as String;
          if (benchmarkName != benchmarkIterator.current) {
            profileData.completeError(Exception(
              'Browser returned benchmark results from a wrong benchmark.\n'
              'Requested to run bechmark ${benchmarkIterator.current}, but '
              'got results for $benchmarkName.',
            ));
            server.close();
          }

          // Trace data is null when the benchmark is not frame-based, such as RawRecorder.
          if (latestPerformanceTrace != null) {
            final BlinkTraceSummary traceSummary = BlinkTraceSummary.fromJson(latestPerformanceTrace);
            profile['totalUiFrame.average'] = traceSummary.averageTotalUIFrameTime.inMicroseconds;
            profile['scoreKeys'] ??= <dynamic>[]; // using dynamic for consistency with JSON
            profile['scoreKeys'].add('totalUiFrame.average');
            latestPerformanceTrace = null;
          }
          collectedProfiles.add(profile);
          return Response.ok('Profile received');
        } else if (request.requestedUri.path.endsWith('/start-performance-tracing')) {
          latestPerformanceTrace = null;
          await chrome.beginRecordingPerformance(request.requestedUri.queryParameters['label']);
          return Response.ok('Started performance tracing');
        } else if (request.requestedUri.path.endsWith('/stop-performance-tracing')) {
          latestPerformanceTrace = await chrome.endRecordingPerformance();
          return Response.ok('Stopped performance tracing');
        } else if (request.requestedUri.path.endsWith('/on-error')) {
          final Map<String, dynamic> errorDetails = json.decode(await request.readAsString()) as Map<String, dynamic>;
          server.close();
          // Keep the stack trace as a string. It's thrown in the browser, not this Dart VM.
          profileData.completeError('${errorDetails['error']}\n${errorDetails['stackTrace']}');
          return Response.ok('');
        } else if (request.requestedUri.path.endsWith('/next-benchmark')) {
          if (benchmarks == null) {
            benchmarks = (json.decode(await request.readAsString()) as List<dynamic>).cast<String>();
            benchmarkIterator = benchmarks.iterator;
          }
          if (benchmarkIterator.moveNext()) {
            final String nextBenchmark = benchmarkIterator.current;
            print('Launching benchmark "$nextBenchmark"');
            return Response.ok(nextBenchmark);
          } else {
            profileData.complete(collectedProfiles);
            return Response.notFound('Finished running benchmarks.');
          }
        } else if (request.requestedUri.path.endsWith('/print-to-console')) {
          // A passthrough used by
          // `dev/benchmarks/macrobenchmarks/lib/web_benchmarks.dart`
          // to print information.
          final String message = await request.readAsString();
          print('[APP] $message');
          return Response.ok('Reported.');
        } else {
          return Response.notFound(
              'This request is not handled by the profile-data handler.');
        }
      } catch (error, stackTrace) {
        profileData.completeError(error, stackTrace);
        return Response.internalServerError(body: '$error');
      }
    }).add(createStaticHandler(
      path.join(macrobenchmarksDirectory, 'build', 'web'),
    ));

    server = await io.HttpServer.bind('localhost', benchmarkServerPort);
    try {
      shelf_io.serveRequests(server, cascade.handler);

      final String dartToolDirectory = path.join('$macrobenchmarksDirectory/.dart_tool');
      final String userDataDir = io.Directory(dartToolDirectory).createTempSync('chrome_user_data_').path;

      // TODO(yjbanov): temporarily disables headful Chrome until we get
      //                devicelab hardware that is able to run it. Our current
      //                GCE VMs can only run in headless mode.
      //                See: https://github.com/flutter/flutter/issues/50164
      final bool isUncalibratedSmokeTest = io.Platform.environment['CALIBRATED'] != 'true';
      // final bool isUncalibratedSmokeTest =
      //     io.Platform.environment['UNCALIBRATED_SMOKE_TEST'] == 'true';
      final ChromeOptions options = ChromeOptions(
        url: 'http://localhost:$benchmarkServerPort/index.html',
        userDataDirectory: userDataDir,
        windowHeight: 1024,
        windowWidth: 1024,
        headless: isUncalibratedSmokeTest,
        debugPort: chromeDebugPort,
      );

      print('Launching Chrome.');
      whenChromeIsReady = Chrome.launch(
        options,
        onError: (String error) {
          profileData.completeError(Exception(error));
        },
        workingDirectory: cwd,
      );

      print('Waiting for the benchmark to report benchmark profile.');
      final String backend = useCanvasKit ? 'canvaskit' : 'html';
      final Map<String, dynamic> taskResult = <String, dynamic>{};
      final List<String> benchmarkScoreKeys = <String>[];
      final List<Map<String, dynamic>> profiles = await profileData.future;

      print('Received profile data');
      for (final Map<String, dynamic> profile in profiles) {
        final String benchmarkName = profile['name'] as String;
        if (benchmarkName.isEmpty) {
          throw 'Benchmark name is empty';
        }

        final String namespace = '$benchmarkName.$backend';
        final List<String> scoreKeys = List<String>.from(profile['scoreKeys'] as List<dynamic>);
        if (scoreKeys == null || scoreKeys.isEmpty) {
          throw 'No score keys in benchmark "$benchmarkName"';
        }
        for (final String scoreKey in scoreKeys) {
          if (scoreKey == null || scoreKey.isEmpty) {
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
      server?.close();
      chrome?.stop();
    }
  });
}
