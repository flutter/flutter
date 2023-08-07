// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import '../../leak_tracking.dart';
import '../leaking_widget.dart';
import 'constants.dart';

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  configureLeakTrackingTearDown(
    configureOnce: true,
    onLeaks: (Leaks leaks) {
      expect(leaks.total, greaterThan(0));

      try {
        expect(leaks, isLeakFree);
      } catch (e) {
        if (e is! TestFailure) {
          rethrow;
        }
        expect(e.message, isNot(contains(test1TrackingOnNoLeaks)));
        expect(e.message, isNot(contains(test2TrackingOffLeaks)));
        expect(e.message, contains('test: $test3TrackingOnLeaks'));
        expect(e.message, contains('test: $test4TrackingOnWithStackTrace'));
      }

      _verifyLeaks(
        leaks,
        test3TrackingOnLeaks,
        notDisposed: 1,
        notGCed: 1,
        shouldContainDebugInfo: false,
      );
      _verifyLeaks(
        leaks,
        test4TrackingOnWithStackTrace,
        notDisposed: 1,
        notGCed: 1,
        shouldContainDebugInfo: true,
      );
    },
  );

  setUpAll(() {
    LeakTracking.warnForUnsupportedPlatforms = false;
  });

  await testMain();
}

/// Verifies [allLeaks] contains expected number of leaks for the test [testName].
///
/// [notDisposed] and [notGCed] set number for expected leaks by leak type.
void _verifyLeaks(
  Leaks allLeaks,
  String testName, {
  int notDisposed = 0,
  int notGCed = 0,
  required bool shouldContainDebugInfo,
}) {
  const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

  final Leaks leaks = Leaks(
    allLeaks.byType.map(
      (LeakType key, List<LeakReport> value) =>
          MapEntry<LeakType, List<LeakReport>>(key, value.where((LeakReport leak) => leak.phase == testName).toList()),
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
    shouldContainDebugInfo,
  );
  _verifyLeakList(
    leaks.notGCed,
    notGCed,
    shouldContainDebugInfo,
  );
}

void _verifyLeakList(
  List<LeakReport> list,
  int expectedCount,
  bool shouldContainDebugInfo,
) {
  expect(list.length, expectedCount);

  for (final LeakReport leak in list) {
    if (shouldContainDebugInfo) {
      expect(leak.context, isNotEmpty);
    } else {
      expect(leak.context ?? <String, dynamic>{}, isEmpty);
    }
    expect(leak.trackedClass, contains(LeakTrackedClass.library));
    expect(leak.trackedClass, contains('$LeakTrackedClass'));
  }
}
