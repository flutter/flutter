// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
#define FLUTTER_FLOW_LAYERS_LAYER_TREE_H_

#include <stdint.h>

#include <memory>

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/time/time_delta.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flow {

class LayerTree {
 public:
  LayerTree();

  ~LayerTree();

  void Raster(CompositorContext::ScopedFrame& frame,
              bool ignore_raster_cache = false);

  // TODO(abarth): Integrate scene updates with the rasterization pass so that
  // we can draw on top of child scenes (and so that we can apply clips and
  // blending operations to child scene).
  void UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                   mojo::gfx::composition::Node* container);

  Layer* root_layer() const { return root_layer_.get(); }

  void set_root_layer(std::unique_ptr<Layer> root_layer) {
    root_layer_ = std::move(root_layer);
  }

  const SkISize& frame_size() const { return frame_size_; }

  void set_frame_size(const SkISize& frame_size) { frame_size_ = frame_size; }

  uint32_t scene_version() const { return scene_version_; }

  void set_scene_version(uint32_t scene_version) {
    scene_version_ = scene_version;
  }

  void set_construction_time(const ftl::TimeDelta& delta) {
    construction_time_ = delta;
  }

  const ftl::TimeDelta& construction_time() const { return construction_time_; }

  // The number of frame intervals missed after which the compositor must
  // trace the rasterized picture to a trace file. Specify 0 to disable all
  // tracing
  void set_rasterizer_tracing_threshold(uint32_t interval) {
    rasterizer_tracing_threshold_ = interval;
  }

  uint32_t rasterizer_tracing_threshold() const {
    return rasterizer_tracing_threshold_;
  }

 private:
  SkISize frame_size_;  // Physical pixels.
  uint32_t scene_version_;
  std::unique_ptr<Layer> root_layer_;

  ftl::TimeDelta construction_time_;
  uint32_t rasterizer_tracing_threshold_;

  FTL_DISALLOW_COPY_AND_ASSIGN(LayerTree);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
