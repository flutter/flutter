// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "mojo/skia/ganesh_surface.h"
#include "sky/compositor/layer_host.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {

Layer::Layer(LayerClient* client) : client_(client), host_(nullptr) {
}

Layer::~Layer() {
}

void Layer::ClearClient() {
  client_ = nullptr;
}

void Layer::SetSize(const gfx::Size& size) {
  size_ = size;
}

void Layer::Display() {
  DCHECK(host_);

  mojo::GaneshContext::Scope scope(host_->ganesh_context());
  mojo::GaneshSurface surface(host_->ganesh_context(),
                              host_->resource_manager()->CreateTexture(size_));

  SkCanvas* canvas = surface.canvas();

  gfx::Rect rect(size_);
  client_->PaintContents(canvas, rect);
  canvas->flush();

  texture_ = surface.TakeTexture();
}

scoped_ptr<mojo::GLTexture> Layer::GetTexture() {
  return texture_.Pass();
}

}  // namespace sky
