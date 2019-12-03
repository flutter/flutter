// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
#define FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

// Don't add an OpacityLayer with no children to the layer tree. Painting an
// OpacityLayer is very costly due to the saveLayer call. If there's no child,
// having the OpacityLayer or not has the same effect. In debug_unopt build, the
// |EnsureSingleChild| will assert if there are no children.
class OpacityLayer : public ContainerLayer {
 public:
  // An offset is provided here because OpacityLayer.addToScene method in the
  // Flutter framework can take an optional offset argument.
  //
  // By default, that offset is always zero, and all the offsets are handled by
  // some parent TransformLayers. But we allow the offset to be non-zero for
  // backward compatibility. If it's non-zero, the old behavior is to propage
  // that offset to all the leaf layers (e.g., PictureLayer). That will make
  // the retained rendering inefficient as a small offset change could propagate
  // to many leaf layers. Therefore we try to capture that offset here to stop
  // the propagation as repainting the OpacityLayer is expensive.
  OpacityLayer(int alpha, const SkPoint& offset);
  ~OpacityLayer() override;

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

  // TODO(chinmaygarde): Once SCN-139 is addressed, introduce a new node in the
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

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
