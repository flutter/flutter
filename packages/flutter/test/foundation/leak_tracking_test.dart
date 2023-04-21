// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'leak_tracking.dart';

final String _leakTrackedClassName = '$_LeakTrackedClass';

Future<void> main() async {


  group('Leak tracking works for non-web',
    () {
      testWidgetsWithLeakTracking(
        'Leak tracker respects all allow lists',
        (WidgetTester tester) async {
          await tester.pumpWidget(_StatelessLeakingWidget());
        },
        leakTrackingConfig: LeakTrackingTestConfig(
          notDisposedAllowList: <String>{_leakTrackedClassName},
          notGCedAllowList: <String>{_leakTrackedClassName},
        ),
      );

      group('Leak tracker respects notGCed allow lists', () {
        // These tests cannot run inside other tests because test nesting is forbidden.
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
            notGCedAllowList: <String>{_leakTrackedClassName},
          ),
        );

        tearDown(() => _verifyLeaks(leaks, expectedNotDisposed: 1));
      });

      group('Leak tracker respects notDisposed allow lists', () {
        // These tests cannot run inside other tests because test nesting is forbidden.
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
            notDisposedAllowList: <String>{_leakTrackedClassName},
          ),
        );

        tearDown(() => _verifyLeaks(leaks, expectedNotGCed: 1));
      });

      group('Leak tracker catches that', () {
        // These tests cannot run inside other tests because test nesting is forbidden.
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

        tearDown(() => _verifyLeaks(leaks, expectedNotDisposed: 1, expectedNotGCed: 1));
      });
    },
    skip: isBrowser,
  );

  testWidgetsWithLeakTracking(
    'Leak tracking is no-op for web',
    (WidgetTester tester) async {
      await tester.pumpWidget(_StatelessLeakingWidget());
    },
    skip: !isBrowser,
  );
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
