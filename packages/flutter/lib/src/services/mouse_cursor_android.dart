// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'mouse_cursor_platform.dart';
import 'platform_channel.dart';

// The channel interface with the platform.
//
// It is separated to a class for the conventience of reference by the shell
// implementation.
@immutable
class _AndroidPlatformActions {
  const _AndroidPlatformActions(this.mouseCursorChannel);

  final MethodChannel mouseCursorChannel;

  // Set cursor as a sytem cursor specified by `platformConstant`.
  Future<void> setAsSystemCursor({
    @required int platformConstant,
  }) {
    assert(platformConstant != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setAsSystemCursor',
      <String, dynamic>{
        'platformConstant': platformConstant,
      },
    );
  }
}

/// The implementation of [MouseCursorPlatformDelegate] that controls an
/// [Android](https://developer.android.com/reference) shell over a method
/// channel.
class MouseCursorAndroidDelegate extends MouseCursorPlatformDelegate {
  /// Create a [MouseCursorAndroidDelegate] by providing the method channel to use.
  ///
  /// The [mouseCursorChannel] must not be null, and is usually
  /// [SystemChannels.mouseCursor].
  MouseCursorAndroidDelegate({@required MethodChannel mouseCursorChannel})
    : assert(mouseCursorChannel != null),
      _platform = _AndroidPlatformActions(mouseCursorChannel);

  // System cursor constants are used to set system cursor on Android.
  // Must be kept in sync with Android's [PointerIcon#Constants](https://developer.android.com/reference/android/view/PointerIcon.html#constants_2)

  /// The same constant as Android's `PointerIcon.TYPE_DEFAULT`,
  /// used internally to set system cursor.
  static const int kPlatformConstantDefault = 1000;

  /// The same constant as Android's `PointerIcon.TYPE_ARROW`,
  /// used internally to set system cursor.
  static const int kPlatformConstantArrow = 1000;

  /// The same constant as Android's `PointerIcon.TYPE_GRAB`,
  /// used internally to set system cursor.
  static const int kPlatformConstantGrab = 1020;

  /// The same constant as Android's `PointerIcon.TYPE_GRABBING`,
  /// used internally to set system cursor.
  static const int kPlatformConstantGrabbing = 1021;

  /// The same constant as Android's `PointerIcon.TYPE_HAND`,
  /// used internally to set system cursor.
  static const int kPlatformConstantHand = 1002;

  /// The same constant as Android's `PointerIcon.TYPE_NULL`,
  /// used internally to set system cursor.
  static const int kPlatformConstantNull = 0;

  /// The same constant as Android's `PointerIcon.TYPE_TEXT`,
  /// used internally to set system cursor.
  static const int kPlatformConstantText = 1008;

  final _AndroidPlatformActions _platform;

  Future<bool> _activatePlatformConstant(int platformConstant) async {
    await _platform.setAsSystemCursor(platformConstant: platformConstant);
    return true;
  }

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    switch (details.systemShape) {
      case MouseCursorSystemShape.none:
        return _activatePlatformConstant(kPlatformConstantNull);
      case MouseCursorSystemShape.basic:
        return _activatePlatformConstant(kPlatformConstantArrow);
      case MouseCursorSystemShape.click:
        return _activatePlatformConstant(kPlatformConstantHand);
      case MouseCursorSystemShape.text:
        return _activatePlatformConstant(kPlatformConstantText);
      case MouseCursorSystemShape.forbidden:
        return false;
      case MouseCursorSystemShape.grab:
        return activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails(
          device: details.device,
          systemShape: MouseCursorSystemShape.click,
        ));
      case MouseCursorSystemShape.grabbing:
        return activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails(
          device: details.device,
          systemShape: MouseCursorSystemShape.click,
        ));
      default:
        break;
    }
    return false;
  }
}
