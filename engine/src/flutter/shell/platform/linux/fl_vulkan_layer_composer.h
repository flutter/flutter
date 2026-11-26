// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_LAYER_COMPOSER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_LAYER_COMPOSER_H_

#include <vector>

#include "flutter/shell/platform/linux/fl_vulkan_device_context.h"

namespace flutter {

struct FlVulkanLayer {
  VkImage image;
  VkRect2D bounds;
};

// Raster-thread only. The target can be reused after Draw returns.
class FlVulkanLayerComposer {
 public:
  explicit FlVulkanLayerComposer(FlVulkanDeviceContext context);
  ~FlVulkanLayerComposer();
  bool Draw(VkImage target,
            VkExtent2D size,
            const std::vector<FlVulkanLayer>& layers);

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_LAYER_COMPOSER_H_
