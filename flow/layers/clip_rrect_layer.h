// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_CLIP_RRECT_LAYER_H_
#define FLOW_LAYERS_CLIP_RRECT_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class ClipRRectLayer : public ContainerLayer {
 public:
  ClipRRectLayer();
  ~ClipRRectLayer() override;

  void set_clip_rrect(const SkRRect& clip_rrect) { clip_rrect_ = clip_rrect; }

 protected:
  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) override;

 private:
  SkRRect clip_rrect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRRectLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_CLIP_RRECT_LAYER_H_
