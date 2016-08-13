// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_RASTERIZER_H_

#include "flutter/content_handler/framebuffer_skia.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer_tree.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "mojo/services/framebuffer/interfaces/framebuffer.mojom.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_content_handler {

class Rasterizer {
 public:
  Rasterizer();
  ~Rasterizer();

  void SetFramebuffer(mojo::InterfaceHandle<mojo::Framebuffer> framebuffer,
                      mojo::FramebufferInfoPtr info);

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree, ftl::Closure callback);

 private:
  FramebufferSkia framebuffer_;
  sk_sp<SkSurface> surface_;
  flow::CompositorContext compositor_context_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
