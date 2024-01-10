// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '_goldens_io.dart'
  if (dart.library.html) '_goldens_web.dart' as flutter_goldens;

/// If true, leak tracking is enabled for all `testWidgets`.
///
/// By default it is false.
/// To enable the leak tracking, either pass the compilation flag
/// `--dart-define LEAK_TRACKING=true` or set the environment variable `LEAK_TRACKING` to `true`.
///
/// See documentation for [testWidgets] on how to except individual tests.
bool isLeakTrackingEnabled() {
  if (kIsWeb) {
    return false;
  }
  // The values can be different: https://github.com/dart-lang/sdk/issues/54568
  return const bool.fromEnvironment('LEAK_TRACKING') || (bool.tryParse(Platform.environment['LEAK_TRACKING'] ?? '')  ?? false);
}

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

  if (isLeakTrackingEnabled()) {
    LeakTesting.enable();

    LeakTracking.warnForUnsupportedPlatforms = false;

    LeakTesting.settings = LeakTesting
      .settings
      .withIgnored(
        allNotGCed: true,
      );

    // Print is here in spite of
    // https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#only-log-actionable-messages-to-the-console
    // to provide a way to detect if the env variable is passed as expected on bots, that is not obvious.
    // Sometimes the bot's environment contains `LEAK_TRACKING=true` but the value is not passed to the test.
    // https://github.com/dart-lang/sdk/issues/54568
    debugPrint('Leak tracking is enabled.');
  }

  // Enable golden file testing using Skia Gold.
  return flutter_goldens.testExecutable(testMain);
}
