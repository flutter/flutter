// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forceFramesEnabled defaults to false and uses normal lifecycle behavior', (
    WidgetTester tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.binding.forceFramesEnabled, isFalse);
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(tester.binding.framesEnabled, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);
  });

  testWidgets(
    'forceFramesEnabled when set to true, keeps frames enabled when hidden or paused but not when detached',
    (WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.forceFramesEnabled = true;
      expect(tester.binding.framesEnabled, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      expect(tester.binding.framesEnabled, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(tester.binding.framesEnabled, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      expect(tester.binding.framesEnabled, isFalse);
    },
  );

  testWidgets('forceFramesEnabled does not disable frames when app is active', (
    WidgetTester tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.forceFramesEnabled = false;
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(tester.binding.framesEnabled, isTrue);
  });

  testWidgets('forceFramesEnabled can be toggled on and off', (WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.binding.forceFramesEnabled, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(tester.binding.framesEnabled, isFalse);

    tester.binding.forceFramesEnabled = true;
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.forceFramesEnabled = false;
    expect(tester.binding.framesEnabled, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);
  });

  testWidgets(
    'forceFramesEnabled schedules frame when changed from false to true while app is hidden',
    (WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      expect(tester.binding.framesEnabled, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);

      tester.binding.forceFramesEnabled = true;
      expect(tester.binding.framesEnabled, isTrue);
      expect(tester.binding.hasScheduledFrame, isTrue);
    },
  );

  testWidgets('forceFramesEnabled never enables frames when detached, even when forced', (
    WidgetTester tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.forceFramesEnabled = true;
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    expect(tester.binding.framesEnabled, isFalse);
    expect(tester.binding.forceFramesEnabled, isTrue);
  });

  testWidgets('forceFramesEnabled resetInternalState clears force flag', (
    WidgetTester tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.forceFramesEnabled = true;
    expect(tester.binding.forceFramesEnabled, isTrue);

    tester.binding.resetInternalState();
    expect(tester.binding.forceFramesEnabled, isFalse);
  });
}
