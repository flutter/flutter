// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/timestamp_query_pool_vk.h"

#include <utility>
#include <vector>

#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/queue_vk.h"

namespace impeller {

// Each slot is read back as a value followed by an availability word, which is
// what `vk::QueryResultFlagBits::eWithAvailability` appends.
static constexpr size_t kWordsPerQuery = 2u;

std::shared_ptr<TimestampQueryPoolVK> TimestampQueryPoolVK::Create(
    const ContextVK& context,
    size_t query_count) {
  if (query_count == 0u) {
    return nullptr;
  }
  if (!context.GetCapabilities()->SupportsTimestampQueries()) {
    return nullptr;
  }
  const std::shared_ptr<DeviceHolderVK> device_holder =
      context.GetDeviceHolder();
  if (!device_holder) {
    return nullptr;
  }

  const vk::PhysicalDeviceLimits limits =
      device_holder->GetPhysicalDevice().getProperties().limits;

  vk::QueryPoolCreateInfo info;
  info.queryCount = static_cast<uint32_t>(query_count);
  info.queryType = vk::QueryType::eTimestamp;
  auto [status, pool] = device_holder->GetDevice().createQueryPoolUnique(info);
  if (status != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create timestamp query pool.";
    return nullptr;
  }

  // Bits above `timestampValidBits` are undefined and have to be discarded. A
  // queue that reports timestamp support always reports at least 36 valid bits.
  const std::vector<vk::QueueFamilyProperties> families =
      device_holder->GetPhysicalDevice().getQueueFamilyProperties();
  const size_t family = context.GetGraphicsQueue()->GetIndex().family;
  uint32_t valid_bits =
      family < families.size() ? families[family].timestampValidBits : 0u;
  if (valid_bits == 0u) {
    VALIDATION_LOG << "The graphics queue does not support timestamps.";
    return nullptr;
  }
  const uint64_t valid_bits_mask =
      valid_bits >= 64u ? ~uint64_t{0} : ((uint64_t{1} << valid_bits) - 1u);

  return std::shared_ptr<TimestampQueryPoolVK>(
      new TimestampQueryPoolVK(device_holder, std::move(pool), query_count,
                               limits.timestampPeriod, valid_bits_mask));
}

TimestampQueryPoolVK::TimestampQueryPoolVK(
    std::weak_ptr<const DeviceHolderVK> device_holder,
    vk::UniqueQueryPool pool,
    size_t query_count,
    float timestamp_period,
    uint64_t valid_bits_mask)
    : TimestampQueryPool(query_count),
      device_holder_(std::move(device_holder)),
      pool_(std::move(pool)),
      timestamp_period_(timestamp_period),
      valid_bits_mask_(valid_bits_mask) {}

TimestampQueryPoolVK::~TimestampQueryPoolVK() = default;

void TimestampQueryPoolVK::RecordTimestamp(const vk::CommandBuffer& buffer,
                                           vk::PipelineStageFlagBits stage,
                                           size_t index) const {
  if (index >= query_count_) {
    return;
  }
  // A query must be reset before it is written again, and the reset has to be
  // ordered before the write in the same buffer. Resetting only this slot
  // leaves the writes recorded by other passes in the pool untouched.
  const uint32_t query = static_cast<uint32_t>(index);
  buffer.resetQueryPool(pool_.get(), query, 1u);
  buffer.writeTimestamp(stage, pool_.get(), query);
}

TimestampQueryResults TimestampQueryPoolVK::Resolve() const {
  TimestampQueryResults results;
  results.timestamps.resize(query_count_);

  std::shared_ptr<const DeviceHolderVK> device_holder = device_holder_.lock();
  if (!device_holder) {
    return results;
  }

  std::vector<uint64_t> words(query_count_ * kWordsPerQuery, 0u);
  // Deliberately no wait bit. Slots the GPU has not retired come back
  // unavailable rather than stalling the caller, and the whole call reports
  // `eNotReady` instead of failing.
  const vk::Result status = device_holder->GetDevice().getQueryPoolResults(
      pool_.get(),                                    //
      0u,                                             //
      static_cast<uint32_t>(query_count_),            //
      words.size() * sizeof(uint64_t),                //
      words.data(),                                   //
      kWordsPerQuery * sizeof(uint64_t),              //
      vk::QueryResultFlagBits::e64 |                  //
          vk::QueryResultFlagBits::eWithAvailability  //
  );
  if (status != vk::Result::eSuccess && status != vk::Result::eNotReady) {
    return results;
  }

  for (size_t i = 0u; i < query_count_; i++) {
    if (words[i * kWordsPerQuery + 1u] == 0u) {
      continue;
    }
    const uint64_t ticks = words[i * kWordsPerQuery] & valid_bits_mask_;
    // Scaled as a double. Tick counts routinely exceed the 24 bit mantissa of
    // the period's own float type.
    results.timestamps[i] = static_cast<uint64_t>(
        static_cast<double>(ticks) * static_cast<double>(timestamp_period_));
  }
  return results;
}

}  // namespace impeller
