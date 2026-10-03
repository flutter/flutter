// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vulkan_device_owner.h"

#include <dlfcn.h>
#include <utility>

namespace flutter {

VulkanDeviceOwner::VulkanDeviceOwner(
    void* vulkan_lib_handle,
    VkInstance instance,
    VkPhysicalDevice physical_device,
    VkDevice device,
    VkQueue queue,
    uint32_t graphics_queue_family_index,
    uint32_t api_version,
    std::vector<std::string> enabled_instance_extensions,
    std::vector<std::string> enabled_device_extensions,
    PFN_vkGetInstanceProcAddr raw_get_instance_proc_addr_fn,
    PFN_vkDestroyDevice destroy_device_fn,
    PFN_vkDestroyInstance destroy_instance_fn)
    : vulkan_lib_handle_(vulkan_lib_handle),
      instance_(instance),
      physical_device_(physical_device),
      device_(device),
      queue_(queue),
      graphics_queue_family_index_(graphics_queue_family_index),
      api_version_(api_version),
      enabled_instance_extensions_(std::move(enabled_instance_extensions)),
      enabled_device_extensions_(std::move(enabled_device_extensions)),
      raw_get_instance_proc_addr_fn_(raw_get_instance_proc_addr_fn),
      destroy_device_fn_(destroy_device_fn),
      destroy_instance_fn_(destroy_instance_fn) {
  if (raw_get_instance_proc_addr_fn_ != nullptr) {
    VulkanQueueGuard::RegisterInstance(instance_,
                                       raw_get_instance_proc_addr_fn_);
  }
  if (device_ != VK_NULL_HANDLE) {
    std::vector<VkQueue> queues;
    if (queue_ != VK_NULL_HANDLE) {
      queues.push_back(queue_);
    }
    VulkanQueueGuard::RegisterDevice(instance_, device_, queues);
  }
}

VulkanDeviceOwner::~VulkanDeviceOwner() {
  VulkanQueueGuard::TearDownDeviceAndInstance(
      instance_, device_, destroy_device_fn_, destroy_instance_fn_);
  instance_ = VK_NULL_HANDLE;
  physical_device_ = VK_NULL_HANDLE;
  device_ = VK_NULL_HANDLE;
  queue_ = VK_NULL_HANDLE;
  if (vulkan_lib_handle_ != nullptr) {
    dlclose(vulkan_lib_handle_);
    vulkan_lib_handle_ = nullptr;
  }
  if (destruction_callback_for_testing_) {
    destruction_callback_for_testing_();
  }
}

void VulkanDeviceOwner::SetDestructionCallbackForTesting(
    DestructionCallback callback) {
  destruction_callback_for_testing_ = std::move(callback);
}

}  // namespace flutter
