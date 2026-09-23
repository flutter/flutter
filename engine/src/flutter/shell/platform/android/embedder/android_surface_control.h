// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SURFACE_CONTROL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SURFACE_CONTROL_H_

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      RAII owner for POSIX `synchronization_fence_fd` handles exported
///             by Impeller Vulkan via `FlutterBackingStorePresentInfo`
///             (RFC 410.0000, ADR-0005, Invariant 3).
///
///             Immediately resets `present_info->synchronization_fence_fd = -1`
///             upon acquisition to prevent double-close hazards, and guarantees
///             `closer(fd)` is invoked on every early return or error path
///             unless explicitly released to `SurfaceControl.Transaction`.
///
class ScopedSyncFenceFd {
 public:
  using CloserFn = std::function<int(int)>;

  explicit ScopedSyncFenceFd(int* fd_slot, CloserFn closer = nullptr);
  explicit ScopedSyncFenceFd(FlutterBackingStorePresentInfo* present_info,
                             CloserFn closer = nullptr);
  ~ScopedSyncFenceFd();

  ScopedSyncFenceFd(ScopedSyncFenceFd&& other) noexcept;
  ScopedSyncFenceFd& operator=(ScopedSyncFenceFd&& other) noexcept;

  bool IsValid() const { return fd_ >= 0; }

  int Get() const { return fd_; }

  /// Releases ownership of the file descriptor after it has been transferred to
  /// `SurfaceControl.Transaction.setBuffer` and resets the local descriptor to
  /// `-1`.
  int Release();

  /// Explicitly closes the descriptor if valid and resets `fd_` to `-1`.
  void Reset();

 private:
  int fd_ = -1;
  CloserFn closer_;

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedSyncFenceFd);
};

//------------------------------------------------------------------------------
/// @brief      Manages per-view `ANativeWindow` surface lifecycles, synchronous
///             surface destruction, and Hybrid Composition++ (HCPP)
///             `SurfaceControl` layer pooling and sync-fence handoff
///             (RFC 410.0000, ADR-0004, ADR-0005).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`. All native window and layer trees are
///             strictly keyed by `FlutterViewId`.
///
class AndroidSurfaceControl {
 public:
  using FenceCloserFn = ScopedSyncFenceFd::CloserFn;
  using WindowReleaserFn = std::function<void(uintptr_t)>;

  AndroidSurfaceControl(std::shared_ptr<JniDelegate> jni_delegate,
                        const FlutterEngineProcTable& proc_table,
                        FenceCloserFn fence_closer = nullptr,
                        WindowReleaserFn window_releaser = nullptr);

  ~AndroidSurfaceControl();

  /// Attaches a native window surface for `view_id` (`0` for the implicit
  /// primary view, or non-zero for secondary presentation/multi-window views)
  /// and dispatches initial viewport metrics via `embedder_api_`.
  bool NotifySurfaceCreated(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                            FlutterViewId view_id,
                            uintptr_t native_window_handle,
                            int32_t width,
                            int32_t height,
                            double pixel_ratio);

  /// Updates the viewport metrics for `view_id` via `embedder_api_`.
  bool NotifySurfaceChanged(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                            FlutterViewId view_id,
                            int32_t width,
                            int32_t height,
                            double pixel_ratio);

  /// Synchronously detaches the rendering surface for `view_id`, releases all
  /// pooled `SurfaceControl` layers, and completes
  /// `embedder_api_.NotifyDestroyed` / `embedder_api_.RemoveView` before
  /// returning to Android OS (ADR-0004, Invariant 5).
  bool NotifySurfaceDestroyed(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                              FlutterViewId view_id);

  /// Presents an HCPP backing store `AHardwareBuffer` and takes immediate POSIX
  /// ownership of `present_info->synchronization_fence_fd` (ADR-0005,
  /// Invariant 3).
  ///
  /// On every code path (success or error),
  /// `present_info->synchronization_fence_fd` is reset to `-1`, and the
  /// descriptor is either handed off to
  /// `SurfaceTransactionProvider::SetBufferWithFence` or closed via
  /// `fence_closer_`.
  bool PresentBackingStore(FlutterViewId view_id,
                           int64_t layer_id,
                           uintptr_t hardware_buffer_handle,
                           int32_t width,
                           int32_t height,
                           FlutterBackingStorePresentInfo* present_info);

  /// Commits the pending `SurfaceControl.Transaction` for `view_id` and
  /// recycles any layers that were not presented in the current frame back into
  /// the view's `free_layer_pool`.
  bool CommitTransaction(FlutterViewId view_id);

  /// Returns whether `view_id` currently has an attached native window surface.
  bool HasAttachedSurface(FlutterViewId view_id) const;

  /// Returns the attached native window handle for `view_id`.
  uintptr_t GetNativeWindowHandle(FlutterViewId view_id) const;

  /// Returns the number of active and pooled `SurfaceControl` handles for
  /// `view_id` (used for host unit test characterization).
  size_t GetActiveLayerCount(FlutterViewId view_id) const;
  size_t GetPooledLayerCount(FlutterViewId view_id) const;

 private:
  struct ViewSurfaceRecord {
    uintptr_t native_window_handle = 0;
    int32_t width = 0;
    int32_t height = 0;
    double pixel_ratio = 1.0;
    bool surface_attached = false;
    std::unordered_map<int64_t, uintptr_t> active_layers;
    std::unordered_set<int64_t> touched_layers_in_frame;
    std::vector<uintptr_t> free_layer_pool;
  };

  void ReleaseAllLayersForViewLocked(ViewSurfaceRecord* record);

  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};
  FenceCloserFn fence_closer_;
  WindowReleaserFn window_releaser_;

  std::atomic<bool> first_frame_dispatched_{false};

  mutable std::mutex mutex_;
  std::unordered_map<FlutterViewId, ViewSurfaceRecord> views_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceControl);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_SURFACE_CONTROL_H_
