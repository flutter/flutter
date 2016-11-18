// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_

#include <vector>
#include "flutter/flow/layers/layer.h"

namespace flow {

class ContainerLayer : public Layer {
 public:
  ContainerLayer();
  ~ContainerLayer() override;

  void Add(std::unique_ptr<Layer> layer);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void PrerollChildren(PrerollContext* context, const SkMatrix& matrix);

  void PaintChildren(PaintContext& context) const;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context,
                   mozart::Node* container) override;
  void UpdateSceneChildrenInsideNode(SceneUpdateContext& context,
                                     mozart::Node* container,
                                     mozart::NodePtr node);
  void UpdateSceneChildren(SceneUpdateContext& context,
                           mozart::Node* container);
#endif  // defined(OS_FUCHSIA)

  const std::vector<std::unique_ptr<Layer>>& layers() const { return layers_; }

 protected:
  // Valid only after preroll when needs_system_composite() is true.
  const SkMatrix& ctm() const { return ctm_; }

 private:
  std::vector<std::unique_ptr<Layer>> layers_;

  SkMatrix ctm_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
