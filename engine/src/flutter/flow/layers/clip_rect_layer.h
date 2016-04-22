// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_CLIP_RECT_LAYER_H_
#define FLOW_LAYERS_CLIP_RECT_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class ClipRectLayer : public ContainerLayer {
 public:
  ClipRectLayer();
  ~ClipRectLayer() override;

  void set_clip_rect(const SkRect& clip_rect) { clip_rect_ = clip_rect; }

 protected:
  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) override;

 private:
  SkRect clip_rect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRectLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_CLIP_RECT_LAYER_H_
