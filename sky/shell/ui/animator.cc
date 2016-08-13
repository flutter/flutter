// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/ui/animator.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"
#include "flutter/services/rasterizer/rasterizer.mojom.h"

namespace sky {
namespace shell {

const int kPipelineDepth = 3;

Animator::Animator(const Engine::Config& config,
                   rasterizer::RasterizerPtr rasterizer,
                   Engine* engine)
    : config_(config),
      rasterizer_(rasterizer.Pass()),
      engine_(engine),
      outstanding_requests_(0),
      did_defer_frame_request_(false),
      engine_requested_frame_(false),
      paused_(false),
      is_ready_to_draw_(false),
      weak_factory_(this) {}

Animator::~Animator() {}

void Animator::RequestFrame() {
  if (engine_requested_frame_)
    return;
  TRACE_EVENT_ASYNC_BEGIN0("flutter", "Frame request pending", this);
  engine_requested_frame_ = true;

  DCHECK(!did_defer_frame_request_);
  outstanding_requests_++;
  TRACE_COUNTER1("flutter", "outstanding_requests_", outstanding_requests_);
  if (outstanding_requests_ >= kPipelineDepth) {
    TRACE_EVENT_INSTANT1("flutter", "Frame request deferred",
                         TRACE_EVENT_SCOPE_THREAD, "outstanding_requests_",
                         outstanding_requests_);
    did_defer_frame_request_ = true;
    return;
  }

  if (!AwaitVSync()) {
    base::MessageLoop::current()->PostDelayedTask(
        FROM_HERE,
        base::Bind(&Animator::BeginFrame, weak_factory_.GetWeakPtr(), 0),
        base::TimeDelta::FromMilliseconds(16));
  }
}

void Animator::Stop() {
  paused_ = true;
}

void Animator::Start() {
  Reset();
  RequestFrame();
}

void Animator::Animate(mojo::gfx::composition::FrameInfoPtr frame_info) {
  BeginFrame(frame_info->frame_time);
}

void Animator::BeginFrame(int64_t time_stamp) {
  TRACE_EVENT_ASYNC_END0("flutter", "Frame request pending", this);
  DCHECK(engine_requested_frame_);
  DCHECK(outstanding_requests_ > 0);
  DCHECK(outstanding_requests_ <= kPipelineDepth) << outstanding_requests_;

  engine_requested_frame_ = false;

  if (paused_) {
    OnFrameComplete();
    return;
  }

  begin_time_ = ftl::TimePoint::Now();
  ftl::TimePoint frame_time =
      time_stamp
          ? ftl::TimePoint() + ftl::TimeDelta::FromMicroseconds(time_stamp)
          : begin_time_;

  is_ready_to_draw_ = true;
  engine_->BeginFrame(frame_time);
  bool was_ready_to_draw = is_ready_to_draw_;
  is_ready_to_draw_ = false;

  // If we were still ready to draw when done with the frame, that means we
  // didn't draw anything this frame and we should acknowledge the frame
  // ourselves instead of waiting for the rasterizer to acknowledge it.
  if (was_ready_to_draw)
    OnFrameComplete();
}

void Animator::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!is_ready_to_draw_)
    return;  // Only draw once per frame.
  is_ready_to_draw_ = false;

  layer_tree->set_construction_time(ftl::TimePoint::Now() - begin_time_);

  // TODO(abarth): Doesn't this leak if OnFrameComplete never runs?
  rasterizer_->Draw(
      reinterpret_cast<uint64_t>(layer_tree.release()),
      base::Bind(&Animator::OnFrameComplete, weak_factory_.GetWeakPtr()));
}

void Animator::OnFrameComplete() {
  DCHECK(outstanding_requests_ > 0);
  --outstanding_requests_;
  TRACE_COUNTER1("flutter", "outstanding_requests_", outstanding_requests_);
  if (paused_)
    return;

  if (did_defer_frame_request_) {
    did_defer_frame_request_ = false;

    if (!AwaitVSync())
      BeginFrame(0);
  }
}

bool Animator::AwaitVSync() {
  if (frame_scheduler_) {
    frame_scheduler_->ScheduleFrame(
        base::Bind(&Animator::Animate, weak_factory_.GetWeakPtr()));
    return true;
  } else if (vsync_provider_) {
    vsync_provider_->AwaitVSync(
        base::Bind(&Animator::BeginFrame, weak_factory_.GetWeakPtr()));
    return true;
  }
  return false;
}

void Animator::Reset() {
  weak_factory_.InvalidateWeakPtrs();

  outstanding_requests_ = 0;
  TRACE_COUNTER1("flutter", "outstanding_requests_", outstanding_requests_);
  did_defer_frame_request_ = false;
  engine_requested_frame_ = false;
  paused_ = false;
}

void Animator::set_vsync_provider(vsync::VSyncProviderPtr vsync_provider) {
  DCHECK(!engine_requested_frame_);
  vsync_provider_ = vsync_provider.Pass();
}

}  // namespace shell
}  // namespace sky
