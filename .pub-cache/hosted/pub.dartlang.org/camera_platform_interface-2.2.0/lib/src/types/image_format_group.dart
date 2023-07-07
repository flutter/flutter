// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Group of image formats that are comparable across Android and iOS platforms.
enum ImageFormatGroup {
  /// The image format does not fit into any specific group.
  unknown,

  /// Multi-plane YUV 420 format.
  ///
  /// This format is a generic YCbCr format, capable of describing any 4:2:0
  /// chroma-subsampled planar or semiplanar buffer (but not fully interleaved),
  /// with 8 bits per color sample.
  ///
  /// On Android, this is `android.graphics.ImageFormat.YUV_420_888`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat.html#YUV_420_888
  ///
  /// On iOS, this is `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`. See
  /// https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers/kcvpixelformattype_420ypcbcr8biplanarvideorange?language=objc
  yuv420,

  /// 32-bit BGRA.
  ///
  /// On iOS, this is `kCVPixelFormatType_32BGRA`. See
  /// https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers/kcvpixelformattype_32bgra?language=objc
  bgra8888,

  /// 32-big RGB image encoded into JPEG bytes.
  ///
  /// On Android, this is `android.graphics.ImageFormat.JPEG`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat#JPEG
  jpeg,
}

/// Extension on [ImageFormatGroup] to stringify the enum
extension ImageFormatGroupName on ImageFormatGroup {
  /// returns a String value for [ImageFormatGroup]
  /// returns 'unknown' if platform is not supported
  /// or if [ImageFormatGroup] is not supported for the platform
  String name() {
    switch (this) {
      case ImageFormatGroup.bgra8888:
        return 'bgra8888';
      case ImageFormatGroup.yuv420:
        return 'yuv420';
      case ImageFormatGroup.jpeg:
        return 'jpeg';
      case ImageFormatGroup.unknown:
      default:
        return 'unknown';
    }
  }
}
