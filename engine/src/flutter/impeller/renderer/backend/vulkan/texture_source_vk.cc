// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_source_vk.h"

#include <algorithm>

namespace impeller {

namespace {

// Whether a cached attachment set is the one a render pass asks for. A
// released attachment never matches: its weak pointer is expired, so a new
// texture at the same address compares unequal.
bool SameAttachments(const FramebufferAttachmentsVK& cached,
                     const FramebufferAttachmentsVK& wanted) {
  if (cached.size() != wanted.size()) {
    return false;
  }
  for (size_t i = 0; i < cached.size(); i++) {
    std::shared_ptr<const TextureSourceVK> source = cached[i].source.lock();
    if (!source || source != wanted[i].source.lock() ||
        cached[i].mip_level != wanted[i].mip_level ||
        cached[i].slice != wanted[i].slice) {
      return false;
    }
  }
  return true;
}

bool AnyReleased(const FramebufferAttachmentsVK& attachments) {
  return std::any_of(attachments.begin(), attachments.end(),
                     [](const FramebufferAttachmentVK& attachment) {
                       return attachment.source.expired();
                     });
}

}  // namespace

TextureSourceVK::TextureSourceVK(TextureDescriptor desc) : desc_(desc) {}

TextureSourceVK::~TextureSourceVK() = default;

const TextureDescriptor& TextureSourceVK::GetTextureDescriptor() const {
  return desc_;
}

std::shared_ptr<YUVConversionVK> TextureSourceVK::GetYUVConversion() const {
  return nullptr;
}

vk::ImageLayout TextureSourceVK::GetLayout() const {
  return layout_;
}

vk::ImageLayout TextureSourceVK::SetLayoutWithoutEncoding(
    vk::ImageLayout layout) const {
  const auto old_layout = layout_;
  layout_ = layout;
  return old_layout;
}

fml::Status TextureSourceVK::SetLayout(const BarrierVK& barrier) const {
  const vk::ImageLayout old_layout =
      SetLayoutWithoutEncoding(barrier.new_layout);
  vk::ImageMemoryBarrier image_barrier;
  image_barrier.srcAccessMask = barrier.src_access;
  image_barrier.dstAccessMask = barrier.dst_access;
  image_barrier.oldLayout = old_layout;
  image_barrier.newLayout = barrier.new_layout;
  image_barrier.image = GetImage();
  image_barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image_barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image_barrier.subresourceRange.aspectMask = ToImageAspectFlags(desc_.format);
  image_barrier.subresourceRange.baseMipLevel = barrier.base_mip_level;
  image_barrier.subresourceRange.levelCount =
      desc_.mip_count - barrier.base_mip_level;
  image_barrier.subresourceRange.baseArrayLayer = 0u;
  image_barrier.subresourceRange.layerCount = ToArrayLayerCount(desc_);

  barrier.cmd_buffer.pipelineBarrier(barrier.src_stage,  // src stage
                                     barrier.dst_stage,  // dst stage
                                     {},                 // dependency flags
                                     nullptr,            // memory barriers
                                     nullptr,            // buffer barriers
                                     image_barrier       // image barriers
  );

  return {};
}

void TextureSourceVK::SetCachedFrameData(
    const FramebufferAndRenderPass& data,
    SampleCount sample_count,
    uint32_t mip_level,
    uint32_t slice,
    const FramebufferAttachmentsVK& attachments) {
  // A framebuffer whose attachment has been released can never be handed out
  // again. The command buffers that used it hold their own references.
  frame_data_.erase(std::remove_if(frame_data_.begin(), frame_data_.end(),
                                   [](const CachedFrameDataEntry& entry) {
                                     return AnyReleased(entry.attachments);
                                   }),
                    frame_data_.end());
  for (auto& entry : frame_data_) {
    if (entry.sample_count == sample_count && entry.mip_level == mip_level &&
        entry.slice == slice &&
        SameAttachments(entry.attachments, attachments)) {
      entry.data = data;
      return;
    }
  }
  frame_data_.push_back({sample_count, mip_level, slice, attachments, data});
}

FramebufferAndRenderPass TextureSourceVK::GetCachedFrameData(
    SampleCount sample_count,
    uint32_t mip_level,
    uint32_t slice,
    const FramebufferAttachmentsVK& attachments) const {
  for (const auto& entry : frame_data_) {
    if (entry.sample_count == sample_count && entry.mip_level == mip_level &&
        entry.slice == slice &&
        SameAttachments(entry.attachments, attachments)) {
      return entry.data;
    }
  }
  return {};
}

size_t TextureSourceVK::GetCachedFrameDataCountForTesting() const {
  return frame_data_.size();
}

}  // namespace impeller
