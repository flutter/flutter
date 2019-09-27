// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
#define FLUTTER_FLOW_LAYERS_LAYER_TREE_H_

#include <stdint.h>

#include <memory>

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class LayerTree {
 public:
  LayerTree();

  ~LayerTree();

  void Preroll(CompositorContext::ScopedFrame& frame,
               bool ignore_raster_cache = false);

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context,
                   scenic::ContainerNode& container);
#endif

  void Paint(CompositorContext::ScopedFrame& frame,
             bool ignore_raster_cache = false) const;

  sk_sp<SkPicture> Flatten(const SkRect& bounds);

  Layer* root_layer() const { return root_layer_.get(); }

  void set_root_layer(std::shared_ptr<Layer> root_layer) {
    root_layer_ = std::move(root_layer);
  }

  const SkISize& frame_size() const { return frame_size_; }

  void set_frame_size(const SkISize& frame_size) { frame_size_ = frame_size; }

  void RecordBuildTime(fml::TimePoint begin_start);
  fml::TimePoint build_start() const { return build_start_; }
  fml::TimePoint build_finish() const { return build_finish_; }
  fml::TimeDelta build_time() const { return build_finish_ - build_start_; }

  // The number of frame intervals missed after which the compositor must
  // trace the rasterized picture to a trace file. Specify 0 to disable all
  // tracing
  void set_rasterizer_tracing_threshold(uint32_t interval) {
    rasterizer_tracing_threshold_ = interval;
  }

  uint32_t rasterizer_tracing_threshold() const {
    return rasterizer_tracing_threshold_;
  }

  void set_checkerboard_raster_cache_images(bool checkerboard) {
    checkerboard_raster_cache_images_ = checkerboard;
  }

  void set_checkerboard_offscreen_layers(bool checkerboard) {
    checkerboard_offscreen_layers_ = checkerboard;
  }

 private:
  SkISize frame_size_;  // Physical pixels.
  std::shared_ptr<Layer> root_layer_;
  fml::TimePoint build_start_;
  fml::TimePoint build_finish_;
  uint32_t rasterizer_tracing_threshold_;
  bool checkerboard_raster_cache_images_;
  bool checkerboard_offscreen_layers_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTree);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
