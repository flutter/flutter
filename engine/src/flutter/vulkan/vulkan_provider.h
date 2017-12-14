// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_PROVIDER_H_
#define FLUTTER_VULKAN_VULKAN_PROVIDER_H_

#include "flutter/vulkan/vulkan_handle.h"

namespace vulkan {

class VulkanProvider {
 public:
  virtual const vulkan::VulkanProcTable& vk() = 0;
  virtual const vulkan::VulkanHandle<VkDevice>& vk_device() = 0;
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_PROVIDER_H_
