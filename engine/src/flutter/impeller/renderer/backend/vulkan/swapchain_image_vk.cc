// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain_image_vk.h"

namespace impeller {

SwapchainImageVK::SwapchainImageVK(vk::Device device,
                                   vk::Image image,
                                   PixelFormat image_format,
                                   ISize image_size)
    : image_(image), image_format_(image_format), image_size_(image_size) {
  vk::ImageViewCreateInfo view_info;
  view_info.image = image_;
  view_info.viewType = vk::ImageViewType::e2D;
  view_info.format = ToVKImageFormat(image_format_);
  view_info.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.levelCount = 1u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.layerCount = 1u;

  auto [view_result, view] = device.createImageViewUnique(view_info);
  if (view_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create image view: "
                   << vk::to_string(view_result);
    return;
  }

  image_view_ = std::move(view);
  is_valid_ = true;
}

SwapchainImageVK::~SwapchainImageVK() = default;

bool SwapchainImageVK::IsValid() const {
  return is_valid_;
}

PixelFormat SwapchainImageVK::GetPixelFormat() const {
  return image_format_;
}

ISize SwapchainImageVK::GetSize() const {
  return image_size_;
}

// |TextureSourceVK|
vk::Image SwapchainImageVK::GetVKImage() const {
  return image_;
}

// |TextureSourceVK|
vk::ImageView SwapchainImageVK::GetVKImageView() const {
  return image_view_.get();
}

}  // namespace impeller
