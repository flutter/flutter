// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_RASTERIZER_H_

#include <memory>

#include "apps/mozart/services/composition/scenes.fidl.h"
#include "flutter/flow/layers/layer_tree.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {

class Rasterizer {
 public:
  virtual ~Rasterizer();

  static std::unique_ptr<Rasterizer> Create();

  virtual void SetScene(fidl::InterfaceHandle<mozart::Scene> scene) = 0;

  virtual void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                    ftl::Closure callback) = 0;
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
