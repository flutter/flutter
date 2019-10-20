// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'basic.dart';

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
class AndroidMouseCursorActions {
  /// TODOC
  const AndroidMouseCursorActions(this.mouseCursorChannel);

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
class AndroidSystemCursorCollection extends SystemCursorCollection {
  /// TODOC
  const AndroidSystemCursorCollection();

  Future<void> _activateSystemConstant({
    ActivateMouseCursorDetails details,
    int systemConstant,
  }) {
    return AndroidMouseCursorActions(details.mouseCursorChannel)
      .setDeviceAsSystemCursor(device: details.device, systemConstant: systemConstant);
  }

  @override
  Future<void> activateShape(ActivateMouseCursorDetails details, SystemCursorShape shape) {
    switch (shape) {
      case SystemCursorShape.none:
        return _activateSystemConstant(
          details: details,
          systemConstant: AndroidMouseCursorConstants.TYPE_NULL,
        );
      case SystemCursorShape.basic:
        break;
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
        break;
      case SystemCursorShape.grab:
        return activateShape(details, SystemCursorShape.click);
      case SystemCursorShape.grabbing:
        return activateShape(details, SystemCursorShape.click);
    }
    return _activateSystemConstant(
      systemConstant: AndroidMouseCursorConstants.TYPE_ARROW,
    );
  }
}
