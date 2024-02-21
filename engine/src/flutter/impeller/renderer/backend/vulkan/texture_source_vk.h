// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_

#include "flutter/fml/status.h"
#include "impeller/base/thread.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/barrier_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

/// Abstract base class that represents a vkImage and an vkImageView.
///
/// This is intended to be used with an impeller::TextureVK. Example
/// implementations represent swapchain images or uploaded textures.
class TextureSourceVK {
 public:
  virtual ~TextureSourceVK();

  const TextureDescriptor& GetTextureDescriptor() const;

  virtual vk::Image GetImage() const = 0;

  /// @brief Retrieve the image view used for sampling/blitting/compute with
  ///        this texture source.
  virtual vk::ImageView GetImageView() const = 0;

  /// @brief Retrieve the image view used for render target attachments
  ///        with this texture source.
  ///
  /// ImageViews used as render target attachments cannot have any mip levels.
  /// In cases where we want to generate mipmaps with the result of this
  /// texture, we need to create multiple image views.
  virtual vk::ImageView GetRenderTargetView() const = 0;

  /// Encodes the layout transition `barrier` to `barrier.cmd_buffer` for the
  /// image.
  ///
  /// The transition is from the layout stored via `SetLayoutWithoutEncoding` to
  /// `barrier.new_layout`.
  fml::Status SetLayout(const BarrierVK& barrier) const;

  /// Store the layout of the image.
  ///
  /// This just is bookkeeping on the CPU, to actually set the layout use
  /// `SetLayout`.
  ///
  /// @param layout The new layout.
  /// @return The old layout.
  vk::ImageLayout SetLayoutWithoutEncoding(vk::ImageLayout layout) const;

  /// Get the last layout assigned to the TextureSourceVK.
  ///
  /// This value is synchronized with the GPU via SetLayout so it may not
  /// reflect the actual layout.
  vk::ImageLayout GetLayout() const;

  /// Whether or not this is a swapchain image.
  virtual bool IsSwapchainImage() const = 0;

  /// Store the last framebuffer object used with this texture.
  ///
  /// This field is only set if this texture is used as the resolve texture
  /// of a render pass. By construction, this framebuffer should be compatible
  /// with any future render passes.
  void SetFramebuffer(const SharedHandleVK<vk::Framebuffer>& framebuffer);

  /// Store the last render pass object used with this texture.
  ///
  /// This field is only set if this texture is used as the resolve texture
  /// of a render pass. By construction, this framebuffer should be compatible
  /// with any future render passes.
  void SetRenderPass(const SharedHandleVK<vk::RenderPass>& render_pass);

  /// Retrieve the last framebuffer object used with this texture.
  ///
  /// May be nullptr if no previous framebuffer existed.
  SharedHandleVK<vk::Framebuffer> GetFramebuffer() const;

  /// Retrieve the last render pass object used with this texture.
  ///
  /// May be nullptr if no previous render pass existed.
  SharedHandleVK<vk::RenderPass> GetRenderPass() const;

 protected:
  const TextureDescriptor desc_;

  explicit TextureSourceVK(TextureDescriptor desc);

 private:
  SharedHandleVK<vk::Framebuffer> framebuffer_ = nullptr;
  SharedHandleVK<vk::RenderPass> render_pass_ = nullptr;
  mutable RWMutex layout_mutex_;
  mutable vk::ImageLayout layout_ IPLR_GUARDED_BY(layout_mutex_) =
      vk::ImageLayout::eUndefined;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_
