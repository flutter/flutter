// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// Creates a device lab task that runs benchmarks in
/// `dev/benchmarks/microbenchmarks` reports results to the dashboard.
TaskFunction createMicrobenchmarkTask() {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();

    Future<Map<String, double>> _runMicrobench(String benchmarkPath) async {
      Future<Map<String, double>> _run() async {
        print('Running $benchmarkPath');
        final Directory appDir = dir(
            path.join(flutterDirectory.path, 'dev/benchmarks/microbenchmarks'));
        final Process flutterProcess = await inDirectory(appDir, () async {
          final List<String> options = <String>[
            '-v',
            // --release doesn't work on iOS due to code signing issues
            '--profile',
            '--no-publish-port',
            '-d',
            device.deviceId,
          ];
          options.add(benchmarkPath);
          return _startFlutter(
            options: options,
            canFail: false,
          );
        });

        return _readJsonResults(flutterProcess);
      }
      return _run();
    }

    final Map<String, double> allResults = <String, double>{
      ...await _runMicrobench('lib/stocks/layout_bench.dart'),
      ...await _runMicrobench('lib/stocks/build_bench.dart'),
      ...await _runMicrobench('lib/geometry/matrix_utils_transform_bench.dart'),
      ...await _runMicrobench('lib/geometry/rrect_contains_bench.dart'),
      ...await _runMicrobench('lib/gestures/velocity_tracker_bench.dart'),
      ...await _runMicrobench('lib/gestures/gesture_detector_bench.dart'),
      ...await _runMicrobench('lib/stocks/animation_bench.dart'),
      ...await _runMicrobench('lib/language/sync_star_bench.dart'),
      ...await _runMicrobench('lib/language/sync_star_semantics_bench.dart'),
      ...await _runMicrobench('lib/foundation/all_elements_bench.dart'),
      ...await _runMicrobench('lib/foundation/change_notifier_bench.dart'),
 };

    return TaskResult.success(allResults, benchmarkScoreKeys: allResults.keys.toList());
  };
}

Future<Process> _startFlutter({
  List<String> options = const <String>[],
  bool canFail = false,
  Map<String, String> environment,
}) {
  final List<String> args = flutterCommandArgs('run', options);
  return startProcess(path.join(flutterDirectory.path, 'bin', 'flutter'), args, environment: environment);
}

Future<Map<String, double>> _readJsonResults(Process process) {
  // IMPORTANT: keep these values in sync with dev/benchmarks/microbenchmarks/lib/common.dart
  const String jsonStart = '================ RESULTS ================';
  const String jsonEnd = '================ FORMATTED ==============';
  const String jsonPrefix = ':::JSON:::';
  bool jsonStarted = false;
  final StringBuffer jsonBuf = StringBuffer();
  final Completer<Map<String, double>> completer = Completer<Map<String, double>>();

  final StreamSubscription<String> stderrSub = process.stderr
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) {
        stderr.writeln('[STDERR] $line');
      });

  bool processWasKilledIntentionally = false;
  bool resultsHaveBeenParsed = false;
  final StreamSubscription<String> stdoutSub = process.stdout
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) async {
    print(line);

    if (line.contains(jsonStart)) {
      jsonStarted = true;
      return;
    }

    if (line.contains(jsonEnd)) {
      final String jsonOutput = jsonBuf.toString();

      // If we end up here and have already parsed the results, it suggests that
      // we have received output from another test because our `flutter run`
      // process did not terminate correctly.
      // https://github.com/flutter/flutter/issues/19096#issuecomment-402756549
      if (resultsHaveBeenParsed) {
        throw 'Additional JSON was received after results has already been '
              'processed. This suggests the `flutter run` process may have lived '
              'past the end of our test and collected additional output from the '
              'next test.\n\n'
              'The JSON below contains all collected output, including both from '
              'the original test and what followed.\n\n'
              '$jsonOutput';
      }

      jsonStarted = false;
      processWasKilledIntentionally = true;
      resultsHaveBeenParsed = true;
      // Sending a SIGINT/SIGTERM to the process here isn't reliable because [process] is
      // the shell (flutter is a shell script) and doesn't pass the signal on.
      // Sending a `q` is an instruction to quit using the console runner.
      // See https://github.com/flutter/flutter/issues/19208
      process.stdin.write('q');
      await process.stdin.flush();
      // Also send a kill signal in case the `q` above didn't work.
      process.kill(ProcessSignal.sigint);
      try {
        completer.complete(Map<String, double>.from(json.decode(jsonOutput) as Map<String, dynamic>));
      } catch (ex) {
        completer.completeError('Decoding JSON failed ($ex). JSON string was: $jsonOutput');
      }
      return;
    }

    if (jsonStarted && line.contains(jsonPrefix))
      jsonBuf.writeln(line.substring(line.indexOf(jsonPrefix) + jsonPrefix.length));
  });

  process.exitCode.then<void>((int code) async {
    await Future.wait<void>(<Future<void>>[
      stdoutSub.cancel(),
      stderrSub.cancel(),
    ]);
    if (!processWasKilledIntentionally && code != 0) {
      completer.completeError('flutter run failed: exit code=$code');
    }
  });

  return completer.future;
}
