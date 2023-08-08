// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../leak_tracking.dart';
import 'leaking_widget.dart';

const String _test0TrackingOffLeaks = 'test0, tracking-off';
const String _test1TrackingOn = 'test1, tracking-on';
const String _test2TrackingOffLeaks = 'test2, tracking-off';
const String _test3TrackingOn = 'test3, tracking-on';

bool get _isTrackingOn => !LeakTracking.phase.isPaused && LeakTracking.isStarted;

/// Tests with default leak tracking configuration.
///
/// This set of tests verifies that if `testWidgetsWithLeakTracking` is used at least once,
/// leak tracking is configured as expected, and is noop for `testWidgets`.
void main() {
  group('groups are handled', () {
    testWidgets(_test0TrackingOffLeaks, (WidgetTester widgetTester) async {
      // Flutter test engine may change test order.
      expect(_isTrackingOn, false);
      expect(LeakTracking.phase.name, null);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    });

    testWidgetsWithLeakTracking(_test1TrackingOn, (WidgetTester widgetTester) async {
      expect(_isTrackingOn, true);
      expect(LeakTracking.phase.name, _test1TrackingOn);
    });

    testWidgets(_test2TrackingOffLeaks, (WidgetTester widgetTester) async {
      expect(_isTrackingOn, false);
      expect(LeakTracking.phase.name, null);
      await widgetTester.pumpWidget(StatelessLeakingWidget());
    });
  },
  skip: kIsWeb); // [intended] Leak tracking is off for web.

  testWidgetsWithLeakTracking(_test3TrackingOn, (WidgetTester widgetTester) async {
    expect(_isTrackingOn, true);
    expect(LeakTracking.phase.name, _test3TrackingOn);
    expect(LeakTracking.phase.isPaused, false);
  },
  skip: kIsWeb); // [intended] Leak tracking is off for web.
}
