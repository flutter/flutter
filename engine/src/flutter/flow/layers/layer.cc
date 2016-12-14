// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer.h"

#include "third_party/skia/include/core/SkColorFilter.h"

namespace flow {

Layer::Layer()
    : parent_(nullptr),
      needs_system_composite_(false),
      has_paint_bounds_(false),
      paint_bounds_() {}

Layer::~Layer() = default;

void Layer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  if (!has_paint_bounds()) {
    set_paint_bounds(SkRect::MakeEmpty());
  }
}

#if defined(OS_FUCHSIA)
void Layer::UpdateScene(SceneUpdateContext& context, mozart::Node* container) {}
#endif

}  // namespace flow
