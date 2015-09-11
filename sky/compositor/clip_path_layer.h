// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_CLIP_PATH_LAYER_H_
#define SKY_COMPOSITOR_CLIP_PATH_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class ClipPathLayer : public ContainerLayer {
 public:
  ClipPathLayer();
  ~ClipPathLayer() override;

  void set_clip_path(const SkPath& clip_path) { clip_path_ = clip_path; }

 protected:
  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  SkPath clip_path_;

  DISALLOW_COPY_AND_ASSIGN(ClipPathLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_CLIP_PATH_LAYER_H_
