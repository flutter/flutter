// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

_Pragma("GCC diagnostic push");
_Pragma("GCC diagnostic ignored \"-Wnullability-completeness\"");
_Pragma("GCC diagnostic ignored \"-Wunused-variable\"");
_Pragma("GCC diagnostic ignored \"-Wthread-safety-analysis\"");

#define VMA_IMPLEMENTATION
#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"

#include <memory>

_Pragma("GCC diagnostic pop");

namespace impeller {

AllocatorVK::AllocatorVK(ContextVK& context,
                         uint32_t vulkan_api_version,
                         const vk::PhysicalDevice& physical_device,
                         const vk::Device& logical_device,
                         const vk::Instance& instance,
                         PFN_vkGetInstanceProcAddr get_instance_proc_address,
                         PFN_vkGetDeviceProcAddr get_device_proc_address)
    : context_(context) {
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
  // TODO (kaushikiska): consider optimizing  the usage flags based on
  // StorageMode.
  auto buffer_create_info = static_cast<vk::BufferCreateInfo::NativeType>(
      vk::BufferCreateInfo()
          .setUsage(vk::BufferUsageFlagBits::eStorageBuffer |
                    vk::BufferUsageFlagBits::eTransferSrc |
                    vk::BufferUsageFlagBits::eTransferDst)
          .setSize(length)
          .setSharingMode(vk::SharingMode::eExclusive));

  VmaAllocationCreateInfo allocCreateInfo = {};
  allocCreateInfo.usage = VMA_MEMORY_USAGE_AUTO;
  allocCreateInfo.flags =
      VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT |
      VMA_ALLOCATION_CREATE_MAPPED_BIT;

  VkBuffer buffer;
  VmaAllocation buffer_allocation;
  VmaAllocationInfo buffer_allocation_info;
  auto result = vk::Result{
      vmaCreateBuffer(allocator_, &buffer_create_info, &allocCreateInfo,
                      &buffer, &buffer_allocation, &buffer_allocation_info)};

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to allocate a device buffer";
    return nullptr;
  }

  auto device_allocation = std::make_unique<DeviceBufferAllocationVK>(
      allocator_, buffer, buffer_allocation, buffer_allocation_info);

  return std::make_shared<DeviceBufferVK>(length, mode, context_,
                                          std::move(device_allocation));
}

}  // namespace impeller
