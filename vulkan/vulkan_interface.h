// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_INTERFACE_H_
#define FLUTTER_VULKAN_VULKAN_INTERFACE_H_

#define VK_NO_PROTOTYPES 1

#include "third_party/vulkan/src/vulkan/vulkan.h"

#define VK_KHR_ANDROID_SURFACE_EXTENSION_NAME "VK_KHR_android_surface"

typedef VkFlags VkAndroidSurfaceCreateFlagsKHR;

typedef struct VkAndroidSurfaceCreateInfoKHR {
  VkStructureType sType;
  const void* pNext;
  VkAndroidSurfaceCreateFlagsKHR flags;
  void* window;
} VkAndroidSurfaceCreateInfoKHR;

typedef VkResult(VKAPI_PTR* PFN_vkCreateAndroidSurfaceKHR)(
    VkInstance instance,
    const VkAndroidSurfaceCreateInfoKHR* pCreateInfo,
    const VkAllocationCallbacks* pAllocator,
    VkSurfaceKHR* pSurface);

#endif  // FLUTTER_VULKAN_VULKAN_INTERFACE_H_
