// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_SURFACE_H_
#define FLUTTER_VULKAN_VULKAN_SURFACE_H_

#include "lib/ftl/macros.h"
#include "vulkan_handle.h"
#include "vulkan_proc_table.h"

namespace vulkan {

class VulkanSurface {
 public:
  VulkanSurface();

  virtual ~VulkanSurface();

  virtual const char* ExtensionName() = 0;

  virtual VkSurfaceKHR CreateSurfaceHandle(
      VulkanProcTable& vk,
      VulkanHandle<VkInstance>& instance) = 0;

  virtual bool IsValid() const = 0;

 private:
  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanSurface);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_SURFACE_H_
