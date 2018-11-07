// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_RECT_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_RECT_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class ClipRectLayer : public ContainerLayer {
 public:
  ClipRectLayer(Clip clip_behavior);
  ~ClipRectLayer() override;

  void set_clip_rect(const SkRect& clip_rect) { clip_rect_ = clip_rect; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  SkRect clip_rect_;
  Clip clip_behavior_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipRectLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_CLIP_RECT_LAYER_H_
