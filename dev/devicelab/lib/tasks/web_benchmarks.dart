// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// The port number used by the local benchmark server.
const int benchmarkServerPort = 9999;

Future<TaskResult> runWebBenchmark({ @required bool useCanvasKit }) async {
  final String macrobenchmarksDirectory = path.join('${flutterDirectory.path}', 'dev', 'benchmarks', 'macrobenchmarks');
  return await inDirectory(macrobenchmarksDirectory, () async {
    await evalFlutter('build', options: <String>[
      'web',
      if (useCanvasKit)
        '--dart-define=FLUTTER_WEB_USE_SKIA=true',
      '--profile',
      '-t',
      'lib/web_benchmarks.dart',
    ], environment: <String, String>{
      'FLUTTER_WEB': 'true',
    });
    final Completer<List<Map<String, dynamic>>> profileData = Completer<List<Map<String, dynamic>>>();
    final List<Map<String, dynamic>> collectedProfiles = <Map<String, dynamic>>[];
    List<String> benchmarks;
    Iterator<String> benchmarkIterator;

    io.HttpServer server;
    Cascade cascade = Cascade();
    cascade = cascade.add((Request request) async {
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
        collectedProfiles.add(profile);
        return Response.ok('Profile received');
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
      } else {
        return Response.notFound(
            'This request is not handled by the profile-data handler.');
      }
    }).add(createStaticHandler(
      path.join('$macrobenchmarksDirectory', 'build', 'web'),
    ));

    server = await io.HttpServer.bind('localhost', benchmarkServerPort);
    io.Process chromeProcess;
    try {
      shelf_io.serveRequests(server, cascade.handler);

      final bool isChromeNoSandbox =
          io.Platform.environment['CHROME_NO_SANDBOX'] == 'true';

      final String dartToolDirectory = path.join('$macrobenchmarksDirectory/.dart_tool');
      final String userDataDir = io.Directory(dartToolDirectory).createTempSync('chrome_user_data_').path;
      final List<String> args = <String>[
        '--user-data-dir=$userDataDir',
        'http://localhost:$benchmarkServerPort/index.html',
        if (isChromeNoSandbox)
          '--no-sandbox',
        '--window-size=1024,1024',
        '--disable-extensions',
        '--disable-popup-blocking',
        // Indicates that the browser is in "browse without sign-in" (Guest session) mode.
        '--bwsi',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-default-apps',
        '--disable-translate',
      ];

      // TODO(yjbanov): temporarily disables headful Chrome until we get
      //                devicelab hardware that is able to run it. Our current
      //                GCE VMs can only run in headless mode.
      //                See: https://github.com/flutter/flutter/issues/50164
      final bool isUncalibratedSmokeTest = io.Platform.environment['CALIBRATED'] != 'true';
      // final bool isUncalibratedSmokeTest =
      //     io.Platform.environment['UNCALIBRATED_SMOKE_TEST'] == 'true';
      if (isUncalibratedSmokeTest) {
        print('Running in headless mode because running on uncalibrated hardware.');
        args.add('--headless');
        // When running in headless mode Chrome exits immediately unless
        // a debug port is specified.
        args.add('--remote-debugging-port=${benchmarkServerPort + 1}');
      }

      chromeProcess = await startProcess(
        _findSystemChromeExecutable(),
        args,
        workingDirectory: cwd,
      );

      bool receivedProfileData = false;
      chromeProcess.exitCode.then((int exitCode) {
        if (!receivedProfileData) {
          profileData.completeError(Exception(
            'Chrome process existed prematurely with exit code $exitCode',
          ));
        }
      });
      forwardStandardStreams(chromeProcess);

      print('Waiting for the benchmark to report benchmark profile.');

      final String backend = useCanvasKit ? 'canvaskit' : 'html';
      final Map<String, dynamic> taskResult = <String, dynamic>{};
      final List<String> benchmarkScoreKeys = <String>[];
      final List<Map<String, dynamic>> profiles = await profileData.future;
      print('Received profile data');
      receivedProfileData = true;
      for (final Map<String, dynamic> profile in profiles) {
        final String benchmarkName = profile['name'] as String;
        final String benchmarkScoreKey = '$benchmarkName.$backend.averageDrawFrameDuration';
        taskResult[benchmarkScoreKey] = profile['averageDrawFrameDuration'].toDouble(); // micros
        taskResult['$benchmarkName.$backend.drawFrameDurationNoise'] = profile['drawFrameDurationNoise'].toDouble(); // micros
        benchmarkScoreKeys.add(benchmarkScoreKey);
      }
      return TaskResult.success(taskResult, benchmarkScoreKeys: benchmarkScoreKeys);
    } finally {
      server.close();
      chromeProcess?.kill();
    }
  });
}

String _findSystemChromeExecutable() {
  // On some environments, such as the Dart HHH tester, Chrome resides in a
  // non-standard location and is provided via the following environment
  // variable.
  final String envExecutable = io.Platform.environment['CHROME_EXECUTABLE'];
  if (envExecutable != null) {
    return envExecutable;
  }

  if (io.Platform.isLinux) {
    final io.ProcessResult which =
        io.Process.runSync('which', <String>['google-chrome']);

    if (which.exitCode != 0) {
      throw Exception('Failed to locate system Chrome installation.');
    }

    return (which.stdout as String).trim();
  } else if (io.Platform.isMacOS) {
    return '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  } else {
    throw Exception('Web benchmarks cannot run on ${io.Platform.operatingSystem} yet.');
  }
}
