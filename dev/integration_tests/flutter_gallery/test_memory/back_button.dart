// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See //dev/devicelab/bin/tasks/flutter_gallery__memory_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter_test/flutter_test.dart';

Future<void> endOfAnimation() async {
  do {
    await SchedulerBinding.instance.endOfFrame;
  } while (SchedulerBinding.instance.hasScheduledFrame);
}

int iteration = 0;

class LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('==== MEMORY BENCHMARK ==== $state ====');
    debugPrint('This was lifecycle event number $iteration in this instance');
  }
}

Future<void> main() async {
  runApp(const GalleryApp());
  await endOfAnimation();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  debugPrint('==== MEMORY BENCHMARK ==== READY ====');
  WidgetsBinding.instance.addObserver(LifecycleObserver());
}
