// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '_goldens_io.dart'
  if (dart.library.html) '_goldens_web.dart' as flutter_goldens;

/// If true, leak tracking will be enabled for all tests `testWidgetsWithLeakTracking`.
///
/// By default, the constant is false.
/// To enable the leak tracking for all tests, either pass the compilation flag
/// `--dart-define=flutter_test_config.leak_tracking=true` or
/// temporarily pass `defaultValue = true` to `fromEnvironment` in the constant definition.
///
/// To enable leak tracking for an individual test file, add the line to the test `main`:
/// `LeakTesting.settings = LeakTesting.settings.withTrackedAll()`.
const bool _kLeakTracking = bool.fromEnvironment('LEAK_TRACKING');

/// Test configuration for each test library in this directory.
///
/// See https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  // Enable checks because there are many implementations of [RenderBox] in this
  // package can benefit from the additional validations.
  debugCheckIntrinsicSizes = true;

  // Make tap() et al fail if the given finder specifies a widget that would not
  // receive the event.
  WidgetController.hitTestWarningShouldBeFatal = true;

  // Leak tracking is off by default.
  // To enable it, follow doc for [_kLeakTracking].
  if (_kLeakTracking) {
    LeakTesting.enable();

    LeakTracking.warnForUnsupportedPlatforms = false;

    LeakTesting.settings = LeakTesting
      .settings
      .withTrackedAll()
      // TODO(polina-c): clean up leaks and stop ignoring them.
      // https://github.com/flutter/flutter/issues/137311
      .withIgnored(
        allNotGCed: true,
        notDisposed: <String, int?>{
          'OverlayEntry': null,
        },
      );
  }

  // Enable golden file testing using Skia Gold.
  return flutter_goldens.testExecutable(testMain);
}
