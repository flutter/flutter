// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_TRANSFORM_LAYER_H_
#define SKY_COMPOSITOR_TRANSFORM_LAYER_H_

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

class TransformLayer : public ContainerLayer {
 public:
  TransformLayer();
  ~TransformLayer() override;

  void set_transform(const SkMatrix& transform) { transform_ = transform; }

  SkMatrix model_view_matrix(const SkMatrix& model_matrix) const override;

 protected:
  void Paint(PaintContext& context) override;

 private:
  SkMatrix transform_;

  DISALLOW_COPY_AND_ASSIGN(TransformLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_TRANSFORM_LAYER_H_
