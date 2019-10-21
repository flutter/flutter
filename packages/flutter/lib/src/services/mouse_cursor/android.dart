// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

/// TODOC
class AndroidMouseCursorConstants {
  // Must be kept in sync with
  // https://developer.android.com/reference/android/view/PointerIcon.html

  static const int TYPE_DEFAULT = 1000;

  static const int TYPE_ARROW = 1000;

  static const int TYPE_GRAB = 1020;

  static const int TYPE_GRABBING = 1021;

  static const int TYPE_HAND = 1002;

  static const int TYPE_NULL = 0;

  static const int TYPE_TEXT = 1008;
}

/// TODOC
@immutable
class _AndroidMouseCursorActions {
  /// TODOC
  const _AndroidMouseCursorActions(this.mouseCursorChannel);

  /// TODOC
  final MethodChannel mouseCursorChannel;

  /// TODOC
  Future<void> setDeviceAsSystemCursor({int device, int systemConstant}) {
    return mouseCursorChannel.invokeMethod<void>(
      'setDeviceAsSystemCursor',
      <String, dynamic>{
        'device': device,
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

  Future<bool> _activateSystemConstant({
    ActivateMouseCursorDetails details,
    int systemConstant,
  }) async {
    await _AndroidMouseCursorActions(_mouseCursorChannel)
      .setDeviceAsSystemCursor(device: details.device, systemConstant: systemConstant);
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  @override
  Future<bool> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) async {
    switch (shape) {
      case SystemCursorShape.none:
        return _activateSystemConstant(
          details: details,
          systemConstant: AndroidMouseCursorConstants.TYPE_NULL,
        );
      case SystemCursorShape.basic:
        return _activateSystemConstant(
          systemConstant: AndroidMouseCursorConstants.TYPE_ARROW,
        );
      case SystemCursorShape.click:
        return _activateSystemConstant(
          details: details,
          systemConstant: AndroidMouseCursorConstants.TYPE_HAND,
        );
      case SystemCursorShape.text:
        return _activateSystemConstant(
          details: details,
          systemConstant: AndroidMouseCursorConstants.TYPE_TEXT,
        );
      case SystemCursorShape.forbidden:
        return false;
      case SystemCursorShape.grab:
        return activateSystemCursor(details, SystemCursorShape.click);
      case SystemCursorShape.grabbing:
        return activateSystemCursor(details, SystemCursorShape.click);
    }
    return false;
  }
}
