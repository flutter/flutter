// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/surface_frame.h"

#include <limits>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flutter {

SurfaceFrame::SurfaceFrame(sk_sp<SkSurface> surface,
                           FramebufferInfo framebuffer_info,
                           const SubmitCallback& submit_callback,
                           std::unique_ptr<GLContextResult> context_result,
                           bool display_list_fallback)
    : surface_(surface),
      framebuffer_info_(std::move(framebuffer_info)),
      submit_callback_(submit_callback),
      context_result_(std::move(context_result)) {
  FML_DCHECK(submit_callback_);
  if (surface_) {
    canvas_ = surface_->getCanvas();
  } else if (display_list_fallback) {
    dl_recorder_ = sk_make_sp<DisplayListCanvasRecorder>(
        SkRect::MakeWH(std::numeric_limits<SkScalar>::max(),
                       std::numeric_limits<SkScalar>::max()));
    canvas_ = dl_recorder_.get();
  }
}

bool SurfaceFrame::Submit() {
  if (submitted_) {
    return false;
  }

  submitted_ = PerformSubmit();

  return submitted_;
}

bool SurfaceFrame::IsSubmitted() const {
  return submitted_;
}

SkCanvas* SurfaceFrame::SkiaCanvas() {
  return canvas_;
}

sk_sp<SkSurface> SurfaceFrame::SkiaSurface() const {
  return surface_;
}

bool SurfaceFrame::PerformSubmit() {
  if (submit_callback_ == nullptr) {
    return false;
  }

  if (submit_callback_(*this, SkiaCanvas())) {
    return true;
  }

  return false;
}

sk_sp<DisplayListBuilder> SurfaceFrame::GetDisplayListBuilder() {
  return dl_recorder_ ? dl_recorder_->builder() : nullptr;
}

sk_sp<DisplayList> SurfaceFrame::BuildDisplayList() {
  TRACE_EVENT0("impeller", "SurfaceFrame::BuildDisplayList");
  return dl_recorder_ ? dl_recorder_->Build() : nullptr;
}

}  // namespace flutter
