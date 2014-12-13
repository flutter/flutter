// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "base/debug/trace_event.h"
#include "mojo/skia/ganesh_surface.h"
#include "sky/compositor/display_delegate.h"
#include "sky/compositor/layer_host.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {

Layer::Layer(LayerClient* client)
  : client_(client),
    host_(nullptr) {
  delegate_.reset(DisplayDelegate::create(client));
}

Layer::~Layer() {
}

void Layer::SetSize(const gfx::Size& size) {
  size_ = size;
}

void Layer::GetPixelsForTesting(std::vector<unsigned char>* pixels) {
  delegate_->GetPixelsForTesting(pixels);
}

void Layer::Display() {
  TRACE_EVENT0("sky", "Layer::Display");

  DCHECK(host_);

  mojo::GaneshSurface surface(host_->ganesh_context(),
                              host_->resource_manager()->CreateTexture(size_));

  gfx::Rect rect(size_);
  delegate_->Paint(surface, rect);

  texture_ = surface.TakeTexture();
}

scoped_ptr<mojo::GLTexture> Layer::GetTexture() {
  return texture_.Pass();
}

}  // namespace sky
