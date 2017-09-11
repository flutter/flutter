// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_
#define FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_

#include "flutter/vulkan/vulkan_native_surface.h"
#include "lib/fxl/macros.h"

namespace vulkan {

class VulkanNativeSurfaceMagma : public vulkan::VulkanNativeSurface {
 public:
  VulkanNativeSurfaceMagma();

  // Alternate constructor which allows the caller to specify the surface's
  // width and height.
  // TODO: Remove this once we have a Fuchsia Display API.
  VulkanNativeSurfaceMagma(int32_t surface_width, int32_t surface_height);

  ~VulkanNativeSurfaceMagma();

  const char* GetExtensionName() const override;

  uint32_t GetSkiaExtensionName() const override;

  VkSurfaceKHR CreateSurfaceHandle(
      vulkan::VulkanProcTable& vk,
      const vulkan::VulkanHandle<VkInstance>& instance) const override;

  bool IsValid() const override;

  SkISize GetSize() const override;

 private:
  SkISize size_;
  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanNativeSurfaceMagma);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_MAGMA_H_
