// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_PROC_TABLE_H_
#define FLUTTER_VULKAN_VULKAN_PROC_TABLE_H_

#include "lib/ftl/macros.h"
#include "vulkan_interface.h"

namespace vulkan {

class VulkanProcTable {
 public:
  template <class T>
  class Proc {
   public:
    using Proto = T;

    Proc(T proc = nullptr) : proc_(proc) {}

    ~Proc() { proc_ = nullptr; }

    Proc operator=(T proc) {
      proc_ = proc;
      return *this;
    }

    operator bool() const { return proc_ != nullptr; }

    operator T() const { return proc_; }

   private:
    T proc_;
  };

  VulkanProcTable();

  ~VulkanProcTable();

  bool IsValid() const;

  Proc<PFN_vkCreateInstance> createInstance;
  Proc<PFN_vkDestroyInstance> destroyInstance;
  Proc<PFN_vkEnumeratePhysicalDevices> enumeratePhysicalDevices;
  Proc<PFN_vkCreateDevice> createDevice;
  Proc<PFN_vkDestroyDevice> destroyDevice;
  Proc<PFN_vkGetDeviceQueue> getDeviceQueue;
  Proc<PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR>
      getPhysicalDeviceSurfaceCapabilitiesKHR;
  Proc<PFN_vkGetPhysicalDeviceSurfaceFormatsKHR>
      getPhysicalDeviceSurfaceFormatsKHR;
  Proc<PFN_vkCreateSwapchainKHR> createSwapchainKHR;
  Proc<PFN_vkGetSwapchainImagesKHR> getSwapchainImagesKHR;
  Proc<PFN_vkGetPhysicalDeviceSurfacePresentModesKHR>
      getPhysicalDeviceSurfacePresentModesKHR;
  Proc<PFN_vkDestroySurfaceKHR> destroySurfaceKHR;
  Proc<PFN_vkDestroySwapchainKHR> destroySwapchainKHR;
  Proc<PFN_vkCreateCommandPool> createCommandPool;
  Proc<PFN_vkDestroyCommandPool> destroyCommandPool;
  Proc<PFN_vkCreateSemaphore> createSemaphore;
  Proc<PFN_vkDestroySemaphore> destroySemaphore;
  Proc<PFN_vkAllocateCommandBuffers> allocateCommandBuffers;
  Proc<PFN_vkFreeCommandBuffers> freeCommandBuffers;
  Proc<PFN_vkCreateFence> createFence;
  Proc<PFN_vkDestroyFence> destroyFence;
  Proc<PFN_vkWaitForFences> waitForFences;

#if OS_ANDROID
  Proc<PFN_vkCreateAndroidSurfaceKHR> createAndroidSurfaceKHR;
#endif  // OS_ANDROID

 private:
  bool valid_;
  void* handle_;

  bool OpenLibraryHandle();
  bool CloseLibraryHandle();
  bool AcquireProcs();

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanProcTable);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_PROC_TABLE_H_
