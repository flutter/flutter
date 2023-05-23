// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"

namespace impeller {

SamplerLibraryVK::SamplerLibraryVK(
    const std::weak_ptr<DeviceHolder>& device_holder)
    : device_holder_(device_holder) {}

SamplerLibraryVK::~SamplerLibraryVK() = default;

std::shared_ptr<const Sampler> SamplerLibraryVK::GetSampler(
    SamplerDescriptor desc) {
  auto found = samplers_.find(desc);
  if (found != samplers_.end()) {
    return found->second;
  }
  auto device_holder = device_holder_.lock();
  if (!device_holder || !device_holder->GetDevice()) {
    return nullptr;
  }

  const auto mip_map = ToVKSamplerMipmapMode(desc.mip_filter);

  const auto min_filter = ToVKSamplerMinMagFilter(desc.min_filter);
  const auto mag_filter = ToVKSamplerMinMagFilter(desc.mag_filter);

  const auto address_mode_u = ToVKSamplerAddressMode(desc.width_address_mode);
  const auto address_mode_v = ToVKSamplerAddressMode(desc.height_address_mode);
  const auto address_mode_w = ToVKSamplerAddressMode(desc.depth_address_mode);

  const auto sampler_create_info =
      vk::SamplerCreateInfo()
          .setMagFilter(mag_filter)
          .setMinFilter(min_filter)
          .setAddressModeU(address_mode_u)
          .setAddressModeV(address_mode_v)
          .setAddressModeW(address_mode_w)
          .setBorderColor(vk::BorderColor::eFloatTransparentBlack)
          .setMipmapMode(mip_map);

  auto res =
      device_holder->GetDevice().createSamplerUnique(sampler_create_info);
  if (res.result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to create sampler: " << vk::to_string(res.result);
    return nullptr;
  }

  auto sampler = std::make_shared<SamplerVK>(desc, std::move(res.value));

  if (!sampler->IsValid()) {
    return nullptr;
  }

  if (!desc.label.empty()) {
    ContextVK::SetDebugName(device_holder->GetDevice(), sampler->GetSampler(),
                            desc.label.c_str());
  }

  samplers_[desc] = sampler;
  return sampler;
}

}  // namespace impeller
