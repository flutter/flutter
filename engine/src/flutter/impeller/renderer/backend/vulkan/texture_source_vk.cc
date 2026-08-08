// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_source_vk.h"

#include <algorithm>

namespace impeller {

TextureSourceVK::TextureSourceVK(TextureDescriptor desc) : desc_(desc) {
  const uint32_t subresource_count =
      std::max<uint32_t>(desc_.mip_count, 1u) * LayerCount();
  layouts_.resize(subresource_count, vk::ImageLayout::eUndefined);
}

TextureSourceVK::~TextureSourceVK() = default;

const TextureDescriptor& TextureSourceVK::GetTextureDescriptor() const {
  return desc_;
}

std::shared_ptr<YUVConversionVK> TextureSourceVK::GetYUVConversion() const {
  return nullptr;
}

uint32_t TextureSourceVK::LayerCount() const {
  return ToArrayLayerCount(desc_);
}

vk::ImageLayout TextureSourceVK::GetLayout(uint32_t mip_level,
                                           uint32_t array_layer) const {
  const size_t index =
      static_cast<size_t>(mip_level) * LayerCount() + array_layer;
  return index < layouts_.size() ? layouts_[index]
                                 : vk::ImageLayout::eUndefined;
}

vk::ImageLayout TextureSourceVK::SetLayoutWithoutEncoding(
    vk::ImageLayout layout,
    uint32_t base_mip_level,
    uint32_t level_count,
    uint32_t base_array_layer,
    uint32_t layer_count) const {
  const uint32_t layers = LayerCount();
  const uint32_t mip_count = std::max<uint32_t>(desc_.mip_count, 1u);
  if (level_count == 0u) {
    level_count = mip_count - base_mip_level;
  }
  if (layer_count == 0u) {
    layer_count = layers - base_array_layer;
  }
  const vk::ImageLayout old_layout =
      GetLayout(base_mip_level, base_array_layer);
  for (uint32_t mip = base_mip_level; mip < base_mip_level + level_count;
       mip++) {
    for (uint32_t layer = base_array_layer;
         layer < base_array_layer + layer_count; layer++) {
      const size_t index = static_cast<size_t>(mip) * layers + layer;
      if (index < layouts_.size()) {
        layouts_[index] = layout;
      }
    }
  }
  return old_layout;
}

fml::Status TextureSourceVK::SetLayout(const BarrierVK& barrier) const {
  const uint32_t mip_count = std::max<uint32_t>(desc_.mip_count, 1u);
  const uint32_t layers = LayerCount();
  const uint32_t level_count = barrier.mip_level_count == 0u
                                   ? mip_count - barrier.base_mip_level
                                   : barrier.mip_level_count;
  const uint32_t layer_count = barrier.array_layer_count == 0u
                                   ? layers - barrier.base_array_layer
                                   : barrier.array_layer_count;
  // Records the new layout for the whole targeted range and returns the old
  // layout of the first subresource. Callers transition ranges that share one
  // layout (a single subresource, or a freshly created/uniform image), so one
  // barrier with that old layout is correct.
  const vk::ImageLayout old_layout = SetLayoutWithoutEncoding(
      barrier.new_layout, barrier.base_mip_level, level_count,
      barrier.base_array_layer, layer_count);
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
  image_barrier.subresourceRange.levelCount = level_count;
  image_barrier.subresourceRange.baseArrayLayer = barrier.base_array_layer;
  image_barrier.subresourceRange.layerCount = layer_count;

  barrier.cmd_buffer.pipelineBarrier(barrier.src_stage,  // src stage
                                     barrier.dst_stage,  // dst stage
                                     {},                 // dependency flags
                                     nullptr,            // memory barriers
                                     nullptr,            // buffer barriers
                                     image_barrier       // image barriers
  );

  return {};
}

void TextureSourceVK::SetCachedFrameData(const FramebufferAndRenderPass& data,
                                         SampleCount sample_count,
                                         uint32_t mip_level,
                                         uint32_t slice) {
  for (auto& entry : frame_data_) {
    if (entry.sample_count == sample_count && entry.mip_level == mip_level &&
        entry.slice == slice) {
      entry.data = data;
      return;
    }
  }
  frame_data_.push_back({sample_count, mip_level, slice, data});
}

FramebufferAndRenderPass TextureSourceVK::GetCachedFrameData(
    SampleCount sample_count,
    uint32_t mip_level,
    uint32_t slice) const {
  for (const auto& entry : frame_data_) {
    if (entry.sample_count == sample_count && entry.mip_level == mip_level &&
        entry.slice == slice) {
      return entry.data;
    }
  }
  return {};
}

}  // namespace impeller
