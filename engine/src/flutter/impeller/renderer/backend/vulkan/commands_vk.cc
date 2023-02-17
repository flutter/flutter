// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/commands_vk.h"

namespace impeller {

TransitionImageLayoutCommandVK::TransitionImageLayoutCommandVK(
    vk::Image image,
    vk::ImageLayout old_layout,
    vk::ImageLayout new_layout,
    uint32_t mip_levels)
    : image_(image),
      old_layout_(old_layout),
      new_layout_(new_layout),
      mip_levels_(mip_levels) {}

TransitionImageLayoutCommandVK::~TransitionImageLayoutCommandVK() = default;

bool TransitionImageLayoutCommandVK::Submit(
    FencedCommandBufferVK* command_buffer) {
  if (!command_buffer) {
    return false;
  }

  vk::ImageMemoryBarrier barrier =
      vk::ImageMemoryBarrier()
          .setSrcAccessMask(vk::AccessFlagBits::eColorAttachmentWrite |
                            vk::AccessFlagBits::eTransferWrite)
          .setDstAccessMask(vk::AccessFlagBits::eColorAttachmentRead |
                            vk::AccessFlagBits::eShaderRead)
          .setOldLayout(old_layout_)
          .setNewLayout(new_layout_)
          .setSrcQueueFamilyIndex(VK_QUEUE_FAMILY_IGNORED)
          .setDstQueueFamilyIndex(VK_QUEUE_FAMILY_IGNORED)
          .setImage(image_)
          .setSubresourceRange(
              vk::ImageSubresourceRange()
                  .setAspectMask(vk::ImageAspectFlagBits::eColor)
                  .setBaseMipLevel(0)
                  .setLevelCount(mip_levels_)
                  .setBaseArrayLayer(0)
                  .setLayerCount(1));

  vk::PipelineStageFlags src_stage = vk::PipelineStageFlagBits::eAllGraphics;
  vk::PipelineStageFlags dst_stage = vk::PipelineStageFlagBits::eAllGraphics;

  auto transition_cmd = command_buffer->GetSingleUseChild();

  vk::CommandBufferBeginInfo begin_info;
  begin_info.setFlags(vk::CommandBufferUsageFlagBits::eOneTimeSubmit);
  auto res = transition_cmd.begin(begin_info);

  if (res != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to begin command buffer: " << vk::to_string(res);
    return false;
  }

  transition_cmd.pipelineBarrier(src_stage, dst_stage, {}, nullptr, nullptr,
                                 barrier);
  res = transition_cmd.end();
  if (res != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to end command buffer: " << vk::to_string(res);
    return false;
  }

  return true;
}

}  // namespace impeller
