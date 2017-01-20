// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_
#define FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_

#include "flutter/vulkan/vulkan_native_surface.h"
#include "lib/ftl/macros.h"

namespace vulkan {

class VulkanNativeSurfaceMagma : public vulkan::VulkanNativeSurface {
 public:
  VulkanNativeSurfaceMagma();

  ~VulkanNativeSurfaceMagma();

  const char* GetExtensionName() const override;

  uint32_t GetSkiaExtensionName() const override;

  VkSurfaceKHR CreateSurfaceHandle(
      vulkan::VulkanProcTable& vk,
      const vulkan::VulkanHandle<VkInstance>& instance) const override;

  bool IsValid() const override;

  SkISize GetSize() const override;

 private:
  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanNativeSurfaceMagma);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_
