// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

// The channel interface with the platform.
//
// It is separated to a class for the conventience of reference by the shell
// implementation.
@immutable
class _GLFWMouseCursorActions {
  const _GLFWMouseCursorActions(this.mouseCursorChannel);

  final MethodChannel mouseCursorChannel;

  // Set cursor as a sytem cursor specified by `systemConstant`, and/or hidden.
  //
  // If `hidden` is true, `systemConstant` is ignored.
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

/// The implementation of [MouseCursorPlatformDelegate] that controls
/// [GLFW](https://www.glfw.org) over a method channel.
class MouseCursorGLFWDelegate extends MouseCursorPlatformDelegate {
  /// Create a [MouseCursorGLFWDelegate] by providing the method channel to use.
  ///
  /// The [mouseCursorChannel] must not be null.
  MouseCursorGLFWDelegate({@required this.mouseCursorChannel})
    : assert(mouseCursorChannel != null);

  /// The method channel to control the platform with.
  final MethodChannel mouseCursorChannel;

  // System cursor constants are used to set system cursor on GLFW.
  // Must be kept in sync with GLFW's
  // [Standard cursor shapes](https://www.glfw.org/docs/latest/group__shapes.html)

  /// The same constant as GLFW's `GLFW_ARROW_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantArrow = 0x00036001;

  /// The same constant as GLFW's `GLFW_IBEAM_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantIbeam = 0x00036002;

  /// The same constant as GLFW's `GLFW_HAND_CURSOR`,
  /// used internally to set system cursor.
  static const int kSystemConstantHand = 0x00036004;

  Future<bool> _activateSystemConstant(int systemConstant) async {
    await _GLFWMouseCursorActions(mouseCursorChannel)
      .setAsSystemCursor(
        systemConstant: systemConstant,
        hidden: false,
      );
    return true;
  }

  Future<bool> _hideCursor() async {
    await _GLFWMouseCursorActions(mouseCursorChannel)
      .setAsSystemCursor(
        systemConstant: 0,
        hidden: true,
      );
    return true;
  }

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    switch (details.shape) {
      case SystemMouseCursorShape.none:
        return _hideCursor();
      case SystemMouseCursorShape.basic:
        return _activateSystemConstant(MouseCursorGLFWDelegate.kSystemConstantArrow);
      case SystemMouseCursorShape.click:
        return _activateSystemConstant(MouseCursorGLFWDelegate.kSystemConstantHand);
      case SystemMouseCursorShape.text:
        return _activateSystemConstant(MouseCursorGLFWDelegate.kSystemConstantIbeam);
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
