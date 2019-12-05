// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_ELEVATED_CONTAINER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_ELEVATED_CONTAINER_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

class ElevatedContainerLayer : public ContainerLayer {
 public:
  ElevatedContainerLayer(float elevation);
  ~ElevatedContainerLayer() override = default;

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  float elevation() const { return clamped_elevation_; }
  float total_elevation() const {
    return parent_elevation_ + clamped_elevation_;
  }

 private:
  float parent_elevation_ = 0.0f;
  float elevation_ = 0.0f;
  float clamped_elevation_ = 0.0f;

  FML_DISALLOW_COPY_AND_ASSIGN(ElevatedContainerLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_ELEVATED_CONTAINER_LAYER_H_
