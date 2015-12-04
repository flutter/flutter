#!/usr/bin/env dart
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';

const int ITERATIONS = 3;

String runWithLoggingSync(List<String> cmd, {
  bool checked: true,
  String workingDirectory
}) {
  ProcessResult results =
      Process.runSync(cmd[0], cmd.getRange(1, cmd.length).toList(), workingDirectory: workingDirectory);
  if (results.exitCode != 0) {
    String errorDescription = 'Error code ${results.exitCode} '
        'returned when attempting to run command: ${cmd.join(' ')}';
    print(errorDescription);
    if (results.stderr.length > 0)
      print('Errors logged: ${results.stderr.trim()}');
    if (checked)
      throw errorDescription;
  }
  if (results.stdout.trim().isNotEmpty)
    print(results.stdout.trim());
  return results.stdout;
}

double timeToFirstFrame(trace) {
  // TODO(eseidel): Sort! Events are not guarenteed to be in timestamp order.
  List events = trace['traceEvents'];
  int firstTimeStamp = events[0]['ts'].toInt();
  var firstSwap = events.firstWhere((e) => e['name'] == 'NativeViewGLSurfaceEGL:RealSwapBuffers');
  int swapStart = firstSwap['ts'].toInt();
  int swapEnd = swapStart + firstSwap['dur'].toInt();
  return (swapEnd - firstTimeStamp) / 1000; // microseconds to milliseconds.
}

Future<double> test(String tracesDir, String projectPath, int runNumber) async {
  // If we used package:path we could grab the basename of project_path
  // and include that in the trace_name.
  String tracePath = "${tracesDir}/trace_$runNumber.json";
  runWithLoggingSync([
    'flutter',
    'start',
    '--trace-startup'
  ], workingDirectory: projectPath);
  await new Future.delayed(const Duration(seconds: 2), () => "");
  runWithLoggingSync([
    'flutter',
    'trace',
    '--stop',
    '--out=${tracePath}'
  ], workingDirectory: projectPath);

  JsonDecoder decoder = new JsonDecoder();
  String contents = await new File(tracePath).readAsString();
  Map data = await decoder.convert(contents);
  return timeToFirstFrame(data);
}

// package:statistics has slightly nicer ones of these.
double mean(List<double> times) {
  return times.reduce((a,b) => a + b) / times.length;
}

double median(List<double> times) {
  times.sort();
  return times[times.length ~/ 2];
}

main(List<String> args) async {
  // We could do much more sophisticated things if we used package:args.
  if (args.length < 1) {
    print("Usage: profile_startup.dart PROJECT_PATH\n");
    print("PROJECT_PATH required.");
    return 1;
  }
  String projectPath = args[0];
  String traces_dir = '/tmp';

  List<double> times = [];
  print("Profiling startup using flutter start --trace-startup.");
  print("Measuring from first trace event to completion of first frame upload.");
  print("aka NativeViewGLSurfaceEGL:RealSwapBuffers.\n");
  print("NOTE: If device is not on/unlocked tracing may fail.\n");

  print("$ITERATIONS runs using $projectPath:");
  for (var x = 0; x < ITERATIONS; x++) {
    int runNumber = x + 1;
    double time = await test(traces_dir, projectPath, runNumber);
    print(" ${runNumber.toString().padLeft(2)} $time");
    times.add(time);
  }
  print("mean: ${mean(times)}");
  print("median: ${median(times)}");
}
