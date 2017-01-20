// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_SOFTWARE_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_SOFTWARE_RASTERIZER_H_

#include <memory>

#include "apps/mozart/services/buffers/cpp/buffer_producer.h"
#include "flutter/content_handler/rasterizer.h"
#include "flutter/flow/compositor_context.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {

class SoftwareRasterizer : public Rasterizer {
 public:
  SoftwareRasterizer();

  ~SoftwareRasterizer() override;

  void SetScene(fidl::InterfaceHandle<mozart::Scene> scene) override;

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
            ftl::Closure callback) override;

 private:
  mozart::ScenePtr scene_;
  std::unique_ptr<mozart::BufferProducer> buffer_producer_;
  flow::CompositorContext compositor_context_;

  FTL_DISALLOW_COPY_AND_ASSIGN(SoftwareRasterizer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_SOFTWARE_RASTERIZER_H_
