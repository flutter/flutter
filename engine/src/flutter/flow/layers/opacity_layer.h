// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_OPACITY_LAYER_H_
#define FLOW_LAYERS_OPACITY_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class OpacityLayer : public ContainerLayer {
 public:
  OpacityLayer();
  ~OpacityLayer() override;

  void set_alpha(int alpha) { alpha_ = alpha; }

 protected:
  void Paint(PaintContext& context) override;

 private:
  int alpha_;

  DISALLOW_COPY_AND_ASSIGN(OpacityLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_OPACITY_LAYER_H_
