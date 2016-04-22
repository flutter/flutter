// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/paint_context.h"

#include "base/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flow {

PaintContext::PaintContext() {
}

void PaintContext::BeginFrame(ScopedFrame& frame, bool enableInstrumentation) {
  if (enableInstrumentation) {
    frame_count_.Increment();
    frame_time_.Start();
  }
}

void PaintContext::EndFrame(ScopedFrame& frame, bool enableInstrumentation) {
  raster_cache_.SweepAfterFrame();
  if (enableInstrumentation) {
    frame_time_.Stop();
  }
}

PaintContext::ScopedFrame PaintContext::AcquireFrame(
    GrContext* gr_context, SkCanvas& canvas, bool instrumentation_enabled) {
  return ScopedFrame(*this, gr_context, canvas, instrumentation_enabled);
}

PaintContext::ScopedFrame::ScopedFrame(PaintContext& context,
                                       GrContext* gr_context,
                                       SkCanvas& canvas,
                                       bool instrumentation_enabled)
    : context_(context), gr_context_(gr_context), canvas_(&canvas),
      instrumentation_enabled_(instrumentation_enabled) {
  context_.BeginFrame(*this, instrumentation_enabled_);
}

PaintContext::ScopedFrame::ScopedFrame(ScopedFrame&& frame) = default;

PaintContext::ScopedFrame::~ScopedFrame() {
  context_.EndFrame(*this, instrumentation_enabled_);
}

PaintContext::~PaintContext() {
}

void PaintContext::OnGrContextDestroyed() {
  raster_cache_.Clear();
}

}  // namespace flow
