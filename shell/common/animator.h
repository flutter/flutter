// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_ANIMATOR_H_
#define FLUTTER_SHELL_COMMON_ANIMATOR_H_

#include "flutter/common/task_runners.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "flutter/synchronization/pipeline.h"
#include "flutter/synchronization/semaphore.h"

namespace shell {

class Animator final {
 public:
  class Delegate {
   public:
    virtual void OnAnimatorBeginFrame(fml::TimePoint frame_time) = 0;

    virtual void OnAnimatorNotifyIdle(int64_t deadline) = 0;

    virtual void OnAnimatorDraw(
        fml::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) = 0;

    virtual void OnAnimatorDrawLastLayerTree() = 0;
  };

  Animator(Delegate& delegate,
           blink::TaskRunners task_runners,
           std::unique_ptr<VsyncWaiter> waiter);

  ~Animator();

  void RequestFrame(bool regenerate_layer_tree = true);

  void Render(std::unique_ptr<flow::LayerTree> layer_tree);

  void Start();

  void Stop();

  void SetDimensionChangePending();

 private:
  using LayerTreePipeline = flutter::Pipeline<flow::LayerTree>;

  void BeginFrame(fml::TimePoint frame_start_time,
                  fml::TimePoint frame_target_time);

  bool CanReuseLastLayerTree();
  void DrawLastLayerTree();

  void AwaitVSync();

  const char* FrameParity();

  Delegate& delegate_;
  blink::TaskRunners task_runners_;
  std::shared_ptr<VsyncWaiter> waiter_;

  fml::TimePoint last_begin_frame_time_;
  int64_t dart_frame_deadline_;
  fml::RefPtr<LayerTreePipeline> layer_tree_pipeline_;
  flutter::Semaphore pending_frame_semaphore_;
  LayerTreePipeline::ProducerContinuation producer_continuation_;
  int64_t frame_number_;
  bool paused_;
  bool regenerate_layer_tree_;
  bool frame_scheduled_;
  int notify_idle_task_id_;
  bool dimension_change_pending_;
  SkISize last_layer_tree_size_;

  fml::WeakPtrFactory<Animator> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_ANIMATOR_H_
