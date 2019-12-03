// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_

#include <vector>
#include "flutter/flow/layers/layer.h"

namespace flutter {

class ContainerLayer : public Layer {
 public:
  ContainerLayer();

  void Add(std::shared_ptr<Layer> layer);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;
#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

  const std::vector<std::shared_ptr<Layer>>& layers() const { return layers_; }

  // Called when the layer, which must be a child of this container,
  // changes its tree_reads_surface() result from false to true.
  void NotifyChildReadback(const Layer* layer);

 protected:
  void PrerollChildren(PrerollContext* context,
                       const SkMatrix& child_matrix,
                       SkRect* child_paint_bounds);
  void PaintChildren(PaintContext& context) const;

  virtual bool ComputeTreeReadsSurface() const override;

#if defined(OS_FUCHSIA)
  void UpdateSceneChildren(SceneUpdateContext& context);
#endif  // defined(OS_FUCHSIA)

  // Specify whether or not the container has its children render
  // to a SaveLayer which will prevent many rendering anomalies
  // from propagating to the parent - such as if the children
  // read back from the surface on which they render, or if the
  // children perform non-associative rendering. Those children
  // will now be performing those operations on the SaveLayer
  // rather than the layer that this container renders onto.
  void set_renders_to_save_layer(bool value);

  // For OpacityLayer to restructure to have a single child.
  void ClearChildren();

 private:
  std::vector<std::shared_ptr<Layer>> layers_;

  // child_needs_screen_readback_ is maintained even if the
  // renders_to_save_layer_ property is set in case both
  // parameters are dynamically and independently determined.
  bool child_needs_screen_readback_;
  bool renders_to_save_layer_;

  FML_DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
