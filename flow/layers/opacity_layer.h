// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
#define FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class OpacityLayer : public ContainerLayer {
 public:
  OpacityLayer();
  ~OpacityLayer() override;

  void set_alpha(int alpha) { alpha_ = alpha; }
  void set_offset(const SkPoint& offset) { offset_ = offset; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

  // TODO(chinmaygarde): Once MZ-139 is addressed, introduce a new node in the
  // session scene hierarchy.

 private:
  int alpha_;
  SkPoint offset_;

  // Restructure (if necessary) OpacityLayer to have only one child.
  //
  // This is needed to ensure that retained rendering can always be applied to
  // save the costly saveLayer.
  //
  // If there are multiple children, this creates a new identity TransformLayer,
  // sets all children to be the TransformLayer's children, and sets that
  // TransformLayer as the single child of this OpacityLayer.
  void EnsureSingleChild();

  FML_DISALLOW_COPY_AND_ASSIGN(OpacityLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
