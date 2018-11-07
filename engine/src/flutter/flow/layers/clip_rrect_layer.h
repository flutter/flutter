// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class ClipRRectLayer : public ContainerLayer {
 public:
  ClipRRectLayer(Clip clip_behavior);
  ~ClipRRectLayer() override;

  void set_clip_rrect(const SkRRect& clip_rrect) { clip_rrect_ = clip_rrect; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  SkRRect clip_rrect_;
  Clip clip_behavior_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipRRectLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_CLIP_RRECT_LAYER_H_
