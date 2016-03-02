// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ANIMATOR_H_
#define SKY_SHELL_UI_ANIMATOR_H_

#include "base/memory/weak_ptr.h"
#include "mojo/services/gfx/composition/interfaces/scheduling.mojom.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {

class Animator {
 public:
  explicit Animator(const Engine::Config& config,
                    rasterizer::RasterizerPtr rasterizer, Engine* engine);
  ~Animator();

  void RequestFrame();
  void FlushRealTimeEvents();

  void Start();
  void Stop();
  void Reset();

  void set_vsync_provider(vsync::VSyncProviderPtr vsync_provider);

  void set_scene_scheduler(
      mojo::InterfaceHandle<mojo::gfx::composition::SceneScheduler> scene_scheduler) {
    scene_scheduler_ = mojo::gfx::composition::SceneSchedulerPtr::Create(scene_scheduler.Pass());
  }


 private:
  void Animate(mojo::gfx::composition::FrameInfoPtr frame_info);
  void BeginFrame(int64_t time_stamp);
  void OnFrameComplete();
  bool AwaitVSync();

  Engine::Config config_;
  rasterizer::RasterizerPtr rasterizer_;
  Engine* engine_;
  mojo::gfx::composition::SceneSchedulerPtr scene_scheduler_;
  vsync::VSyncProviderPtr vsync_provider_;
  int outstanding_requests_;
  bool did_defer_frame_request_;
  bool engine_requested_frame_;
  bool paused_;

  base::WeakPtrFactory<Animator> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ANIMATOR_H_
