// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ANIMATOR_H_
#define SKY_SHELL_UI_ANIMATOR_H_

#include "base/memory/weak_ptr.h"
#include "lib/ftl/time/time_point.h"
#include "mojo/services/gfx/composition/interfaces/scheduling.mojom.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {

class Animator {
 public:
  explicit Animator(const Engine::Config& config,
                    rasterizer::RasterizerPtr rasterizer,
                    Engine* engine);
  ~Animator();

  void RequestFrame();
  void FlushRealTimeEvents();

  void Render(std::unique_ptr<flow::LayerTree> layer_tree);

  void Start();
  void Stop();
  void Reset();

  void set_vsync_provider(vsync::VSyncProviderPtr vsync_provider);

  void set_frame_scheduler(
      mojo::InterfaceHandle<mojo::gfx::composition::FrameScheduler>
          frame_scheduler) {
    frame_scheduler_ = mojo::gfx::composition::FrameSchedulerPtr::Create(
        frame_scheduler.Pass());
  }

 private:
  void Animate(mojo::gfx::composition::FrameInfoPtr frame_info);
  void BeginFrame(int64_t time_stamp);
  void OnFrameComplete();
  bool AwaitVSync();

  Engine::Config config_;
  rasterizer::RasterizerPtr rasterizer_;
  Engine* engine_;
  mojo::gfx::composition::FrameSchedulerPtr frame_scheduler_;
  vsync::VSyncProviderPtr vsync_provider_;
  int outstanding_requests_;
  bool did_defer_frame_request_;
  bool engine_requested_frame_;
  bool paused_;
  bool is_ready_to_draw_;
  ftl::TimePoint begin_time_;

  base::WeakPtrFactory<Animator> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ANIMATOR_H_
