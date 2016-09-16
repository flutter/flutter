// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_proc_table.h"
#include "lib/ftl/logging.h"

#include <dlfcn.h>

namespace vulkan {

VulkanProcTable::VulkanProcTable() : valid_(false), handle_(nullptr) {
  if (!OpenLibraryHandle()) {
    return;
  }

  if (!AcquireProcs()) {
    return;
  }

  valid_ = true;
}

VulkanProcTable::~VulkanProcTable() {
  CloseLibraryHandle();
}

bool VulkanProcTable::IsValid() const {
  return valid_;
}

bool VulkanProcTable::OpenLibraryHandle() {
  dlerror();  // clear existing errors on thread.
  handle_ = dlopen("libvulkan.so", RTLD_NOW);
  if (handle_ == nullptr) {
    FTL_DLOG(WARNING) << "Could not open the vulkan library: " << dlerror();
    return false;
  }
  return true;
}

bool VulkanProcTable::CloseLibraryHandle() {
  if (handle_ != nullptr) {
    dlerror();  // clear existing errors on thread.
    if (dlclose(handle_) != 0) {
      FTL_DLOG(ERROR) << "Could not close the vulkan library handle. This "
                         "indicates a leak.";
      FTL_DLOG(ERROR) << dlerror();
    }
    handle_ = nullptr;
  }

  return handle_ == nullptr;
}

bool VulkanProcTable::AcquireProcs() {
  if (handle_ == nullptr) {
    return false;
  }

#define ACQUIRE_PROC(symbol, name)                                       \
  if (!(symbol = reinterpret_cast<decltype(symbol)::Proto>(              \
            dlsym(handle_, name)))) {                                    \
    FTL_DLOG(WARNING) << "Could not acquire proc for function " << name; \
    return false;                                                        \
  }

  ACQUIRE_PROC(createInstance, "vkCreateInstance");
  ACQUIRE_PROC(destroyInstance, "vkDestroyInstance");
  ACQUIRE_PROC(enumeratePhysicalDevices, "vkEnumeratePhysicalDevices");
  ACQUIRE_PROC(createDevice, "vkCreateDevice");
  ACQUIRE_PROC(destroyDevice, "vkDestroyDevice");
  ACQUIRE_PROC(createAndroidSurfaceKHR, "vkCreateAndroidSurfaceKHR");
  ACQUIRE_PROC(getDeviceQueue, "vkGetDeviceQueue");
  ACQUIRE_PROC(getPhysicalDeviceSurfaceCapabilitiesKHR,
               "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
  ACQUIRE_PROC(getPhysicalDeviceSurfaceFormatsKHR,
               "vkGetPhysicalDeviceSurfaceFormatsKHR");
  ACQUIRE_PROC(createSwapchainKHR, "vkCreateSwapchainKHR");
  ACQUIRE_PROC(getSwapchainImagesKHR, "vkGetSwapchainImagesKHR");
  ACQUIRE_PROC(getPhysicalDeviceSurfacePresentModesKHR,
               "vkGetPhysicalDeviceSurfacePresentModesKHR");
  ACQUIRE_PROC(destroySurfaceKHR, "vkDestroySurfaceKHR");
  ACQUIRE_PROC(createCommandPool, "createCommandPool");
  ACQUIRE_PROC(destroyCommandPool, "destroyCommandPool");
  ACQUIRE_PROC(createSemaphore, "vkCreateSemaphore");
  ACQUIRE_PROC(destroySemaphore, "vkDestroySemaphore");
  ACQUIRE_PROC(allocateCommandBuffers, "vkAllocateCommandBuffers");
  ACQUIRE_PROC(freeCommandBuffers, "vkFreeCommandBuffers");
  ACQUIRE_PROC(createFence, "vkCreateFence");
  ACQUIRE_PROC(destroyFence, "vkDestroyFence");
  ACQUIRE_PROC(waitForFences, "vkWaitForFences");

#undef ACQUIRE_PROC

  return true;
}

}  // namespace vulkan
