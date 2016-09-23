// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_ANIMATOR_H_
#define SHELL_COMMON_ANIMATOR_H_

#include "base/memory/weak_ptr.h"
#include "flutter/services/vsync/fallback/vsync_provider_fallback_impl.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/synchronization/pipeline.h"
#include "flutter/synchronization/semaphore.h"
#include "lib/ftl/memory/ref_ptr.h"
#include "lib/ftl/time/time_point.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"

namespace shell {

class Animator {
 public:
  explicit Animator(Rasterizer* rasterizer, Engine* engine);

  ~Animator();

  void RequestFrame();

  void Render(std::unique_ptr<flow::LayerTree> layer_tree);

  void Start();

  void Stop();

  void set_vsync_provider(vsync::VSyncProviderPtr vsync_provider);

 private:
  using LayerTreePipeline = flutter::Pipeline<flow::LayerTree>;

  void BeginFrame(int64_t time_stamp);

  void AwaitVSync(const vsync::VSyncProvider::AwaitVSyncCallback& callback);

  ftl::WeakPtr<Rasterizer> rasterizer_;
  Engine* engine_;
  vsync::VSyncProviderPtr vsync_provider_;
  vsync::VSyncProviderPtr fallback_vsync_provider_;
  ftl::TimePoint last_begin_frame_time_;
  ftl::RefPtr<LayerTreePipeline> layer_tree_pipeline_;
  flutter::Semaphore pending_frame_semaphore_;
  LayerTreePipeline::ProducerContinuation producer_continuation_;
  bool paused_;

  base::WeakPtrFactory<Animator> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace shell

#endif  // SHELL_COMMON_ANIMATOR_H_
