// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Allows access to the haptic feedback interface on the device.
///
/// This API is intentionally terse since it calls default platform behavior. It
/// is not suitable for precise control of the system's haptic feedback module.
class HapticFeedback {
  HapticFeedback._();

  /// Provides haptic feedback to the user for a short duration.
  ///
  /// On iOS, this uses the platform "sound" for vibration (via
  /// `AudioServicesPlaySystemSound`).
  ///
  /// On Android, this uses the platform haptic feedback API to simulates a
  /// short tap on a virtual keyboard.
  static Future<Null> vibrate() async {
    await PlatformMessages.invokeMethod('flutter/platform', 'HapticFeedback.vibrate');
  }
}
