// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:matcher/expect.dart' as matcher;
import 'package:matcher/src/expect/async_matcher.dart';

import 'utils/leaking_classes.dart'; // ignore: implementation_imports

late final String _test1TrackingOnNoLeaks;
late final String _test2TrackingOffLeaks;
late final String _test3TrackingOnLeaks;
late final String _test4TrackingOnWithStackTrace;
late final String _test5TrackingOnWithPath;

void main() {
  late final Leaks reportedLeaks;
  experimentalCollectedLeaksReporter = (Leaks leaks) => reportedLeaks = leaks;
  LeakTesting.settings = LeakTesting.settings.copyWith(ignoredLeaks: const IgnoredLeaks(), ignore: false);

  group('Group', () {
    testWidgets('test', (_) async {
      StatelessLeakingWidget();
    });
  });

  testWidgetsWithLeakTracking(_test1TrackingOnNoLeaks = 'test1, tracking-on, no leaks', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test1TrackingOnNoLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(Container());
  });

  testWidgets(_test2TrackingOffLeaks = 'test2, tracking-off, leaks', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, null);
    expect(LeakTracking.phase.ignoreLeaks, true);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(_test3TrackingOnLeaks = 'test3, tracking-on, leaks', (widgetTester) async {
    expect(LeakTracking.isStarted, true);
    expect(LeakTracking.phase.name, _test3TrackingOnLeaks);
    expect(LeakTracking.phase.ignoreLeaks, false);
    await widgetTester.pumpWidget(StatelessLeakingWidget());
  });

  testWidgetsWithLeakTracking(
    _test4TrackingOnWithStackTrace = 'test4, tracking-on, with stack trace',
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test4TrackingOnWithStackTrace);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
    leakTesting: LeakTesting.settings.withCreationStackTrace(),
  );

  testWidgetsWithLeakTracking(
    _test5TrackingOnWithPath = 'test5, tracking-on, with path',
    (widgetTester) async {
      expect(LeakTracking.isStarted, true);
      expect(LeakTracking.phase.name, _test5TrackingOnWithPath);
      expect(LeakTracking.phase.ignoreLeaks, false);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    },
    leakTesting: LeakTesting.settings.withRetainingPath(),
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
      expect(e.message, contains('test: $_test4TrackingOnWithStackTrace'));
      expect(e.message, contains('test: $_test5TrackingOnWithPath'));
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
      _test4TrackingOnWithStackTrace,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>[],
        LeakType.notDisposed: <String>[],
      },
    );
    _verifyLeaks(
      reportedLeaks,
      _test5TrackingOnWithPath,
      notDisposed: 1,
      notGCed: 1,
      expectedContextKeys: <LeakType, List<String>>{
        LeakType.notGCed: <String>[],
        LeakType.notDisposed: <String>[],
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

  final leaks = Leaks(
    allLeaks.byType.map(
      (key, value) =>
          MapEntry(key, value.where((leak) => leak.phase == testName).toList()),
    ),
  );

  if (notDisposed + notGCed > 0) {
    expect(
      () => expect(leaks, isLeakFree),
      throwsA(
        predicate((Object? e) {
          return e is TestFailure && e.toString().contains(linkToLeakTracker);
        }),
      ),
    );
  } else {
    expect(leaks, isLeakFree);
  }

  _verifyLeakList(
    leaks.notDisposed,
    notDisposed,
  );
  _verifyLeakList(
    leaks.notGCed,
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
