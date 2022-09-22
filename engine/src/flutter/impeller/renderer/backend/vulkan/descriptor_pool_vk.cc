// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {

DescriptorPoolVK::DescriptorPoolVK(vk::Device device) {
  constexpr size_t kPoolSize = 1024;

  std::vector<vk::DescriptorPoolSize> pool_sizes = {
      {vk::DescriptorType::eSampler, kPoolSize},
      {vk::DescriptorType::eCombinedImageSampler, kPoolSize},
      {vk::DescriptorType::eSampledImage, kPoolSize},
      {vk::DescriptorType::eStorageImage, kPoolSize},
      {vk::DescriptorType::eUniformTexelBuffer, kPoolSize},
      {vk::DescriptorType::eStorageTexelBuffer, kPoolSize},
      {vk::DescriptorType::eUniformBuffer, kPoolSize},
      {vk::DescriptorType::eStorageBuffer, kPoolSize},
      {vk::DescriptorType::eUniformBufferDynamic, kPoolSize},
      {vk::DescriptorType::eStorageBufferDynamic, kPoolSize},
      {vk::DescriptorType::eInputAttachment, kPoolSize},
  };

  vk::DescriptorPoolCreateInfo pool_info = {
      vk::DescriptorPoolCreateFlagBits::eFreeDescriptorSet,  // flags
      static_cast<uint32_t>(pool_sizes.size() * kPoolSize),  // max sets
      static_cast<uint32_t>(pool_sizes.size()),              // pool sizes count
      pool_sizes.data()                                      // pool sizes
  };

  auto res = device.createDescriptorPoolUnique(pool_info);
  if (res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
    return;
  }

  pool_ = std::move(res.value);
  is_valid_ = true;
}

vk::DescriptorPool DescriptorPoolVK::GetPool() {
  return *pool_;
}

DescriptorPoolVK::~DescriptorPoolVK() = default;

}  // namespace impeller
