// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'recorder.dart';

/// Benchmarks the performance of the [defaultTargetPlatform] getter.
///
/// The getter relies on the expensive `window.matchMedia` and if not properly
/// cached can cause performance issues.
class BenchDefaultTargetPlatform extends RawRecorder {
  BenchDefaultTargetPlatform() : super(name: benchmarkName);

  static const String benchmarkName = 'default_target_platform';

  /// A dummy counter just to make sure the compiler doesn't inline the
  /// benchmark and make it a no-op.
  int counter = 0;

  @override
  void body(Profile profile) {
    profile.record('runtime', () {
      for (int i = 0; i < 10000; i++) {
        counter += defaultTargetPlatform.index;
      }
    }, reported: true);
  }
}
