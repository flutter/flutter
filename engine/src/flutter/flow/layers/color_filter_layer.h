// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_COLOR_FILTER_LAYER_H_
#define FLOW_LAYERS_COLOR_FILTER_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class ColorFilterLayer : public ContainerLayer {
 public:
  ColorFilterLayer();
  ~ColorFilterLayer() override;

  void set_color(SkColor color) { color_ = color; }

  void set_transfer_mode(SkXfermode::Mode transfer_mode) {
    transfer_mode_ = transfer_mode;
  }

 protected:
  void Paint(PaintContext& context) override;

 private:
  SkColor color_;
  SkXfermode::Mode transfer_mode_;

  DISALLOW_COPY_AND_ASSIGN(ColorFilterLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_COLOR_FILTER_LAYER_H_
