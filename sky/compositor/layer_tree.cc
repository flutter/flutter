// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer_tree.h"

#include "sky/compositor/layer.h"

namespace sky {
namespace compositor {

LayerTree::LayerTree() : rasterizer_tracing_threashold_(0) {
}

LayerTree::~LayerTree() {
}

}  // namespace compositor
}  // namespace sky
