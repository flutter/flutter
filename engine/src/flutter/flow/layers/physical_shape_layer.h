// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

class PhysicalShapeLayer : public ContainerLayer {
 public:
  PhysicalShapeLayer(DlColor color,
                     DlColor shadow_color,
                     float elevation,
                     const SkPath& path,
                     Clip clip_behavior);

  void Diff(DiffContext* context, const Layer* old_layer) override;

  void Preroll(PrerollContext* context) override;

  void Paint(PaintContext& context) const override;

  bool UsesSaveLayer() const {
    return clip_behavior_ == Clip::antiAliasWithSaveLayer;
  }

  float elevation() const { return elevation_; }

 private:
  DlColor color_;
  DlColor shadow_color_;
  float elevation_ = 0.0f;
  SkPath path_;
  Clip clip_behavior_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
