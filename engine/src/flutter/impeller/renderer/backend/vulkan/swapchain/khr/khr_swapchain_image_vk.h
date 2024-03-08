// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_IMAGE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_IMAGE_VK_H_

#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

class KHRSwapchainImageVK final : public TextureSourceVK {
 public:
  KHRSwapchainImageVK(TextureDescriptor desc,
                      const vk::Device& device,
                      vk::Image image);

  // |TextureSourceVK|
  ~KHRSwapchainImageVK() override;

  bool IsValid() const;

  PixelFormat GetPixelFormat() const;

  ISize GetSize() const;

  // |TextureSourceVK|
  vk::Image GetImage() const override;

  std::shared_ptr<Texture> GetMSAATexture() const;

  std::shared_ptr<Texture> GetDepthStencilTexture() const;

  // |TextureSourceVK|
  vk::ImageView GetImageView() const override;

  vk::ImageView GetRenderTargetView() const override;

  void SetMSAATexture(std::shared_ptr<Texture> texture);

  void SetDepthStencilTexture(std::shared_ptr<Texture> texture);

  bool IsSwapchainImage() const override { return true; }

 private:
  vk::Image image_ = VK_NULL_HANDLE;
  vk::UniqueImageView image_view_ = {};
  std::shared_ptr<Texture> msaa_texture_;
  std::shared_ptr<Texture> depth_stencil_texture_;
  bool is_valid_ = false;

  KHRSwapchainImageVK(const KHRSwapchainImageVK&) = delete;

  KHRSwapchainImageVK& operator=(const KHRSwapchainImageVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_IMAGE_VK_H_
