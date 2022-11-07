// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('scheduleForcedFrame sets up frame callbacks', () async {
    SchedulerBinding.instance.scheduleForcedFrame();
    expect(SchedulerBinding.instance.platformDispatcher.onBeginFrame, isNotNull);
  });

  test('debugAssertNoTimeDilation does not throw if time dilate already reset', () async {
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
}
