// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "third_party/skia/include/core/SkColorFilter.h"

namespace sky {
namespace compositor {

Layer::Layer()
    : parent_(nullptr)
    , has_paint_bounds_(false)
    , paint_bounds_() {
}

Layer::~Layer() {
}

}  // namespace compositor
}  // namespace sky
