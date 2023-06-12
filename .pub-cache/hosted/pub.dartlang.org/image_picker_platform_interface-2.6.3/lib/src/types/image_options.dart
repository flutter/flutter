// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Specifies image-specific options for picking.
class ImageOptions {
  /// Creates an instance with the given [maxHeight], [maxWidth], [imageQuality]
  /// and [requestFullMetadata].
  const ImageOptions({
    this.maxHeight,
    this.maxWidth,
    this.imageQuality,
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

  /// If true, requests full image metadata, which may require extra permissions
  /// on some platforms, (e.g., NSPhotoLibraryUsageDescription on iOS).
  //
  // Defaults to true.
  final bool requestFullMetadata;
}
