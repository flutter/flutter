// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

/// TODOC
@immutable
class _GLFWMouseCursorActions {
  /// TODOC
  const _GLFWMouseCursorActions(this.mouseCursorChannel);

  /// TODOC
  final MethodChannel mouseCursorChannel;

  /// TODOC
  Future<void> setAsSystemCursor({
    @required int systemConstant,
    @required bool hidden,
  }) {
    assert(systemConstant != null);
    assert(hidden != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setAsSystemCursor',
      <String, dynamic>{
        'systemConstant': systemConstant,
        'hidden': hidden,
      },
    );
  }
}

/// TODOC
class MouseCursorGLFWDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  MouseCursorGLFWDelegate(this._mouseCursorChannel);

  final MethodChannel _mouseCursorChannel;

  // System cursor constants are used to set system cursor on GLFW.
  // Must be kept in sync with GLFW's [Standard cursor shapes](https://www.glfw.org/docs/latest/group__shapes.html)

  /// The same constant as GLFW's `GLFW_ARROW_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantArrow = 0x00036001;

  /// The same constant as GLFW's `GLFW_IBEAM_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantIbeam = 0x00036002;

  /// The same constant as GLFW's `GLFW_HAND_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantHand = 0x00036004;

  Future<bool> _activateSystemConstant({
    @required ActivateMouseCursorDetails details,
    @required int systemConstant,
  }) async {
    await _GLFWMouseCursorActions(_mouseCursorChannel)
      .setAsSystemCursor(
        systemConstant: systemConstant,
        hidden: false,
      );
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  Future<bool> _hideCursor({
    @required ActivateMouseCursorDetails details,
  }) async {
    await _GLFWMouseCursorActions(_mouseCursorChannel)
      .setAsSystemCursor(
        systemConstant: 0,
        hidden: true,
      );
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  @override
  Future<bool> activateSystemCursor(
    ActivateMouseCursorDetails details,
    SystemCursorShape shape,
  ) async {
    switch (shape) {
      case SystemCursorShape.none:
        return _hideCursor(
          details: details,
        );
      case SystemCursorShape.basic:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorGLFWDelegate.kSystemConstantArrow,
        );
      case SystemCursorShape.click:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorGLFWDelegate.kSystemConstantHand,
        );
      case SystemCursorShape.text:
        return _activateSystemConstant(
          details: details,
          systemConstant: MouseCursorGLFWDelegate.kSystemConstantIbeam,
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
