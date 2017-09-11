// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/animator.h"

#include "flutter/common/threads.h"
#include "flutter/fml/trace_event.h"
#include "lib/fxl/time/stopwatch.h"
#include "dart/runtime/include/dart_tools_api.h"

namespace shell {

Animator::Animator(fxl::WeakPtr<Rasterizer> rasterizer,
                   VsyncWaiter* waiter,
                   Engine* engine)
    : rasterizer_(rasterizer),
      waiter_(waiter),
      engine_(engine),
      last_begin_frame_time_(),
      dart_frame_deadline_(0),
      layer_tree_pipeline_(fxl::MakeRefCounted<LayerTreePipeline>(2)),
      pending_frame_semaphore_(1),
      frame_number_(1),
      paused_(false),
      frame_scheduled_(false),
      weak_factory_(this) {}

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

static int64_t FxlToDartOrEarlier(fxl::TimePoint time) {
  int64_t dart_now = Dart_TimelineGetMicros();
  fxl::TimePoint fxl_now = fxl::TimePoint::Now();
  return (time - fxl_now).ToMicroseconds() + dart_now;
}

void Animator::BeginFrame(fxl::TimePoint frame_start_time,
                          fxl::TimePoint frame_target_time) {
  TRACE_EVENT_ASYNC_END0("flutter", "Frame Request Pending", frame_number_++);

  frame_scheduled_ = false;
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
      TRACE_EVENT_INSTANT0("flutter", "ConsumerSlowDefer");
      RequestFrame();
      return;
    }
  }

  // We have acquired a valid continuation from the pipeline and are ready
  // to service potential frame.
  FXL_DCHECK(producer_continuation_);

  last_begin_frame_time_ = frame_start_time;
  dart_frame_deadline_ = FxlToDartOrEarlier(frame_target_time);
  engine_->BeginFrame(last_begin_frame_time_);

  if (!frame_scheduled_) {
    // We don't have another frame pending, so we're waiting on user input
    // or I/O. Allow the Dart VM 100 ms.
    engine_->NotifyIdle(dart_frame_deadline_ + 100000);
  }
}

void Animator::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree) {
    // Note the frame time for instrumentation.
    layer_tree->set_construction_time(fxl::TimePoint::Now() -
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
    // request to the VsyncWaiter.
    return;
  }

  // The AwaitVSync is going to call us back at the next VSync. However, we want
  // to be reasonably certain that the UI thread is not in the middle of a
  // particularly expensive callout. We post the AwaitVSync to run right after
  // an idle. This does NOT provide a guarantee that the UI thread has not
  // started an expensive operation right after posting this message however.
  // To support that, we need edge triggered wakes on VSync.

  blink::Threads::UI()->PostTask(
      [ self = weak_factory_.GetWeakPtr(), frame_number = frame_number_ ]() {
        if (!self.get()) {
          return;
        }
        TRACE_EVENT_ASYNC_BEGIN0("flutter", "Frame Request Pending",
                                 frame_number);
        self->AwaitVSync();
      });
  frame_scheduled_ = true;
}

void Animator::AwaitVSync() {
  waiter_->AsyncWaitForVsync([self = weak_factory_.GetWeakPtr()](
      fxl::TimePoint frame_start_time, fxl::TimePoint frame_target_time) {
    if (self)
      self->BeginFrame(frame_start_time, frame_target_time);
  });

  engine_->NotifyIdle(dart_frame_deadline_);
}

}  // namespace shell
