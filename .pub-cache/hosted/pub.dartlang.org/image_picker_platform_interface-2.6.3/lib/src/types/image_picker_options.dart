// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'types.dart';

/// Specifies options for picking a single image from the device's camera or gallery.
class ImagePickerOptions {
  /// Creates an instance with the given [maxHeight], [maxWidth], [imageQuality],
  /// [referredCameraDevice] and [requestFullMetadata].
  const ImagePickerOptions({
    this.maxHeight,
    this.maxWidth,
    this.imageQuality,
    this.preferredCameraDevice = CameraDevice.rear,
    this.requestFullMetadata = true,
  });

  /// The maximum width of the image, in pixels.
  ///
  /// If null, the image will only be resized if [maxHeight] is specified.
  final double? maxWidth;

  /// The maximum height of the image, in pixels.
  ///
  /// If null, the image will only be resized if [maxWidth] is specified.
  final double? maxHeight;

  /// Modifies the quality of the image, ranging from 0-100 where 100 is the
  /// original/max quality.
  ///
  /// Compression is only supported for certain image types such as JPEG. If
  /// compression is not supported for the image that is picked, a warning
  /// message will be logged.
  ///
  /// If null, the image will be returned with the original quality.
  final int? imageQuality;

  /// Used to specify the camera to use when the `source` is [ImageSource.camera].
  ///
  /// Ignored if the source is not [ImageSource.camera], or the chosen camera is not
  /// supported on the device. Defaults to [CameraDevice.rear].
  final CameraDevice preferredCameraDevice;

  /// If true, requests full image metadata, which may require extra permissions
  /// on some platforms, (e.g., NSPhotoLibraryUsageDescription on iOS).
  //
  // Defaults to true.
  final bool requestFullMetadata;
}
