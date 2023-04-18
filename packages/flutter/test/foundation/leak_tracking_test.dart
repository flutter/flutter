// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'leak_tracking.dart';

Future<void> main() async {
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

    tearDown(() {
      const String linkToLeakTracker = 'https://github.com/dart-lang/leak_tracker';

      expect(
        () => expect(leaks, isLeakFree),
        throwsA(
          predicate((Object? e) {
            return e is TestFailure && e.toString().contains(linkToLeakTracker);
          }),
        ),
      );
      expect(leaks.total, 2);

      final LeakReport notDisposedLeak = leaks.notDisposed.first;
      expect(
        notDisposedLeak.trackedClass,
        contains(_LeakTrackedClass.library),
      );
      expect(notDisposedLeak.trackedClass, contains('$_LeakTrackedClass'));

      final LeakReport notGcedLeak = leaks.notDisposed.first;
      expect(notGcedLeak.trackedClass, contains(_LeakTrackedClass.library));
      expect(notGcedLeak.trackedClass, contains('$_LeakTrackedClass'));
     });
  });
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
