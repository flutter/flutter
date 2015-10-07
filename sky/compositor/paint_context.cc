// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/paint_context.h"
#include "base/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "sky/compositor/picture_serializer.h"
#include "sky/engine/wtf/RefPtr.h"

namespace sky {
namespace compositor {

PaintContext::PaintContext() {
}

void PaintContext::beginFrame(ScopedFrame& frame, bool enableInstrumentation) {
  if (enableInstrumentation) {
    frame_count_.increment();
    frame_time_.start();
  }
}

void PaintContext::endFrame(ScopedFrame& frame, bool enableInstrumentation) {
  if (enableInstrumentation) {
    frame_time_.stop();
  }
}

PaintContext::ScopedFrame PaintContext::AcquireFrame(SkCanvas& canvas) {
  return ScopedFrame(*this, canvas);
}

PaintContext::ScopedFrame PaintContext::AcquireFrame(
    const std::string& trace_file_name,
    gfx::Size frame_size) {
  return ScopedFrame(*this, trace_file_name, frame_size);
}

PaintContext::ScopedFrame::ScopedFrame(PaintContext& context, SkCanvas& canvas)
    : context_(context), canvas_(&canvas), instrumentation_enabled_(true) {
  context_.beginFrame(*this, instrumentation_enabled_);
}

PaintContext::ScopedFrame::ScopedFrame(ScopedFrame&& frame) = default;

PaintContext::ScopedFrame::ScopedFrame(PaintContext& context,
                                       const std::string& trace_file_name,
                                       gfx::Size frame_size)
    : context_(context),
      trace_file_name_(trace_file_name),
      trace_recorder_(new SkPictureRecorder()),
      instrumentation_enabled_(false) {
  trace_recorder_->beginRecording(
      SkRect::MakeWH(frame_size.width(), frame_size.height()));
  canvas_ = trace_recorder_->getRecordingCanvas();
  DCHECK(canvas_);
  DCHECK(trace_file_name.length() > 0);
  context_.beginFrame(*this, instrumentation_enabled_);
}

PaintContext::ScopedFrame::~ScopedFrame() {
  context_.endFrame(*this, instrumentation_enabled_);

  if (trace_file_name_.length() > 0) {
    RefPtr<SkPicture> picture =
        adoptRef(trace_recorder_->endRecordingAsPicture());
    SerializePicture(trace_file_name_.c_str(), picture.get());
  }
}

PaintContext::~PaintContext() {
}

}  // namespace compositor
}  // namespace sky
