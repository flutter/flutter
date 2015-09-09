// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_OPACITY_LAYER_H_
#define SKY_COMPOSITOR_OPACITY_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class OpacityLayer : public ContainerLayer {
 public:
  OpacityLayer();
  ~OpacityLayer() override;

  void set_alpha(int alpha) { alpha_ = alpha; }

  void Paint(PaintContext& context) override;

 private:
  int alpha_;

  DISALLOW_COPY_AND_ASSIGN(OpacityLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_OPACITY_LAYER_H_
