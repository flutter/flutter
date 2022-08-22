// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_ANIMATOR_H_
#define FLUTTER_SHELL_COMMON_ANIMATOR_H_

#include <deque>

#include "flutter/common/task_runners.h"
#include "flutter/flow/frame_timings.h"
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
    virtual void OnAnimatorBeginFrame(fml::TimePoint frame_target_time,
                                      uint64_t frame_number) = 0;

    virtual void OnAnimatorNotifyIdle(fml::TimePoint deadline) = 0;

    virtual void OnAnimatorUpdateLatestFrameTargetTime(
        fml::TimePoint frame_target_time) = 0;

    virtual void OnAnimatorDraw(
        std::shared_ptr<LayerTreePipeline> pipeline) = 0;

    virtual void OnAnimatorDrawLastLayerTree(
        std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder) = 0;
  };

  Animator(Delegate& delegate,
           TaskRunners task_runners,
           std::unique_ptr<VsyncWaiter> waiter);

  ~Animator();

  void RequestFrame(bool regenerate_layer_tree = true);

  void Render(std::unique_ptr<flutter::LayerTree> layer_tree);

  const std::weak_ptr<VsyncWaiter> GetVsyncWaiter() const;

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
  ///           `SmoothPointerDataDispatcher`, and for our own flow events.
  ///
  /// @see      `PointerDataDispatcher::ScheduleSecondaryVsyncCallback`.
  void ScheduleSecondaryVsyncCallback(uintptr_t id,
                                      const fml::closure& callback);

  // Enqueue |trace_flow_id| into |trace_flow_ids_|.  The flow event will be
  // ended at either the next frame, or the next vsync interval with no active
  // active rendering.
  void EnqueueTraceFlowId(uint64_t trace_flow_id);

 private:
  void BeginFrame(std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder);

  bool CanReuseLastLayerTree();

  void DrawLastLayerTree(
      std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder);

  void AwaitVSync();

  // Clear |trace_flow_ids_| if |frame_scheduled_| is false.
  void ScheduleMaybeClearTraceFlowIds();

  Delegate& delegate_;
  TaskRunners task_runners_;
  std::shared_ptr<VsyncWaiter> waiter_;

  std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder_;
  uint64_t frame_request_number_ = 1;
  fml::TimePoint dart_frame_deadline_;
  std::shared_ptr<LayerTreePipeline> layer_tree_pipeline_;
  fml::Semaphore pending_frame_semaphore_;
  LayerTreePipeline::ProducerContinuation producer_continuation_;
  bool regenerate_layer_tree_ = false;
  bool frame_scheduled_ = false;
  int notify_idle_task_id_ = 0;
  SkISize last_layer_tree_size_ = {0, 0};
  std::deque<uint64_t> trace_flow_ids_;
  bool has_rendered_ = false;

  fml::WeakPtrFactory<Animator> weak_factory_;

  friend class testing::ShellTest;

  FML_DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_ANIMATOR_H_
