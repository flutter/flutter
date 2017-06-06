// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

/// [Color] constants that describe colors commonly used in iOS applications.
class CupertinoColors {
  CupertinoColors._();

  /// iOS 10's default blue color. Used to indicate active elements such as
  /// buttons, selected tabs and your own chat bubbles.
  static const Color activeBlue = const Color(0xFF007AFF);

  /// iOS 10's default green color. Used to indicate active accents such as
  /// the switch in its on state and some accent buttons such as the call button
  /// and Apple Map's 'Go' button.
  static const Color activeGreen = const Color(0xFF4CD964);

  /// Opaque white color. Used for backgrounds and fonts against dark backgrounds.
  static const Color white = const Color(0xFFFFFFFF);

  /// Opaque black color. Used for texts against light backgrounds.
  static const Color black = const Color(0xFF000000);

  /// Used in iOS 10 for light background fills such as the chat bubble background.
  static const Color lightBackgroundGray = const Color(0xFFE5E5EA);

  /// Used in iOS 10 for unselected selectables such as tab bar items in their
  /// inactive state.
  ///
  /// Not the same gray as disabled buttons etc.
  static const Color inactiveGray = const Color(0xFF929292);

  /// Used for iOS 10 for destructive actions such as the delete actions in
  /// table view cells and dialogs.
  ///
  /// Not the same red as the camera shutter or springboard icon notifications
  /// or the foreground red theme in various native apps such as HealthKit.
  static const Color destructiveRed = const Color(0xFFFF3B30);
}
