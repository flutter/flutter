// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VULKAN_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_vk.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class EmbedderExternalTextureSourceVulkan final
    : public impeller::TextureSourceVK {
 public:
  EmbedderExternalTextureSourceVulkan(
      const std::shared_ptr<impeller::Context>& context,
      FlutterVulkanExternalTexture* embedder_desc);

  // |TextureSourceVK|
  ~EmbedderExternalTextureSourceVulkan() override;

  // |TextureSourceVK|
  impeller::vk::Image GetImage() const override;

  // |TextureSourceVK|
  impeller::vk::ImageView GetImageView() const override;

  // |TextureSourceVK|
  impeller::vk::ImageView GetRenderTargetView(
      uint32_t mip_level,
      uint32_t array_layer) const override;

  bool IsValid() const;

  // |TextureSourceVK|
  bool IsSwapchainImage() const override;

  // |TextureSourceVK|
  std::shared_ptr<impeller::YUVConversionVK> GetYUVConversion() const override;

 private:
  bool CreateTextureImageView(
      const impeller::vk::Device& device,
      FlutterVulkanExternalTexture* embedder_desc,
      const std::shared_ptr<impeller::YUVConversionVK>& yuv_conversion_wrapper);
  impeller::TextureDescriptor ToTextureDescriptor(
      FlutterVulkanExternalTexture* embedder_desc);
  std::shared_ptr<impeller::YUVConversionVK> CreateYUVConversion(
      const impeller::ContextVK& context,
      FlutterVulkanExternalTexture* embedder_desc);
  std::shared_ptr<impeller::YUVConversionVK> yuv_conversion_ = {};
  bool needs_yuv_conversion_ = false;
  bool is_swapchain_image_ = false;
  bool is_valid_ = false;
  impeller::vk::Image texture_image_;
  impeller::vk::UniqueImageView texture_image_view_ = {};
  VoidCallback destruction_callback_;
  void* user_data_;
  EmbedderExternalTextureSourceVulkan(
      const EmbedderExternalTextureSourceVulkan&) = delete;
  EmbedderExternalTextureSourceVulkan& operator=(
      const EmbedderExternalTextureSourceVulkan&) = delete;
};

class EmbedderExternalTextureVulkan : public flutter::Texture {
 public:
  using ExternalTextureCallback = std::function<
      std::unique_ptr<FlutterVulkanExternalTexture>(int64_t, size_t, size_t)>;
  EmbedderExternalTextureVulkan(int64_t texture_identifier,
                                const ExternalTextureCallback& callback);

  ~EmbedderExternalTextureVulkan();

 private:
  const ExternalTextureCallback& external_texture_callback_;

  sk_sp<DlImage> last_image_;

  sk_sp<DlImage> ResolveTexture(int64_t texture_id,
                                GrDirectContext* context,
                                impeller::AiksContext* aiks_context,
                                const SkISize& size);
  sk_sp<DlImage> ResolveTextureSkia(int64_t texture_id,
                                    GrDirectContext* context,
                                    const SkISize& size);
  sk_sp<DlImage> ResolveTextureImpeller(int64_t texture_id,
                                        impeller::AiksContext* aiks_context,
                                        const SkISize& size);

  // |flutter::Texture|
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |flutter::Texture|
  void OnGrContextCreated() override;

  // |flutter::Texture|
  void OnGrContextDestroyed() override;

  // |flutter::Texture|
  void MarkNewFrameAvailable() override;

  // |flutter::Texture|
  void OnTextureUnregistered() override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureVulkan);
};
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_VULKAN_H_
