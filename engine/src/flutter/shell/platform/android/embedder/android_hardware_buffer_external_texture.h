// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Manages zero-copy `AHardwareBuffer` Vulkan external textures
///             (`FlutterVulkanExternalTexture` with `ycbcr_conversion_info`)
///             and OpenGL ES external textures (`FlutterOpenGLTexture2` with
///             `uv_transform`) through the public C Embedder API
///             (RFC 410.0000, ADR-0006).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`. Guarantees that acquired
///             `AHardwareBuffer` handles remain pinned until the engine invokes
///             `FlutterVulkanExternalTexture.destruction_callback`.
///
class AndroidHardwareBufferExternalTexture {
 public:
  AndroidHardwareBufferExternalTexture(
      std::shared_ptr<JniDelegate> jni_delegate,
      const FlutterEngineProcTable& proc_table);

  ~AndroidHardwareBufferExternalTexture();

  /// Registers `texture_id` with the engine via
  /// `embedder_api_.RegisterExternalTexture`.
  bool RegisterTexture(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                       int64_t texture_id);

  /// Unregisters `texture_id` with the engine via
  /// `embedder_api_.UnregisterExternalTexture`.
  bool UnregisterTexture(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                         int64_t texture_id);

  /// Signals to the engine that a new frame is ready for `texture_id` via
  /// `embedder_api_.MarkExternalTextureFrameAvailable`.
  bool MarkFrameAvailable(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                          int64_t texture_id);

  /// Updates the UV coordinate transformation matrix for `texture_id`
  /// (e.g. from `SurfaceTexture.getTransformMatrix()`).
  void SetTextureUvTransform(int64_t texture_id,
                             const FlutterTransformation& uv_transform);

  /// Configures vendor YCbCr sampler conversion parameters for camera or video
  /// decoder `AHardwareBuffer` streams on `texture_id` (ADR-0006, Invariant 2).
  void SetTextureYcbcrConversionInfo(
      int64_t texture_id,
      const FlutterVulkanYcbcrConversionInfo& ycbcr_info);

  /// Configures the OpenGL texture name (`GL_TEXTURE_EXTERNAL_OES`) for
  /// `texture_id`.
  void SetOpenGLTextureName(int64_t texture_id,
                            uint32_t target,
                            uint32_t gl_texture_name);

  /// Pull-based callback invoked on the raster thread to populate a zero-copy
  /// `FlutterVulkanExternalTexture` backed by `AHardwareBuffer` (ADR-0006).
  bool AcquireVulkanExternalTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterVulkanExternalTexture* texture_out);

  /// Pull-based callback invoked on the raster thread to populate a
  /// `FlutterOpenGLTexture2` including `uv_transform` (ADR-0006).
  bool AcquireOpenGLExternalTextureFrame(int64_t texture_id,
                                         size_t width,
                                         size_t height,
                                         FlutterOpenGLTexture2* texture_out);

  size_t GetActiveBufferLeaseCount() const;

 private:
  struct TextureRecord {
    bool registered = false;
    FlutterTransformation uv_transform = {1.0, 0.0, 0.0, 0.0, 1.0,
                                          0.0, 0.0, 0.0, 1.0};
    bool has_ycbcr_info = false;
    FlutterVulkanYcbcrConversionInfo ycbcr_info = {};
    uint32_t gl_target = 0x8D65;  // GL_TEXTURE_EXTERNAL_OES
    uint32_t gl_texture_name = 0;
  };

  struct BufferLeaseContext {
    AndroidHardwareBufferExternalTexture* owner = nullptr;
    std::shared_ptr<JniDelegate> jni_delegate;
    uintptr_t hardware_buffer_handle = 0;
  };

  static void OnReleaseHardwareBufferLease(void* user_data);

  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};

  mutable std::mutex mutex_;
  std::unordered_map<int64_t, TextureRecord> textures_;
  size_t active_buffer_leases_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidHardwareBufferExternalTexture);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_
