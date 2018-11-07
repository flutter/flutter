// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_SHADER_MASK_LAYER_H_
#define FLUTTER_FLOW_LAYERS_SHADER_MASK_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

#include "third_party/skia/include/core/SkShader.h"

namespace flow {

class ShaderMaskLayer : public ContainerLayer {
 public:
  ShaderMaskLayer();
  ~ShaderMaskLayer() override;

  void set_shader(sk_sp<SkShader> shader) { shader_ = shader; }

  void set_mask_rect(const SkRect& mask_rect) { mask_rect_ = mask_rect; }

  void set_blend_mode(SkBlendMode blend_mode) { blend_mode_ = blend_mode; }

  void Paint(PaintContext& context) const override;

 private:
  sk_sp<SkShader> shader_;
  SkRect mask_rect_;
  SkBlendMode blend_mode_;

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderMaskLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_SHADER_MASK_LAYER_H_
