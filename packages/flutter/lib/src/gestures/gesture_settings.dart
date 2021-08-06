// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// The device specific gesture settings scaled into logical pixels.
///
/// See also:
///
///  * [GestureSettings], the configuration that this is derived from.
@immutable
class DeviceGestureSettings {
  /// Create a new [DeviceGestureSettings] with configured settings in logical
  /// pixels.
  const DeviceGestureSettings({
    this.touchSlop,
  });

  /// Create a new [DeviceGestureSettings] from the current window.
  factory DeviceGestureSettings.fromWindow(ui.SingletonFlutterWindow window) {
    final double? physicalTouchSlop = window.viewConfiguration.gestureSettings.physicalTouchSlop;
    return DeviceGestureSettings(
      touchSlop: physicalTouchSlop == null ? null : physicalTouchSlop / window.devicePixelRatio
    );
  }

  /// The touch slop value from the [gestureSettings] in logical pixels, or
  /// `null` if it was not set.
  final double? touchSlop;

  @override
  int get hashCode => ui.hashValues(touchSlop, 23);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is DeviceGestureSettings
      && other.touchSlop == touchSlop;
  }
}
