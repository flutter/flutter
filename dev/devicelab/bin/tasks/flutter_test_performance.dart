// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test runs `flutter test` on the `trivial_widget_test.dart` four times.
//
// The first time, the result is ignored, on the basis that it's warming the
// cache.
//
// The second time tests how long a regular test takes to run.
//
// Before the third time, a change is made to the implementation of one of the
// files that the test depends on (indirectly).
//
// Before the fourth time, a change is made to the interface in that same file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

// Matches the output of the "test" package, e.g.: "00:01 +1 loading foo"
final RegExp testOutputPattern = RegExp(r'^[0-9][0-9]:[0-9][0-9] \+[0-9]+: (.+?) *$');

enum TestStep {
  starting,
  buildingFlutterTool,
  runningPubGet,
  testWritesFirstCarriageReturn,
  testLoading,
  testRunning,
  testPassed,
}

Future<int> runTest({bool coverage = false}) async {
  final List<String> arguments = <String>[
    'test',
    '--benchmark'
  ];
  if (coverage) {
    arguments.add('--coverage');
  }
  final String workingDirectory = path.join(flutterDirectory.path, 'dev', 'automated_tests');
  arguments.add(path.join('flutter_test', 'trivial_widget_test.dart'));
  final Process analysis = await startProcess(
    path.join(flutterDirectory.path, 'bin', 'flutter'),
    arguments,
    workingDirectory: workingDirectory
  );
  final int result = await analysis.exitCode;
  if (result != 0) {
    throw Exception('Test process exited with non-zero exit code');
  }
  final String testTime = File(path.join(workingDirectory, '.benchmark_time')).readAsStringSync();
  return int.tryParse(testTime);
}

void main() {
  task(() async {
    final File nodeSourceFile = File(path.join(
      flutterDirectory.path, 'packages', 'flutter', 'lib', 'src', 'foundation', 'node.dart',
    ));
    final String originalSource = await nodeSourceFile.readAsString();
    try {
      await runTest(); // first number is meaningless; could have had to build the tool, run pub get, have a cache, etc
      final int withoutChange = await runTest(); // run test again with no change
      await nodeSourceFile.writeAsString( // only change implementation
        originalSource
          .replaceAll('_owner', '_xyzzy')
      );
      final int implementationChange = await runTest(); // run test again with implementation changed
      await nodeSourceFile.writeAsString( // change interface as well
        originalSource
          .replaceAll('_owner', '_xyzzy')
          .replaceAll('owner', '_owner')
          .replaceAll('_xyzzy', 'owner')
      );
      final int interfaceChange = await runTest(); // run test again with interface changed
      // run test with coverage enabled.
      final int withCoverage = await runTest(coverage: true);
      final Map<String, dynamic> data = <String, dynamic>{
        'without_change_elapsed_time_ms': withoutChange,
        'implementation_change_elapsed_time_ms': implementationChange,
        'interface_change_elapsed_time_ms': interfaceChange,
        'with_coverage_time_ms': withCoverage,
      };
      return TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
    } finally {
      await nodeSourceFile.writeAsString(originalSource);
    }
  });
}
