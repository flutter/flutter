// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/sampler_vk.h"

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_vk.h"

namespace impeller {

static vk::UniqueSampler CreateSampler(
    const vk::Device& device,
    const SamplerDescriptor& desc,
    const std::shared_ptr<YUVConversionVK>& yuv_conversion) {
  const auto mip_map = ToVKSamplerMipmapMode(desc.mip_filter);

  const auto min_filter = ToVKSamplerMinMagFilter(desc.min_filter);
  const auto mag_filter = ToVKSamplerMinMagFilter(desc.mag_filter);

  const auto address_mode_u = ToVKSamplerAddressMode(desc.width_address_mode);
  const auto address_mode_v = ToVKSamplerAddressMode(desc.height_address_mode);
  const auto address_mode_w = ToVKSamplerAddressMode(desc.depth_address_mode);

  vk::StructureChain<vk::SamplerCreateInfo,
                     // For VK_KHR_sampler_ycbcr_conversion
                     vk::SamplerYcbcrConversionInfo>
      sampler_chain;

  auto& sampler_info = sampler_chain.get();

  sampler_info.magFilter = mag_filter;
  sampler_info.minFilter = min_filter;
  sampler_info.addressModeU = address_mode_u;
  sampler_info.addressModeV = address_mode_v;
  sampler_info.addressModeW = address_mode_w;
  sampler_info.borderColor = vk::BorderColor::eFloatTransparentBlack;
  sampler_info.mipmapMode = mip_map;

  if (yuv_conversion && yuv_conversion->IsValid()) {
    sampler_chain.get<vk::SamplerYcbcrConversionInfo>().conversion =
        yuv_conversion->GetConversion();

    //
    // TL;DR: When using YUV conversion, our samplers are somewhat hobbled and
    // not all options configurable in Impeller (especially the linear
    // filtering which is by far the most used form of filtering) can be
    // supported. Switch to safe defaults.
    //
    // Spec: If sampler Y'CBCR conversion is enabled and the potential format
    // features of the sampler Y'CBCR conversion do not support or enable
    // separate reconstruction filters, minFilter and magFilter must be equal to
    // the sampler Y'CBCR conversion's chromaFilter.
    //
    // Thing is, we don't enable separate reconstruction filters. By the time we
    // are here, we also don't have access to the descriptor used to create this
    // conversion. So we don't yet know what the chromaFilter is. But eNearest
    // is a safe bet since the `AndroidHardwareBufferTextureSourceVK` defaults
    // to that safe value. So just use that.
    //
    // See the validation VUID-VkSamplerCreateInfo-minFilter-01645 for more.
    //
    sampler_info.magFilter = vk::Filter::eNearest;
    sampler_info.minFilter = vk::Filter::eNearest;

    // Spec: If sampler Y′CBCR conversion is enabled, addressModeU,
    // addressModeV, and addressModeW must be
    // VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, anisotropyEnable must be VK_FALSE,
    // and unnormalizedCoordinates must be VK_FALSE.
    //
    // See the validation VUID-VkSamplerCreateInfo-addressModeU-01646 for more.
    //
    sampler_info.addressModeU = vk::SamplerAddressMode::eClampToEdge;
    sampler_info.addressModeV = vk::SamplerAddressMode::eClampToEdge;
    sampler_info.addressModeW = vk::SamplerAddressMode::eClampToEdge;
    sampler_info.anisotropyEnable = false;
    sampler_info.unnormalizedCoordinates = false;
  } else {
    sampler_chain.unlink<vk::SamplerYcbcrConversionInfo>();
  }

  auto sampler = device.createSamplerUnique(sampler_chain.get());
  if (sampler.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create sampler: "
                   << vk::to_string(sampler.result);
    return {};
  }

  if (!desc.label.empty()) {
    ContextVK::SetDebugName(device, sampler.value.get(), desc.label.c_str());
  }

  return std::move(sampler.value);
}

SamplerVK::SamplerVK(const vk::Device& device,
                     SamplerDescriptor desc,
                     std::shared_ptr<YUVConversionVK> yuv_conversion)
    : Sampler(std::move(desc)),
      device_(device),
      sampler_(MakeSharedVK<vk::Sampler>(
          CreateSampler(device, desc_, yuv_conversion))),
      yuv_conversion_(std::move(yuv_conversion)) {
  is_valid_ = sampler_ && !!sampler_->Get();
}

SamplerVK::~SamplerVK() = default;

vk::Sampler SamplerVK::GetSampler() const {
  return *sampler_;
}

std::shared_ptr<SamplerVK> SamplerVK::CreateVariantForConversion(
    std::shared_ptr<YUVConversionVK> conversion) const {
  if (!conversion || !is_valid_) {
    return nullptr;
  }
  return std::make_shared<SamplerVK>(device_, desc_, std::move(conversion));
}

const std::shared_ptr<YUVConversionVK>& SamplerVK::GetYUVConversion() const {
  return yuv_conversion_;
}

}  // namespace impeller
