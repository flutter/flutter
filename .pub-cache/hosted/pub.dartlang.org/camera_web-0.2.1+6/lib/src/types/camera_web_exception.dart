// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_web/src/types/types.dart';

/// An exception thrown when the camera with id [cameraId] reports
/// an initialization, configuration or video streaming error,
/// or enters into an unexpected state.
///
/// This error should be emitted on the `onCameraError` stream
/// of the camera platform.
class CameraWebException implements Exception {
  /// Creates a new instance of [CameraWebException]
  /// with the given error [cameraId], [code] and [description].
  CameraWebException(this.cameraId, this.code, this.description);

  /// The id of the camera this exception is associated to.
  int cameraId;

  /// The error code of this exception.
  CameraErrorCode code;

  /// The description of this exception.
  String description;

  @override
  String toString() => 'CameraWebException($cameraId, $code, $description)';
}
