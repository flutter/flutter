// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/animator.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"

namespace sky {
namespace shell {

Animator::Animator(const Engine::Config& config, Engine* engine)
    : config_(config),
      engine_(engine),
      engine_requested_frame_(false),
      frame_in_progress_(false),
      weak_factory_(this) {
}

Animator::~Animator() {
}

void Animator::RequestFrame() {
  if (engine_requested_frame_)
    return;
  engine_requested_frame_ = true;

  if (!frame_in_progress_) {
    frame_in_progress_ = true;
    base::MessageLoop::current()->PostTask(
        FROM_HERE,
        base::Bind(&Animator::BeginFrame, weak_factory_.GetWeakPtr()));
  }
}

void Animator::CancelFrameRequest() {
  engine_requested_frame_ = false;
}

void Animator::BeginFrame() {
  DCHECK(frame_in_progress_);
  // There could be a request in the message loop at time of cancel.
  if (!engine_requested_frame_) {
    frame_in_progress_ = false;
    return;
  }
  engine_requested_frame_ = false;

  engine_->BeginFrame(base::TimeTicks::Now());
  config_.gpu_task_runner->PostTaskAndReply(
      FROM_HERE,
      base::Bind(&GPUDelegate::Draw, config_.gpu_delegate, engine_->Paint()),
      base::Bind(&Animator::OnFrameComplete, weak_factory_.GetWeakPtr()));
}

void Animator::OnFrameComplete() {
  DCHECK(frame_in_progress_);
  frame_in_progress_ = false;
  if (engine_requested_frame_) {
    frame_in_progress_ = true;
    BeginFrame();
  }
}

}  // namespace shell
}  // namespace sky
