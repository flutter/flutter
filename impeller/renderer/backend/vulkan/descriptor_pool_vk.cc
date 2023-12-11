// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include <optional>

#include "flutter/fml/trace_event.h"
#include "impeller/base/allocation.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

// Holds the command pool in a background thread, recyling it when not in use.
class BackgroundDescriptorPoolVK final {
 public:
  BackgroundDescriptorPoolVK(BackgroundDescriptorPoolVK&&) = default;

  explicit BackgroundDescriptorPoolVK(
      vk::UniqueDescriptorPool&& pool,
      uint32_t allocated_capacity,
      std::weak_ptr<DescriptorPoolRecyclerVK> recycler)
      : pool_(std::move(pool)),
        allocated_capacity_(allocated_capacity),
        recycler_(std::move(recycler)) {}

  ~BackgroundDescriptorPoolVK() {
    auto const recycler = recycler_.lock();

    // Not only does this prevent recycling when the context is being destroyed,
    // but it also prevents the destructor from effectively being called twice;
    // once for the original BackgroundCommandPoolVK() and once for the moved
    // BackgroundCommandPoolVK().
    if (!recycler) {
      return;
    }

    recycler->Reclaim(std::move(pool_), allocated_capacity_);
  }

 private:
  BackgroundDescriptorPoolVK(const BackgroundDescriptorPoolVK&) = delete;

  BackgroundDescriptorPoolVK& operator=(const BackgroundDescriptorPoolVK&) =
      delete;

  vk::UniqueDescriptorPool pool_;
  uint32_t allocated_capacity_;
  std::weak_ptr<DescriptorPoolRecyclerVK> recycler_;
};

DescriptorPoolVK::DescriptorPoolVK(
    const std::weak_ptr<const ContextVK>& context)
    : context_(context) {
  FML_DCHECK(context.lock());
}

DescriptorPoolVK::~DescriptorPoolVK() {
  if (!pool_) {
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

  auto reset_pool_when_dropped = BackgroundDescriptorPoolVK(
      std::move(pool_), allocated_capacity_, recycler);

  UniqueResourceVKT<BackgroundDescriptorPoolVK> pool(
      context->GetResourceManager(), std::move(reset_pool_when_dropped));
}

fml::StatusOr<std::vector<vk::DescriptorSet>>
DescriptorPoolVK::AllocateDescriptorSets(
    uint32_t buffer_count,
    uint32_t sampler_count,
    uint32_t subpass_count,
    const std::vector<vk::DescriptorSetLayout>& layouts) {
  std::shared_ptr<const ContextVK> strong_context = context_.lock();
  if (!strong_context) {
    return fml::Status(fml::StatusCode::kUnknown, "No device");
  }
  auto minimum_capacity =
      std::max(std::max(sampler_count, buffer_count), subpass_count);
  auto [new_pool, capacity] =
      strong_context->GetDescriptorPoolRecycler()->Get(minimum_capacity);
  if (!new_pool) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Failed to create descriptor pool");
  }
  pool_ = std::move(new_pool);
  allocated_capacity_ = capacity;

  vk::DescriptorSetAllocateInfo set_info;
  set_info.setDescriptorPool(pool_.get());
  set_info.setSetLayouts(layouts);

  auto [result, sets] =
      strong_context->GetDevice().allocateDescriptorSets(set_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not allocate descriptor sets: "
                   << vk::to_string(result);
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  return sets;
}

void DescriptorPoolRecyclerVK::Reclaim(vk::UniqueDescriptorPool&& pool,
                                       uint32_t allocated_capacity) {
  // Reset the pool on a background thread.
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }
  auto device = strong_context->GetDevice();
  device.resetDescriptorPool(pool.get());

  // Move the pool to the recycled list.
  Lock recycled_lock(recycled_mutex_);

  if (recycled_.size() < kMaxRecycledPools) {
    recycled_.push_back(std::make_pair(std::move(pool), allocated_capacity));
    return;
  }

  // If recycled has exceeded the max size of 32, then we need to remove a pool
  // from the list. If we were to drop this pool, then there is a risk that
  // the list of recycled descriptor pools could fill up with descriptors that
  // are too small to reuse. This would lead to all subsequent descriptor
  // allocations no longer being recycled. Instead, we pick the first
  // descriptor pool with a smaller capacity than the reseting pool to drop.
  // This may result in us dropping the current pool instead.
  std::optional<size_t> selected_index = std::nullopt;
  for (auto i = 0u; i < recycled_.size(); i++) {
    const auto& [_, capacity] = recycled_[i];
    if (capacity < allocated_capacity) {
      selected_index = i;
      break;
    }
  }
  if (selected_index.has_value()) {
    recycled_[selected_index.value()] =
        std::make_pair(std::move(pool), allocated_capacity);
  }
  // If selected index has no value, then no pools had a smaller capacity than
  // this one and we drop it instead.
}

DescriptorPoolAndSize DescriptorPoolRecyclerVK::Get(uint32_t minimum_capacity) {
  // See note on DescriptorPoolRecyclerVK doc comment.
  auto rounded_capacity =
      std::max(Allocation::NextPowerOfTwoSize(minimum_capacity), 64u);

  // Recycle a pool with a matching minumum capcity if it is available.
  auto recycled_pool = Reuse(rounded_capacity);
  if (recycled_pool.has_value()) {
    return std::move(recycled_pool.value());
  }
  return Create(rounded_capacity);
}

DescriptorPoolAndSize DescriptorPoolRecyclerVK::Create(
    uint32_t minimum_capacity) {
  FML_DCHECK(Allocation::NextPowerOfTwoSize(minimum_capacity) ==
             minimum_capacity);
  auto strong_context = context_.lock();
  if (!strong_context) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
    return {};
  }

  std::vector<vk::DescriptorPoolSize> pools = {
      vk::DescriptorPoolSize{vk::DescriptorType::eCombinedImageSampler,
                             minimum_capacity},
      vk::DescriptorPoolSize{vk::DescriptorType::eUniformBuffer,
                             minimum_capacity},
      vk::DescriptorPoolSize{vk::DescriptorType::eStorageBuffer,
                             minimum_capacity},
      vk::DescriptorPoolSize{vk::DescriptorType::eInputAttachment,
                             minimum_capacity}};
  vk::DescriptorPoolCreateInfo pool_info;
  pool_info.setMaxSets(minimum_capacity + minimum_capacity);
  pool_info.setPoolSizes(pools);
  auto [result, pool] =
      strong_context->GetDevice().createDescriptorPoolUnique(pool_info);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to create a descriptor pool";
  }
  return std::make_pair(std::move(pool), minimum_capacity);
}

std::optional<DescriptorPoolAndSize> DescriptorPoolRecyclerVK::Reuse(
    uint32_t minimum_capacity) {
  FML_DCHECK(Allocation::NextPowerOfTwoSize(minimum_capacity) ==
             minimum_capacity);
  Lock lock(recycled_mutex_);

  std::optional<size_t> found_index = std::nullopt;
  for (auto i = 0u; i < recycled_.size(); i++) {
    const auto& [_, capacity] = recycled_[i];
    if (capacity >= minimum_capacity) {
      found_index = i;
      break;
    }
  }
  if (!found_index.has_value()) {
    return std::nullopt;
  }
  auto pair = std::move(recycled_[found_index.value()]);
  recycled_.erase(recycled_.begin() + found_index.value());
  return pair;
}

}  // namespace impeller
