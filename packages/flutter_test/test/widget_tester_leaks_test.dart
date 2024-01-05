// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Objects that should not be GCed during.
final _retainer = <InstrumentedDisposable>[];

final List<LeakTestCase> _tests = <LeakTestCase>[
  // LeakTestCase(
  //   name: 'no leaks',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     await pumpWidgets!(Container());
  //   },
  // ),
  LeakTestCase(
    name: 'not disposed disposable',
    body: (PumpWidgetsCallback? pumpWidgets,
        RunAsyncCallback<dynamic>? runAsync) async {
      InstrumentedDisposable();
    },
    notDisposedTotal: 1,
  ),
  // LeakTestCase(
  //   name: 'not GCed disposable',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     _retainer.add(InstrumentedDisposable()..dispose());
  //   },
  //   notGCedTotal: 1,
  // ),
  // LeakTestCase(
  //   name: 'leaking widget',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     StatelessLeakingWidget();
  //   },
  //   notDisposedTotal: 1,
  //   notGCedTotal: 1,
  // ),
  // LeakTestCase(
  //     name: 'dispose in tear down',
  //     body: (PumpWidgetsCallback? pumpWidgets,
  //         RunAsyncCallback<dynamic>? runAsync) async {
  //       final InstrumentedDisposable myClass = InstrumentedDisposable();
  //       addTearDown(myClass.dispose);
  //     }),

  // LeakTestCase(
  //   name: 'pumped leaking widget',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     await pumpWidgets!(StatelessLeakingWidget());
  //   },
  // ),
  // LeakTestCase(
  //   name: 'leaking widget in runAsync',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     await runAsync!(() async {
  //       await pumpWidgets!(StatelessLeakingWidget());
  //     });
  //   },
  // ),
  // LeakTestCase(
  //   name: 'pumped in runAsync',
  //   body: (PumpWidgetsCallback? pumpWidgets,
  //       RunAsyncCallback<dynamic>? runAsync) async {
  //     await runAsync!(() async {
  //       await pumpWidgets!(StatelessLeakingWidget());
  //     });
  //   },
  // ),
];

class _TestExecution {
  _TestExecution({required this.settings, required this.settingName, required this.test});

  final String settingName;
  final LeakTesting settings;
  final LeakTestCase test;

  String get name => '${test.name}, $settingName';
}

String _currentFilePath() {
  return RegExp(r'#.*main \((.*):.*:.*\)')
        .firstMatch(StackTrace.current.toString())!
        .group(1).toString();
}

final List<_TestExecution> _testExecutions = <_TestExecution>[];

void main() {
  LeakTesting.collectedLeaksReporter = (Leaks leaks) => _verifyLeaks(leaks);
  LeakTesting.enable();

  LeakTesting.settings = LeakTesting.settings
  .withTrackedAll()
  .withTracked(allNotDisposed: true, allNotGCed: true)
  .withIgnored(
    createdByTestHelpers: true,
    testHelperExceptions: <RegExp>[RegExp(RegExp.escape(_currentFilePath()))],
  );

  for (final LeakTestCase test in _tests) {
    for (final  MapEntry<String, LeakTesting Function(LeakTesting settings)> settingsCase in leakTestingSettingsCases.entries) {
      final LeakTesting settings = settingsCase.value(LeakTesting.settings);
      if (settings.leakDiagnosticConfig.collectRetainingPathForNotGCed) {
        // Retaining path requires vm to be started, so skipping.
        continue;
      }
      final _TestExecution execution = _TestExecution(settingName: settingsCase.key, test: test, settings: settings);
      _testExecutions.add(execution);
      testWidgets(execution.name, experimentalLeakTesting: settings, (WidgetTester tester) async {
        await test.body(tester.pumpWidget, tester.runAsync);
      });
    }
  }
}

void _verifyLeaks(Leaks leaks) {
  for (final _TestExecution execution in _testExecutions) {
    final Leaks testLeaks = leaks.byPhase[execution.name] ?? Leaks.empty();
    execution.test.verifyLeaks(testLeaks, execution.settings, testDescription: execution.name);
  }
}
