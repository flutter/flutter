// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

FlutterEmbedderNative::FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterEmbedderNative");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative quarantined target.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);
  std::lock_guard<std::mutex> surf_lock(surface_mutex_);
#if defined(__ANDROID__)
  if (native_window_) {
    ANativeWindow_release(native_window_);
    native_window_ = nullptr;
  }
#endif
}

bool FlutterEmbedderNative::IsQuarantineEnforced() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsQuarantineEnforced");
  // The quarantine enforces zero internal UI / Skia header inclusions.
  return true;
}

bool FlutterEmbedderNative::VerifyEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::VerifyEmbedderVersion");
  return FLUTTER_ENGINE_VERSION >= 1;
}

size_t FlutterEmbedderNative::GetEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEmbedderVersion");
  return FLUTTER_ENGINE_VERSION;
}

void FlutterEmbedderNative::SetNativeWindow(ANativeWindow* window) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetNativeWindow");
  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);
  std::lock_guard<std::mutex> surf_lock(surface_mutex_);
  if (native_window_ == window) {
    return;
  }
#if defined(__ANDROID__)
  if (window) {
    ANativeWindow_acquire(window);
  }
  if (native_window_) {
    ANativeWindow_release(native_window_);
  }
#endif
  native_window_ = window;
}

ANativeWindow* FlutterEmbedderNative::GetNativeWindow() {
  std::lock_guard<std::mutex> lock(surface_mutex_);
  return native_window_;
}

ANativeWindow* FlutterEmbedderNative::AcquireNativeWindow() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::AcquireNativeWindow");
  std::lock_guard<std::mutex> lock(surface_mutex_);
#if defined(__ANDROID__)
  if (native_window_) {
    ANativeWindow_acquire(native_window_);
  }
#endif
  return native_window_;
}

bool FlutterEmbedderNative::BlitSoftwareRaster(
    const void* allocation,
    size_t row_bytes,
    size_t height,
    const SoftwareBuffer& dst_buffer) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::BlitSoftwareRaster");
  if (!allocation || row_bytes < 4 || (row_bytes % 4 != 0) || height == 0) {
    return false;
  }
  if (!dst_buffer.bits || dst_buffer.width <= 0 || dst_buffer.height <= 0 ||
      dst_buffer.stride <= 0 || dst_buffer.stride < dst_buffer.width) {
    return false;
  }

  const size_t src_width = row_bytes / 4;
  const size_t copy_width_px =
      std::min(src_width, static_cast<size_t>(dst_buffer.width));
  const size_t copy_height =
      std::min(height, static_cast<size_t>(dst_buffer.height));

  const uint8_t* src_row = reinterpret_cast<const uint8_t*>(allocation);
  uint8_t* dst_row = reinterpret_cast<uint8_t*>(dst_buffer.bits);

  if (dst_buffer.format == kFormatRgba8888) {
    const size_t copy_bytes_per_row = copy_width_px * 4;
    const size_t dst_stride_bytes = dst_buffer.stride * 4;

    for (size_t y = 0; y < copy_height; ++y) {
      std::memcpy(dst_row, src_row, copy_bytes_per_row);

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  } else if (dst_buffer.format == kFormatRgbx8888) {
    const size_t copy_bytes_per_row = copy_width_px * 4;
    const size_t dst_stride_bytes = dst_buffer.stride * 4;

    for (size_t y = 0; y < copy_height; ++y) {
      const uint32_t* src_px = reinterpret_cast<const uint32_t*>(src_row);
      uint32_t* dst_px = reinterpret_cast<uint32_t*>(dst_row);

      for (size_t x = 0; x < copy_width_px; ++x) {
        // Little endian: byte 0=R, 1=G, 2=B, 3=X. Force opaque alpha channel on
        // RGBX.
        dst_px[x] = src_px[x] | 0xFF000000;
      }

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  } else if (dst_buffer.format == kFormatRgb565) {
    const size_t copy_bytes_per_row = copy_width_px * 2;
    const size_t dst_stride_bytes = dst_buffer.stride * 2;

    for (size_t y = 0; y < copy_height; ++y) {
      const uint32_t* src_px = reinterpret_cast<const uint32_t*>(src_row);
      uint16_t* dst_px = reinterpret_cast<uint16_t*>(dst_row);

      for (size_t x = 0; x < copy_width_px; ++x) {
        uint32_t pixel = src_px[x];
        // Premultiplied RGBA (Little Endian: R=byte0, G=byte1, B=byte2,
        // A=byte3)
        uint8_t r = pixel & 0xFF;
        uint8_t g = (pixel >> 8) & 0xFF;
        uint8_t b = (pixel >> 16) & 0xFF;
        uint8_t a = (pixel >> 24) & 0xFF;

        if (a > 0 && a < 255) {
          r = static_cast<uint8_t>(std::min<uint32_t>(255, (r * 255) / a));
          g = static_cast<uint8_t>(std::min<uint32_t>(255, (g * 255) / a));
          b = static_cast<uint8_t>(std::min<uint32_t>(255, (b * 255) / a));
        }

        dst_px[x] = static_cast<uint16_t>(((r >> 3) << 11) | ((g >> 2) << 5) |
                                          (b >> 3));
      }

      // Clear remaining row margin and stride padding
      if (copy_bytes_per_row < dst_stride_bytes) {
        std::memset(dst_row + copy_bytes_per_row, 0,
                    dst_stride_bytes - copy_bytes_per_row);
      }

      src_row += row_bytes;
      dst_row += dst_stride_bytes;
    }

    // Clear remaining bottom rows if destination buffer is taller than src
    if (copy_height < static_cast<size_t>(dst_buffer.height)) {
      const size_t remaining_rows =
          static_cast<size_t>(dst_buffer.height) - copy_height;
      std::memset(dst_row, 0, remaining_rows * dst_stride_bytes);
    }

    return true;
  }

  FML_LOG(ERROR) << "Unsupported buffer format for software presentation: "
                 << dst_buffer.format;
  return false;
}

bool FlutterEmbedderNative::PresentSoftware(const void* allocation,
                                            size_t row_bytes,
                                            size_t height) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::PresentSoftware");
  if (!allocation || row_bytes == 0 || height == 0) {
    return false;
  }

  std::lock_guard<std::mutex> pres_lock(presentation_mutex_);

#if defined(__ANDROID__)
  ANativeWindow* window = nullptr;
  {
    std::lock_guard<std::mutex> lock(surface_mutex_);
    if (!native_window_) {
      return false;
    }
    window = native_window_;
    ANativeWindow_acquire(window);
  }

  // RAII guard to guarantee ANativeWindow_release on all exit paths.
  struct WindowReleaser {
    ANativeWindow* win;
    ~WindowReleaser() {
      if (win) {
        ANativeWindow_release(win);
      }
    }
  } releaser{window};

  ANativeWindow_Buffer native_buffer;
  if (ANativeWindow_lock(window, &native_buffer, nullptr) != 0) {
    FML_LOG(ERROR)
        << "Failed to lock ANativeWindow buffer for software presentation.";
    return false;
  }

  // RAII guard to guarantee ANativeWindow_unlockAndPost on all exit paths.
  struct BufferUnlocker {
    ANativeWindow* win;
    ~BufferUnlocker() {
      if (win) {
        ANativeWindow_unlockAndPost(win);
      }
    }
  } unlocker{window};

  SoftwareBuffer buffer;
  buffer.bits = native_buffer.bits;
  buffer.width = native_buffer.width;
  buffer.height = native_buffer.height;
  buffer.stride = native_buffer.stride;
  buffer.format = native_buffer.format;

  return BlitSoftwareRaster(allocation, row_bytes, height, buffer);
#else
  // Non-Android host stub for testing
  std::lock_guard<std::mutex> lock(surface_mutex_);
  return native_window_ != nullptr;
#endif
}

}  // namespace android
}  // namespace flutter
