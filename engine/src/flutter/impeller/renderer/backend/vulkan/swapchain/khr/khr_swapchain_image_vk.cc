// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain/khr/khr_swapchain_image_vk.h"

namespace impeller {

KHRSwapchainImageVK::KHRSwapchainImageVK(TextureDescriptor desc,
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

KHRSwapchainImageVK::~KHRSwapchainImageVK() = default;

bool KHRSwapchainImageVK::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Texture> KHRSwapchainImageVK::GetMSAATexture() const {
  return msaa_texture_;
}

std::shared_ptr<Texture> KHRSwapchainImageVK::GetDepthStencilTexture() const {
  return depth_stencil_texture_;
}

void KHRSwapchainImageVK::SetMSAATexture(std::shared_ptr<Texture> texture) {
  msaa_texture_ = std::move(texture);
}

void KHRSwapchainImageVK::SetDepthStencilTexture(
    std::shared_ptr<Texture> texture) {
  depth_stencil_texture_ = std::move(texture);
}

PixelFormat KHRSwapchainImageVK::GetPixelFormat() const {
  return desc_.format;
}

ISize KHRSwapchainImageVK::GetSize() const {
  return desc_.size;
}

// |TextureSourceVK|
vk::Image KHRSwapchainImageVK::GetImage() const {
  return image_;
}

// |TextureSourceVK|
vk::ImageView KHRSwapchainImageVK::GetImageView() const {
  return image_view_.get();
}

// |TextureSourceVK|
vk::ImageView KHRSwapchainImageVK::GetRenderTargetView() const {
  return image_view_.get();
}

}  // namespace impeller
