// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/allocation.h"

namespace impeller {

DescriptorPoolVK::DescriptorPoolVK(vk::Device device) : device_(device) {}

DescriptorPoolVK::~DescriptorPoolVK() = default;

static vk::UniqueDescriptorPool CreatePool(const vk::Device& device,
                                           uint32_t pool_count) {
  TRACE_EVENT0("impeller", "CreateDescriptorPool");
  std::vector<vk::DescriptorPoolSize> pools = {
      {vk::DescriptorType::eCombinedImageSampler, pool_count},
      {vk::DescriptorType::eUniformBuffer, pool_count},
      {vk::DescriptorType::eStorageBuffer, pool_count},
      {vk::DescriptorType::eSampledImage, pool_count},
      {vk::DescriptorType::eSampler, pool_count},
  };

  vk::DescriptorPoolCreateInfo pool_info;
  pool_info.setMaxSets(pools.size() * pool_count);
  pool_info.setPoolSizes(pools);

  auto [result, pool] = device.createDescriptorPoolUnique(pool_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
  }
  return std::move(pool);
}

std::optional<vk::DescriptorSet> DescriptorPoolVK::AllocateDescriptorSet(
    const vk::DescriptorSetLayout& layout) {
  auto pool = GetDescriptorPool();
  if (!pool) {
    return std::nullopt;
  }
  vk::DescriptorSetAllocateInfo set_info;
  set_info.setDescriptorPool(pool.value());
  set_info.setSetLayouts(layout);
  auto [result, sets] = device_.allocateDescriptorSets(set_info);
  if (result == vk::Result::eErrorOutOfPoolMemory) {
    return GrowPool() ? AllocateDescriptorSet(layout) : std::nullopt;
  }
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not allocate descriptor sets: "
                   << vk::to_string(result);
    return std::nullopt;
  }
  return sets[0];
}

std::optional<vk::DescriptorPool> DescriptorPoolVK::GetDescriptorPool() {
  if (pools_.empty()) {
    return GrowPool() ? GetDescriptorPool() : std::nullopt;
  }
  return *pools_.back();
}

bool DescriptorPoolVK::GrowPool() {
  const auto new_pool_size = Allocation::NextPowerOfTwoSize(pool_size_ + 1u);
  auto new_pool = CreatePool(device_, new_pool_size);
  if (!new_pool) {
    return false;
  }
  pool_size_ = new_pool_size;
  pools_.push(std::move(new_pool));
  return true;
}

}  // namespace impeller
