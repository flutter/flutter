// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_VK_H_

#include "impeller/base/backend_cast.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class TextureVK final : public Texture, public BackendCast<TextureVK, Texture> {
 public:
  TextureVK(std::weak_ptr<Context> context,
            std::shared_ptr<TextureSourceVK> source);

  // |Texture|
  ~TextureVK() override;

  vk::Image GetImage() const;

  vk::ImageView GetImageView() const;

  vk::ImageView GetRenderTargetView() const;

  bool SetLayout(const BarrierVK& barrier) const;

  vk::ImageLayout SetLayoutWithoutEncoding(vk::ImageLayout layout) const;

  vk::ImageLayout GetLayout() const;

  std::shared_ptr<const TextureSourceVK> GetTextureSource() const;

  // |Texture|
  ISize GetSize() const override;

  void SetMipMapGenerated();

  bool IsSwapchainImage() const;

  std::shared_ptr<SamplerVK> GetImmutableSamplerVariant(
      const SamplerVK& sampler) const;

  /// Store the last framebuffer and render pass object used with this texture.
  ///
  /// This method is only called if this texture is used as the resolve texture
  /// of a render pass. By construction, this framebuffer should be compatible
  /// with any future render passes.
  void SetCachedFrameData(const FramebufferAndRenderPass& data,
                          SampleCount sample_count);

  /// Retrieve the last framebuffer and render pass object used with this
  /// texture.
  ///
  /// An empty FramebufferAndRenderPass is returned if there is no cached data
  /// for a particular sample count.
  const FramebufferAndRenderPass& GetCachedFrameData(
      SampleCount sample_count) const;

 private:
  std::weak_ptr<Context> context_;
  std::shared_ptr<TextureSourceVK> source_;
  bool has_validation_layers_ = false;

  // |Texture|
  void SetLabel(std::string_view label) override;

  // |Texture|
  void SetLabel(std::string_view label, std::string_view trailing) override;

  // |Texture|
  bool OnSetContents(const uint8_t* contents,
                     size_t length,
                     size_t slice) override;

  // |Texture|
  bool OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                     size_t slice) override;

  // |Texture|
  bool IsValid() const override;

  TextureVK(const TextureVK&) = delete;

  TextureVK& operator=(const TextureVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_VK_H_
