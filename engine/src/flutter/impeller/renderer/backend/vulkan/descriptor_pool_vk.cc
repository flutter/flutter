// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"

#include <optional>

#include "impeller/base/validation.h"

namespace impeller {

struct DescriptorPoolSize {
  size_t buffer_bindings;
  size_t texture_bindings;
  size_t storage_bindings;
  size_t subpass_bindings;
};

/// Descriptor pools are always allocated with the following sizes.
static const constexpr DescriptorPoolSize kDefaultBindingSize =
    DescriptorPoolSize{
        .buffer_bindings = 512u,   // Buffer Bindings
        .texture_bindings = 256u,  // Texture Bindings
        .storage_bindings = 32,
        .subpass_bindings = 4u  // Subpass Bindings
    };

DescriptorPoolVK::DescriptorPoolVK(std::weak_ptr<const ContextVK> context)
    : context_(std::move(context)) {}

void DescriptorPoolVK::Destroy() {
  pools_.clear();
}

DescriptorPoolVK::DescriptorPoolVK(std::weak_ptr<const ContextVK> context,
                                   DescriptorCacheMap descriptor_sets,
                                   std::vector<vk::UniqueDescriptorPool> pools)
    : context_(std::move(context)),
      descriptor_sets_(std::move(descriptor_sets)),
      pools_(std::move(pools)) {}

DescriptorPoolVK::~DescriptorPoolVK() {
  if (pools_.empty()) {
    return;
  }

  auto const context = context_.lock();
  if (!context) {
    return;
  }
  auto const recycler = context->GetDescriptorPoolRecycler();
  if (!recycler) {
    return;
  }

  recycler->Reclaim(std::move(descriptor_sets_), std::move(pools_));
}

fml::StatusOr<vk::DescriptorSet> DescriptorPoolVK::AllocateDescriptorSets(
    const vk::DescriptorSetLayout& layout,
    PipelineKey pipeline_key,
    const ContextVK& context_vk) {
  DescriptorCacheMap::iterator existing = descriptor_sets_.find(pipeline_key);
  if (existing != descriptor_sets_.end() && !existing->second.unused.empty()) {
    auto descriptor_set = existing->second.unused.back();
    existing->second.unused.pop_back();
    existing->second.used.push_back(descriptor_set);
    return descriptor_set;
  }

  if (pools_.empty()) {
    CreateNewPool(context_vk);
  }

  vk::DescriptorSetAllocateInfo set_info;
  set_info.setDescriptorPool(pools_.back().get());
  set_info.setPSetLayouts(&layout);
  set_info.setDescriptorSetCount(1);

  vk::DescriptorSet set;
  auto result = context_vk.GetDevice().allocateDescriptorSets(&set_info, &set);
  if (result == vk::Result::eErrorOutOfPoolMemory) {
    // If the pool ran out of memory, we need to create a new pool.
    CreateNewPool(context_vk);
    set_info.setDescriptorPool(pools_.back().get());
    result = context_vk.GetDevice().allocateDescriptorSets(&set_info, &set);
  }
  auto lookup_result =
      descriptor_sets_.try_emplace(pipeline_key, DescriptorCache{});
  lookup_result.first->second.used.push_back(set);

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not allocate descriptor sets: "
                   << vk::to_string(result);
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  return set;
}

fml::Status DescriptorPoolVK::CreateNewPool(const ContextVK& context_vk) {
  auto new_pool = context_vk.GetDescriptorPoolRecycler()->Get();
  if (!new_pool) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Failed to create descriptor pool");
  }
  pools_.emplace_back(std::move(new_pool));
  return fml::Status();
}

void DescriptorPoolRecyclerVK::Reclaim(
    DescriptorCacheMap descriptor_sets,
    std::vector<vk::UniqueDescriptorPool> pools) {
  // Reset the pool on a background thread.
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }

  for (auto& [_, cache] : descriptor_sets) {
    cache.unused.insert(cache.unused.end(), cache.used.begin(),
                        cache.used.end());
    cache.used.clear();
  }

  // Move the pool to the recycled list. If more than 32 pool are
  // cached then delete the newest entry.
  Lock recycled_lock(recycled_mutex_);
  while (recycled_.size() >= kMaxRecycledPools) {
    auto& back_entry = recycled_.back();
    back_entry->Destroy();
    recycled_.pop_back();
  }
  recycled_.push_back(std::make_shared<DescriptorPoolVK>(
      context_, std::move(descriptor_sets), std::move(pools)));
}

vk::UniqueDescriptorPool DescriptorPoolRecyclerVK::Get() {
  // Recycle a pool with a matching minumum capcity if it is available.
  return Create();
}

vk::UniqueDescriptorPool DescriptorPoolRecyclerVK::Create() {
  auto strong_context = context_.lock();
  if (!strong_context) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
    return {};
  }

  std::vector<vk::DescriptorPoolSize> pools = {
      vk::DescriptorPoolSize{vk::DescriptorType::eCombinedImageSampler,
                             kDefaultBindingSize.texture_bindings},
      vk::DescriptorPoolSize{vk::DescriptorType::eUniformBuffer,
                             kDefaultBindingSize.buffer_bindings},
      vk::DescriptorPoolSize{vk::DescriptorType::eStorageBuffer,
                             kDefaultBindingSize.storage_bindings},
      vk::DescriptorPoolSize{vk::DescriptorType::eInputAttachment,
                             kDefaultBindingSize.subpass_bindings}};
  vk::DescriptorPoolCreateInfo pool_info;
  pool_info.setMaxSets(kDefaultBindingSize.texture_bindings +
                       kDefaultBindingSize.buffer_bindings +
                       kDefaultBindingSize.storage_bindings +
                       kDefaultBindingSize.subpass_bindings);
  pool_info.setPoolSizes(pools);
  auto [result, pool] =
      strong_context->GetDevice().createDescriptorPoolUnique(pool_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
  }
  return std::move(pool);
}

std::shared_ptr<DescriptorPoolVK>
DescriptorPoolRecyclerVK::GetDescriptorPool() {
  {
    Lock recycled_lock(recycled_mutex_);
    if (!recycled_.empty()) {
      auto result = recycled_.back();
      recycled_.pop_back();
      return result;
    }
  }
  return std::make_shared<DescriptorPoolVK>(context_);
}

}  // namespace impeller
