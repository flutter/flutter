// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/surface.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace shell {

SurfaceFrame::SurfaceFrame(sk_sp<SkSurface> surface,
                           SubmitCallback submit_callback)
    : submitted_(false), surface_(surface), submit_callback_(submit_callback) {
  FTL_DCHECK(submit_callback_);
}

SurfaceFrame::~SurfaceFrame() {
  if (submit_callback_) {
    // Dropping without a Submit.
    submit_callback_(nullptr);
  }
}

bool SurfaceFrame::Submit() {
  if (submitted_) {
    return false;
  }

  submitted_ = PerformSubmit();

  return submitted_;
}

SkCanvas* SurfaceFrame::SkiaCanvas() {
  return surface_ != nullptr ? surface_->getCanvas() : nullptr;
}

bool SurfaceFrame::PerformSubmit() {
  if (submit_callback_ == nullptr) {
    return false;
  }

  if (submit_callback_(SkiaCanvas())) {
    return true;
  }

  return false;
}

Surface::~Surface() = default;

}  // namespace shell
