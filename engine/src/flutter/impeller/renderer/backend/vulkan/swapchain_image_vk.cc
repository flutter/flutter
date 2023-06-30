// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain_image_vk.h"

namespace impeller {

SwapchainImageVK::SwapchainImageVK(TextureDescriptor desc,
                                   const vk::Device& device,
                                   vk::Image image)
    : TextureSourceVK(desc), image_(image) {
  vk::ImageViewCreateInfo view_info;
  view_info.image = image_;
  view_info.viewType = vk::ImageViewType::e2D;
  view_info.format = ToVKImageFormat(desc.format);
  view_info.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = desc.mip_count;
  view_info.subresourceRange.layerCount = ToArrayLayerCount(desc.type);

  auto [view_result, view] = device.createImageViewUnique(view_info);
  if (view_result != vk::Result::eSuccess) {
    return;
  }

  image_view_ = std::move(view);
  is_valid_ = true;
}

SwapchainImageVK::~SwapchainImageVK() = default;

bool SwapchainImageVK::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Texture> SwapchainImageVK::GetMSAATexture() const {
  return msaa_tex_;
}

bool SwapchainImageVK::HasMSAATexture() const {
  return msaa_tex_ != nullptr;
}

void SwapchainImageVK::SetMSAATexture(std::shared_ptr<Texture> msaa_tex) {
  msaa_tex_ = std::move(msaa_tex);
}

PixelFormat SwapchainImageVK::GetPixelFormat() const {
  return desc_.format;
}

ISize SwapchainImageVK::GetSize() const {
  return desc_.size;
}

// |TextureSourceVK|
vk::Image SwapchainImageVK::GetImage() const {
  return image_;
}

// |TextureSourceVK|
vk::ImageView SwapchainImageVK::GetImageView() const {
  return image_view_.get();
}

}  // namespace impeller
