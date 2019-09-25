// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_

#include <memory>
#include <vector>

#include "flutter/flow/layers/layer.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkRRect.h"

namespace flutter {

class ContainerLayer : public Layer {
 public:
  ContainerLayer(bool force_single_child = false);
  ~ContainerLayer() override = default;

  void Add(std::shared_ptr<Layer> layer);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;
  void UpdateScene(SceneUpdateContext& context) override;

  bool should_render_as_frame() const { return !frame_rrect_.isEmpty(); }
  void set_frame_properties(SkRRect frame_rrect,
                            SkColor frame_color,
                            float frame_opacity) {
    frame_rrect_ = frame_rrect;
    frame_color_ = frame_color;
    frame_opacity_ = frame_opacity;
  }

  float elevation() const { return clamped_elevation_; }
  float total_elevation() const {
    return parent_elevation_ + clamped_elevation_;
  }
  void set_elevation(float elevation) {
    parent_elevation_ = 0.0f;
    elevation_ = elevation;
    clamped_elevation_ = elevation;
  }

  const std::vector<std::shared_ptr<Layer>>& layers() const { return layers_; }

 private:
  std::vector<std::shared_ptr<Layer>> layers_;
  std::shared_ptr<ContainerLayer> single_child_;
  SkRRect frame_rrect_;
  SkColor frame_color_;
  float parent_elevation_ = 0.0f;
  float elevation_ = 0.0f;
  float clamped_elevation_ = 0.0f;
  float frame_opacity_ = 1.0f;

  FML_DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
