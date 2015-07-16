// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/ganesh_surface.h"

namespace mojo {

GaneshSurface::GaneshSurface(GaneshContext* context,
                             scoped_ptr<GLTexture> texture)
    : texture_(texture.Pass()) {
  GrBackendTextureDesc desc;
  desc.fFlags = kRenderTarget_GrBackendTextureFlag;
  desc.fWidth = texture_->size().width;
  desc.fHeight = texture_->size().height;
  desc.fConfig = kSkia8888_GrPixelConfig;
  desc.fOrigin = kTopLeft_GrSurfaceOrigin;
  desc.fTextureHandle = texture_->texture_id();
  DCHECK(texture_->texture_id());

  auto gr_texture = skia::AdoptRef(
      context->gr()->textureProvider()->wrapBackendTexture(desc));
  DCHECK(gr_texture);
  surface_ = skia::AdoptRef(
      SkSurface::NewRenderTargetDirect(gr_texture->asRenderTarget()));
  DCHECK(surface_);
}

GaneshSurface::~GaneshSurface() {
}

scoped_ptr<GLTexture> GaneshSurface::TakeTexture() {
  surface_.clear();
  return texture_.Pass();
}

}  // namespace mojo
