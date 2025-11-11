// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('scheduleForcedFrame sets up frame callbacks', () {
    SchedulerBinding.instance.scheduleForcedFrame();
    expect(SchedulerBinding.instance.platformDispatcher.onBeginFrame, isNotNull);
  });

  test('Ticker.forceFrames requests forced frames', () async {
    final Ticker t = Ticker((_) {});
    t.forceFrames = true;
    final TickerFuture f = t.start();
    addTearDown(() async {
      t.stop();
      await f;
    });
    // A forced frame should be scheduled even if frames are otherwise disabled.
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
  });

  test('debugAssertNoTimeDilation does not throw if time dilate already reset', () {
    timeDilation = 2.0;
    timeDilation = 1.0;
    SchedulerBinding.instance.debugAssertNoTimeDilation('reason'); // no error
  });

  test('debugAssertNoTimeDilation throw if time dilate not reset', () async {
    timeDilation = 3.0;
    expect(
      () => SchedulerBinding.instance.debugAssertNoTimeDilation('reason'),
      throwsA(isA<FlutterError>().having((FlutterError e) => e.message, 'message', 'reason')),
    );
    timeDilation = 1.0;
  });

  test('Adding a persistent frame callback during a persistent frame callback', () {
    bool calledBack = false;
    SchedulerBinding.instance.addPersistentFrameCallback((Duration timeStamp) {
      if (!calledBack) {
        SchedulerBinding.instance.addPersistentFrameCallback((Duration timeStamp) {
          calledBack = true;
        });
      }
    });
    SchedulerBinding.instance.handleBeginFrame(null);
    SchedulerBinding.instance.handleDrawFrame();
    expect(calledBack, false);
    SchedulerBinding.instance.handleBeginFrame(null);
    SchedulerBinding.instance.handleDrawFrame();
    expect(calledBack, true);
  });
}
