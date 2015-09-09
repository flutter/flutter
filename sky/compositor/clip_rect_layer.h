// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_CLIP_RECT_LAYER_H_
#define SKY_COMPOSITOR_CLIP_RECT_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class ClipRectLayer : public ContainerLayer {
 public:
  ClipRectLayer();
  ~ClipRectLayer() override;

  void set_clip_rect(const SkRect& clip_rect) { clip_rect_ = clip_rect; }

  void Paint(GrContext* context, SkCanvas* canvas) override;

 private:
  SkRect clip_rect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRectLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_CLIP_RECT_LAYER_H_
