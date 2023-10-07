// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'leak_tracking.dart';

final String _leakTrackedClassName = '$_LeakTrackedClass';

Leaks _leaksOfAllTypes() => Leaks(<LeakType, List<LeakReport>> {
  LeakType.notDisposed: <LeakReport>[LeakReport(code: 1, context: <String, dynamic>{}, type:'myNotDisposedClass', trackedClass: 'myTrackedClass')],
  LeakType.notGCed: <LeakReport>[LeakReport(code: 2, context: <String, dynamic>{}, type:'myNotGCedClass', trackedClass: 'myTrackedClass')],
  LeakType.gcedLate: <LeakReport>[LeakReport(code: 3, context: <String, dynamic>{}, type:'myGCedLateClass', trackedClass: 'myTrackedClass')],
});

Future<void> main() async {
  test('Trivial $LeakCleaner returns only non-disposed leaks.', () {
    final LeakCleaner leakCleaner = LeakCleaner(const LeakTrackingTestConfig());
    final Leaks leaks = _leaksOfAllTypes();
    final int leakTotal = leaks.total;

    final Leaks cleanedLeaks = leakCleaner.clean(leaks);

    expect(leaks.total, leakTotal);
    expect(cleanedLeaks.total, 1);
  });

  test('$LeakCleaner catches extra leaks', () {
    Leaks leaks = _leaksOfAllTypes();
    final LeakReport leak = leaks.notDisposed.first;
    leaks.notDisposed.add(leak);

    final LeakTrackingTestConfig config = LeakTrackingTestConfig(
      notDisposedAllowList: <String, int?>{leak.type: 1},
    );
    leaks = LeakCleaner(config).clean(leaks);

    expect(leaks.notDisposed, hasLength(2));
  });

  group('Leak tracking works for non-web, and', () {
    testWidgetsWithLeakTracking(
      'respects all allow lists',
      (WidgetTester tester) async {
        await tester.pumpWidget(_StatelessLeakingWidget());
      },
      leakTrackingConfig: LeakTrackingTestConfig(
        notDisposedAllowList: <String, int?>{_leakTrackedClassName: null},
        notGCedAllowList: <String, int?>{_leakTrackedClassName: null},
      ),
    );

    testWidgetsWithLeakTracking(
      'respects count in allow lists',
      (WidgetTester tester) async {
        await tester.pumpWidget(_StatelessLeakingWidget());
      },
      leakTrackingConfig: LeakTrackingTestConfig(
        notDisposedAllowList: <String, int?>{_leakTrackedClassName: 1},
        notGCedAllowList: <String, int?>{_leakTrackedClassName: 1},
      ),
    );

    group('fails if number or leaks is more than allowed', () {
      // This test cannot run inside other tests because test nesting is forbidden.
      // So, `expect` happens outside the tests, in `tearDown`.
      late Leaks leaks;

      testWidgetsWithLeakTracking(
        'for $_StatelessLeakingWidget',
        (WidgetTester tester) async {
          await tester.pumpWidget(_StatelessLeakingWidget());
          await tester.pumpWidget(_StatelessLeakingWidget());
        },
        leakTrackingConfig: LeakTrackingTestConfig(
          onLeaks: (Leaks theLeaks) {
            leaks = theLeaks;
          },
          failTestOnLeaks: false,
          notDisposedAllowList: <String, int?>{_leakTrackedClassName: 1},
        ),
      );

      tearDown(() => _verifyLeaks(leaks, expectedNotDisposed: 2));
    });

    group('respects notGCed allow lists', () {
      // These tests cannot run inside other tests because test nesting is forbidden.
      // So, `expect` happens outside the tests, in `tearDown`.
      late Leaks leaks;

      testWidgetsWithLeakTracking(
        'when $_StatelessLeakingWidget leaks',
        (WidgetTester tester) async {
          await tester.pumpWidget(_StatelessLeakingWidget());
        },
        leakTrackingConfig: LeakTrackingTestConfig(
          onLeaks: (Leaks theLeaks) {
            leaks = theLeaks;
          },
          failTestOnLeaks: false,
          notGCedAllowList: <String, int?>{_leakTrackedClassName: null},
        ),
      );

      tearDown(() => _verifyLeaks(leaks, expectedNotDisposed: 1));
    });

    group('catches that', () {
      // These test cannot run inside other tests because test nesting is forbidden.
      // So, `expect` happens outside the tests, in `tearDown`.
      late Leaks leaks;

      testWidgetsWithLeakTracking(
        '$_StatelessLeakingWidget leaks',
        (WidgetTester tester) async {
          await tester.pumpWidget(_StatelessLeakingWidget());
        },
        leakTrackingConfig: LeakTrackingTestConfig(
          onLeaks: (Leaks theLeaks) {
            leaks = theLeaks;
          },
          failTestOnLeaks: false,
        ),
      );

      tearDown(() => _verifyLeaks(leaks, expectedNotDisposed: 1));
    });
  },
  skip: isBrowser); // [intended] Leak detection is off for web.

  testWidgetsWithLeakTracking('Leak tracking is no-op for web', (WidgetTester tester) async {
    await tester.pumpWidget(_StatelessLeakingWidget());
  },
  skip: !isBrowser); // [intended] Leaks detection is off for web.
}

/// Verifies [leaks] contains expected number of leaks for [_LeakTrackedClass].
void _verifyLeaks(Leaks leaks, { int expectedNotDisposed = 0,  int expectedNotGCed = 0 }) {
  const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

  expect(
    () => expect(leaks, isLeakFree),
    throwsA(
      predicate((Object? e) {
        return e is TestFailure && e.toString().contains(linkToLeakTracker);
      }),
    ),
  );

  _verifyLeakList(leaks.notDisposed, expectedNotDisposed);
  _verifyLeakList(leaks.notGCed, expectedNotGCed);
}

void _verifyLeakList(List<LeakReport> list, int expectedCount){
  expect(list.length, expectedCount);

  for (final LeakReport leak in list) {
    expect(leak.trackedClass, contains(_LeakTrackedClass.library));
    expect(leak.trackedClass, contains(_leakTrackedClassName));
  }
}

/// Storage to keep disposed objects, to generate not-gced leaks.
final List<_LeakTrackedClass> _notGcedStorage = <_LeakTrackedClass>[];

class _StatelessLeakingWidget extends StatelessWidget {
  _StatelessLeakingWidget() {
    // ignore: unused_local_variable, the variable is used to create non disposed leak
    final _LeakTrackedClass notDisposed = _LeakTrackedClass();
    _notGcedStorage.add(_LeakTrackedClass()..dispose());
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _LeakTrackedClass {
  _LeakTrackedClass() {
    dispatchObjectCreated(
      library: library,
      className: '$_LeakTrackedClass',
      object: this,
    );
  }

  static const String library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    dispatchObjectDisposed(object: this);
  }
}
