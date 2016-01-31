// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/layer.h"

#include "third_party/skia/include/core/SkColorFilter.h"

namespace flow {

Layer::Layer()
    : parent_(nullptr)
    , has_paint_bounds_(false)
    , paint_bounds_() {
}

Layer::~Layer() {
}

void Layer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
}

}  // namespace flow
