// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "third_party/skia/include/core/SkColorFilter.h"

namespace sky {
namespace compositor {

Layer::Layer() {
}

Layer::~Layer() {
}

SkMatrix Layer::model_view_matrix(const SkMatrix& model_matrix) const {
  return model_matrix;
}

}  // namespace compositor
}  // namespace sky
