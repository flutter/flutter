// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/ui/animator.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"
#include "flutter/common/threads.h"

namespace sky {
namespace shell {

Animator::Animator(Rasterizer* rasterizer, Engine* engine)
    : rasterizer_(rasterizer),
      engine_(engine),
      layer_tree_pipeline_(ftl::MakeRefCounted<LayerTreePipeline>(3)),
      pending_frame_semaphore_(1),
      paused_(false),
      weak_factory_(this) {
  new services::vsync::VsyncProviderFallbackImpl(
      mojo::InterfaceRequest<::vsync::VSyncProvider>(
          mojo::GetProxy(&fallback_vsync_provider_)));
}

Animator::~Animator() = default;

void Animator::Stop() {
  paused_ = true;
}

void Animator::Start() {
  if (!paused_) {
    return;
  }

  paused_ = false;
  RequestFrame();
}

void Animator::BeginFrame(int64_t time_stamp) {
  pending_frame_semaphore_.Signal();

  LayerTreePipeline::Producer producer = [this]() {
    renderable_tree_.reset();
    engine_->BeginFrame(ftl::TimePoint::Now());
    return std::move(renderable_tree_);
  };

  if (!layer_tree_pipeline_->Produce(producer)) {
    TRACE_EVENT_INSTANT0("flutter", "ConsumerSlowDefer",
                         TRACE_EVENT_SCOPE_PROCESS);
    RequestFrame();
    return;
  }

  auto weak_rasterizer = rasterizer_->GetWeakRasterizerPtr();
  auto pipeline = layer_tree_pipeline_;

  blink::Threads::Gpu()->PostTask([weak_rasterizer, pipeline]() {
    if (!weak_rasterizer) {
      return;
    }
    weak_rasterizer->Draw(pipeline);
  });
}

void Animator::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  renderable_tree_ = std::move(layer_tree);
}

void Animator::RequestFrame() {
  if (paused_) {
    return;
  }

  if (!pending_frame_semaphore_.TryWait()) {
    // Multiple calls to Animator::RequestFrame will still result in a single
    // request to the VSyncProvider.
    return;
  }

  // The AwaitVSync is going to call us back at the next VSync. However, we want
  // to be reasonably certain that the UI thread is not in the middle of a
  // particularly expensive callout. We post the AwaitVSync to run right after
  // an idle. This does NOT provide a guarantee that the UI thread has not
  // started an expensive operation right after posting this message however.
  // To support that, we need edge triggered wakes on VSync.

  auto weak = weak_factory_.GetWeakPtr();

  blink::Threads::UI()->PostTask([weak]() {
    if (!weak) {
      return;
    }

    TRACE_EVENT_INSTANT0("flutter", "RequestFrame", TRACE_EVENT_SCOPE_PROCESS);

    DCHECK(weak->vsync_provider_)
        << "A VSync provider must be present to schedule a frame.";

    weak->AwaitVSync(base::Bind(&Animator::BeginFrame, weak));
  });
}

void Animator::set_vsync_provider(vsync::VSyncProviderPtr vsync_provider) {
  vsync_provider_ = vsync_provider.Pass();

  // We may be waiting on a VSync signal from the old VSync provider.
  pending_frame_semaphore_.Signal();

  RequestFrame();
}

void Animator::AwaitVSync(
    const vsync::VSyncProvider::AwaitVSyncCallback& callback) {
  // First, try the platform provided VSync provider.
  if (vsync_provider_) {
    vsync_provider_->AwaitVSync(callback);
    return;
  }

  // Then, use the fallback provider if the platform cannot reliably supply
  // VSync signals to us.
  return fallback_vsync_provider_->AwaitVSync(callback);
}

}  // namespace shell
}  // namespace sky
