// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_skia_proc_table.h"

#include <cstring>

namespace vulkan {

GrVkGetProc CreateSkiaGetProc(const fml::RefPtr<vulkan::VulkanProcTable>& vk) {
  if (!vk || !vk->IsValid()) {
    return nullptr;
  }

  return [vk](const char* proc_name, VkInstance instance, VkDevice device) {
    if (device != VK_NULL_HANDLE) {
      PFN_vkVoidFunction result = nullptr;
      VulkanHandle<VkDevice> device_handle =
          VulkanHandle<VkDevice>{device, nullptr};
      if (strcmp(proc_name, "vkQueueSubmit") == 0) {
        result = vk->AcquireThreadsafeSubmitQueue(device_handle);
      } else if (strcmp(proc_name, "vkQueueWaitIdle") == 0) {
        result = vk->AcquireThreadsafeQueueWaitIdle(device_handle);
      } else {
        result = vk->AcquireProc(proc_name, device_handle);
      }

      if (result != nullptr) {
        return result;
      }
    }

    return vk->AcquireProc(proc_name,
                           VulkanHandle<VkInstance>{instance, nullptr});
  };
}

}  // namespace vulkan
