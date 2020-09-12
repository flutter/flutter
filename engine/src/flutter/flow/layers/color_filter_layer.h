// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_COLOR_FILTER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_COLOR_FILTER_LAYER_H_

#include "flutter/flow/layers/container_layer.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace flutter {

class ColorFilterLayer : public ContainerLayer {
 public:
  ColorFilterLayer(sk_sp<SkColorFilter> filter);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

 private:
  sk_sp<SkColorFilter> filter_;

  FML_DISALLOW_COPY_AND_ASSIGN(ColorFilterLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_COLOR_FILTER_LAYER_H_
