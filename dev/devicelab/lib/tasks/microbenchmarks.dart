// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// The maximum amount of time a single microbenchmark is allowed to take.
const Duration _kBenchmarkTimeout = const Duration(minutes: 10);

/// Creates a device lab task that runs benchmarks in
/// `dev/benchmarks/microbenchmarks` reports results to the dashboard.
TaskFunction createMicrobenchmarkTask() {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();

    Future<Map<String, double>> _runMicrobench(String benchmarkPath, {bool previewDart2: true}) async {
      Future<Map<String, double>> _run() async {
        print('Running $benchmarkPath');
        final Directory appDir = dir(
            path.join(flutterDirectory.path, 'dev/benchmarks/microbenchmarks'));
        final Process flutterProcess = await inDirectory(appDir, () async {
          if (deviceOperatingSystem == DeviceOperatingSystem.ios)
            await prepareProvisioningCertificates(appDir.path);
          final List<String> options = <String>[
            '-v',
            // --release doesn't work on iOS due to code signing issues
            '--profile',
            '-d',
            device.deviceId,
          ];
          if (previewDart2)
            options.add('--preview-dart-2');
          else
            options.add('--no-preview-dart-2');
          setLocalEngineOptionIfNecessary(options);
          options.add(benchmarkPath);
          return await _startFlutter(
            options: options,
            canFail: false,
          );
        });

        return await _readJsonResults(flutterProcess);
      }
      return _run().timeout(_kBenchmarkTimeout);
    }

    final Map<String, double> allResults = <String, double>{};
    allResults.addAll(await _runMicrobench('lib/stocks/layout_bench.dart'));
    allResults.addAll(await _runMicrobench('lib/stocks/build_bench.dart'));
    allResults.addAll(await _runMicrobench('lib/gestures/velocity_tracker_bench.dart'));
    allResults.addAll(await _runMicrobench('lib/stocks/animation_bench.dart'));

    // Run micro-benchmarks once again in --no-preview-dart-2 mode.
    // Append "_dart1" suffix to the result keys to distinguish them from
    // the original results.

    void addDart1Results(Map<String, double> benchmarkResults) {
      benchmarkResults.forEach((String key, double result) {
        allResults[key + '_dart1'] = result;
      });
    }

    addDart1Results(await _runMicrobench(
        'lib/stocks/layout_bench.dart', previewDart2: false));
    addDart1Results(await _runMicrobench(
        'lib/stocks/layout_bench.dart', previewDart2: false));
    addDart1Results(await _runMicrobench(
        'lib/stocks/build_bench.dart', previewDart2: false));
    addDart1Results(await _runMicrobench(
        'lib/gestures/velocity_tracker_bench.dart', previewDart2: false));
    addDart1Results(await _runMicrobench(
        'lib/stocks/animation_bench.dart', previewDart2: false));
    return new TaskResult.success(allResults, benchmarkScoreKeys: allResults.keys.toList());
  };
}

Future<Process> _startFlutter({
  String command: 'run',
  List<String> options: const <String>[],
  bool canFail: false,
  Map<String, String> environment,
}) {
  final List<String> args = <String>['run']..addAll(options);
  return startProcess(path.join(flutterDirectory.path, 'bin', 'flutter'), args, environment: environment);
}

Future<Map<String, double>> _readJsonResults(Process process) {
  // IMPORTANT: keep these values in sync with dev/benchmarks/microbenchmarks/lib/common.dart
  const String jsonStart = '================ RESULTS ================';
  const String jsonEnd = '================ FORMATTED ==============';
  const String jsonPrefix = ':::JSON:::';
  bool jsonStarted = false;
  final StringBuffer jsonBuf = new StringBuffer();
  final Completer<Map<String, double>> completer = new Completer<Map<String, double>>();

  final StreamSubscription<String> stderrSub = process.stderr
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
        stderr.writeln('[STDERR] $line');
      });

  bool processWasKilledIntentionally = false;
  final StreamSubscription<String> stdoutSub = process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
    print(line);

    if (line.contains(jsonStart)) {
      jsonStarted = true;
      return;
    }

    if (line.contains(jsonEnd)) {
      jsonStarted = false;
      processWasKilledIntentionally = true;
      // ignore: deprecated_member_use
      process.kill(ProcessSignal.SIGINT); // flutter run doesn't quit automatically
      final String jsonOutput = jsonBuf.toString();
      try {
        completer.complete(json.decode(jsonOutput));
      } catch (ex) {
        completer.completeError('Decoding JSON failed ($ex). JSON string was: $jsonOutput');
      }
      return;
    }

    if (jsonStarted && line.contains(jsonPrefix))
      jsonBuf.writeln(line.substring(line.indexOf(jsonPrefix) + jsonPrefix.length));
  });

  process.exitCode.then<int>((int code) {
    stdoutSub.cancel();
    stderrSub.cancel();
    if (!processWasKilledIntentionally && code != 0) {
      completer.completeError('flutter run failed: exit code=$code');
    }
  });

  return completer.future;
}
