// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/services.dart';

/// Tracks how often feedback has been requested since its instantiation.
///
/// It replaces the MockMethodCallHandler of [SystemChannels.platform] and
/// cannot be used in combination with other classes that do the same.
class FeedbackTester {
  FeedbackTester() {
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate')
        _hapticCount++;
      if (methodCall.method == 'SystemSound.play' &&
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

  /// Stops tracking.
  void dispose() {
    SystemChannels.platform.setMockMethodCallHandler(null);
  }
}
