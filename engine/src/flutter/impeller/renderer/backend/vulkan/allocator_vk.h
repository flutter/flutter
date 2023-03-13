// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

#include <memory>

namespace impeller {

class AllocatorVK final : public Allocator {
 public:
  // |Allocator|
  ~AllocatorVK() override;

 private:
  friend class ContextVK;

  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  VmaAllocator allocator_ = {};
  std::weak_ptr<Context> context_;
  vk::Device device_;
  ISize max_texture_size_ = {4096, 4096};
  bool is_valid_ = false;

  AllocatorVK(std::weak_ptr<Context> context,
              uint32_t vulkan_api_version,
              const vk::PhysicalDevice& physical_device,
              const vk::Device& logical_device,
              const vk::Instance& instance,
              PFN_vkGetInstanceProcAddr get_instance_proc_address,
              PFN_vkGetDeviceProcAddr get_device_proc_address);

  // |Allocator|
  bool IsValid() const;

  // |Allocator|
  std::shared_ptr<DeviceBuffer> OnCreateBuffer(
      const DeviceBufferDescriptor& desc) override;

  // |Allocator|
  std::shared_ptr<Texture> OnCreateTexture(
      const TextureDescriptor& desc) override;

  // |Allocator|
  ISize GetMaxTextureSizeSupported() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(AllocatorVK);
};

}  // namespace impeller
