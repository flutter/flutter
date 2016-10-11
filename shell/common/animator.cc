// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/animator.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"
#include "flutter/common/threads.h"
#include "lib/ftl/time/stopwatch.h"

namespace shell {

Animator::Animator(ftl::WeakPtr<Rasterizer> rasterizer, Engine* engine)
    : rasterizer_(rasterizer),
      engine_(engine),
      layer_tree_pipeline_(ftl::MakeRefCounted<LayerTreePipeline>(3)),
      pending_frame_semaphore_(1),
      paused_(false),
      weak_factory_(this) {
  new sky::services::vsync::VsyncProviderFallbackImpl(
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

  if (!producer_continuation_) {
    // We may already have a valid pipeline continuation in case a previous
    // begin frame did not result in an Animation::Render. Simply reuse that
    // instead of asking the pipeline for a fresh continuation.
    producer_continuation_ = layer_tree_pipeline_->Produce();

    if (!producer_continuation_) {
      // If we still don't have valid continuation, the pipeline is currently
      // full because the consumer is being too slow. Try again at the next
      // frame interval.
      TRACE_EVENT_INSTANT0("flutter", "ConsumerSlowDefer",
                           TRACE_EVENT_SCOPE_PROCESS);
      RequestFrame();
      return;
    }
  }

  // We have acquired a valid continuation from the pipeline and are ready
  // to service potential frame.
  DCHECK(producer_continuation_);

  last_begin_frame_time_ = ftl::TimePoint::Now();
  engine_->BeginFrame(last_begin_frame_time_);
}

void Animator::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree) {
    // Note the frame time for instrumentation.
    layer_tree->set_construction_time(ftl::TimePoint::Now() -
                                      last_begin_frame_time_);
  }

  // Commit the pending continuation.
  producer_continuation_.Complete(std::move(layer_tree));

  blink::Threads::Gpu()->PostTask(
      [ rasterizer = rasterizer_, pipeline = layer_tree_pipeline_ ]() {
        if (!rasterizer.get())
          return;
        rasterizer->Draw(pipeline);
      });
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

  blink::Threads::UI()->PostTask([self = weak_factory_.GetWeakPtr()]() {
    if (!self.get())
      return;
    TRACE_EVENT_INSTANT0("flutter", "RequestFrame", TRACE_EVENT_SCOPE_PROCESS);
    self->AwaitVSync(base::Bind(&Animator::BeginFrame, self));
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
