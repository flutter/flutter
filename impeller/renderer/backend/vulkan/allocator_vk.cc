// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

_Pragma("GCC diagnostic push");
_Pragma("GCC diagnostic ignored \"-Wnullability-completeness\"");
_Pragma("GCC diagnostic ignored \"-Wunused-variable\"");
_Pragma("GCC diagnostic ignored \"-Wthread-safety-analysis\"");

#define VMA_IMPLEMENTATION
#include "impeller/renderer/backend/vulkan/allocator_vk.h"

_Pragma("GCC diagnostic pop");

namespace impeller {

AllocatorVK::AllocatorVK(uint32_t vulkan_api_version,
                         const vk::PhysicalDevice& physical_device,
                         const vk::Device& logical_device,
                         const vk::Instance& instance,
                         PFN_vkGetInstanceProcAddr get_instance_proc_address,
                         PFN_vkGetDeviceProcAddr get_device_proc_address) {
  VmaVulkanFunctions proc_table = {};
  proc_table.vkGetInstanceProcAddr = get_instance_proc_address;
  proc_table.vkGetDeviceProcAddr = get_device_proc_address;

  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.vulkanApiVersion = vulkan_api_version;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = logical_device;
  allocator_info.instance = instance;
  allocator_info.pVulkanFunctions = &proc_table;

  VmaAllocator allocator = {};
  auto result = vk::Result{::vmaCreateAllocator(&allocator_info, &allocator)};
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create memory allocator";
    return;
  }
  allocator_ = allocator;
  is_valid_ = true;
}

AllocatorVK::~AllocatorVK() {
  if (allocator_) {
    ::vmaDestroyAllocator(allocator_);
  }
}

// |Allocator|
bool AllocatorVK::IsValid() const {
  return is_valid_;
}

// |Allocator|
std::shared_ptr<Texture> AllocatorVK::CreateTexture(
    StorageMode mode,
    const TextureDescriptor& desc) {
  FML_UNREACHABLE();
}

// |Allocator|
std::shared_ptr<DeviceBuffer> AllocatorVK::CreateBuffer(StorageMode mode,
                                                        size_t length) {
  FML_UNREACHABLE();
}

}  // namespace impeller
