// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

class PhysicalShapeLayer : public ContainerLayer {
 public:
  PhysicalShapeLayer(SkColor color,
                     SkColor shadow_color,
                     float elevation,
                     const SkPath& path,
                     Clip clip_behavior);

  static SkRect ComputeShadowBounds(const SkRect& bounds,
                                    float elevation,
                                    float pixel_ratio);
  static void DrawShadow(SkCanvas* canvas,
                         const SkPath& path,
                         SkColor color,
                         float elevation,
                         bool transparentOccluder,
                         SkScalar dpr);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

  bool UsesSaveLayer() const {
    return clip_behavior_ == Clip::antiAliasWithSaveLayer;
  }

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

  float total_elevation() const { return total_elevation_; }

 private:
#if defined(OS_FUCHSIA)
  bool child_layer_exists_below_ = false;
#endif
  SkColor color_;
  SkColor shadow_color_;
  float elevation_ = 0.0f;
  float total_elevation_ = 0.0f;
  SkPath path_;
  bool isRect_;
  SkRRect frameRRect_;
  Clip clip_behavior_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
