// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_ANIMATOR_H_
#define FLUTTER_SHELL_COMMON_ANIMATOR_H_

#include <deque>

#include "flutter/common/task_runners.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/synchronization/semaphore.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/pipeline.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/vsync_waiter.h"

namespace flutter {

namespace testing {
class ShellTest;
}

/// Executor of animations.
///
/// In conjunction with the |VsyncWaiter| it allows callers (typically Dart
/// code) to schedule work that ends up generating a |LayerTree|.
class Animator final {
 public:
  class Delegate {
   public:
    virtual void OnAnimatorBeginFrame(fml::TimePoint frame_target_time) = 0;

    virtual void OnAnimatorNotifyIdle(int64_t deadline) = 0;

    virtual void OnAnimatorDraw(
        fml::RefPtr<Pipeline<flutter::LayerTree>> pipeline) = 0;

    virtual void OnAnimatorDrawLastLayerTree() = 0;
  };

  Animator(Delegate& delegate,
           TaskRunners task_runners,
           std::unique_ptr<VsyncWaiter> waiter);

  ~Animator();

  float GetDisplayRefreshRate() const;

  void RequestFrame(bool regenerate_layer_tree = true);

  void Render(std::unique_ptr<flutter::LayerTree> layer_tree);

  //--------------------------------------------------------------------------
  /// @brief    Schedule a secondary callback to be executed right after the
  ///           main `VsyncWaiter::AsyncWaitForVsync` callback (which is added
  ///           by `Animator::RequestFrame`).
  ///
  ///           Like the callback in `AsyncWaitForVsync`, this callback is
  ///           only scheduled to be called once, and it's supposed to be
  ///           called in the UI thread. If there is no AsyncWaitForVsync
  ///           callback (`Animator::RequestFrame` is not called), this
  ///           secondary callback will still be executed at vsync.
  ///
  ///           This callback is used to provide the vsync signal needed by
  ///           `SmoothPointerDataDispatcher`.
  ///
  /// @see      `PointerDataDispatcher::ScheduleSecondaryVsyncCallback`.
  void ScheduleSecondaryVsyncCallback(const fml::closure& callback);

  void Start();

  void Stop();

  void SetDimensionChangePending();

  // Enqueue |trace_flow_id| into |trace_flow_ids_|.  The corresponding flow
  // will be ended during the next |BeginFrame|.
  void EnqueueTraceFlowId(uint64_t trace_flow_id);

 private:
  using LayerTreePipeline = Pipeline<flutter::LayerTree>;

  void BeginFrame(fml::TimePoint frame_start_time,
                  fml::TimePoint frame_target_time);

  bool CanReuseLastLayerTree();
  void DrawLastLayerTree();

  void AwaitVSync();

  const char* FrameParity();

  Delegate& delegate_;
  TaskRunners task_runners_;
  std::shared_ptr<VsyncWaiter> waiter_;

  fml::TimePoint last_frame_begin_time_;
  fml::TimePoint last_frame_target_time_;
  int64_t dart_frame_deadline_;
  fml::RefPtr<LayerTreePipeline> layer_tree_pipeline_;
  fml::Semaphore pending_frame_semaphore_;
  LayerTreePipeline::ProducerContinuation producer_continuation_;
  int64_t frame_number_;
  bool paused_;
  bool regenerate_layer_tree_;
  bool frame_scheduled_;
  int notify_idle_task_id_;
  bool dimension_change_pending_;
  SkISize last_layer_tree_size_;
  std::deque<uint64_t> trace_flow_ids_;

  fml::WeakPtrFactory<Animator> weak_factory_;

  friend class testing::ShellTest;

  FML_DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_ANIMATOR_H_
