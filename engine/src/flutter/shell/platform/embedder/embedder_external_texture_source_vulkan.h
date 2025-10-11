// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_SOURCE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_SOURCE_VULKAN_H_

#include "flutter/shell/platform/embedder/embedder.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_vk.h"

namespace flutter {

class ContextVK;

class EmbedderExternalTextureSourceVulkan final
    : public impeller::TextureSourceVK {
 public:
  EmbedderExternalTextureSourceVulkan(
      const std::shared_ptr<impeller::Context>& context,
      FlutterVulkanTexture* embedder_desc);

  // |TextureSourceVK|
  ~EmbedderExternalTextureSourceVulkan() override;

  // |TextureSourceVK|
  impeller::vk::Image GetImage() const override;

  // |TextureSourceVK|
  impeller::vk::ImageView GetImageView() const override;

  // |TextureSourceVK|
  impeller::vk::ImageView GetRenderTargetView() const override;

  bool IsValid() const;

  // |TextureSourceVK|
  bool IsSwapchainImage() const override;

  // |TextureSourceVK|
  std::shared_ptr<impeller::YUVConversionVK> GetYUVConversion() const override;

 private:
  bool CreateTextureImageView(
      const impeller::vk::Device& device,
      FlutterVulkanTexture* embedder_desc,
      const std::shared_ptr<impeller::YUVConversionVK>& yuv_conversion_wrapper);
  impeller::TextureDescriptor ToTextureDescriptor(
      FlutterVulkanTexture* embedder_desc);
  std::shared_ptr<impeller::YUVConversionVK> CreateYUVConversion(
      const impeller::ContextVK& context,
      FlutterVulkanTexture* embedder_desc);
  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion_ = {};
  bool needs_yuv_conversion_ = false;
  bool is_swapchain_image_ = false;
  bool is_valid_ = false;
  impeller::vk::Image texture_image_;
  impeller::vk::DeviceMemory texture_device_memory_;
  impeller::vk::UniqueImageView texture_image_view_ = {};
  EmbedderExternalTextureSourceVulkan(
      const EmbedderExternalTextureSourceVulkan&) = delete;
  EmbedderExternalTextureSourceVulkan& operator=(
      const EmbedderExternalTextureSourceVulkan&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_SOURCE_VULKAN_H_
