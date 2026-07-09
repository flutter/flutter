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

void DescriptorPoolVK::AbandonForDriverCrash() {
  // Release each UniqueDescriptorPool handle so that the vk::UniqueHandle
  // destructor never calls vkDestroyDescriptorPool on the corrupted device.
  for (auto& pool : pools_) {
    pool.release();
  }
  pools_.clear();
  descriptor_sets_.clear();
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
    // Context is dying - release Vulkan handles without making API calls.
    for (auto& pool : pools_) {
      pool.release();
    }
    return;
  }
  auto const recycler = context->GetDescriptorPoolRecycler();
  if (!recycler) {
    for (auto& pool : pools_) {
      pool.release();
    }
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
    auto pool_status = CreateNewPool(context_vk);
    if (!pool_status.ok()) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Failed to create descriptor pool");
    }
    set_info.setDescriptorPool(pools_.back().get());
    result = context_vk.GetDevice().allocateDescriptorSets(&set_info, &set);
  }

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not allocate descriptor sets: "
                   << vk::to_string(result);
    return fml::Status(fml::StatusCode::kUnknown, "");
  }

  // Register the newly allocated descriptor set in the per-pipeline cache.
  // try_emplace inserts a new DescriptorCache if one doesn't exist for
  // this pipeline key. The set is tracked as "used" and will be moved
  // to "unused" during frame-end reclamation for reuse in future frames.
  auto lookup_result =
      descriptor_sets_.try_emplace(pipeline_key, DescriptorCache{});
  lookup_result.first->second.used.push_back(set);
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
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }

  // Reset all underlying VkDescriptorPool handles via vkResetDescriptorPool.
  // This frees ALL descriptor sets allocated from each pool, returning them
  // to the unallocated state. Without this, pools become permanently exhausted
  // and cache misses (different pipeline keys on reuse) would trigger
  // VK_ERROR_OUT_OF_POOL_MEMORY, causing new raw pool creation every time.
  auto device = strong_context->GetDevice();
  for (auto& pool : pools) {
    auto reset_result = device.resetDescriptorPool(pool.get());
    if (reset_result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Could not reset descriptor pool: "
                     << vk::to_string(reset_result);
    }
  }
  // The descriptor set handles in the cache are now invalid after pool reset.
  descriptor_sets.clear();

  // Move the pool to the recycled list. If more than 32 pools are
  // cached then delete the newest entry (back of the deque).
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
  // Try to extract a reset raw pool from the recycled wrappers first.
  {
    Lock recycled_lock(recycled_mutex_);
    for (auto it = recycled_.begin(); it != recycled_.end(); ++it) {
      if (!(*it)->pools_.empty()) {
        auto pool = std::move((*it)->pools_.back());
        (*it)->pools_.pop_back();
        if ((*it)->pools_.empty()) {
          recycled_.erase(it);
        }
        return pool;
      }
    }
  }
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
