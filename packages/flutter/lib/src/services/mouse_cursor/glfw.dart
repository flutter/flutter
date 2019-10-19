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
class GLFWMouseCursor extends MouseCursor {
  /// TODOC
  /// When hidden is true, value is ignored.
  const GLFWMouseCursor({
    @required this.value,
    this.hidden = false,
    @required this.description,
  }) : assert(value != null), assert(description != null);

  /// TODOC
  final int value;

  /// TODOC
  final bool hidden;

  /// TODOC
  final String description;

  @override
  Future<void> onActivate(MouseCursorActivateDetails details) {
    return GLFWMouseCursorActions(details.mouseCursorChannel)
      .setDeviceAsSystemCursor(
        device: details.device,
        systemConstant: value,
        hidden: hidden,
      );
  }

  @override
  String describeCursor() => description;
}

/// TODOC
class GLFWSystemCursorCollection extends SystemCursorCollection {
  /// TODOC
  const GLFWSystemCursorCollection();

  @override
  MouseCursor get none => const GLFWMouseCursor(
    value: GLFWMouseCursorConstants.GLFW_ARROW_CURSOR,
    hidden: true,
    description: 'hidden',
  );

  @override
  MouseCursor get basic => const GLFWMouseCursor(
    value: GLFWMouseCursorConstants.GLFW_ARROW_CURSOR,
    description: 'arrow',
  );

  @override
  MouseCursor get click => const GLFWMouseCursor(
    value: GLFWMouseCursorConstants.GLFW_HAND_CURSOR,
    description: 'hand',
  );

  @override
  MouseCursor get text => const GLFWMouseCursor(
    value: GLFWMouseCursorConstants.GLFW_IBEAM_CURSOR,
    description: 'ibeam',
  );

  @override
  MouseCursor get grab => click;

  @override
  MouseCursor get grabbing => click;
}
