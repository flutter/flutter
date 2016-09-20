// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/platform/haptic_feedback.dart' as mojom;

import 'shell.dart';

mojom.HapticFeedbackProxy _initHapticFeedbackProxy() {
  return shell.connectToApplicationService('mojo:flutter_platform', mojom.HapticFeedback.connectToService);
}

final mojom.HapticFeedbackProxy _hapticFeedbackProxy = _initHapticFeedbackProxy();

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
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the intent to provide haptic feedback to the user
  ///   was successfully conveyed to the embedder. There may not be any actual
  ///   feedback if the device does not have a vibrator or one is disabled in
  ///   system settings.
  static Future<bool> vibrate() {
    Completer<bool> completer = new Completer<bool>();
    _hapticFeedbackProxy.vibrate((bool result) {
      completer.complete(result);
    });
    return completer.future;
  }
}
