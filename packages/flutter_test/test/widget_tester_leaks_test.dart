// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'utils/leaking_classes.dart';

late final String _test1TrackingOnNoLeaks;
late final String _test2TrackingOffLeaks;
late final String _test3TrackingOnLeaks;
late final String _test4TrackingOnWithCreationStackTrace;
late final String _test5TrackingOnWithDisposalStackTrace;
late final String _test6TrackingOnNoLeaks;
late final String _test7TrackingOnNoLeaks;
late final String _test8TrackingOnNotDisposed;

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

  testWidgets(_test7TrackingOnNoLeaks = 'test7, tracking-on, tear down, no leaks', (_) async {
    final LeakTrackedClass myClass = LeakTrackedClass();
    addTearDown(myClass.dispose);
  });

  testWidgets(_test8TrackingOnNotDisposed = 'test8, tracking-on, not disposed leak', (_) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test8TrackingOnNotDisposed);
    expect(LeakTracking.phase.ignoreLeaks, false);
    LeakTrackedClass();
  });
}

int _leakReporterInvocationCount = 0;

void verifyLeaks(Leaks leaks) {
  _leakReporterInvocationCount += 1;
  expect(_leakReporterInvocationCount, 1);

  try {
    expect(leaks, isLeakFree);
  } on TestFailure catch (e) {
    expect(e.message, contains('https://github.com/dart-lang/leak_tracker'));

    expect(e.message, isNot(contains(_test1TrackingOnNoLeaks)));
    expect(e.message, isNot(contains(_test2TrackingOffLeaks)));
    expect(e.message, contains('test: $_test3TrackingOnLeaks'));
    expect(e.message, contains('test: $_test4TrackingOnWithCreationStackTrace'));
    expect(e.message, contains('test: $_test5TrackingOnWithDisposalStackTrace'));
    expect(e.message, isNot(contains(_test6TrackingOnNoLeaks)));
    expect(e.message, isNot(contains(_test7TrackingOnNoLeaks)));
    expect(e.message, contains('test: $_test8TrackingOnNotDisposed'));
  }

  _verifyLeaks(
    leaks,
    _test3TrackingOnLeaks,
    notDisposed: 1,
    notGCed: 1,
    expectedContextKeys: <LeakType, List<String>>{
      LeakType.notGCed: <String>[],
      LeakType.notDisposed: <String>[],
    },
  );
  _verifyLeaks(
    leaks,
    _test4TrackingOnWithCreationStackTrace,
    notDisposed: 1,
    notGCed: 1,
    expectedContextKeys: <LeakType, List<String>>{
      LeakType.notGCed: <String>['start'],
      LeakType.notDisposed: <String>['start'],
    },
  );
  _verifyLeaks(
    leaks,
    _test5TrackingOnWithDisposalStackTrace,
    notDisposed: 1,
    notGCed: 1,
    expectedContextKeys: <LeakType, List<String>>{
      LeakType.notGCed: <String>['disposal'],
      LeakType.notDisposed: <String>[],
    },
  );
  _verifyLeaks(
    leaks,
    _test8TrackingOnNotDisposed,
    notDisposed: 1,
    expectedContextKeys: <LeakType, List<String>>{},
  );
}

/// Verifies [allLeaks] contain expected number of leaks for the test [testDescription].
///
/// [notDisposed] and [notGCed] set number for expected leaks by leak type.
/// The method will fail if the leaks context does not contain [expectedContextKeys].
void _verifyLeaks(
  Leaks allLeaks,
  String testDescription, {
  int notDisposed = 0,
  int notGCed = 0,
  Map<LeakType, List<String>> expectedContextKeys = const <LeakType, List<String>>{},
}) {
  final Leaks testLeaks = Leaks(
    allLeaks.byType.map(
      (LeakType key, List<LeakReport> value) =>
          MapEntry<LeakType, List<LeakReport>>(key, value.where((LeakReport leak) => leak.phase == testDescription).toList()),
    ),
  );

  for (final LeakType type in expectedContextKeys.keys) {
    final List<LeakReport> leaks = testLeaks.byType[type]!;
    final List<String> expectedKeys = expectedContextKeys[type]!..sort();
    for (final LeakReport leak in leaks) {
      final List<String> actualKeys = leak.context?.keys.toList() ?? <String>[];
      expect(actualKeys..sort(), equals(expectedKeys), reason: '$testDescription, $type');
    }
  }

  _verifyLeakList(
    testLeaks.notDisposed,
    notDisposed,
    testDescription,
  );
  _verifyLeakList(
    testLeaks.notGCed,
    notGCed,
    testDescription,
  );
}

void _verifyLeakList(
  List<LeakReport> list,
  int expectedCount,
  String testDescription,
) {
  expect(list.length, expectedCount, reason: testDescription);

  for (final LeakReport leak in list) {
    expect(leak.trackedClass, contains(LeakTrackedClass.library));
    expect(leak.trackedClass, contains('$LeakTrackedClass'));
  }
}
