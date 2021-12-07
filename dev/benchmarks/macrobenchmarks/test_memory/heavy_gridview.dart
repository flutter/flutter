// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/common.dart';
import 'package:macrobenchmarks/main.dart';

Future<void> endOfAnimation() async {
  do {
    await SchedulerBinding.instance!.endOfFrame;
  } while (SchedulerBinding.instance!.hasScheduledFrame);
}

Future<void> main() async {
  runApp(const MacrobenchmarksApp(initialRoute: kHeavyGridViewRouteName));
  await endOfAnimation();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  debugPrint('==== MEMORY BENCHMARK ==== READY ====');
}
