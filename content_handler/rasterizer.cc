// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"

#include <utility>

#include "lib/ftl/functional/make_runnable.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter_content_handler {

Rasterizer::Rasterizer() {}

Rasterizer::~Rasterizer() {}

void Rasterizer::SetFramebuffer(
    mojo::InterfaceHandle<mojo::Framebuffer> framebuffer,
    mojo::FramebufferInfoPtr info) {
  framebuffer_.Bind(std::move(framebuffer), std::move(info));
}

void Rasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                      ftl::Closure callback) {
  if (!framebuffer_.surface()) {
    callback();
    return;
  }

  SkCanvas* canvas = framebuffer_.surface()->getCanvas();
  flow::CompositorContext::ScopedFrame frame =
      compositor_context_.AcquireFrame(nullptr, *canvas);
  canvas->clear(SK_ColorBLACK);
  layer_tree->Raster(frame);
  canvas->flush();

  framebuffer_.ConvertToCorrectPixelFormatIfNeeded();
  framebuffer_.Finish();
  callback();
}

}  // namespace flutter_content_handler
