// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/animator.h"

#include "flutter/common/threads.h"
#include "flutter/fml/trace_event.h"
#include "lib/fxl/time/stopwatch.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"

namespace shell {

Animator::Animator(fml::WeakPtr<Rasterizer> rasterizer,
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
      regenerate_layer_tree_(false),
      frame_scheduled_(false),
      dimension_change_pending_(false),
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

// Indicate that screen dimensions will be changing in order to force rendering
// of an updated frame even if the animator is currently paused.
void Animator::SetDimensionChangePending() {
  dimension_change_pending_ = true;
}

// This Parity is used by the timeline component to correctly align
// GPU Workloads events with their respective Framework Workload.
const char* Animator::FrameParity() {
  return (frame_number_ % 2) ? "even" : "odd";
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
  regenerate_layer_tree_ = false;
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
  {
    TRACE_EVENT2("flutter", "Framework Workload", "mode", "basic", "frame",
                 FrameParity());
    engine_->BeginFrame(last_begin_frame_time_);
  }

  if (!frame_scheduled_) {
    // We don't have another frame pending, so we're waiting on user input
    // or I/O. Allow the Dart VM 100 ms.
    engine_->NotifyIdle(dart_frame_deadline_ + 100000);
  }
}

void Animator::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (dimension_change_pending_ &&
      layer_tree->frame_size() != last_layer_tree_size_) {
    dimension_change_pending_ = false;
  }
  last_layer_tree_size_ = layer_tree->frame_size();

  if (layer_tree) {
    // Note the frame time for instrumentation.
    layer_tree->set_construction_time(fxl::TimePoint::Now() -
                                      last_begin_frame_time_);
  }

  // Commit the pending continuation.
  producer_continuation_.Complete(std::move(layer_tree));

  blink::Threads::Gpu()->PostTask([
    rasterizer = rasterizer_, pipeline = layer_tree_pipeline_,
    frame_id = FrameParity()
  ]() {
    if (!rasterizer.get())
      return;
    TRACE_EVENT2("flutter", "GPU Workload", "mode", "basic", "frame", frame_id);
    rasterizer->Draw(pipeline);
  });
}

bool Animator::CanReuseLastLayerTree() {
  return !regenerate_layer_tree_;
}

void Animator::DrawLastLayerTree() {
  pending_frame_semaphore_.Signal();
  blink::Threads::Gpu()->PostTask([rasterizer = rasterizer_]() {
    if (rasterizer.get())
      rasterizer->DrawLastLayerTree();
  });
}

void Animator::RequestFrame(bool regenerate_layer_tree) {
  if (regenerate_layer_tree) {
    regenerate_layer_tree_ = true;
  }
  if (paused_ && !dimension_change_pending_) {
    return;
  }

  if (!pending_frame_semaphore_.TryWait()) {
    // Multiple calls to Animator::RequestFrame will still result in a
    // single request to the VsyncWaiter.
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
    if (self) {
      if (self->CanReuseLastLayerTree()) {
        self->DrawLastLayerTree();
      } else {
        self->BeginFrame(frame_start_time, frame_target_time);
      }
    }
  });

  engine_->NotifyIdle(dart_frame_deadline_);
}

}  // namespace shell
