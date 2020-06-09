// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/surface_frame.h"
#include "flutter/fml/logging.h"

namespace flutter {

SurfaceFrame::SurfaceFrame(sk_sp<SkSurface> surface,
                           bool supports_readback,
                           const SubmitCallback& submit_callback)
    : surface_(surface),
      supports_readback_(supports_readback),
      submit_callback_(submit_callback) {
  FML_DCHECK(submit_callback_);
}

SurfaceFrame::SurfaceFrame(sk_sp<SkSurface> surface,
                           bool supports_readback,
                           const SubmitCallback& submit_callback,
                           std::unique_ptr<GLContextResult> context_result)
    : submitted_(false),
      surface_(surface),
      supports_readback_(supports_readback),
      submit_callback_(submit_callback),
      context_result_(std::move(context_result)) {
  FML_DCHECK(submit_callback_);
}

SurfaceFrame::~SurfaceFrame() {
  if (submit_callback_ && !submitted_) {
    // Dropping without a Submit.
    submit_callback_(*this, nullptr);
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
  return surface_ != nullptr ? surface_->getCanvas() : nullptr;
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

}  // namespace flutter
