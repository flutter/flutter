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
@immutable
class AndroidSystemMouseCursor extends MouseCursor {
  /// TODOC
  const AndroidSystemMouseCursor({
    @required this.value,
    @required this.description,
  }) : assert(value != null), assert(description != null);

  /// TODOC
  final int value;

  /// TODOC
  final String description;

  @override
  Future<void> onActivate(MouseCursorActivateDetails details) {
    return AndroidMouseCursorActions(details.mouseCursorChannel)
      .setDeviceAsSystemCursor(device: details.device, systemConstant: value);
  }

  @override
  String describeCursor() => description;
}

/// TODOC
class AndroidSystemCursorCollection extends SystemCursorCollection {
  /// TODOC
  const AndroidSystemCursorCollection();

  @override
  MouseCursor get none => const AndroidSystemMouseCursor(
    value: AndroidMouseCursorConstants.TYPE_NULL,
    description: 'null',
  );

  @override
  MouseCursor get basic => const AndroidSystemMouseCursor(
    value: AndroidMouseCursorConstants.TYPE_ARROW,
    description: 'arrow',
  );

  @override
  MouseCursor get click => const AndroidSystemMouseCursor(
    value: AndroidMouseCursorConstants.TYPE_HAND,
    description: 'hand',
  );

  @override
  MouseCursor get text => const AndroidSystemMouseCursor(
    value: AndroidMouseCursorConstants.TYPE_TEXT,
    description: 'text',
  );

  @override
  MouseCursor get grab => click;

  @override
  MouseCursor get grabbing => click;
}
