// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'basic.dart';

/// TODOC
class GLFWMouseCursorConstants {
  // Must be kept in sync with
  // https://www.glfw.org/docs/latest/group__shapes.html

  static const int GLFW_ARROW_CURSOR = 0x00036001;

  static const int GLFW_IBEAM_CURSOR = 0x00036002;

  static const int GLFW_HAND_CURSOR = 0x00036004;
}

/// TODOC
@immutable
class GLFWMouseCursorActions {
  /// TODOC
  const GLFWMouseCursorActions(this.mouseCursorChannel);

  /// TODOC
  final MethodChannel mouseCursorChannel;

  /// TODOC
  Future<void> setDeviceAsSystemCursor({int device, int systemConstant, bool hidden}) {
    return mouseCursorChannel.invokeMethod<void>(
      'setDeviceAsSystemCursor',
      <String, dynamic>{
        'device': device,
        'systemConstant': systemConstant,
        'hidden': hidden,
      },
    );
  }
}

/// TODOC
@immutable
class MouseCursorGLFWDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorGLFWDelegate();

  Future<void> _activateSystemConstant({
    ActivateMouseCursorDetails details,
    int systemConstant,
    bool hidden,
  }) {
    return GLFWMouseCursorActions(details.mouseCursorChannel)
      .setDeviceAsSystemCursor(
        device: details.device,
        systemConstant: systemConstant,
        hidden: hidden,
      );
  }

  @override
  Future<void> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) {
    switch (shape) {
      case SystemCursorShape.none:
        return _activateSystemConstant(
          details: details,
          systemConstant: GLFWMouseCursorConstants.GLFW_ARROW_CURSOR,
          hidden: true,
        );
      case SystemCursorShape.basic:
        break;
      case SystemCursorShape.click:
        return _activateSystemConstant(
          details: details,
          systemConstant: GLFWMouseCursorConstants.GLFW_HAND_CURSOR,
        );
      case SystemCursorShape.text:
        return _activateSystemConstant(
          systemConstant: GLFWMouseCursorConstants.GLFW_IBEAM_CURSOR,
        );
      case SystemCursorShape.forbidden:
        break;
      case SystemCursorShape.grab:
        return activateSystemCursor(details, SystemCursorShape.click);
      case SystemCursorShape.grabbing:
        return activateSystemCursor(details, SystemCursorShape.click);
    }
    return _activateSystemConstant(
      systemConstant: GLFWMouseCursorConstants.GLFW_ARROW_CURSOR,
    );
  }
}
