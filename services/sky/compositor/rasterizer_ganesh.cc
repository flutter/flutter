// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/compositor/rasterizer_ganesh.h"

#include "base/trace_event/trace_event.h"
#include "mojo/skia/ganesh_surface.h"
#include "services/sky/compositor/layer_host.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace sky {

RasterizerGanesh::RasterizerGanesh(LayerHost* host) : host_(host) {
  DCHECK(host_);
}

RasterizerGanesh::~RasterizerGanesh() {
}

scoped_ptr<mojo::GLTexture> RasterizerGanesh::Rasterize(SkPicture* picture) {
  TRACE_EVENT0("sky", "RasterizerGanesh::Rasterize");

  SkRect cull_rect = picture->cullRect();
  gfx::Size size(cull_rect.width(), cull_rect.height());

  mojo::GaneshSurface surface(host_->ganesh_context(),
                              host_->resource_manager()->CreateTexture(size));

  SkCanvas* canvas = surface.canvas();
  canvas->drawPicture(picture);
  canvas->flush();

  return surface.TakeTexture();
}

}  // namespace sky
