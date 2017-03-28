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

/// The maximum amount of time a single microbenchmarks is allowed to take.
const Duration _kBenchmarkTimeout = const Duration(minutes: 6);

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
          if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
            await prepareProvisioningCertificates(appDir.path);
          }
          return await _startFlutter(
            options: <String>[
              '--profile',
              // --release doesn't work on iOS due to code signing issues
              '-d',
              device.deviceId,
              benchmarkPath,
            ],
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

    return new TaskResult.success(allResults, benchmarkScoreKeys: allResults.keys.toList());
  };
}

Future<Process> _startFlutter({
  String command = 'run',
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
  bool jsonStarted = false;
  final StringBuffer jsonBuf = new StringBuffer();
  final Completer<Map<String, double>> completer = new Completer<Map<String, double>>();
  StreamSubscription<String> stdoutSub;

  int prefixLength = 0;
  stdoutSub = process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
    print(line);

    if (line.contains(jsonStart)) {
      jsonStarted = true;
      prefixLength = line.indexOf(jsonStart);
      return;
    }

    if (line.contains(jsonEnd)) {
      jsonStarted = false;
      stdoutSub.cancel();
      process.kill(ProcessSignal.SIGINT);  // flutter run doesn't quit automatically
      completer.complete(JSON.decode(jsonBuf.toString()));
      return;
    }

    if (jsonStarted)
      jsonBuf.writeln(line.substring(prefixLength));
  });

  return completer.future;
}
