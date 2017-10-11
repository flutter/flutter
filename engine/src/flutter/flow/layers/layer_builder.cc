// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_builder.h"
#include "flutter/flow/layers/default_layer_builder.h"

namespace flow {

std::unique_ptr<LayerBuilder> LayerBuilder::Create() {
  return std::make_unique<DefaultLayerBuilder>();
}

LayerBuilder::LayerBuilder() = default;

LayerBuilder::~LayerBuilder() = default;

int LayerBuilder::GetRasterizerTracingThreshold() const {
  return rasterizer_tracing_threshold_;
}

bool LayerBuilder::GetCheckerboardRasterCacheImages() const {
  return checkerboard_raster_cache_images_;
}

bool LayerBuilder::GetCheckerboardOffscreenLayers() const {
  return checkerboard_offscreen_layers_;
}

void LayerBuilder::SetRasterizerTracingThreshold(uint32_t frameInterval) {
  rasterizer_tracing_threshold_ = frameInterval;
}

void LayerBuilder::SetCheckerboardRasterCacheImages(bool checkerboard) {
  checkerboard_raster_cache_images_ = checkerboard;
}

void LayerBuilder::SetCheckerboardOffscreenLayers(bool checkerboard) {
  checkerboard_offscreen_layers_ = checkerboard;
}

}  // namespace flow
