// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class PhysicalShapeLayer : public ContainerLayer {
 public:
  PhysicalShapeLayer(Clip clip_behavior);
  ~PhysicalShapeLayer() override;

  void set_path(const SkPath& path);

  void set_elevation(float elevation) { elevation_ = elevation; }
  void set_color(SkColor color) { color_ = color; }
  void set_shadow_color(SkColor shadow_color) { shadow_color_ = shadow_color; }
  void set_device_pixel_ratio(SkScalar dpr) { device_pixel_ratio_ = dpr; }

  static void DrawShadow(SkCanvas* canvas,
                         const SkPath& path,
                         SkColor color,
                         float elevation,
                         bool transparentOccluder,
                         SkScalar dpr);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  float elevation_;
  SkColor color_;
  SkColor shadow_color_;
  SkScalar device_pixel_ratio_;
  SkPath path_;
  bool isRect_;
  SkRRect frameRRect_;
  Clip clip_behavior_;
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
