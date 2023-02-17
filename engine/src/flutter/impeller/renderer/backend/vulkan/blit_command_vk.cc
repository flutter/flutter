// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/blit_command_vk.h"

#include "impeller/renderer/backend/vulkan/commands_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

BlitEncodeVK::~BlitEncodeVK() = default;

//------------------------------------------------------------------------------
/// BlitCopyTextureToTextureCommandVK
///

BlitCopyTextureToTextureCommandVK::~BlitCopyTextureToTextureCommandVK() =
    default;

std::string BlitCopyTextureToTextureCommandVK::GetLabel() const {
  return label;
}

[[nodiscard]] bool BlitCopyTextureToTextureCommandVK::Encode(
    FencedCommandBufferVK* fenced_command_buffer) const {
  // cast source and destination to TextureVK
  const auto& source_tex_vk = TextureVK::Cast(*source);
  const auto& dest_tex_vk = TextureVK::Cast(*destination);

  // get the vulkan image and image view
  const auto source_image = source_tex_vk.GetImage();
  const auto dest_image = dest_tex_vk.GetImage();

  // copy the source image to the destination image, from source_region to
  // destination_origin.
  vk::ImageCopy image_copy;
  image_copy.setSrcSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setDstSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));

  image_copy.srcOffset =
      vk::Offset3D(source_region.origin.x, source_region.origin.y, 0);
  image_copy.dstOffset =
      vk::Offset3D(destination_origin.x, destination_origin.y, 0);
  image_copy.extent =
      vk::Extent3D(source_region.size.width, source_region.size.height, 1);

  // get single use command buffer
  auto copy_cmd = fenced_command_buffer->GetSingleUseChild();

  vk::CommandBufferBeginInfo begin_info;
  begin_info.setFlags(vk::CommandBufferUsageFlagBits::eOneTimeSubmit);
  auto res = copy_cmd.begin(begin_info);

  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to begin command buffer: " << vk::to_string(res);
    return false;
  }

  uint32_t mip_count = source_tex_vk.GetTextureDescriptor().mip_count;

  // transition the source image to transfer source optimal
  TransitionImageLayoutCommandVK transition_source_cmd =
      TransitionImageLayoutCommandVK(source_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferSrcOptimal,
                                     mip_count);
  bool success = transition_source_cmd.Submit(fenced_command_buffer);
  if (!success) {
    VALIDATION_LOG << "Failed to transition source image layout";
    return false;
  }

  // transition the destination image to transfer destination optimal
  TransitionImageLayoutCommandVK transition_dest_cmd =
      TransitionImageLayoutCommandVK(dest_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferDstOptimal,
                                     mip_count);
  success = transition_dest_cmd.Submit(fenced_command_buffer);
  if (!success) {
    VALIDATION_LOG << "Failed to transition destination image layout";
    return false;
  }

  // issue the copy command
  copy_cmd.copyImage(source_image, vk::ImageLayout::eTransferSrcOptimal,
                     dest_image, vk::ImageLayout::eTransferDstOptimal,
                     image_copy);
  res = copy_cmd.end();
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(res);
    return false;
  }

  return true;
}

//------------------------------------------------------------------------------
/// BlitCopyTextureToBufferCommandVK
///

BlitCopyTextureToBufferCommandVK::~BlitCopyTextureToBufferCommandVK() = default;

std::string BlitCopyTextureToBufferCommandVK::GetLabel() const {
  return label;
}

[[nodiscard]] bool BlitCopyTextureToBufferCommandVK::Encode(
    FencedCommandBufferVK* fenced_command_buffer) const {
  // cast source and destination to TextureVK
  const auto& source_tex_vk = TextureVK::Cast(*source);
  const auto& dest_buf_vk = DeviceBufferVK::Cast(*destination);

  // get the vulkan image and image view
  const auto source_image = source_tex_vk.GetImage();

  // get buffer image handle
  const auto dest_buffer = dest_buf_vk.GetVKBufferHandle();

  // copy the source image to the destination buffer, from source_region to
  // destination_origin.
  vk::BufferImageCopy image_copy{};
  image_copy.setBufferOffset(destination_offset);
  image_copy.setBufferRowLength(0);
  image_copy.setBufferImageHeight(0);
  image_copy.setImageSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setImageOffset(
      vk::Offset3D(source_region.origin.x, source_region.origin.y, 0));
  image_copy.setImageExtent(
      vk::Extent3D(source_region.size.width, source_region.size.height, 1));

  uint32_t mip_count = source_tex_vk.GetTextureDescriptor().mip_count;

  // transition the source image to transfer source optimal
  TransitionImageLayoutCommandVK transition_source_cmd =
      TransitionImageLayoutCommandVK(source_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferSrcOptimal,
                                     mip_count);
  bool success = transition_source_cmd.Submit(fenced_command_buffer);
  if (!success) {
    return false;
  }

  // get single use command buffer
  auto copy_cmd = fenced_command_buffer->GetSingleUseChild();

  vk::CommandBufferBeginInfo begin_info;
  begin_info.setFlags(vk::CommandBufferUsageFlagBits::eOneTimeSubmit);
  auto res = copy_cmd.begin(begin_info);

  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to begin command buffer: " << vk::to_string(res);
    return false;
  }

  // issue the copy command
  copy_cmd.copyImageToBuffer(source_image, vk::ImageLayout::eTransferSrcOptimal,
                             dest_buffer, image_copy);
  res = copy_cmd.end();
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(res);
  }

  return true;
}

//------------------------------------------------------------------------------
/// BlitGenerateMipmapCommandVK
///

BlitGenerateMipmapCommandVK::~BlitGenerateMipmapCommandVK() = default;

std::string BlitGenerateMipmapCommandVK::GetLabel() const {
  return label;
}

[[nodiscard]] bool BlitGenerateMipmapCommandVK::Encode(
    FencedCommandBufferVK* fenced_command_buffer) const {
  const auto& source_tex_vk = TextureVK::Cast(*texture);
  const auto source_image = source_tex_vk.GetImage();

  const auto size = source_tex_vk.GetTextureDescriptor().size;
  uint32_t mip_count = source_tex_vk.GetTextureDescriptor().mip_count;

  uint32_t mip_width = size.width;
  uint32_t mip_height = size.height;

  // create the subresource range
  vk::ImageSubresourceRange subresource_range{};
  subresource_range.setAspectMask(vk::ImageAspectFlagBits::eColor);
  subresource_range.setBaseArrayLayer(0);
  subresource_range.setLayerCount(1);
  subresource_range.setLevelCount(1);

  // create a barrier to transition the image to transfer source optimal
  vk::ImageMemoryBarrier barrier{};
  barrier.setImage(source_image);
  barrier.setSrcQueueFamilyIndex(VK_QUEUE_FAMILY_IGNORED);
  barrier.setDstQueueFamilyIndex(VK_QUEUE_FAMILY_IGNORED);
  barrier.setSubresourceRange(subresource_range);

  auto gen_mip_cmd = fenced_command_buffer->Get();

  vk::CommandBufferBeginInfo begin_info;
  begin_info.setFlags(vk::CommandBufferUsageFlagBits::eOneTimeSubmit);
  auto begin_res = gen_mip_cmd.begin(begin_info);

  if (begin_res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to begin command buffer: "
                   << vk::to_string(begin_res);
    return false;
  }

  // transition all layers to transfer dst optimal
  for (uint32_t i = 0; i < mip_count; i++) {
    barrier.subresourceRange.baseMipLevel = i;
    barrier.oldLayout = vk::ImageLayout::eUndefined;
    barrier.newLayout = vk::ImageLayout::eTransferDstOptimal;
    barrier.srcAccessMask = vk::AccessFlagBits::eTransferWrite;
    barrier.dstAccessMask = vk::AccessFlagBits::eTransferWrite;

    gen_mip_cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                                vk::PipelineStageFlagBits::eTransfer, {},
                                nullptr, nullptr, barrier);
  }

  for (uint32_t i = 1; i < mip_count; i++) {
    barrier.subresourceRange.baseMipLevel = i - 1;
    barrier.oldLayout = vk::ImageLayout::eTransferDstOptimal;
    barrier.newLayout = vk::ImageLayout::eTransferSrcOptimal;
    barrier.srcAccessMask = vk::AccessFlagBits::eTransferWrite;
    barrier.dstAccessMask = vk::AccessFlagBits::eTransferRead;

    gen_mip_cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                                vk::PipelineStageFlagBits::eTransfer, {},
                                nullptr, nullptr, barrier);

    vk::ImageBlit blit{};

    // src
    blit.srcOffsets[0] = vk::Offset3D(0, 0, 0);
    blit.srcOffsets[1] = vk::Offset3D(mip_width, mip_height, 1);
    blit.srcSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.srcSubresource.mipLevel = i - 1;
    blit.srcSubresource.baseArrayLayer = 0;
    blit.srcSubresource.layerCount = 1;

    // dst
    blit.dstOffsets[0] = vk::Offset3D(0, 0, 0);
    blit.dstOffsets[1] = vk::Offset3D(mip_width > 1 ? mip_width / 2 : 1,
                                      mip_height > 1 ? mip_height / 2 : 1, 1);
    blit.dstSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.dstSubresource.mipLevel = i;
    blit.dstSubresource.baseArrayLayer = 0;
    blit.dstSubresource.layerCount = 1;

    gen_mip_cmd.blitImage(source_image, vk::ImageLayout::eTransferSrcOptimal,
                          source_image, vk::ImageLayout::eTransferDstOptimal,
                          blit, vk::Filter::eLinear);

    // transition the previous mip level to shader read only optimal
    barrier.oldLayout = vk::ImageLayout::eUndefined;
    barrier.newLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
    barrier.srcAccessMask = vk::AccessFlagBits::eTransferRead;
    barrier.dstAccessMask = vk::AccessFlagBits::eShaderRead;

    gen_mip_cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                                vk::PipelineStageFlagBits::eFragmentShader, {},
                                nullptr, nullptr, barrier);

    if (mip_width > 1) {
      mip_width /= 2;
    }

    if (mip_height > 1) {
      mip_height /= 2;
    }
  }

  // transition the last mip level to shader read only optimal
  barrier.subresourceRange.baseMipLevel = mip_count - 1;
  barrier.oldLayout = vk::ImageLayout::eUndefined;
  barrier.newLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
  barrier.srcAccessMask = vk::AccessFlagBits::eTransferRead;
  barrier.dstAccessMask = vk::AccessFlagBits::eShaderRead;

  gen_mip_cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                              vk::PipelineStageFlagBits::eFragmentShader, {},
                              nullptr, nullptr, barrier);

  // submit the command buffer
  auto res = gen_mip_cmd.end();
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(res);
    return false;
  }

  return true;
}

// END: BlitGenerateMipmapCommandVK

}  // namespace impeller
