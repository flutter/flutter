// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// Tracks how often feedback has been requested since its instantiation.
class FeedbackTester {
  FeedbackTester() {
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) {
      if (methodCall.method == "HapticFeedback.vibrate")
        _hapticCount++;
      if (methodCall.method == "SystemSound.play" &&
          methodCall.arguments == SystemSoundType.click.toString())
        _clickSoundCount++;
    });
  }

  /// Number of times haptic feedback was requested (vibration).
  int get hapticCount => _hapticCount;
  int _hapticCount = 0;

  /// Number of times the click sound was requested to play.
  int get clickSoundCount => _clickSoundCount;
  int _clickSoundCount = 0;
}