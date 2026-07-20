// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_source_vulkan.h"

#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_library_vk.h"
#include "vulkan/vulkan.hpp"

namespace flutter {

bool RequiresYCBCRConversion(impeller::vk::Format format) {
  switch (format) {
    case impeller::vk::Format::eG8B8R83Plane420Unorm:
    case impeller::vk::Format::eG8B8R82Plane420Unorm:
    case impeller::vk::Format::eG8B8R83Plane422Unorm:
    case impeller::vk::Format::eG8B8R82Plane422Unorm:
    case impeller::vk::Format::eG8B8R83Plane444Unorm:
      return true;
    default:
      // NOTE: NOT EXHAUSTIVE.
      break;
  }
  return false;
}

EmbedderExternalTextureSourceVulkan::EmbedderExternalTextureSourceVulkan(
    const std::shared_ptr<impeller::Context>& p_context,
    FlutterVulkanTexture* embedder_desc)
    : TextureSourceVK(ToTextureDescriptor(embedder_desc)) {
  const auto& context = impeller::ContextVK::Cast(*p_context);
  const auto& device = context.GetDevice();
  texture_image_ =
      impeller::vk::Image(reinterpret_cast<VkImage>(embedder_desc->image));
  texture_device_memory_ = impeller::vk::DeviceMemory(
      reinterpret_cast<VkDeviceMemory>(embedder_desc->image_memory));
  destruction_callback_ = embedder_desc->destruction_callback;
  user_data_ = embedder_desc->user_data;

  needs_yuv_conversion_ = RequiresYCBCRConversion(
      static_cast<impeller::vk::Format>(embedder_desc->format));
  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion;
  if (needs_yuv_conversion_) {
    // Figure out how to perform YUV conversions.
    yuv_conversion = CreateYUVConversion(context, embedder_desc);
    if (!yuv_conversion || !yuv_conversion->IsValid()) {
      VALIDATION_LOG << "Fail to create yuv conversion";
      return;
    }
  }

  // Create image view for the newly created image.
  if (!CreateTextureImageView(device, embedder_desc, yuv_conversion)) {
    VALIDATION_LOG << "Fail to create texture image view";
    return;
  }

  yuv_conversion_ = std::move(yuv_conversion);
  is_valid_ = true;
}

EmbedderExternalTextureSourceVulkan::~EmbedderExternalTextureSourceVulkan() {
  if (destruction_callback_) {
    destruction_callback_(user_data_);
  }
}

impeller::PixelFormat ToPixelFormat(int32_t vk_format) {
  switch (vk_format) {
    case VK_FORMAT_UNDEFINED:
      return impeller::PixelFormat::kUnknown;
    case VK_FORMAT_R8G8B8A8_UNORM:
      return impeller::PixelFormat::kR8G8B8A8UNormInt;
    case VK_FORMAT_R8G8B8A8_SRGB:
      return impeller::PixelFormat::kR8G8B8A8UNormIntSRGB;
    case VK_FORMAT_B8G8R8A8_UNORM:
      return impeller::PixelFormat::kB8G8R8A8UNormInt;
    case VK_FORMAT_B8G8R8A8_SRGB:
      return impeller::PixelFormat::kB8G8R8A8UNormIntSRGB;
    case VK_FORMAT_R32G32B32A32_SFLOAT:
      return impeller::PixelFormat::kR32G32B32A32Float;
    case VK_FORMAT_R16G16B16A16_SFLOAT:
      return impeller::PixelFormat::kR16G16B16A16Float;
    case VK_FORMAT_S8_UINT:
      return impeller::PixelFormat::kS8UInt;
    case VK_FORMAT_D24_UNORM_S8_UINT:
      return impeller::PixelFormat::kD24UnormS8Uint;
    case VK_FORMAT_D32_SFLOAT_S8_UINT:
      return impeller::PixelFormat::kD32FloatS8UInt;
    case VK_FORMAT_R8_UNORM:
      return impeller::PixelFormat::kR8UNormInt;
    case VK_FORMAT_R8G8_UNORM:
      return impeller::PixelFormat::kR8G8UNormInt;
    default:
      return impeller::PixelFormat::kUnknown;
  }
}

impeller::TextureDescriptor
EmbedderExternalTextureSourceVulkan::ToTextureDescriptor(
    FlutterVulkanTexture* embedder_desc) {
  const auto size =
      impeller::ISize{static_cast<int64_t>(embedder_desc->width),
                      static_cast<int64_t>(embedder_desc->height)};
  impeller::TextureDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.format = ToPixelFormat(embedder_desc->format);
  desc.size = size;
  desc.type = impeller::TextureType::kTexture2D;
  desc.sample_count = impeller::SampleCount::kCount1;
  desc.compression_type = impeller::CompressionType::kLossless;
  desc.mip_count = 1u;
  desc.usage = impeller::TextureUsage::kRenderTarget;
  return desc;
}

std::shared_ptr<impeller::YUVConversionVK>
EmbedderExternalTextureSourceVulkan::CreateYUVConversion(
    const impeller::ContextVK& context,
    FlutterVulkanTexture* embedder_desc) {
  impeller::YUVConversionDescriptorVK conversion_chain;
  auto& conversion_info = conversion_chain.get();

  conversion_info.format =
      static_cast<impeller::vk::Format>(embedder_desc->format);
  conversion_info.ycbcrModel =
      impeller::vk::SamplerYcbcrModelConversion::eYcbcr709;
  conversion_info.ycbcrRange = impeller::vk::SamplerYcbcrRange::eItuFull;
  conversion_info.components = {impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity,
                                impeller::vk::ComponentSwizzle::eIdentity};
  conversion_info.xChromaOffset = impeller::vk::ChromaLocation::eCositedEven;
  conversion_info.yChromaOffset = impeller::vk::ChromaLocation::eCositedEven;
  conversion_info.chromaFilter = impeller::vk::Filter::eNearest;
  conversion_info.forceExplicitReconstruction = false;
  return context.GetYUVConversionLibrary()->GetConversion(conversion_chain);
}

bool EmbedderExternalTextureSourceVulkan::CreateTextureImageView(
    const impeller::vk::Device& device,
    FlutterVulkanTexture* embedder_desc,
    const std::shared_ptr<impeller::YUVConversionVK>& yuv_conversion_wrapper) {
  impeller::vk::StructureChain<impeller::vk::ImageViewCreateInfo,
                               impeller::vk::SamplerYcbcrConversionInfo>
      view_chain;
  auto& view_info = view_chain.get();
  view_info.image = texture_image_;
  view_info.viewType = impeller::vk::ImageViewType::e2D;
  view_info.format = static_cast<impeller::vk::Format>(embedder_desc->format);
  view_info.subresourceRange.aspectMask =
      impeller::vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = 1;
  view_info.subresourceRange.layerCount = 1;

  if (RequiresYCBCRConversion(
          static_cast<impeller::vk::Format>(embedder_desc->format))) {
    view_chain.get<impeller::vk::SamplerYcbcrConversionInfo>().conversion =
        yuv_conversion_wrapper->GetConversion();
  } else {
    view_chain.unlink<impeller::vk::SamplerYcbcrConversionInfo>();
  }
  auto image_view = device.createImageViewUnique(view_info);
  if (image_view.result != impeller::vk::Result::eSuccess) {
    return false;
  }
  texture_image_view_ = std::move(image_view.value);
  return true;
}

bool EmbedderExternalTextureSourceVulkan::IsValid() const {
  return is_valid_;
}

// |TextureSourceVK|
impeller::vk::Image EmbedderExternalTextureSourceVulkan::GetImage() const {
  return texture_image_;
}

// |TextureSourceVK|
impeller::vk::ImageView EmbedderExternalTextureSourceVulkan::GetImageView()
    const {
  return texture_image_view_.get();
}

// |TextureSourceVK|
impeller::vk::ImageView
EmbedderExternalTextureSourceVulkan::GetRenderTargetView(
    uint32_t mip_level,
    uint32_t array_layer) const {
  return texture_image_view_.get();
}

// |TextureSourceVK|
bool EmbedderExternalTextureSourceVulkan::IsSwapchainImage() const {
  return is_swapchain_image_;
}

// |TextureSourceVK|
std::shared_ptr<impeller::YUVConversionVK>
EmbedderExternalTextureSourceVulkan::GetYUVConversion() const {
  return needs_yuv_conversion_ ? yuv_conversion_ : nullptr;
}

}  // namespace flutter
