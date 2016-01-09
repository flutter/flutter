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

void LayerTree::Raster(PaintContext::ScopedFrame& frame) {
  Layer::PrerollContext context = { frame, SkRect::MakeEmpty() };
  root_layer_->Preroll(&context, SkMatrix());
  root_layer_->Paint(frame);
}

}  // namespace compositor
}  // namespace sky
