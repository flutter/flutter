// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// Specifies where an allocation resides and how it may be used.
enum StorageMode {
  /// Allocations can be mapped onto the hosts address space and also be used by
  /// the device.
  hostVisible,

  /// Allocations can only be used by the device. This location is optimal for
  /// use by the device. If the host needs to access these allocations, the
  /// data must first be copied into a host visible allocation.
  devicePrivate,

  /// Used by the device for temporary render targets. These allocations cannot
  /// be copied to or from other allocations. This storage mode is only valid
  /// for Textures.
  ///
  /// These allocations reside in tile memory which has higher bandwidth, lower
  /// latency and lower power consumption. The total device memory usage is
  /// also lower as a separate allocation does not need to be created in
  /// device memory. Prefer using these allocations for intermediates like depth
  /// and stencil buffers.
  deviceTransient,
}

enum PixelFormat {
  unknown,
  a8UNormInt,
  r8UNormInt,
  r8g8UNormInt,
  r8g8b8a8UNormInt,
  r8g8b8a8UNormIntSRGB,
  b8g8r8a8UNormInt,
  b8g8r8a8UNormIntSRGB,
  r32g32b32a32Float,
  r16g16b16a16Float,
  b10g10r10XR,
  b10g10r10XRSRGB,
  b10g10r10a10XR,
  // Depth and stencil formats.
  s8UInt,
  d24UnormS8Uint,
  d32FloatS8UInt,
}

enum TextureCoordinateSystem {
  /// Alternative coordinate system used when uploading texture data from the
  /// host.
  /// (0, 0) is the bottom-left of the image with +Y going up.
  uploadFromHost,

  /// Default coordinate system.
  /// (0, 0) is the top-left of the image with +Y going down.
  renderToTexture,
}
