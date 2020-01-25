// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<void> main() async {
  await task(_runWebBenchmark);
}

/// List of benchmarks we want to run in the devicelab.
const List<String> benchmarks = <String>[
  'draw_rect',
  'text_out_of_picture_bounds',
  'bench_simple_lazy_text_scroll',
];

Future<TaskResult> _runWebBenchmark() async {
  final String macrobenchmarksDirectory = path.join('${flutterDirectory.path}', 'dev', 'benchmarks', 'macrobenchmarks');
  return await inDirectory(macrobenchmarksDirectory, () async {
    final Map<String, dynamic> taskResult = <String, dynamic>{};
    final List<String> benchmarkScoreKeys = <String>[];
    await _runBenchmarksForBackend(taskResult, benchmarkScoreKeys, false);
    await _runBenchmarksForBackend(taskResult, benchmarkScoreKeys, true);
    return TaskResult.success(taskResult, benchmarkScoreKeys: benchmarkScoreKeys);
  });
}

Future<void> _runBenchmarksForBackend(Map<String, dynamic> taskResult, List<String> benchmarkScoreKeys, bool useSkiaBackend) async {
    final String macrobenchmarksDirectory = path.join('${flutterDirectory.path}', 'dev', 'benchmarks', 'macrobenchmarks');
    await evalFlutter('build', options: <String>[
      'web',
      if (useSkiaBackend)
        '--dart-define=FLUTTER_WEB_USE_SKIA=true',
      '--release',
      '-t',
      'lib/web_benchmarks.dart',
    ]);
    final String backend = useSkiaBackend ? 'skia' : 'html';
    final Completer<List<String>> profileData = Completer<List<String>>();
    final Iterator<String> benchmarkIterator = benchmarks.iterator;
    final List<String> collectedProfiles = <String>[];

    Cascade cascade = Cascade();
    cascade = cascade.add((Request request) async {
      if (request.requestedUri.path.endsWith('/profile-data')) {
        collectedProfiles.add(await request.readAsString());
        return Response.ok('Profile received');
      } else if (request.requestedUri.path.endsWith('/next-benchmark')) {
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

    final io.HttpServer server = await io.HttpServer.bind('localhost', 8080);
    try {
      shelf_io.serveRequests(server, cascade.handler);

      final bool isChromeNoSandbox =
          io.Platform.environment['CHROME_NO_SANDBOX'] == 'true';

      final String dartToolDirectory = path.join('$macrobenchmarksDirectory/.dart_tool');
      final String userDataDir = io.Directory(dartToolDirectory).createTempSync('chrome_user_data_').path;
      final List<String> args = <String>[
        '--user-data-dir=$userDataDir',
        'http://localhost:8080/index.html',
        // '--headless',
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
        // '--remote-debugging-port=$kDevtoolsPort',
      ];

      final io.Process process = await io.Process.start(
        _findSystemChromeExecutable(),
        args,
        workingDirectory: cwd,
      );

      print('Waiting for the benchmark to report benchmark profile.');

      for (final String profileJson in await profileData.future) {
        final Map<String, dynamic> profile = json.decode(profileJson) as Map<String, dynamic>;
        final String benchmarkName = profile['name'] as String;
        taskResult['$benchmarkName.$backend.averageDrawFrameDuration'] = profile['averageDrawFrameDuration'].toDouble(); // micros
        taskResult['$benchmarkName.$backend.drawFrameDurationNoise'] = profile['drawFrameDurationNoise'].toDouble(); // micros
        benchmarkScoreKeys.add('$benchmarkName.$backend.averageDrawFrameDuration');
      }

      process.kill();
    } finally {
      server.close();
    }
}

String _findSystemChromeExecutable() {
  final io.ProcessResult which =
      io.Process.runSync('which', <String>['google-chrome']);

  if (which.exitCode != 0) {
    throw Exception('Failed to locate system Chrome installation.');
  }

  return (which.stdout as String).trim();
}
