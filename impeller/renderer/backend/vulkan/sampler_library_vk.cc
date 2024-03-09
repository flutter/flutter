// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {

SamplerLibraryVK::SamplerLibraryVK(
    const std::weak_ptr<DeviceHolderVK>& device_holder)
    : device_holder_(device_holder) {}

SamplerLibraryVK::~SamplerLibraryVK() = default;

static const std::unique_ptr<const Sampler> kNullSampler = nullptr;

const std::unique_ptr<const Sampler>& SamplerLibraryVK::GetSampler(
    SamplerDescriptor desc) {
  auto found = samplers_.find(desc);
  if (found != samplers_.end()) {
    return found->second;
  }
  auto device_holder = device_holder_.lock();
  if (!device_holder || !device_holder->GetDevice()) {
    return kNullSampler;
  }
  return (samplers_[desc] =
              std::make_unique<SamplerVK>(device_holder->GetDevice(), desc));
}

}  // namespace impeller
