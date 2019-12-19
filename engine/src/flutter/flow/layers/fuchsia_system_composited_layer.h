// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_FUCHSIA_SYSTEM_COMPOSITED_LAYER_H_
#define FLUTTER_FLOW_LAYERS_FUCHSIA_SYSTEM_COMPOSITED_LAYER_H_

#include "flutter/flow/layers/elevated_container_layer.h"
#include "flutter/flow/scene_update_context.h"

namespace flutter {

class FuchsiaSystemCompositedLayer : public ElevatedContainerLayer {
 public:
  static bool can_system_composite() { return true; }

  FuchsiaSystemCompositedLayer(SkColor color, SkAlpha opacity, float elevation);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void UpdateScene(SceneUpdateContext& context) override;

  void set_dimensions(SkRRect rrect) { rrect_ = rrect; }

  SkColor color() const { return color_; }
  SkAlpha opacity() const { return opacity_; }

 private:
  SkRRect rrect_ = SkRRect::MakeEmpty();
  SkColor color_ = SK_ColorTRANSPARENT;
  SkAlpha opacity_ = SK_AlphaOPAQUE;

  FML_DISALLOW_COPY_AND_ASSIGN(FuchsiaSystemCompositedLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_FUCHSIA_SYSTEM_COMPOSITED_LAYER_H_
