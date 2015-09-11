// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_CONTAINER_LAYER_H_
#define SKY_COMPOSITOR_CONTAINER_LAYER_H_

#include "sky/compositor/layer.h"

namespace sky {
namespace compositor {

class ContainerLayer : public Layer {
 public:
  ContainerLayer();
  ~ContainerLayer() override;

  void Add(std::unique_ptr<Layer> layer);

  void PaintChildren(PaintContext::ScopedFrame& frame) const;

  const std::vector<std::unique_ptr<Layer>>& layers() const { return layers_; }

 private:
  std::vector<std::unique_ptr<Layer>> layers_;

  DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_CONTAINER_LAYER_H_
