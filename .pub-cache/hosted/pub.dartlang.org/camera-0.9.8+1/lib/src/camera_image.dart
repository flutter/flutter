// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';

// TODO(stuartmorgan): Remove all of these classes in a breaking change, and
// vend the platform interface versions directly. See
// https://github.com/flutter/flutter/issues/104188

/// A single color plane of image data.
///
/// The number and meaning of the planes in an image are determined by the
/// format of the Image.
class Plane {
  Plane._fromPlatformInterface(CameraImagePlane plane)
      : bytes = plane.bytes,
        bytesPerPixel = plane.bytesPerPixel,
        bytesPerRow = plane.bytesPerRow,
        height = plane.height,
        width = plane.width;

  // Only used by the deprecated codepath that's kept to avoid breaking changes.
  // Never called by the plugin itself.
  Plane._fromPlatformData(Map<dynamic, dynamic> data)
      : bytes = data['bytes'] as Uint8List,
        bytesPerPixel = data['bytesPerPixel'] as int?,
        bytesPerRow = data['bytesPerRow'] as int,
        height = data['height'] as int?,
        width = data['width'] as int?;

  /// Bytes representing this plane.
  final Uint8List bytes;

  /// The distance between adjacent pixel samples on Android, in bytes.
  ///
  /// Will be `null` on iOS.
  final int? bytesPerPixel;

  /// The row stride for this color plane, in bytes.
  final int bytesPerRow;

  /// Height of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android
  final int? height;

  /// Width of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android.
  final int? width;
}

/// Describes how pixels are represented in an image.
class ImageFormat {
  ImageFormat._fromPlatformInterface(CameraImageFormat format)
      : group = format.group,
        raw = format.raw;

  // Only used by the deprecated codepath that's kept to avoid breaking changes.
  // Never called by the plugin itself.
  ImageFormat._fromPlatformData(this.raw) : group = _asImageFormatGroup(raw);

  /// Describes the format group the raw image format falls into.
  final ImageFormatGroup group;

  /// Raw version of the format from the Android or iOS platform.
  ///
  /// On Android, this is an `int` from class `android.graphics.ImageFormat`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat
  ///
  /// On iOS, this is a `FourCharCode` constant from Pixel Format Identifiers.
  /// See https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers?language=objc
  final dynamic raw;
}

// Only used by the deprecated codepath that's kept to avoid breaking changes.
// Never called by the plugin itself.
ImageFormatGroup _asImageFormatGroup(dynamic rawFormat) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    switch (rawFormat) {
      // android.graphics.ImageFormat.YUV_420_888
      case 35:
        return ImageFormatGroup.yuv420;
      // android.graphics.ImageFormat.JPEG
      case 256:
        return ImageFormatGroup.jpeg;
    }
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    switch (rawFormat) {
      // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      case 875704438:
        return ImageFormatGroup.yuv420;
      // kCVPixelFormatType_32BGRA
      case 1111970369:
        return ImageFormatGroup.bgra8888;
    }
  }

  return ImageFormatGroup.unknown;
}

/// A single complete image buffer from the platform camera.
///
/// This class allows for direct application access to the pixel data of an
/// Image through one or more [Uint8List]. Each buffer is encapsulated in a
/// [Plane] that describes the layout of the pixel data in that plane. The
/// [CameraImage] is not directly usable as a UI resource.
///
/// Although not all image formats are planar on iOS, we treat 1-dimensional
/// images as single planar images.
class CameraImage {
  /// Creates a [CameraImage] from the platform interface version.
  CameraImage.fromPlatformInterface(CameraImageData data)
      : format = ImageFormat._fromPlatformInterface(data.format),
        height = data.height,
        width = data.width,
        planes = List<Plane>.unmodifiable(data.planes.map<Plane>(
            (CameraImagePlane plane) => Plane._fromPlatformInterface(plane))),
        lensAperture = data.lensAperture,
        sensorExposureTime = data.sensorExposureTime,
        sensorSensitivity = data.sensorSensitivity;

  /// Creates a [CameraImage] from method channel data.
  @Deprecated('Use fromPlatformInterface instead')
  CameraImage.fromPlatformData(Map<dynamic, dynamic> data)
      : format = ImageFormat._fromPlatformData(data['format']),
        height = data['height'] as int,
        width = data['width'] as int,
        lensAperture = data['lensAperture'] as double?,
        sensorExposureTime = data['sensorExposureTime'] as int?,
        sensorSensitivity = data['sensorSensitivity'] as double?,
        planes = List<Plane>.unmodifiable((data['planes'] as List<dynamic>)
            .map<Plane>((dynamic planeData) =>
                Plane._fromPlatformData(planeData as Map<dynamic, dynamic>)));

  /// Format of the image provided.
  ///
  /// Determines the number of planes needed to represent the image, and
  /// the general layout of the pixel data in each [Uint8List].
  final ImageFormat format;

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
  final List<Plane> planes;

  /// The aperture settings for this image.
  ///
  /// Represented as an f-stop value.
  final double? lensAperture;

  /// The sensor exposure time for this image in nanoseconds.
  final int? sensorExposureTime;

  /// The sensor sensitivity in standard ISO arithmetic units.
  final double? sensorSensitivity;
}
