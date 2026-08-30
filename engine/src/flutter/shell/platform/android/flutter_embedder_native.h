// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstddef>
#include <cstdint>
#include <mutex>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if defined(__ANDROID__)
#include <android/native_window.h>
#else
// Opaque forward declaration for non-Android unit test builds.
typedef struct ANativeWindow ANativeWindow;
#endif

namespace flutter {
namespace android {

/// @brief Quarantined native entry point and manager for the Android C-API
/// Embedder.
///
/// This class enforces strict GN and C-ABI isolation from legacy Skia /
/// internal UI headers, serving as the foundational shield for Phase 1.2+ of
/// the Android embedder migration.
class FlutterEmbedderNative {
 public:
  FlutterEmbedderNative();
  virtual ~FlutterEmbedderNative();

  /// @brief Checks whether the embedder C-API quarantine is active.
  /// @return True if quarantined and running strictly on top of embedder.h.
  static bool IsQuarantineEnforced();

  /// @brief Verifies that the embedder engine version is compatible with the
  /// current build.
  /// @return True if version verification succeeds.
  static bool VerifyEmbedderVersion();

  /// @brief Returns the version number of the Embedder C-API.
  static size_t GetEmbedderVersion();

  /// @brief Associates or clears the underlying ANativeWindow surface.
  /// Thread-safe and synchronizes against in-flight presentation.
  void SetNativeWindow(ANativeWindow* window);

  /// @brief Returns the current ANativeWindow surface pointer.
  /// @warning Unsafe raw pointer return susceptible to concurrent lifecycle
  /// races. Prefer AcquireNativeWindow() which increments reference count.
  [[deprecated("Use AcquireNativeWindow() to prevent dangling pointer races")]]
  ANativeWindow* GetNativeWindow();

  /// @brief Acquires and returns a reference-counted ANativeWindow pointer.
  /// The caller takes ownership of the acquired reference and must call
  /// ANativeWindow_release when done on Android. Thread-safe.
  ANativeWindow* AcquireNativeWindow();

  /// @brief Raw buffer descriptor for software presentation blitting.
  struct SoftwareBuffer {
    void* bits = nullptr;
    int32_t width = 0;
    int32_t height = 0;
    int32_t stride = 0;
    int32_t format = 0;
  };

#if defined(__ANDROID__)
  static constexpr int32_t kFormatRgba8888 = WINDOW_FORMAT_RGBA_8888;
  static constexpr int32_t kFormatRgbx8888 = WINDOW_FORMAT_RGBX_8888;
  static constexpr int32_t kFormatRgb565 = WINDOW_FORMAT_RGB_565;
#else
  static constexpr int32_t kFormatRgba8888 = 1;
  static constexpr int32_t kFormatRgbx8888 = 2;
  static constexpr int32_t kFormatRgb565 = 4;
#endif

  /// @brief Pure software raster blitter decoupled from OS handles for
  /// multi-platform testability and verification.
  ///
  /// Blits and formats premultiplied RGBA pixels from allocation to dst_buffer
  /// handling row strides, margin zeroing, bottom-row clearing, and RGB565
  /// un-premultiplication with clamping.
  static bool BlitSoftwareRaster(const void* allocation,
                                 size_t row_bytes,
                                 size_t height,
                                 const SoftwareBuffer& dst_buffer);

  /// @brief Blits software raster pixels directly to the ANativeWindow buffer
  /// using pure Android NDK APIs with zero Skia or engine internal
  /// dependencies.
  ///
  /// Thread-safe: Serializes with other presentation calls and synchronizes
  /// with SetNativeWindow teardown.
  ///
  /// @param allocation Pointer to the raw software pixel buffer (RGBA_8888,
  ///        premultiplied).
  /// @param row_bytes Byte stride per row in the allocation buffer.
  /// @param height Height of the allocation buffer in pixels.
  /// @return True if presentation succeeded, false otherwise.
  bool PresentSoftware(const void* allocation, size_t row_bytes, size_t height);

 private:
  std::mutex surface_mutex_;
  std::mutex presentation_mutex_;
  ANativeWindow* native_window_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
