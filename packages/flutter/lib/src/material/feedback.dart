// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Provides platform-specific acoustic and/or haptic feedback for certain
/// actions.
///
/// See also:
/// * [FeedbackWrapper] to provide feedback for a gesture callback by
///   wrapping it.
class Feedback {
  Feedback._();

  /// Provides platform-specific feedback for a tap.
  static Future<Null> forTap(BuildContext context) async {
    switch(_platform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return SystemSound.play(SystemSoundType.click);
      default:
        return new Future<Null>.value();
    }
  }

  /// Provides platform-specific feedback for a long press.
  static Future<Null> forLongPress(BuildContext context) {
    switch(_platform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return HapticFeedback.vibrate();
      default:
        return new Future<Null>.value();
    }
  }

  static TargetPlatform _platform(BuildContext context) => Theme.of(context).platform;

}

/// Wraps a GestureCallback to provide platform-specific acoustic and/or haptic
/// feedback before executing the callback.
///
/// See also:
/// * [Feedback] to provide feedback without wrapping a callback.
class FeedbackWrapper {
  FeedbackWrapper._();

  /// Provides platform-specific feedback for a tap.
  static GestureTapCallback forTap(GestureTapCallback callback, BuildContext context) {
    if (callback == null)
      return null;
    return () {
      Feedback.forTap(context);
      callback();
    };
  }

  /// Provides platform-specific feedback for a long press.
  static GestureLongPressCallback forLongPress(GestureLongPressCallback callback, BuildContext context) {
    if (callback == null)
      return null;
    return () {
      Feedback.forLongPress(context);
      callback();
    };
  }
}
