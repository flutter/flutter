// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_TEXTURE_SOURCE_VK_H_

#include <array>
#include <cstdint>
#include <memory>
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

class TextureSourceVK;

/// One image view a framebuffer holds: the texture source it was made from
/// and the subresource it views.
///
/// The source is held weakly. A cached framebuffer must not keep its
/// attachments alive, and an attachment that has been released must never
/// match again, even when a new texture is later allocated at the same
/// address.
struct FramebufferAttachmentVK {
  std::weak_ptr<const TextureSourceVK> source;
  uint32_t mip_level = 0u;
  uint32_t slice = 0u;
};

/// The image views of a framebuffer, in attachment order.
///
/// Fixed capacity, like the image view array a framebuffer is created from,
/// so that the key a render pass looks the cache up with is built without
/// allocating.
struct FramebufferAttachmentsVK {
  std::array<FramebufferAttachmentVK, kMaxAttachments> attachments;
  size_t count = 0u;

  /// Whether both name the same subresources of the same textures.
  ///
  /// Textures are compared by ownership, not by address, and without locking
  /// the weak pointers. A set built from live textures never matches one that
  /// names a texture released since: a texture allocated later has its own
  /// control block, even at the same address.
  bool IsSameAs(const FramebufferAttachmentsVK& other) const;

  /// Whether any of the textures has been released.
  bool AnyReleased() const;
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

  /// Store the framebuffer and render pass used to render into the
  /// `(sample_count, mip_level, slice)` subresource of this texture with the
  /// given attachments.
  ///
  /// This is only called when this texture is being used as the resolve (or
  /// non-MSAA color) target of a render pass, and only when the framebuffer
  /// was just created for a cache miss.
  ///
  /// [attachments] lists every image view the framebuffer holds. A cache keyed
  /// on this texture alone hands back a framebuffer referring to somebody
  /// else's depth (or multisample color) texture: valid while that texture
  /// lives, and a dangling view once it does not.
  ///
  /// Entries whose attachments have since been released are dropped before a
  /// new one is added, so a texture paired with a stream of transient depth
  /// textures does not accumulate framebuffers.
  void SetCachedFrameData(const FramebufferAndRenderPass& data,
                          SampleCount sample_count,
                          uint32_t mip_level,
                          uint32_t slice,
                          const FramebufferAttachmentsVK& attachments);

  /// Retrieve the cached framebuffer and render pass for the given
  /// `(sample_count, mip_level, slice)` subresource and attachment set.
  ///
  /// An empty `FramebufferAndRenderPass` is returned when no cached entry
  /// exists for that key. Entries are populated lazily on first use and
  /// live until this texture or one of their attachments is released.
  FramebufferAndRenderPass GetCachedFrameData(
      SampleCount sample_count,
      uint32_t mip_level,
      uint32_t slice,
      const FramebufferAttachmentsVK& attachments) const;

  /// Retrieve a cached render pass for the `(sample_count, mip_level, slice)`
  /// subresource whose framebuffer had `attachment_count` attachments, or null
  /// if there is none.
  ///
  /// The attachment textures are not compared: a render pass only depends on
  /// their formats and sample counts, which are taken to be the same for
  /// every render pass that targets this subresource. A cache miss caused by
  /// a different depth or multisample texture therefore needs a new
  /// framebuffer, but not a new render pass.
  SharedHandleVK<vk::RenderPass> GetCachedRenderPass(
      SampleCount sample_count,
      uint32_t mip_level,
      uint32_t slice,
      size_t attachment_count) const;

  /// The number of cached framebuffers, for tests.
  size_t GetCachedFrameDataCountForTesting() const;

 protected:
  const TextureDescriptor desc_;

  explicit TextureSourceVK(TextureDescriptor desc);

 private:
  // `sample_count`, `mip_level` and `slice` are those of the first attachment,
  // and are kept beside it because they, without the attachment identities,
  // are what decides whether the render pass can be shared.
  struct CachedFrameDataEntry {
    SampleCount sample_count;
    uint32_t mip_level;
    uint32_t slice;
    FramebufferAttachmentsVK attachments;
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
