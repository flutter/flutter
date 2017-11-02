// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/compositor_context.h"

#include "third_party/skia/include/core/SkCanvas.h"

namespace flow {

CompositorContext::CompositorContext(std::unique_ptr<ProcessInfo> info)
    : process_info_(std::move(info)) {}

CompositorContext::~CompositorContext() = default;

void CompositorContext::BeginFrame(ScopedFrame& frame,
                                   bool enable_instrumentation) {
  if (enable_instrumentation) {
    frame_count_.Increment();
    frame_time_.Start();

    if (process_info_ && process_info_->SampleNow()) {
      memory_usage_.Add(process_info_->GetResidentMemorySize());
    }
  }
}

void CompositorContext::EndFrame(ScopedFrame& frame,
                                 bool enable_instrumentation) {
  raster_cache_.SweepAfterFrame();
  if (enable_instrumentation) {
    frame_time_.Stop();
  }
}

CompositorContext::ScopedFrame CompositorContext::AcquireFrame(
    GrContext* gr_context,
    SkCanvas* canvas,
    bool instrumentation_enabled) {
  return ScopedFrame(*this, gr_context, canvas, instrumentation_enabled);
}

CompositorContext::ScopedFrame::ScopedFrame(CompositorContext& context,
                                            GrContext* gr_context,
                                            SkCanvas* canvas,
                                            bool instrumentation_enabled)
    : context_(context),
      gr_context_(gr_context),
      canvas_(canvas),
      instrumentation_enabled_(instrumentation_enabled) {
  context_.BeginFrame(*this, instrumentation_enabled_);
}

CompositorContext::ScopedFrame::ScopedFrame(ScopedFrame&& frame) = default;

CompositorContext::ScopedFrame::~ScopedFrame() {
  context_.EndFrame(*this, instrumentation_enabled_);
}

void CompositorContext::OnGrContextCreated() {
  texture_registry_.OnGrContextCreated();
}

void CompositorContext::OnGrContextDestroyed() {
  texture_registry_.OnGrContextDestroyed();
  raster_cache_.Clear();
}

}  // namespace flow
