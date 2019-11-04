// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'platform_channel.dart';

/// The standard implementation [MouseCursorPlatform] that communicates with
/// the platform over a method channel.
///
/// This is the implementation used by [MouseTracker].
class StandardMouseCursorPlatform extends MouseCursorPlatform {
  /// Create a [StandardMouseCursorPlatform] by providing the channel.
  ///
  /// The channel must not be null, and is usually [SystemChannels.mouseCursor].
  StandardMouseCursorPlatform(this.channel) : assert(channel != null);

  /// The channel to use to communicate with the platform.
  final MethodChannel channel;

  @override
  Future<bool> activateSystemShape(MouseCursorActivateSystemShapeDetails details) {
    assert(details != null);
    return channel.invokeMethod<void>(
      'activateSystemShape',
      <String, dynamic>{
        'device': details.device,
        'systemShape': details.systemShape,
      },
    );
  }
}
