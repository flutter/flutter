// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_surface_android.h"

namespace vulkan {

VulkanSurfaceAndroid::VulkanSurfaceAndroid(ANativeWindow* native_window)
    : native_window_(native_window) {
  if (native_window_ == nullptr) {
    return;
  }
  ANativeWindow_acquire(native_window_);
}

VulkanSurfaceAndroid::~VulkanSurfaceAndroid() {
  if (native_window_ == nullptr) {
    return;
  }
  ANativeWindow_release(native_window_);
}

const char* VulkanSurfaceAndroid::ExtensionName() {
  return VK_KHR_ANDROID_SURFACE_EXTENSION_NAME;
}

VkSurfaceKHR VulkanSurfaceAndroid::CreateSurfaceHandle(
    VulkanProcTable& vk,
    VulkanHandle<VkInstance>& instance) {
  if (!vk.IsValid() || !instance) {
    return VK_NULL_HANDLE;
  }

  const VkAndroidSurfaceCreateInfoKHR create_info = {
      .sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR,
      .pNext = nullptr,
      .flags = 0,
      .window = native_window_,
  };

  VkSurfaceKHR surface = VK_NULL_HANDLE;

  if (vk.createAndroidSurfaceKHR(instance, &create_info, nullptr, &surface) !=
      VK_SUCCESS) {
    return VK_NULL_HANDLE;
  }

  return surface;
}

bool VulkanSurfaceAndroid::IsValid() const {
  return native_window_ != nullptr;
}

}  // namespace vulkan
