// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'utils/memory_leak_tests.dart';

class _TestExecution {
  _TestExecution(
      {required this.settings, required this.settingName, required this.test});

<<<<<<< HEAD
void main() {
  LeakTesting.enable();
  LeakTesting.collectedLeaksReporter = (Leaks leaks) => verifyLeaks(leaks);
  LeakTesting.settings = LeakTesting.settings.copyWith(ignore: false);

  // It is important that the test file starts with group, to test that leaks are collected for all tests after group too.
  group('Group', () {
    testWidgets('test', (_) async {
      StatelessLeakingWidget();
    });
  });

  testWidgets(_test1TrackingOnNoLeaks = 'test1, tracking-on, no leaks', (WidgetTester widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test1TrackingOnNoLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(Container());
  });

  testWidgets(
    _test2TrackingOffLeaks = 'test2, tracking-off, leaks',
    experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
  (WidgetTester widgetTester) async {
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(_test3TrackingOnLeaks = 'test3, tracking-on, leaks', (WidgetTester widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test3TrackingOnLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(
    _test4TrackingOnWithCreationStackTrace = 'test4, tracking-on, with creation stack trace',
    experimentalLeakTesting: LeakTesting.settings.withCreationStackTrace(),
  (WidgetTester widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test4TrackingOnWithCreationStackTrace);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
  );

  testWidgets(
    _test5TrackingOnWithDisposalStackTrace = 'test5, tracking-on, with disposal stack trace',
  experimentalLeakTesting: LeakTesting.settings.withDisposalStackTrace(),
    (WidgetTester widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test5TrackingOnWithDisposalStackTrace);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
  );

  testWidgets(_test6TrackingOnNoLeaks = 'test6, tracking-on, no leaks', (_) async {
    LeakTrackedClass().dispose();
  });
=======
  final String settingName;
  final LeakTesting settings;
  final LeakTestCase test;
>>>>>>> 8495dee1fd4aacbe9de707e7581203232f591b2f

  String get name => '${test.name}, $settingName';
}

final List<_TestExecution> _testExecutions = <_TestExecution>[];

void main() {
  LeakTesting.collectedLeaksReporter = _verifyLeaks;
  LeakTesting.enable();

  LeakTesting.settings = LeakTesting.settings
      .withTrackedAll()
      .withTracked(allNotDisposed: true, experimentalAllNotGCed: true)
      .withIgnored(
    createdByTestHelpers: true,
    testHelperExceptions: <RegExp>[
      RegExp(RegExp.escape(memoryLeakTestsFilePath()))
    ],
  );

  for (final LeakTestCase test in memoryLeakTests) {
    for (final MapEntry<String,
            LeakTesting Function(LeakTesting settings)> settingsCase
        in leakTestingSettingsCases.entries) {
      final LeakTesting settings = settingsCase.value(LeakTesting.settings);
      if (settings.leakDiagnosticConfig.collectRetainingPathForNotGCed) {
        // Retaining path requires vm to be started, so skipping.
        continue;
      }
      final _TestExecution execution = _TestExecution(
          settingName: settingsCase.key, test: test, settings: settings);
      _testExecutions.add(execution);
      testWidgets(execution.name, experimentalLeakTesting: settings,
          (WidgetTester tester) async {
        await test.body((Widget widget, [Duration? duration]) => tester.pumpWidget(widget, duration: duration), tester.runAsync);
      });
    }
  }
}

void _verifyLeaks(Leaks leaks) {
  for (final _TestExecution execution in _testExecutions) {
    final Leaks testLeaks = leaks.byPhase[execution.name] ?? Leaks.empty();
    execution.test.verifyLeaks(testLeaks, execution.settings,
        testDescription: execution.name);
  }
}
