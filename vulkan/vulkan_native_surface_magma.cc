// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_native_surface_magma.h"

namespace vulkan {

VulkanNativeSurfaceMagma::VulkanNativeSurfaceMagma() = default;

VulkanNativeSurfaceMagma::VulkanNativeSurfaceMagma(int32_t width,
                                                   int32_t height) {
  size_ = SkISize::Make(width, height);
}

VulkanNativeSurfaceMagma::~VulkanNativeSurfaceMagma() = default;

const char* VulkanNativeSurfaceMagma::GetExtensionName() const {
  return VK_KHR_MAGMA_SURFACE_EXTENSION_NAME;
}

uint32_t VulkanNativeSurfaceMagma::GetSkiaExtensionName() const {
  // There is no counterpart in Skia that recognizes the Magma extension name.
  // However, Flutter handles all setup anyway, so this is unnecessary.
  return 0;
}

VkSurfaceKHR VulkanNativeSurfaceMagma::CreateSurfaceHandle(
    vulkan::VulkanProcTable& vk,
    const vulkan::VulkanHandle<VkInstance>& instance) const {
  if (!vk.IsValid() || !instance) {
    return VK_NULL_HANDLE;
  }

  const VkMagmaSurfaceCreateInfoKHR create_info = {
      .sType = VK_STRUCTURE_TYPE_MAGMA_SURFACE_CREATE_INFO_KHR,
      .pNext = nullptr,
  };

  VkSurfaceKHR surface = VK_NULL_HANDLE;

  if (VK_CALL_LOG_ERROR(vk.CreateMagmaSurfaceKHR(
          instance, &create_info, nullptr /* allocator */, &surface)) !=
      VK_SUCCESS) {
    return VK_NULL_HANDLE;
  }

  return surface;
}

bool VulkanNativeSurfaceMagma::IsValid() const {
  // vkCreateMagmaSurfaceKHR doesn't actually take a native handle. So there is
  // nothing to check the validity of.
  return true;
}

SkISize VulkanNativeSurfaceMagma::GetSize() const {
  if (size_.width() != 0 && size_.height() != 0) {
    return size_;
  } else {
    // TODO: Don't hardcode this after we get a proper Fuchsia Display API.
    return SkISize::Make(2160, 1440);
  }
}

}  // namespace vulkan
