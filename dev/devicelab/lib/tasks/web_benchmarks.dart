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

import 'package:flutter_devicelab/framework/browser.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// The port number used by the local benchmark server.
const int benchmarkServerPort = 9999;

Future<TaskResult> runWebBenchmark({ @required bool useCanvasKit }) async {
  final String macrobenchmarksDirectory = path.join(flutterDirectory.path, 'dev', 'benchmarks', 'macrobenchmarks');
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
      path.join(macrobenchmarksDirectory, 'build', 'web'),
    ));

    server = await io.HttpServer.bind('localhost', benchmarkServerPort);
    Chrome chrome;
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
        // When running in headless mode Chrome exits immediately unless
        // a debug port is specified.
        debugPort: isUncalibratedSmokeTest ? benchmarkServerPort + 1 : null,
      );

      print('Launching Chrome.');
      chrome = await Chrome.launch(
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
        final String benchmarkScoreKey = '$benchmarkName.$backend.averageDrawFrameDuration';
        taskResult[benchmarkScoreKey] = profile['averageDrawFrameDuration'].toDouble(); // micros
        taskResult['$benchmarkName.$backend.drawFrameDurationNoise'] = profile['drawFrameDurationNoise'].toDouble(); // micros
        benchmarkScoreKeys.add(benchmarkScoreKey);
      }
      return TaskResult.success(taskResult, benchmarkScoreKeys: benchmarkScoreKeys);
    } finally {
      server.close();
      chrome.stop();
    }
  });
}
