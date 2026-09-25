// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/android_surface_control.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Value-captured representation of a single
///             `FlutterPlatformViewMutation` (RFC 410.0000, ADR-0005,
///             Invariant 4).
///
struct CapturedPlatformViewMutation {
  FlutterPlatformViewMutationType type =
      kFlutterPlatformViewMutationTypeOpacity;
  double opacity = 1.0;
  FlutterRect clip_rect = {};
  FlutterRoundedRect clip_rrect = {};
  FlutterTransformation transformation = {};
};

//------------------------------------------------------------------------------
/// @brief      Value-captured representation of a single `FlutterLayer` within
///             a frame presentation slice (RFC 410.0000, ADR-0005, Invariant
///             4).
///
struct CapturedLayer {
  FlutterLayerContentType type = kFlutterLayerContentTypeBackingStore;
  int64_t identifier = 0;
  FlutterPoint offset = {};
  FlutterSize size = {};
  uintptr_t hardware_buffer_handle = 0;
  const void* software_allocation = nullptr;
  size_t software_row_bytes = 0;
  size_t software_height = 0;
  int synchronization_fence_fd = -1;
  std::vector<CapturedPlatformViewMutation> mutations;

  CapturedLayer();
  ~CapturedLayer();

  CapturedLayer(CapturedLayer&& other) noexcept;
  CapturedLayer& operator=(CapturedLayer&& other) noexcept;

  void ResetFence();

  FML_DISALLOW_COPY_AND_ASSIGN(CapturedLayer);
};

//------------------------------------------------------------------------------
/// @brief      Immutable per-view frame state captured **by value** inside
///             `present_view_callback` before dispatching to the platform
///             thread (RFC 410.0000, ADR-0005, Invariant 4).
///
struct CapturedViewFrameState {
  FlutterViewId view_id = 0;
  std::vector<CapturedLayer> layers;
};

//------------------------------------------------------------------------------
/// @brief      Multi-view safe `FlutterCompositor` and Platform Views
///             coordinator for Hybrid Composition++ (HCPP) and Texture Layer
///             Hybrid Composition (TLHC) (RFC 410.0000, ADR-0005).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`. Enforces Invariant 4: zero mutable
///             per-frame state is stored on the controller; all `FlutterLayer`
///             slices and `FlutterPlatformViewMutation` stacks are captured by
///             value inside the `present_view_callback` closure before posting
///             to the platform task runner.
///
class AndroidPlatformViewsController {
 public:
  using TaskRunnerDispatcher =
      std::function<void(const std::function<void()>&)>;

  struct CommittedViewSummary {
    FlutterViewId view_id = 0;
    size_t backing_store_layer_count = 0;
    size_t platform_view_layer_count = 0;
    std::vector<int64_t> platform_view_ids;
    std::vector<size_t> mutation_counts_per_view;
    uint64_t committed_frames = 0;
  };

  AndroidPlatformViewsController(
      std::shared_ptr<JniDelegate> jni_delegate,
      AndroidSurfaceControl* surface_control,
      TaskRunnerDispatcher platform_dispatcher = nullptr);

  ~AndroidPlatformViewsController();

  /// Deep-copies the engine's `FlutterLayer**` slice and all nested
  /// `FlutterPlatformViewMutation` arrays by value, taking immediate ownership
  /// of any `synchronization_fence_fd` handles (resetting the engine's
  /// `synchronization_fence_fd` to `-1`).
  static CapturedViewFrameState CaptureLayersByValue(
      FlutterViewId view_id,
      const FlutterLayer** layers,
      size_t layers_count);

  /// Handles `FlutterCompositor.present_view_callback` by capturing frame state
  /// by value on the raster thread and dispatching the immutable value snapshot
  /// to the platform thread via `platform_dispatcher_`.
  bool PresentView(const FlutterPresentViewInfo* info);

  /// Static trampoline suitable for `FlutterCompositor.present_view_callback`.
  static bool OnPresentViewCallback(const FlutterPresentViewInfo* info);

  /// Static callback suitable for
  /// `FlutterCompositor.create_backing_store_callback`.
  static bool OnCreateBackingStoreCallback(
      const FlutterBackingStoreConfig* config,
      FlutterBackingStore* backing_store_out,
      void* user_data);

  /// Static callback suitable for
  /// `FlutterCompositor.collect_backing_store_callback`.
  static bool OnCollectBackingStoreCallback(const FlutterBackingStore* renderer,
                                            void* user_data);

  /// Returns the most recently committed frame summary for `view_id` (used for
  /// multi-view concurrency verification in host unit tests).
  bool GetCommittedViewSummary(FlutterViewId view_id,
                               CommittedViewSummary* out_summary) const;

 private:
  void ApplyCapturedFrameOnPlatformThread(
      CapturedViewFrameState captured_state);

  std::shared_ptr<JniDelegate> jni_delegate_;
  AndroidSurfaceControl* surface_control_ = nullptr;
  TaskRunnerDispatcher platform_dispatcher_;
  std::atomic<bool> first_frame_dispatched_{false};

  mutable std::mutex summary_mutex_;
  std::unordered_map<FlutterViewId, CommittedViewSummary> committed_views_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidPlatformViewsController);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_PLATFORM_VIEWS_CONTROLLER_H_
