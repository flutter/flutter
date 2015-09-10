// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_CLIP_RRECT_LAYER_H_
#define SKY_COMPOSITOR_CLIP_RRECT_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class ClipRRectLayer : public ContainerLayer {
 public:
  ClipRRectLayer();
  ~ClipRRectLayer() override;

  void set_clip_rrect(const SkRRect& clip_rrect) { clip_rrect_ = clip_rrect; }

 protected:
  void Paint(PaintContext& context) override;

 private:
  SkRRect clip_rrect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRRectLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_CLIP_RRECT_LAYER_H_
