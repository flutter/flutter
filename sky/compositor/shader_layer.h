// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_SHADER_LAYER_H_
#define SKY_COMPOSITOR_SHADER_LAYER_H_

#include "sky/compositor/container_layer.h"

#include "third_party/skia/include/core/SkShader.h"

namespace sky {
namespace compositor {

class ShaderLayer : public ContainerLayer {
 public:
  ShaderLayer();
  ~ShaderLayer() override;

  void set_shader(SkShader* shader) { shader_ = shader; }

  void set_transfer_mode(SkXfermode::Mode transfer_mode) {
    transfer_mode_ = transfer_mode;
  }

 protected:
  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  RefPtr<SkShader> shader_;
  SkXfermode::Mode transfer_mode_;

  DISALLOW_COPY_AND_ASSIGN(ShaderLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_SHADER_LAYER_H_
