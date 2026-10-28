// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_DEVICE_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_DEVICE_CONTEXT_H_
#include <vulkan/vulkan_core.h>
#include <memory>
namespace flutter {
// Internal lease on the manager's device. Helpers own their command pools;
// submissions must use the synchronized callback, never the raw driver entry.
struct FlVulkanDeviceContext {
  std::shared_ptr<void> lifetime;
  VkDevice device;
  VkQueue queue;
  uint32_t queue_family;
  uint32_t max_image_dimension;
  VkPhysicalDeviceMemoryProperties memory;
  PFN_vkGetDeviceProcAddr get_proc;
  PFN_vkQueueSubmit submit;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_DEVICE_CONTEXT_H_
