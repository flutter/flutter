// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_COLOR_FILTER_LAYER_H_
#define SKY_COMPOSITOR_COLOR_FILTER_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class ColorFilterLayer : public ContainerLayer {
 public:
  ColorFilterLayer();
  ~ColorFilterLayer() override;

  void set_color(SkColor color) { color_ = color; }

  void set_transfer_mode(SkXfermode::Mode transfer_mode) {
    transfer_mode_ = transfer_mode;
  }

 protected:
  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  SkColor color_;
  SkXfermode::Mode transfer_mode_;

  DISALLOW_COPY_AND_ASSIGN(ColorFilterLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_COLOR_FILTER_LAYER_H_
