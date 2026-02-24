// Copyright 2014 The Flutter Authors. All rights reserved.
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

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

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

Future<int> runTest({bool coverage = false, bool noPub = false}) async {
  final clock = Stopwatch()..start();
  final Process analysis = await startFlutter(
    'test',
    options: <String>[
      if (coverage) '--coverage',
      if (noPub) '--no-pub',
      path.join('flutter_test', 'trivial_widget_test.dart'),
    ],
    workingDirectory: path.join(flutterDirectory.path, 'dev', 'automated_tests'),
  );
  final badLines = <String>[];
  TestStep step = TestStep.starting;

  analysis.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen((
    String entry,
  ) {
    print('test stdout ($step): $entry');
    if (step == TestStep.starting && entry == 'Building flutter tool...') {
      // ignore this line
      step = TestStep.buildingFlutterTool;
    } else if (step == TestStep.testPassed &&
        entry.contains('Collecting coverage information...')) {
      // ignore this line
    } else if (step.index < TestStep.runningPubGet.index &&
        entry == 'Running "flutter pub get" in automated_tests...') {
      // ignore this line
      step = TestStep.runningPubGet;
    } else if (step.index <= TestStep.testWritesFirstCarriageReturn.index && entry.trim() == '') {
      // flutter_tools will print a blank line at the start of the test when using some versions
      // of the Dart test package.  In test package version 1.29 this line is no longer present.
      step = TestStep.testWritesFirstCarriageReturn;
    } else {
      final Match? match = testOutputPattern.matchAsPrefix(entry);
      if (match == null) {
        badLines.add('badline(nomatch): "$entry"');
      } else {
        if (step.index <= TestStep.testLoading.index && match.group(1)!.startsWith('loading ')) {
          // first the test loads
          step = TestStep.testLoading;
        } else if (step.index <= TestStep.testRunning.index &&
            match.group(1) == 'A trivial widget test') {
          // then the test runs
          step = TestStep.testRunning;
        } else if (step.index < TestStep.testPassed.index &&
            match.group(1) == 'All tests passed!') {
          // then the test finishes
          step = TestStep.testPassed;
        } else {
          badLines.add('badline(fallthrough): "$entry"');
        }
      }
    }
  });
  analysis.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen((
    String entry,
  ) {
    print('test stderr: $entry');
    badLines.add('badline(stderr): "$entry"');
  });
  final int result = await analysis.exitCode;
  clock.stop();
  if (result != 0) {
    throw Exception('flutter test failed with exit code $result');
  }
  if (badLines.isNotEmpty) {
    const separator = '\n  ';
    throw Exception(
      'flutter test rendered unexpected output:$separator${badLines.join(separator)}',
    );
  }
  if (step != TestStep.testPassed) {
    throw Exception('flutter test did not finish (only reached step $step)');
  }
  print('elapsed time: ${clock.elapsedMilliseconds}ms');
  return clock.elapsedMilliseconds;
}

Future<void> pubGetDependencies(List<Directory> directories) async {
  for (final directory in directories) {
    await inDirectory<void>(directory, () async {
      await flutter('pub', options: <String>['get']);
    });
  }
}

void main() {
  task(() async {
    final nodeSourceFile = File(
      path.join(
        flutterDirectory.path,
        'packages',
        'flutter',
        'lib',
        'src',
        'foundation',
        'node.dart',
      ),
    );
    await pubGetDependencies(<Directory>[
      Directory(path.join(flutterDirectory.path, 'dev', 'automated_tests')),
    ]);
    final String originalSource = await nodeSourceFile.readAsString();
    try {
      await runTest(
        noPub: true,
      ); // first number is meaningless; could have had to build the tool, run pub get, have a cache, etc
      final int withoutChange = await runTest(noPub: true); // run test again with no change
      await nodeSourceFile.writeAsString(
        // only change implementation
        originalSource.replaceAll('_owner', '_xyzzy'),
      );
      final int implementationChange = await runTest(
        noPub: true,
      ); // run test again with implementation changed
      await nodeSourceFile.writeAsString(
        // change interface as well
        originalSource
            .replaceAll('_owner', '_xyzzy')
            .replaceAll('owner', '_owner')
            .replaceAll('_xyzzy', 'owner'),
      );
      final int interfaceChange = await runTest(
        noPub: true,
      ); // run test again with interface changed
      // run test with coverage enabled.
      final int withCoverage = await runTest(coverage: true, noPub: true);
      final data = <String, dynamic>{
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
