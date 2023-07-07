// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../camera_platform_interface.dart';

/// Options for configuring camera streaming.
///
/// Currently unused; this exists for future-proofing of the platform interface
/// API.
@immutable
class CameraImageStreamOptions {}

/// A single color plane of image data.
///
/// The number and meaning of the planes in an image are determined by its
/// format.
@immutable
class CameraImagePlane {
  /// Creates a new instance with the given bytes and optional metadata.
  const CameraImagePlane({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
    this.height,
    this.width,
  });

  /// Bytes representing this plane.
  final Uint8List bytes;

  /// The row stride for this color plane, in bytes.
  final int bytesPerRow;

  /// The distance between adjacent pixel samples in bytes, when available.
  final int? bytesPerPixel;

  /// Height of the pixel buffer, when available.
  final int? height;

  /// Width of the pixel buffer, when available.
  final int? width;
}

/// Describes how pixels are represented in an image.
@immutable
class CameraImageFormat {
  /// Create a new format with the given cross-platform group and raw underyling
  /// platform identifier.
  const CameraImageFormat(this.group, {required this.raw});

  /// Describes the format group the raw image format falls into.
  final ImageFormatGroup group;

  /// Raw version of the format from the underlying platform.
  ///
  /// On Android, this should be an `int` from class
  /// `android.graphics.ImageFormat`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat
  ///
  /// On iOS, this should be a `FourCharCode` constant from Pixel Format
  /// Identifiers. See
  /// https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers
  final dynamic raw;
}

/// A single complete image buffer from the platform camera.
///
/// This class allows for direct application access to the pixel data of an
/// Image through one or more [Uint8List]. Each buffer is encapsulated in a
/// [CameraImagePlane] that describes the layout of the pixel data in that
/// plane. [CameraImageData] is not directly usable as a UI resource.
///
/// Although not all image formats are planar on all platforms, this class
/// treats 1-dimensional images as single planar images.
@immutable
class CameraImageData {
  /// Creates a new instance with the given format, planes, and metadata.
  const CameraImageData({
    required this.format,
    required this.planes,
    required this.height,
    required this.width,
    this.lensAperture,
    this.sensorExposureTime,
    this.sensorSensitivity,
  });

  /// Format of the image provided.
  ///
  /// Determines the number of planes needed to represent the image, and
  /// the general layout of the pixel data in each [Uint8List].
  final CameraImageFormat format;

  /// Height of the image in pixels.
  ///
  /// For formats where some color channels are subsampled, this is the height
  /// of the largest-resolution plane.
  final int height;

  /// Width of the image in pixels.
  ///
  /// For formats where some color channels are subsampled, this is the width
  /// of the largest-resolution plane.
  final int width;

  /// The pixels planes for this image.
  ///
  /// The number of planes is determined by the format of the image.
  final List<CameraImagePlane> planes;

  /// The aperture settings for this image.
  ///
  /// Represented as an f-stop value.
  final double? lensAperture;

  /// The sensor exposure time for this image in nanoseconds.
  final int? sensorExposureTime;

  /// The sensor sensitivity in standard ISO arithmetic units.
  final double? sensorSensitivity;
}
