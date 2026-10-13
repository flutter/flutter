// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_TEXTURE_SOURCE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_TEXTURE_SOURCE_H_

#include <android/hardware_buffer.h>

#include <cstdint>

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      How a SurfaceTexture external texture talks to its producer.
///             The engine makes every call on the raster thread, with the GL
///             ES context of the texture current.
///
///             The fields match the OpenGL texture stream source that the
///             embedder API is going to take, so the texture classes do not
///             depend on JNI.
///
struct SurfaceTextureSource {
  void* user_data = nullptr;

  /// Attaches the producer to `texture_name`, a GL_TEXTURE_EXTERNAL_OES
  /// texture.
  void (*attach)(void* user_data, uint32_t texture_name) = nullptr;

  /// Latches the newest frame and writes its UV transform, a column-major 4x4
  /// matrix, to `transformation_out`.
  void (*update)(void* user_data, float transformation_out[16]) = nullptr;

  /// Detaches the producer from its texture, which deletes the texture name.
  void (*detach)(void* user_data) = nullptr;

  /// Whether a frame arrived since the last update. Only asked when the
  /// texture is painted frozen. Optional; null means no.
  bool (*has_pending_frame)(void* user_data) = nullptr;

  /// Releases `user_data`. Called once, when the texture is destroyed.
  void (*destruction)(void* user_data) = nullptr;
};

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
