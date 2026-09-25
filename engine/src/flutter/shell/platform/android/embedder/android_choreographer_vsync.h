// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_CHOREOGRAPHER_VSYNC_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_CHOREOGRAPHER_VSYNC_H_

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_set>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Pure C Embedder API vsync coordinator bridging
///             `FlutterProjectArgs.vsync_callback` and Android's
///             `AChoreographer` / `Choreographer` frame callback to
///             `embedder_api_.OnVsync` (RFC 410.0000, ADR-0001, ADR-0004).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`. Supports variable refresh rate displays
///             (60Hz / 90Hz / 120Hz LTPO) and safely guards against duplicate
///             or post-teardown baton consumption.
///
class AndroidChoreographerVsync {
 public:
  AndroidChoreographerVsync(std::shared_ptr<JniDelegate> jni_delegate,
                            const FlutterEngineProcTable& proc_table,
                            double initial_refresh_rate_fps = 60.0);

  ~AndroidChoreographerVsync();

  /// Updates the display refresh rate (in frames per second, e.g. 60.0, 90.0,
  /// 120.0) used to compute `frame_target_time_nanos` when the platform
  /// callback provides only the vsync start timestamp.
  void SetRefreshRateFps(double refresh_rate_fps);

  uint64_t GetRefreshPeriodNanos() const;

  /// Invoked by the engine's `FlutterProjectArgs.vsync_callback` when the
  /// Animator requests the next vsync frame window.
  void RequestVsync(intptr_t baton);

  /// Invoked when Android's `Choreographer.FrameCallback.doFrame` or
  /// `AChoreographer_frameCallback64` fires on the UI thread.
  ///
  /// Validates `baton`, normalizes `frame_target_time_nanos`, and invokes
  /// `embedder_api_.OnVsync`.
  bool OnChoreographerFrame(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                            intptr_t baton,
                            uint64_t frame_start_time_nanos,
                            uint64_t frame_target_time_nanos);

  /// Cancels all pending batons (called on engine teardown or GPU suspension).
  void CancelPendingBatons();

  size_t GetPendingBatonCount() const;

 private:
  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};

  mutable std::mutex mutex_;
  uint64_t refresh_period_nanos_ = 16666666ULL;
  std::unordered_set<intptr_t> pending_batons_;
  bool accept_unsolicited_batons_ = true;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidChoreographerVsync);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_CHOREOGRAPHER_VSYNC_H_
