// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_TRANSFORM_LAYER_H_
#define FLOW_LAYERS_TRANSFORM_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class TransformLayer : public ContainerLayer {
 public:
  TransformLayer();
  ~TransformLayer() override;

  void set_transform(const SkMatrix& transform) { transform_ = transform; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) override;

 private:
  SkMatrix transform_;

  FTL_DISALLOW_COPY_AND_ASSIGN(TransformLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_TRANSFORM_LAYER_H_
