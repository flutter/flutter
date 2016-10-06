// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/surface.h"

namespace shell {

SurfaceFrame::SurfaceFrame() : submitted_(false) {}

SurfaceFrame::~SurfaceFrame() = default;

bool SurfaceFrame::Submit() {
  if (submitted_) {
    return false;
  }

  submitted_ = PerformSubmit();

  return submitted_;
}

Surface::Surface() = default;

Surface::~Surface() = default;

}  // namespace shell
