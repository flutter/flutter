// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

/// Error codes that may occur during the camera initialization,
/// configuration or video streaming.
class CameraErrorCode {
  const CameraErrorCode._(this._type);

  final String _type;

  @override
  String toString() => _type;

  /// The camera is not supported.
  static const CameraErrorCode notSupported =
      CameraErrorCode._('cameraNotSupported');

  /// The camera is not found.
  static const CameraErrorCode notFound = CameraErrorCode._('cameraNotFound');

  /// The camera is not readable.
  static const CameraErrorCode notReadable =
      CameraErrorCode._('cameraNotReadable');

  /// The camera options are impossible to satisfy.
  static const CameraErrorCode overconstrained =
      CameraErrorCode._('cameraOverconstrained');

  /// The camera cannot be used or the permission
  /// to access the camera is not granted.
  static const CameraErrorCode permissionDenied =
      CameraErrorCode._('cameraPermission');

  /// The camera options are incorrect or attempted
  /// to access the media input from an insecure context.
  static const CameraErrorCode type = CameraErrorCode._('cameraType');

  /// Some problem occurred that prevented the camera from being used.
  static const CameraErrorCode abort = CameraErrorCode._('cameraAbort');

  /// The user media support is disabled in the current browser.
  static const CameraErrorCode security = CameraErrorCode._('cameraSecurity');

  /// The camera metadata is missing.
  static const CameraErrorCode missingMetadata =
      CameraErrorCode._('cameraMissingMetadata');

  /// The camera orientation is not supported.
  static const CameraErrorCode orientationNotSupported =
      CameraErrorCode._('orientationNotSupported');

  /// The camera torch mode is not supported.
  static const CameraErrorCode torchModeNotSupported =
      CameraErrorCode._('torchModeNotSupported');

  /// The camera zoom level is not supported.
  static const CameraErrorCode zoomLevelNotSupported =
      CameraErrorCode._('zoomLevelNotSupported');

  /// The camera zoom level is invalid.
  static const CameraErrorCode zoomLevelInvalid =
      CameraErrorCode._('zoomLevelInvalid');

  /// The camera has not been initialized or started.
  static const CameraErrorCode notStarted =
      CameraErrorCode._('cameraNotStarted');

  /// The video recording was not started.
  static const CameraErrorCode videoRecordingNotStarted =
      CameraErrorCode._('videoRecordingNotStarted');

  /// An unknown camera error.
  static const CameraErrorCode unknown = CameraErrorCode._('cameraUnknown');

  /// Returns a camera error code based on the media error.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code
  static CameraErrorCode fromMediaError(html.MediaError error) {
    switch (error.code) {
      case html.MediaError.MEDIA_ERR_ABORTED:
        return const CameraErrorCode._('mediaErrorAborted');
      case html.MediaError.MEDIA_ERR_NETWORK:
        return const CameraErrorCode._('mediaErrorNetwork');
      case html.MediaError.MEDIA_ERR_DECODE:
        return const CameraErrorCode._('mediaErrorDecode');
      case html.MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED:
        return const CameraErrorCode._('mediaErrorSourceNotSupported');
      default:
        return const CameraErrorCode._('mediaErrorUnknown');
    }
  }
}
