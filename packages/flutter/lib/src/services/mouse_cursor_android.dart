// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'mouse_cursor.dart';
import 'platform_channel.dart';

// The channel interface with the platform.
//
// It is separated to a class for the conventience of reference by the shell
// implementation.
@immutable
class _AndroidPlatformActions {
  const _AndroidPlatformActions(this.mouseCursorChannel);

  final MethodChannel mouseCursorChannel;

  // Set cursor as a sytem cursor specified by `systemConstant`.
  Future<void> setAsSystemCursor({
    @required int systemConstant,
  }) {
    assert(systemConstant != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setAsSystemCursor',
      <String, dynamic>{
        'systemConstant': systemConstant,
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
  static const int kSystemConstantDefault = 1000;

  /// The same constant as Android's `PointerIcon.TYPE_ARROW`,
  /// used internally to set system cursor.
  static const int kSystemConstantArrow = 1000;

  /// The same constant as Android's `PointerIcon.TYPE_GRAB`,
  /// used internally to set system cursor.
  static const int kSystemConstantGrab = 1020;

  /// The same constant as Android's `PointerIcon.TYPE_GRABBING`,
  /// used internally to set system cursor.
  static const int kSystemConstantGrabbing = 1021;

  /// The same constant as Android's `PointerIcon.TYPE_HAND`,
  /// used internally to set system cursor.
  static const int kSystemConstantHand = 1002;

  /// The same constant as Android's `PointerIcon.TYPE_NULL`,
  /// used internally to set system cursor.
  static const int kSystemConstantNull = 0;

  /// The same constant as Android's `PointerIcon.TYPE_TEXT`,
  /// used internally to set system cursor.
  static const int kSystemConstantText = 1008;

  final _AndroidPlatformActions _platform;

  Future<bool> _activateSystemConstant(int systemConstant) async {
    await _platform.setAsSystemCursor(systemConstant: systemConstant);
    return true;
  }

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    switch (details.shape) {
      case SystemMouseCursorShape.none:
        return _activateSystemConstant(kSystemConstantNull);
      case SystemMouseCursorShape.basic:
        return _activateSystemConstant(kSystemConstantArrow);
      case SystemMouseCursorShape.click:
        return _activateSystemConstant(kSystemConstantHand);
      case SystemMouseCursorShape.text:
        return _activateSystemConstant(kSystemConstantText);
      case SystemMouseCursorShape.forbidden:
        return false;
      case SystemMouseCursorShape.grab:
        return activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails(
          device: details.device,
          shape: SystemMouseCursorShape.click,
        ));
      case SystemMouseCursorShape.grabbing:
        return activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails(
          device: details.device,
          shape: SystemMouseCursorShape.click,
        ));
      default:
        break;
    }
    return false;
  }
}
