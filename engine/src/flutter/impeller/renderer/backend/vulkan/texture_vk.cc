// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

TextureVK::TextureVK(TextureDescriptor desc,
                     std::weak_ptr<Context> context,
                     std::shared_ptr<TextureSourceVK> source)
    : Texture(desc), context_(std::move(context)), source_(std::move(source)) {}

TextureVK::~TextureVK() = default;

void TextureVK::SetLabel(std::string_view label) {
  auto context = context_.lock();
  if (!context) {
    // The context may have died.
    return;
  }
  ContextVK::Cast(*context).SetDebugName(GetImage(), label);
}

bool TextureVK::OnSetContents(const uint8_t* contents,
                              size_t length,
                              size_t slice) {
  if (!IsValid() || !contents) {
    return false;
  }

  const auto& desc = GetTextureDescriptor();

  // Out of bounds access.
  if (length != desc.GetByteSizeOfBaseMipLevel()) {
    VALIDATION_LOG << "illegal to set contents for invalid size";
    return false;
  }

  return source_->SetContents(desc, contents, length, slice);
}

bool TextureVK::OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                              size_t slice) {
  // Vulkan has no threading restrictions. So we can pass this data along to the
  // client rendering API immediately.
  return OnSetContents(mapping->GetMapping(), mapping->GetSize(), slice);
}

bool TextureVK::IsValid() const {
  return !!source_;
}

ISize TextureVK::GetSize() const {
  return GetTextureDescriptor().size;
}

vk::Image TextureVK::GetImage() const {
  return source_->GetVKImage();
}

vk::ImageView TextureVK::GetImageView() const {
  return source_->GetVKImageView();
}

static constexpr vk::ImageAspectFlags ToImageAspectFlags(
    vk::ImageLayout layout) {
  switch (layout) {
    case vk::ImageLayout::eColorAttachmentOptimal:
    case vk::ImageLayout::eShaderReadOnlyOptimal:
      return vk::ImageAspectFlagBits::eColor;
    case vk::ImageLayout::eDepthAttachmentOptimal:
      return vk::ImageAspectFlagBits::eDepth;
    case vk::ImageLayout::eStencilAttachmentOptimal:
      return vk::ImageAspectFlagBits::eStencil;
    default:
      FML_DLOG(INFO) << "Unknown layout to determine aspect.";
      return vk::ImageAspectFlagBits::eNone;
  }
  FML_UNREACHABLE();
}

vk::ImageLayout TextureVK::GetLayout() const {
  ReaderLock lock(layout_mutex_);
  return layout_;
}

vk::ImageLayout TextureVK::SetLayoutWithoutEncoding(
    vk::ImageLayout layout) const {
  WriterLock lock(layout_mutex_);
  const auto old_layout = layout_;
  layout_ = layout;
  return old_layout;
}

bool TextureVK::SetLayout(vk::ImageLayout new_layout,
                          const vk::CommandBuffer& buffer) const {
  const auto old_layout = SetLayoutWithoutEncoding(new_layout);
  if (new_layout == old_layout) {
    return true;
  }

  vk::ImageMemoryBarrier image_barrier;
  image_barrier.srcAccessMask = vk::AccessFlagBits::eColorAttachmentWrite |
                                vk::AccessFlagBits::eTransferWrite;
  image_barrier.dstAccessMask = vk::AccessFlagBits::eColorAttachmentRead |
                                vk::AccessFlagBits::eShaderRead;
  image_barrier.oldLayout = old_layout;
  image_barrier.newLayout = new_layout;
  image_barrier.image = GetImage();
  image_barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image_barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image_barrier.subresourceRange.aspectMask = ToImageAspectFlags(new_layout);
  image_barrier.subresourceRange.baseMipLevel = 0u;
  image_barrier.subresourceRange.levelCount = GetTextureDescriptor().mip_count;
  image_barrier.subresourceRange.baseArrayLayer = 0u;
  image_barrier.subresourceRange.layerCount = 1u;

  buffer.pipelineBarrier(vk::PipelineStageFlagBits::eAllGraphics,  // src stage
                         vk::PipelineStageFlagBits::eAllGraphics,  // dst stage
                         {},            // dependency flags
                         nullptr,       // memory barriers
                         nullptr,       // buffer barriers
                         image_barrier  // image barriers
  );

  return true;
}

}  // namespace impeller
