// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"

#include <algorithm>

#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {

SamplerLibraryVK::SamplerLibraryVK(
    const std::weak_ptr<DeviceHolderVK>& device_holder,
    uint32_t max_sampler_anisotropy)
    : device_holder_(device_holder),
      max_sampler_anisotropy_(max_sampler_anisotropy) {}

SamplerLibraryVK::~SamplerLibraryVK() = default;

raw_ptr<const Sampler> SamplerLibraryVK::GetSampler(
    const SamplerDescriptor& desc) {
  SamplerDescriptor desc_copy = desc;
  // Clamp to the device limit before keying the cache so that all values
  // beyond the limit share one sampler. The limit is 1 (disabled) when the
  // samplerAnisotropy feature is unavailable. The upper bound is floored at 1
  // so std::clamp never sees an inverted range if a driver reports below 1.
  desc_copy.max_anisotropy = static_cast<uint8_t>(
      std::clamp<uint32_t>(desc_copy.max_anisotropy, 1u,
                           std::max<uint32_t>(1u, max_sampler_anisotropy_)));

  uint64_t p_key = SamplerDescriptor::ToKey(desc_copy);
  {
    Lock lock(samplers_mutex_);
    if (auto sampler = FindSampler(p_key)) {
      return sampler;
    }
  }
  auto device_holder = device_holder_.lock();
  if (!device_holder || !device_holder->GetDevice()) {
    return raw_ptr<const Sampler>(nullptr);
  }
  auto sampler =
      std::make_shared<SamplerVK>(device_holder->GetDevice(), desc_copy);
  Lock lock(samplers_mutex_);
  if (auto existing = FindSampler(p_key)) {
    return existing;
  }
  samplers_.push_back(std::make_pair(p_key, std::move(sampler)));
  return raw_ptr(samplers_.back().second);
}

raw_ptr<const Sampler> SamplerLibraryVK::FindSampler(uint64_t key) const {
  for (const auto& [sampler_key, sampler] : samplers_) {
    if (sampler_key == key) {
      return raw_ptr(sampler);
    }
  }
  return raw_ptr<const Sampler>(nullptr);
}

}  // namespace impeller
