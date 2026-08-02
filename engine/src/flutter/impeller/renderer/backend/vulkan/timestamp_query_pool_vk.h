// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TIMESTAMP_QUERY_POOL_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TIMESTAMP_QUERY_POOL_VK_H_

#include <memory>

#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/timestamp_query_pool.h"

namespace impeller {

class ContextVK;

//------------------------------------------------------------------------------
/// @brief      A `vk::QueryPool` of `vk::QueryType::eTimestamp` slots.
///
///             Raw query values are device tick counts. They are scaled by
///             `VkPhysicalDeviceLimits::timestampPeriod` on readback, and
///             masked to the queue's `timestampValidBits` first because the
///             bits above that are undefined.
///
class TimestampQueryPoolVK final
    : public TimestampQueryPool,
      public BackendCast<TimestampQueryPoolVK, TimestampQueryPool> {
 public:
  static std::shared_ptr<TimestampQueryPoolVK> Create(const ContextVK& context,
                                                      size_t query_count);

  // |TimestampQueryPool|
  ~TimestampQueryPoolVK() override;

  // |TimestampQueryPool|
  TimestampQueryResults Resolve() const override;

  //----------------------------------------------------------------------------
  /// @brief      Reset [index] and record a timestamp into it once [stage] is
  ///             reached.
  ///
  ///             Must be recorded outside of a render pass instance, since
  ///             `vkCmdResetQueryPool` is not allowed inside one.
  ///
  void RecordTimestamp(const vk::CommandBuffer& buffer,
                       vk::PipelineStageFlagBits stage,
                       size_t index) const;

 private:
  TimestampQueryPoolVK(std::weak_ptr<const DeviceHolderVK> device_holder,
                       vk::UniqueQueryPool pool,
                       size_t query_count,
                       float timestamp_period,
                       uint64_t valid_bits_mask);

  std::weak_ptr<const DeviceHolderVK> device_holder_;
  vk::UniqueQueryPool pool_;
  float timestamp_period_ = 1.0f;
  uint64_t valid_bits_mask_ = ~uint64_t{0};

  TimestampQueryPoolVK(const TimestampQueryPoolVK&) = delete;

  TimestampQueryPoolVK& operator=(const TimestampQueryPoolVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TIMESTAMP_QUERY_POOL_VK_H_
