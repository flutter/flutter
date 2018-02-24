// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_RASTERIZER_H_

#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/ui/scenic/fidl/session.fidl.h"
#include "zircon/system/ulib/zx/include/zx/eventpair.h"

namespace flutter_runner {

class Rasterizer {
 public:
  virtual ~Rasterizer();

  static std::unique_ptr<Rasterizer> Create();

  virtual void SetScene(
      f1dl::InterfaceHandle<ui_mozart::Mozart> mozart,
      zx::eventpair import_token,
      fxl::Closure metrics_changed_callback) = 0;

  virtual void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                    fxl::Closure callback) = 0;
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_RASTERIZER_H_
