// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

/// TODOC
@immutable
class _AndroidMouseCursorActions {
  /// TODOC
  const _AndroidMouseCursorActions(this.mouseCursorChannel);

  /// TODOC
  final MethodChannel mouseCursorChannel;

  /// TODOC
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

/// TODOC
class MouseCursorAndroidDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorAndroidDelegate(this._mouseCursorChannel);

  final MethodChannel _mouseCursorChannel;

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

  Future<bool> _activateSystemConstant({
    @required ActivateMouseCursorDetails details,
    @required int systemConstant,
  }) async {
    await _AndroidMouseCursorActions(_mouseCursorChannel)
      .setAsSystemCursor(systemConstant: systemConstant);
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  @override
  Future<bool> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) async {
    switch (shape) {
      case SystemCursorShape.none:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorAndroidDelegate.kSystemConstantNull,
        );
      case SystemCursorShape.basic:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorAndroidDelegate.kSystemConstantArrow,
        );
      case SystemCursorShape.click:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorAndroidDelegate.kSystemConstantHand,
        );
      case SystemCursorShape.text:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorAndroidDelegate.kSystemConstantText,
        );
      case SystemCursorShape.forbidden:
        return false;
      case SystemCursorShape.grab:
        return activateSystemCursor(details, SystemCursorShape.click);
      case SystemCursorShape.grabbing:
        return activateSystemCursor(details, SystemCursorShape.click);
      default:
        break;
    }
    return false;
  }
}
