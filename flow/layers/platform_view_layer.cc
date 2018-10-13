// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/platform_view_layer.h"

namespace flow {

PlatformViewLayer::PlatformViewLayer() = default;

PlatformViewLayer::~PlatformViewLayer() = default;

void PlatformViewLayer::Preroll(PrerollContext* context,
                                const SkMatrix& matrix) {
  set_paint_bounds(SkRect::MakeXYWH(offset_.x(), offset_.y(), size_.width(),
                                    size_.height()));
}

void PlatformViewLayer::Paint(PaintContext& context) const {}

}  // namespace flow
