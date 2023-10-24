// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"

namespace impeller {

DescriptorPoolVK::DescriptorPoolVK(
    const std::weak_ptr<const DeviceHolder>& device_holder)
    : device_holder_(device_holder) {
  FML_DCHECK(device_holder.lock());
}

DescriptorPoolVK::~DescriptorPoolVK() = default;

static vk::UniqueDescriptorPool CreatePool(const vk::Device& device,
                                           uint32_t image_count,
                                           uint32_t buffer_count) {
  TRACE_EVENT0("impeller", "CreateDescriptorPool");
  std::vector<vk::DescriptorPoolSize> pools = {};
  if (image_count > 0) {
    pools.emplace_back(vk::DescriptorPoolSize{
        vk::DescriptorType::eCombinedImageSampler, image_count});
  }
  if (buffer_count > 0) {
    pools.emplace_back(vk::DescriptorPoolSize{
        vk::DescriptorType::eUniformBuffer, buffer_count});
    pools.emplace_back(vk::DescriptorPoolSize{
        vk::DescriptorType::eStorageBuffer, buffer_count});
  }
  vk::DescriptorPoolCreateInfo pool_info;
  pool_info.setMaxSets(image_count + buffer_count);
  pool_info.setPoolSizes(pools);
  auto [result, pool] = device.createDescriptorPoolUnique(pool_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
  }
  return std::move(pool);
}

fml::StatusOr<std::vector<vk::DescriptorSet>>
DescriptorPoolVK::AllocateDescriptorSets(
    uint32_t buffer_count,
    uint32_t sampler_count,
    const std::vector<vk::DescriptorSetLayout>& layouts) {
  std::shared_ptr<const DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return fml::Status(fml::StatusCode::kUnknown, "No device");
  }

  auto new_pool =
      CreatePool(strong_device->GetDevice(), sampler_count, buffer_count);
  if (!new_pool) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Failed to create descriptor pool");
  }
  pool_ = std::move(new_pool);

  vk::DescriptorSetAllocateInfo set_info;
  set_info.setDescriptorPool(pool_.get());
  set_info.setSetLayouts(layouts);

  auto [result, sets] =
      strong_device->GetDevice().allocateDescriptorSets(set_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not allocate descriptor sets: "
                   << vk::to_string(result);
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  return sets;
}

}  // namespace impeller
