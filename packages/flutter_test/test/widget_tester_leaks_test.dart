// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'utils/leaking_classes.dart'; // ignore: implementation_imports

late final String _test1TrackingOnNoLeaks;
late final String _test2TrackingOffLeaks;
late final String _test3TrackingOnLeaks;
late final String _test4TrackingOnWithCreationStackTrace;
late final String _test5TrackingOnWithDisposalStackTrace;
late final String _test6TrackingOnWithPath;

void main() {
  late final Leaks reportedLeaks;
  experimentalCollectedLeaksReporter = (Leaks leaks) => reportedLeaks = leaks;
  LeakTesting.settings = LeakTesting.settings.copyWith(ignoredLeaks: const IgnoredLeaks(), ignore: false);

  group('Group', () {
    testWidgets('test', (_) async {
      StatelessLeakingWidget();
    });
  });

  testWidgets(_test1TrackingOnNoLeaks = 'test1, tracking-on, no leaks', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test1TrackingOnNoLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(Container());
  });

  testWidgets(_test2TrackingOffLeaks = 'test2, tracking-off, leaks',
  experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
  (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.ignoreLeaks, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(_test3TrackingOnLeaks = 'test3, tracking-on, leaks', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test3TrackingOnLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgets(
  _test4TrackingOnWithCreationStackTrace = 'test4, tracking-on, with creation stack trace',
  experimentalLeakTesting: LeakTesting.settings.withCreationStackTrace(),
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test4TrackingOnWithCreationStackTrace);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
  );

  testWidgets(
  _test5TrackingOnWithDisposalStackTrace = 'test5, tracking-on, with disposal stack trace',
  experimentalLeakTesting: LeakTesting.settings.withDisposalStackTrace(),
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test5TrackingOnWithDisposalStackTrace);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
  );

  testWidgets(
    _test6TrackingOnWithPath = 'test5, tracking-on, with path',
  experimentalLeakTesting: LeakTesting.settings.withRetainingPath(),
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test6TrackingOnWithPath);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
  );

  tearDownAll(() {
    try {
      expect(reportedLeaks, isLeakFree);
    } catch (e) {
      if (e is! TestFailure) {
        rethrow;
      }
      expect(e.message, contains('https://github.com/dart-lang/leak_tracker'));

      expect(e.message, isNot(contains(_test1TrackingOnNoLeaks)));
      expect(e.message, isNot(contains(_test2TrackingOffLeaks)));
      expect(e.message, contains('test: $_test3TrackingOnLeaks'));
      expect(e.message, contains('test: $_test4TrackingOnWithCreationStackTrace'));
      expect(e.message, contains('test: $_test5TrackingOnWithDisposalStackTrace'));
      expect(e.message, contains('test: $_test6TrackingOnWithPath'));
    }

    _verifyLeaks(
      reportedLeaks,
      _test3TrackingOnLeaks,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>[],
        LeakType.notDisposed: <String>[],
      },
    );
    _verifyLeaks(
      reportedLeaks,
      _test4TrackingOnWithCreationStackTrace,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>['start'],
        LeakType.notDisposed: <String>['start'],
      },
    );
    _verifyLeaks(
      reportedLeaks,
      _test5TrackingOnWithDisposalStackTrace,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>['dispose'],
        LeakType.notDisposed: <String>['dispose'],
      },
    );
    _verifyLeaks(
      reportedLeaks,
      _test6TrackingOnWithPath,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>['path'],
        LeakType.notDisposed: <String>['path'],
      },
    );
  });
}

/// Verifies [allLeaks] contains expected number of leaks for the test [testName].
///
/// [notDisposed] and [notGCed] set number for expected leaks by leak type.
void _verifyLeaks(
  Leaks allLeaks,
  String testName, {
  int notDisposed = 0,
  int notGCed = 0,
  Map<LeakType, List<String>> expectedContextKeys = const <LeakType, List<String>>{},
}) {
  const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

  final testLeaks = Leaks(
    allLeaks.byType.map(
      (key, value) =>
          MapEntry(key, value.where((leak) => leak.phase == testName).toList()),
    ),
  );

  for (LeakType type in expectedContextKeys.keys) {
    final leaks = testLeaks.byType[type]!;
    final expectedKeys = expectedContextKeys[type]!..sort();
    for (final leak in leaks) {
      final actualKeys = leak.context?.keys.toList() ?? <String>[];
      expect(actualKeys..sort(), equals(expectedKeys));
    }
  }

  if (notDisposed + notGCed > 0) {
    expect(
      () => expect(testLeaks, isLeakFree),
      throwsA(
        predicate((Object? e) {
          return e is TestFailure && e.toString().contains(linkToLeakTracker);
        }),
      ),
    );
  } else {
    expect(testLeaks, isLeakFree);
  }

  _verifyLeakList(
    testLeaks.notDisposed,
    notDisposed,
  );
  _verifyLeakList(
    testLeaks.notGCed,
    notGCed,
  );
}

void _verifyLeakList(
  List<LeakReport> list,
  int expectedCount,
) {
  expect(list.length, expectedCount);

  for (final LeakReport leak in list) {
    expect(leak.trackedClass, contains(LeakTrackedClass.library));
    expect(leak.trackedClass, contains('$LeakTrackedClass'));
  }
}
