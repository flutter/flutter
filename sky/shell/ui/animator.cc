// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/animator.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"

namespace sky {
namespace shell {

const int kPipelineDepth = 2;

Animator::Animator(const Engine::Config& config, Engine* engine)
    : config_(config),
      engine_(engine),
      outstanding_draw_requests_(0),
      did_defer_frame_request_(false),
      engine_requested_frame_(false),
      paused_(false),
      weak_factory_(this) {
}

Animator::~Animator() {
}

void Animator::RequestFrame() {
  if (engine_requested_frame_)
    return;

  DCHECK(!did_defer_frame_request_);

  TRACE_EVENT_ASYNC_BEGIN0("sky", "Frame request pending", this);
  engine_requested_frame_ = true;

  if (outstanding_draw_requests_ >= kPipelineDepth) {
    did_defer_frame_request_ = true;
    return;
  }

  base::MessageLoop::current()->PostTask(
      FROM_HERE,
      base::Bind(&Animator::BeginFrame, weak_factory_.GetWeakPtr()));
}

void Animator::Stop() {
  paused_ = true;
  engine_requested_frame_ = false;
}

void Animator::Start() {
  paused_ = false;
  RequestFrame();
}

void Animator::BeginFrame() {
  if (!engine_requested_frame_)
    return;
  engine_requested_frame_ = false;
  TRACE_EVENT_ASYNC_END0("sky", "Frame request pending", this);

  engine_->BeginFrame(base::TimeTicks::Now());
  skia::RefPtr<SkPicture> picture = engine_->Paint();

  outstanding_draw_requests_++;
  DCHECK(outstanding_draw_requests_ <= kPipelineDepth);
  config_.gpu_task_runner->PostTaskAndReply(
      FROM_HERE,
      base::Bind(&GPUDelegate::Draw, config_.gpu_delegate, picture),
      base::Bind(&Animator::OnFrameComplete, weak_factory_.GetWeakPtr()));
}

void Animator::OnFrameComplete() {
  DCHECK(outstanding_draw_requests_ > 0);
  --outstanding_draw_requests_;
  if (paused_)
    return;

  if (engine_requested_frame_ && did_defer_frame_request_) {
    did_defer_frame_request_ = false;
    BeginFrame();
  }
}

}  // namespace shell
}  // namespace sky
