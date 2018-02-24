// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_

#include <memory>

#include "flutter/content_handler/rasterizer.h"
#include "flutter/content_handler/session_connection.h"
#include "flutter/flow/compositor_context.h"
#include "lib/fxl/macros.h"

namespace flutter_runner {

class VulkanRasterizer : public Rasterizer {
 public:
  VulkanRasterizer();

  ~VulkanRasterizer() override;

  bool IsValid() const;

  void SetScene(f1dl::InterfaceHandle<ui_mozart::Mozart> mozart,
                zx::eventpair import_token,
                fxl::Closure metrics_changed_callback) override;

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
            fxl::Closure callback) override;

 private:
  flow::CompositorContext compositor_context_;
  std::unique_ptr<SessionConnection> session_connection_;
  bool valid_;

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanRasterizer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
