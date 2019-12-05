// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_

#include "flutter/flow/layers/elevated_container_layer.h"

namespace flutter {

class PhysicalShapeLayerBase : public ElevatedContainerLayer {
 public:
  static bool can_system_composite() { return false; }

  PhysicalShapeLayerBase(SkColor color, SkAlpha opacity, float elevation)
      : ElevatedContainerLayer(elevation), color_(color) {}

  void set_dimensions(SkRRect rrect) {}

  SkColor color() const { return color_; }
  SkAlpha opacity() const { return SK_AlphaOPAQUE; }

 private:
  SkColor color_;
};

class PhysicalShapeLayer : public PhysicalShapeLayerBase {
 public:
  static SkRect ComputeShadowBounds(const SkRect& bounds,
                                    float elevation,
                                    float pixel_ratio);
  static void DrawShadow(SkCanvas* canvas,
                         const SkPath& path,
                         SkColor color,
                         float elevation,
                         bool transparentOccluder,
                         SkScalar dpr);

  PhysicalShapeLayer(SkColor color,
                     SkColor shadow_color,
                     float elevation,
                     const SkPath& path,
                     Clip clip_behavior);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;

 private:
  SkColor shadow_color_;
  SkPath path_;
  bool isRect_;
  SkRRect frameRRect_;
  Clip clip_behavior_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PHYSICAL_SHAPE_LAYER_H_
