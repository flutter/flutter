// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_TRANSFORM_LAYER_H_
#define FLUTTER_FLOW_LAYERS_TRANSFORM_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

// Be careful that SkMatrix's default constructor doesn't initialize the matrix
// at all. Hence |set_transform| must be called with an initialized SkMatrix.
class TransformLayer : public ContainerLayer {
 public:
  TransformLayer(const SkMatrix& transform);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  SkMatrix transform_;

  FML_DISALLOW_COPY_AND_ASSIGN(TransformLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_TRANSFORM_LAYER_H_
