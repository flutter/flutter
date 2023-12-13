// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DESCRIPTOR_POOL_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DESCRIPTOR_POOL_VK_H_

#include <cstdint>

#include "fml/status_or.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A short-lived fixed-sized descriptor pool. Descriptors
///             from this pool don't need to be freed individually. Instead, the
///             pool must be collected after all the descriptors allocated from
///             it are done being used.
///
///             The pool or it's descriptors may not be accessed from multiple
///             threads.
///
///             Encoders create pools as necessary as they have the same
///             threading and lifecycle restrictions.
class DescriptorPoolVK {
 public:
  explicit DescriptorPoolVK(const std::weak_ptr<const ContextVK>& context);

  ~DescriptorPoolVK();

  fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateDescriptorSets(
      uint32_t buffer_count,
      uint32_t sampler_count,
      uint32_t subpass_count,
      const std::vector<vk::DescriptorSetLayout>& layouts);

 private:
  std::weak_ptr<const ContextVK> context_;
  vk::UniqueDescriptorPool pool_ = {};
  uint32_t allocated_capacity_ = 0;

  DescriptorPoolVK(const DescriptorPoolVK&) = delete;

  DescriptorPoolVK& operator=(const DescriptorPoolVK&) = delete;
};

// A descriptor pool and its allocated buffer/sampler size.
using DescriptorPoolAndSize = std::pair<vk::UniqueDescriptorPool, uint32_t>;

//------------------------------------------------------------------------------
/// @brief      Creates and manages the lifecycle of |vk::DescriptorPoolVK|
///             objects.
///
/// To make descriptor pool recycling more effective, the number of requusted
/// descriptor slots is rounded up the nearest power of two. This also makes
/// determining whether a recycled pool has sufficient slots easier as only a
/// single number comparison is required.
///
/// We round up to a minimum of 64 as the smallest power of two to reduce the
/// range of potential allocations to approximately: 64, 128, 256, 512, 1024,
/// 2048, 4096. Beyond this size applications will have far too many drawing
/// commands to render correctly. We also limit the number of cached descriptor
/// pools to 32, which is somewhat arbitrarily chosen, but given 2-ish frames in
/// flight is about 16 descriptors pools per frame which is extremely generous.
class DescriptorPoolRecyclerVK final
    : public std::enable_shared_from_this<DescriptorPoolRecyclerVK> {
 public:
  ~DescriptorPoolRecyclerVK() = default;

  /// The maximum number of descriptor pools this recycler will hold onto.
  static constexpr size_t kMaxRecycledPools = 32u;

  /// @brief      Creates a recycler for the given |ContextVK|.
  ///
  /// @param[in]  context The context to create the recycler for.
  explicit DescriptorPoolRecyclerVK(std::weak_ptr<ContextVK> context)
      : context_(std::move(context)) {}

  /// @brief      Gets a descriptor pool with at least [minimum_capacity]
  ///             sampler and slots.
  ///
  ///             This may create a new descriptor pool if no existing pools had
  ///             the necessary capacity.
  DescriptorPoolAndSize Get(uint32_t minimum_capacity);

  /// @brief      Returns the descriptor pool to be reset on a background
  ///             thread.
  ///
  /// @param[in]  pool The pool to recycler.
  void Reclaim(vk::UniqueDescriptorPool&& pool, uint32_t allocated_capacity);

 private:
  std::weak_ptr<ContextVK> context_;

  Mutex recycled_mutex_;
  std::vector<DescriptorPoolAndSize> recycled_ IPLR_GUARDED_BY(recycled_mutex_);

  /// @brief      Creates a new |vk::CommandPool|.
  ///
  ///             The descriptor pool will have at least [minimum_capacity]
  ///             buffer and texture slots.
  ///
  /// @returns    Returns a |std::nullopt| if a pool could not be created.
  DescriptorPoolAndSize Create(uint32_t minimum_capacity);

  /// @brief      Reuses a recycled |vk::CommandPool|, if available.
  ///
  ///             The descriptor pool will have at least [minimum_capacity]
  ///             buffer and texture slots. [minimum_capacity] should be rounded
  ///             up to the next power of two for more efficient cache reuse.
  ///
  /// @returns    Returns a |std::nullopt| if a pool was not available.
  std::optional<DescriptorPoolAndSize> Reuse(uint32_t minimum_capacity);

  DescriptorPoolRecyclerVK(const DescriptorPoolRecyclerVK&) = delete;

  DescriptorPoolRecyclerVK& operator=(const DescriptorPoolRecyclerVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DESCRIPTOR_POOL_VK_H_
