// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky_services/flutter/platform/haptic_feedback.mojom.dart' as mojom;

import 'shell.dart';

mojom.HapticFeedbackProxy _initHapticFeedbackProxy() {
  mojom.HapticFeedbackProxy proxy = new mojom.HapticFeedbackProxy.unbound();
  shell.connectToViewAssociatedService(proxy);
  return proxy;
}

final mojom.HapticFeedbackProxy _hapticFeedbackProxy = _initHapticFeedbackProxy();

/// Allows access to the haptic feedback interface on the device. This API is
/// intentionally terse since it invokes default platform behavior. It is not
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
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the intent to provide haptic feedback to the user
  ///   was successfully conveyed to the embedder. There may not be any actual
  ///   feedback if the device does not have a vibrator or one is disabled in
  ///   system settings.
  static Future<bool> vibrate() async {
    return (await _hapticFeedbackProxy.ptr.vibrate()).success;
  }
}
