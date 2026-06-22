// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"

#include <algorithm>

#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {

SamplerLibraryVK::SamplerLibraryVK(
    const std::weak_ptr<DeviceHolderVK>& device_holder,
    float max_sampler_anisotropy)
    : device_holder_(device_holder),
      max_sampler_anisotropy_(max_sampler_anisotropy) {}

SamplerLibraryVK::~SamplerLibraryVK() = default;

void SamplerLibraryVK::ApplyWorkarounds(const WorkaroundsVK& workarounds) {
  mips_disabled_workaround_ = workarounds.broken_mipmap_generation;
}

raw_ptr<const Sampler> SamplerLibraryVK::GetSampler(
    const SamplerDescriptor& desc) {
  SamplerDescriptor desc_copy = desc;
  if (mips_disabled_workaround_) {
    desc_copy.mip_filter = MipFilter::kBase;
  }
  // Clamp to the device limit before keying the cache so that all values
  // beyond the limit share one sampler. The limit is 1 (disabled) when the
  // samplerAnisotropy feature is unavailable. The upper bound is floored at 1
  // so std::clamp never sees an inverted range if a driver reports below 1.
  desc_copy.max_anisotropy = static_cast<uint8_t>(
      std::clamp(static_cast<float>(desc_copy.max_anisotropy), 1.0f,
                 std::max(1.0f, max_sampler_anisotropy_)));

  uint64_t p_key = SamplerDescriptor::ToKey(desc_copy);
  for (const auto& [key, value] : samplers_) {
    if (key == p_key) {
      return raw_ptr(value);
    }
  }
  auto device_holder = device_holder_.lock();
  if (!device_holder || !device_holder->GetDevice()) {
    return raw_ptr<const Sampler>(nullptr);
  }
  samplers_.push_back(std::make_pair(
      p_key,
      std::make_shared<SamplerVK>(device_holder->GetDevice(), desc_copy)));
  return raw_ptr(samplers_.back().second);
}

}  // namespace impeller
