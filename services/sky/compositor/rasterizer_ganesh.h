// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_COMPOSITOR_DISPLAY_RASTERIZER_GANESH_H_
#define SKY_VIEWER_COMPOSITOR_DISPLAY_RASTERIZER_GANESH_H_

#include "services/sky/compositor/rasterizer.h"

namespace sky {
class LayerHost;

class RasterizerGanesh : public Rasterizer {
 public:
  explicit RasterizerGanesh(LayerHost* host);
  ~RasterizerGanesh() override;

  scoped_ptr<mojo::GLTexture> Rasterize(SkPicture* picture) override;

 private:
  LayerHost* host_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerGanesh);
};

}  // namespace sky

#endif  // SKY_VIEWER_COMPOSITOR_DISPLAY_RASTERIZER_GANESH_H_
