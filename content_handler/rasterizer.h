// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_RASTERIZER_H_

#include "apps/mozart/services/composition/interfaces/scenes.mojom.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer_tree.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"

namespace flutter_content_handler {

class Rasterizer {
 public:
  Rasterizer();
  ~Rasterizer();

  void SetScene(mojo::InterfaceHandle<mozart::Scene> scene);

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree, ftl::Closure callback);

 private:
  mozart::ScenePtr scene_;
  flow::CompositorContext compositor_context_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
