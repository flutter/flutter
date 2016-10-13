// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Allows access to the haptic feedback interface on the device. This API is
/// intentionally terse since it calls default platform behavior. It is not
/// suitable for use if you require more flexible access to device sensors and
/// peripherals.
class HapticFeedback {
  HapticFeedback._();

  /// Provides haptic feedback to the user for a short duration.
  ///
  /// Platform Specific Notes:
  ///
  /// * _iOS_: Uses the platform "sound" for vibration (via
  ///   AudioServicesPlaySystemSound)
  /// * _Android_: Uses the platform haptic feedback API that simulates a short
  ///   a short tap on a virtual keyboard.
  static Future<Null> vibrate() async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'HapticFeedback.vibrate',
      'args': const <Null>[],
    });
  }
}
