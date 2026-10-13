// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_TEXTURE_SOURCE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_TEXTURE_SOURCE_H_

#include <android/hardware_buffer.h>

#include <cstdint>

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      One AHardwareBuffer handed to a hardware buffer external
///             texture.
///
struct HardwareBufferFrame {
  /// Valid until `release` is called.
  AHardwareBuffer* buffer = nullptr;
  void* release_user_data = nullptr;
  /// Called once, on the raster thread, when the texture no longer needs
  /// `buffer`.
  void (*release)(void* release_user_data) = nullptr;
};

//------------------------------------------------------------------------------
/// @brief      How a hardware buffer (ImageReader) external texture talks to
///             its producer.
///
///             The fields match the AHardwareBuffer texture source that the
///             embedder API is going to take.
///
struct HardwareBufferSource {
  void* user_data = nullptr;

  /// Called on the raster thread for every paint that is not frozen. Returns
  /// false if there is no frame; the texture then draws its last one again.
  bool (*acquire_frame)(void* user_data,
                        HardwareBufferFrame* frame_out) = nullptr;

  /// Whether the texture drops its current frame and its cache when the GPU
  /// context is destroyed, instead of keeping them.
  bool drop_frames_on_context_destroyed = false;

  /// Releases `user_data`. Called once, when the texture is destroyed.
  void (*destruction)(void* user_data) = nullptr;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_TEXTURE_SOURCE_H_
