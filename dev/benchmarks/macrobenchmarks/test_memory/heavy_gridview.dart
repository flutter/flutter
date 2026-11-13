// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/common.dart';
import 'package:macrobenchmarks/main.dart';

const Duration _initialSettleDelay = Duration(milliseconds: 50);
const Duration _tapSyncDelay = Duration(milliseconds: 200);
const Offset _flingOffset = Offset(0.0, -1000.0);
const double _flingSpeed = 10000.0;
const int _flingIterations = 3;

Future<void> endOfAnimation() async {
  do {
    await SchedulerBinding.instance.endOfFrame;
  } while (SchedulerBinding.instance.hasScheduledFrame);
}

Future<void> main() async {
  final ready = Completer<void>();
  runApp(
    GestureDetector(
      onTap: () {
        if (!ready.isCompleted) {
          debugPrint('==== MEMORY BENCHMARK ==== TAPPED ====');
          ready.complete();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: const IgnorePointer(child: MacrobenchmarksApp(initialRoute: kHeavyGridViewRouteName)),
    ),
  );
  await endOfAnimation();
  await Future<void>.delayed(_initialSettleDelay);
  debugPrint('==== MEMORY BENCHMARK ==== READY ====');

  await ready.future;
  debugPrint('Continuing...');

  // Wait out any errant taps due to synchronization.
  await Future<void>.delayed(_tapSyncDelay);

  // Remove onTap handler, enable pointer events for app.
  runApp(
    GestureDetector(
      child: const IgnorePointer(
        ignoring: false,
        child: MacrobenchmarksApp(initialRoute: kHeavyGridViewRouteName),
      ),
    ),
  );
  await endOfAnimation();

  final WidgetController controller = LiveWidgetController(WidgetsBinding.instance);
  for (var iteration = 0; iteration < _flingIterations; iteration += 1) {
    debugPrint('Flinging... $iteration/$_flingIterations');
    await controller.fling(find.byType(Scrollable), _flingOffset, _flingSpeed);
    await endOfAnimation();
  }

  debugPrint('==== MEMORY BENCHMARK ==== DONE ====');
}
