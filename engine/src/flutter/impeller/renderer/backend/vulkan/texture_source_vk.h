// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_

#include <cstdint>
#include <vector>

#include "flutter/fml/status.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/barrier_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/backend/vulkan/yuv_conversion_vk.h"

namespace impeller {

// These methods should only be used by render_pass_vk.h
struct FramebufferAndRenderPass {
  SharedHandleVK<vk::Framebuffer> framebuffer = nullptr;
  SharedHandleVK<vk::RenderPass> render_pass = nullptr;
};

//------------------------------------------------------------------------------
/// @brief      Abstract base class that represents a vkImage and an
///             vkImageView.
///
///             This is intended to be used with an impeller::TextureVK. Example
///             implementations represent swapchain images, uploaded textures,
///             Android Hardware Buffer backend textures, etc...
///
class TextureSourceVK {
 public:
  virtual ~TextureSourceVK();

  //----------------------------------------------------------------------------
  /// @brief      Gets the texture descriptor for this image source.
  ///
  /// @warning    Texture descriptors from texture sources whose capabilities
  ///             are a superset of those that can be expressed with Vulkan
  ///             (like Android Hardware Buffer) are inferred. Stuff like size,
  ///             mip-counts, types is reliable. So use these descriptors as
  ///             advisory. Creating copies of texture sources from these
  ///             descriptors is usually not possible and  depends on the
  ///             allocator used.
  ///
  /// @return     The texture descriptor.
  ///
  const TextureDescriptor& GetTextureDescriptor() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the image handle for this texture source.
  ///
  /// @return     The image.
  ///
  virtual vk::Image GetImage() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the image view used for sampling/blitting/compute
  ///             with this texture source.
  ///
  /// @return     The image view.
  ///
  virtual vk::ImageView GetImageView() const = 0;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the image view used to attach a specific
  ///             subresource of this texture as a render target.
  ///
  ///             The returned view covers a single mip level and a single
  ///             array layer (or cube map face), since attachment views cannot
  ///             span multiple levels or layers.
  ///
  /// @param[in]  mip_level    The mip level to attach.
  /// @param[in]  array_layer  The array layer or cube map face to attach.
  ///
  /// @return     The render target view.
  ///
  virtual vk::ImageView GetRenderTargetView(uint32_t mip_level,
                                            uint32_t array_layer) const = 0;

  //----------------------------------------------------------------------------
  /// @brief      Encodes the layout transition `barrier` to
  ///             `barrier.cmd_buffer` for the image.
  ///
  ///             The transition is from the layout stored via
  ///             `SetLayoutWithoutEncoding` to `barrier.new_layout`.
  ///
  /// @param[in]  barrier  The barrier.
  ///
  /// @return     If the layout transition was successfully made.
  ///
  fml::Status SetLayout(const BarrierVK& barrier) const;

  //----------------------------------------------------------------------------
  /// @brief      Store the layout of the image.
  ///
  ///             This just is bookkeeping on the CPU, to actually set the
  ///             layout use `SetLayout`.
  ///
  /// @param[in]  layout  The new layout.
  ///
  /// @return     The old layout.
  ///
  vk::ImageLayout SetLayoutWithoutEncoding(vk::ImageLayout layout) const;

  //----------------------------------------------------------------------------
  /// @brief      Get the last layout assigned to the TextureSourceVK.
  ///
  ///             This value is synchronized with the GPU via SetLayout so it
  ///             may not reflect the actual layout.
  ///
  /// @return     The last known layout of the texture source.
  ///
  vk::ImageLayout GetLayout() const;

  //----------------------------------------------------------------------------
  /// @brief      When sampling from textures whose formats are not known to
  ///             Vulkan, a custom conversion is necessary to setup custom
  ///             samplers. This accessor provides this conversion if one is
  ///             present. Most texture source have none.
  ///
  /// @return     The sampler conversion.
  ///
  virtual std::shared_ptr<YUVConversionVK> GetYUVConversion() const;

  //----------------------------------------------------------------------------
  /// @brief      Determines if swapchain image. That is, an image used as the
  ///             root render target.
  ///
  /// @return     Whether or not this is a swapchain image.
  ///
  virtual bool IsSwapchainImage() const = 0;

  // These methods should only be used by render_pass_vk.h

  /// Store the framebuffer and render pass last used to render into the
  /// `(sample_count, mip_level, slice)` subresource of this texture.
  ///
  /// This is only called when this texture is being used as the resolve (or
  /// non-MSAA color) target of a render pass. By construction, the cached
  /// objects are compatible with any future render pass that targets the
  /// same subresource.
  void SetCachedFrameData(const FramebufferAndRenderPass& data,
                          SampleCount sample_count,
                          uint32_t mip_level = 0u,
                          uint32_t slice = 0u);

  /// Retrieve the cached framebuffer and render pass for the given
  /// `(sample_count, mip_level, slice)` subresource.
  ///
  /// An empty `FramebufferAndRenderPass` is returned when no cached entry
  /// exists for that key. Entries are populated lazily on first use and
  /// live for the lifetime of the texture.
  FramebufferAndRenderPass GetCachedFrameData(SampleCount sample_count,
                                              uint32_t mip_level = 0u,
                                              uint32_t slice = 0u) const;

 protected:
  const TextureDescriptor desc_;

  explicit TextureSourceVK(TextureDescriptor desc);

 private:
  struct CachedFrameDataEntry {
    SampleCount sample_count;
    uint32_t mip_level;
    uint32_t slice;
    FramebufferAndRenderPass data;
  };
  // Linear-scanned because N is typically 1 and bounded by
  // `sample_counts * mip_count * layer_count` for the rare textures that
  // are rendered to across many subresources (e.g. a fully populated cube
  // mip chain).
  std::vector<CachedFrameDataEntry> frame_data_;
  mutable vk::ImageLayout layout_ = vk::ImageLayout::eUndefined;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_
