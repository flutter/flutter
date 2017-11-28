// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'assertions.dart';
import 'platform.dart';
import 'print.dart';

/// Returns true if none of the foundation library debug variables have been
/// changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// The `debugPrintOverride` argument can be specified to indicate the expected
/// value of the [debugPrint] variable. This is useful for test frameworks that
/// override [debugPrint] themselves and want to check that their own custom
/// value wasn't overridden by a test.
///
/// See [https://docs.flutter.io/flutter/foundation/foundation-library.html] for
/// a complete list.
bool debugAssertAllFoundationVarsUnset(String reason, { DebugPrintCallback debugPrintOverride: debugPrintThrottled }) {
  assert(() {
    if (debugPrint != debugPrintOverride ||
        debugDefaultTargetPlatformOverride != null)
      throw new FlutterError(reason);
    return true;
  }());
  return true;
}

/// Arguments to whitelist [Timeline] events in order to be shown in the
/// developer centric version of the Observatory Timeline.
const Map<String, String> timelineWhitelistArguments = const <String, String>{
  'mode': 'basic'
};
