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

  FuchsiaSystemCompositedLayer(SkColor color, float elevation);

  void UpdateScene(SceneUpdateContext& context) override;

  void set_dimensions(SkRRect rrect) { rrect_ = rrect; }

  SkColor color() const { return color_; }

 private:
  SkRRect rrect_ = SkRRect::MakeEmpty();
  SkColor color_ = SK_ColorTRANSPARENT;

  FML_DISALLOW_COPY_AND_ASSIGN(FuchsiaSystemCompositedLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_FUCHSIA_SYSTEM_COMPOSITED_LAYER_H_
