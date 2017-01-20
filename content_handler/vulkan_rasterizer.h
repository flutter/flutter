// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_

#include <memory>

#include "flutter/content_handler/rasterizer.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/vulkan/vulkan_window.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {

class VulkanRasterizer : public Rasterizer {
 public:
  VulkanRasterizer();

  ~VulkanRasterizer() override;

  bool IsValid() const;

  void SetScene(fidl::InterfaceHandle<mozart::Scene> scene) override;

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
            ftl::Closure callback) override;

 private:
  std::unique_ptr<vulkan::VulkanWindow> window_;
  flow::CompositorContext compositor_context_;

  bool Draw(std::unique_ptr<flow::LayerTree> layer_tree);

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanRasterizer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
