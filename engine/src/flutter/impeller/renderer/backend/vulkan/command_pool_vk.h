// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <thread>

#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      An opaque object that provides |vk::CommandBuffer| objects.
///
/// A best practice is to create a |CommandPoolVK| for each thread that will
/// submit commands to the GPU, and to recycle (reuse) |vk::CommandBuffer|s by
/// resetting them in a background thread.
///
/// @see
/// https://arm-software.github.io/vulkan_best_practice_for_mobile_developers/samples/performance/command_buffer_usage/command_buffer_usage_tutorial.html#resetting-the-command-pool
class CommandPoolVK final {
 public:
  /// @brief      Gets the |CommandPoolVK| for the current thread.
  ///
  /// @param[in]  context  The |ContextVK| to use.
  ///
  /// If the current thread does not have a |CommandPoolVK|, one will be created
  /// and returned. If the current thread already has a |CommandPoolVK|, it will
  /// be returned.
  ///
  /// @return     The |CommandPoolVK| for the current thread, or |nullptr| if
  ///             either the |ContextVK| is invalid, or a pool could not be
  ///             created for any reason.
  ///
  ///             In other words an invalid command pool will never be returned.
  static std::shared_ptr<CommandPoolVK> GetThreadLocal(
      const ContextVK* context);

  /// @brief      Clears all |CommandPoolVK|s for the given |ContextVK|.
  ///
  /// @param[in]  context  The |ContextVK| to clear.
  ///
  /// Every |CommandPoolVK| that was created for every thread that has ever
  /// called |GetThreadLocal| with the given |ContextVK| will be cleared.
  ///
  /// @note       Should only be called when the |ContextVK| is being destroyed.
  static void ClearAllPools(const ContextVK* context);

  ~CommandPoolVK();

  /// @brief      Whether or not this |CommandPoolVK| is valid.
  ///
  /// A command pool is no longer when valid once it's been |Reset|.
  bool IsValid() const;

  /// @brief      Creates and returns a new |vk::CommandBuffer|.
  ///
  /// An attempt is made to reuse existing buffers (instead of creating new
  /// ones) by recycling buffers that have been collected by
  /// |CollectGraphicsCommandBuffer|.
  ///
  /// @return     Always returns a new |vk::CommandBuffer|, but if for any
  ///             reason a valid command buffer could not be created, it will be
  ///             a `{}` default instance (i.e. while being torn down).
  vk::UniqueCommandBuffer CreateGraphicsCommandBuffer();

  /// @brief      Collects the given |vk::CommandBuffer| for recycling.
  ///
  /// The given |vk::CommandBuffer| will be recycled (reused) in the future when
  /// |CreateGraphicsCommandBuffer| is called.
  ///
  /// @param[in]  buffer  The |vk::CommandBuffer| to collect.
  ///
  /// @note       This method is a noop if a different thread created the pool.
  ///
  /// @see        |GarbageCollectBuffersIfAble|
  void CollectGraphicsCommandBuffer(vk::UniqueCommandBuffer buffer);

 private:
  const std::thread::id owner_id_;
  std::weak_ptr<const DeviceHolder> device_holder_;
  vk::UniqueCommandPool graphics_pool_;
  Mutex buffers_to_collect_mutex_;
  std::vector<vk::UniqueCommandBuffer> buffers_to_collect_
      IPLR_GUARDED_BY(buffers_to_collect_mutex_);
  std::vector<vk::UniqueCommandBuffer> recycled_buffers_;
  bool is_valid_ = false;

  /// @brief      Resets, releasing all |vk::CommandBuffer|s.
  ///
  /// @note       "All" includes active and recycled buffers.
  void Reset();

  explicit CommandPoolVK(const ContextVK* context);

  /// @brief      Collects buffers for recycling if able.
  ///
  /// If any buffers have been returned through |CollectGraphicsCommandBuffer|,
  /// then they are reset and made available to future calls to
  /// |CreateGraphicsCommandBuffer|.
  ///
  /// @note       This method is a noop if a different thread created the pool.
  void GarbageCollectBuffersIfAble() IPLR_REQUIRES(buffers_to_collect_mutex_);

  FML_DISALLOW_COPY_AND_ASSIGN(CommandPoolVK);
};

}  // namespace impeller
