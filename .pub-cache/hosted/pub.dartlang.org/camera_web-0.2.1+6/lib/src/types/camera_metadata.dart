// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Metadata used along the camera description
/// to store additional web-specific camera details.
@immutable
class CameraMetadata {
  /// Creates a new instance of [CameraMetadata]
  /// with the given [deviceId] and [facingMode].
  const CameraMetadata({required this.deviceId, required this.facingMode});

  /// Uniquely identifies the camera device.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaDeviceInfo/deviceId
  final String deviceId;

  /// Describes the direction the camera is facing towards.
  /// May be `user`, `environment`, `left`, `right`
  /// or null if the facing mode is not available.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/facingMode
  final String? facingMode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CameraMetadata &&
        other.deviceId == deviceId &&
        other.facingMode == facingMode;
  }

  @override
  int get hashCode => Object.hash(deviceId.hashCode, facingMode.hashCode);
}
