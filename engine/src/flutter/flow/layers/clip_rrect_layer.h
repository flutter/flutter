// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

class ClipRRectLayer : public ContainerLayer {
 public:
  ClipRRectLayer(const SkRRect& clip_rrect, Clip clip_behavior);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

  bool UsesSaveLayer() const {
    return clip_behavior_ == Clip::antiAliasWithSaveLayer;
  }

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  void UpdateScene(std::shared_ptr<SceneUpdateContext> context) override;
#endif

 private:
  SkRRect clip_rrect_;
  Clip clip_behavior_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipRRectLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_
