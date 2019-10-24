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
class _GLFWPlatformActions {
  const _GLFWPlatformActions(this.mouseCursorChannel);

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

  // Hide cursor, or unhide cursor.
  Future<void> setHidden({
    @required bool hidden,
  }) {
    assert(hidden != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setHidden',
      <String, dynamic>{
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
  /// The [mouseCursorChannel] must not be null, and is usually
  /// [SystemChannels.mouseCursor].
  MouseCursorGLFWDelegate({@required MethodChannel mouseCursorChannel})
    : assert(mouseCursorChannel != null),
      _platform = _GLFWPlatformActions(mouseCursorChannel);

  // System cursor constants are used to set system cursor on GLFW.
  // Must be kept in sync with GLFW's
  // [Standard cursor shapes](https://www.glfw.org/docs/latest/group__shapes.html)

  /// The same constant as GLFW's `GLFW_ARROW_CURSOR`,
  /// used internally to set system cursor.
  static const int kPlatformConstantArrow = 0x00036001;

  /// The same constant as GLFW's `GLFW_IBEAM_CURSOR`,
  /// used internally to set system cursor.
  static const int kPlatformConstantIbeam = 0x00036002;

  /// The same constant as GLFW's `GLFW_HAND_CURSOR`,
  /// used internally to set system cursor.
  static const int kPlatformConstantHand = 0x00036004;

  final _GLFWPlatformActions _platform;
  bool _isHidden = false;

  Future<bool> _activatePlatformConstant(int platformConstant) async {
    if (_isHidden) {
      _isHidden = false;
      await _platform.setHidden(hidden: false);
    }
    await _platform.setAsSystemCursor(platformConstant: platformConstant);
    return true;
  }

  Future<bool> _hideCursor() async {
    if (!_isHidden) {
      _isHidden = true;
      await _platform.setHidden(hidden: true);
    }
    return true;
  }

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    switch (details.systemShape) {
      case MouseCursorSystemShape.none:
        return _hideCursor();
      case MouseCursorSystemShape.basic:
        return _activatePlatformConstant(MouseCursorGLFWDelegate.kPlatformConstantArrow);
      case MouseCursorSystemShape.click:
        return _activatePlatformConstant(MouseCursorGLFWDelegate.kPlatformConstantHand);
      case MouseCursorSystemShape.text:
        return _activatePlatformConstant(MouseCursorGLFWDelegate.kPlatformConstantIbeam);
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
