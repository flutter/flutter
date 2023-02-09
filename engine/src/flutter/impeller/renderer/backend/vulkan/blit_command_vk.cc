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

  // transition the source image to transfer source optimal
  TransitionImageLayoutCommandVK transition_source_cmd =
      TransitionImageLayoutCommandVK(source_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferSrcOptimal);
  bool success = transition_source_cmd.Submit(fenced_command_buffer);
  if (!success) {
    VALIDATION_LOG << "Failed to transition source image layout";
    return false;
  }

  // transition the destination image to transfer destination optimal
  TransitionImageLayoutCommandVK transition_dest_cmd =
      TransitionImageLayoutCommandVK(dest_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferDstOptimal);
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

  // transition the source image to transfer source optimal
  TransitionImageLayoutCommandVK transition_source_cmd =
      TransitionImageLayoutCommandVK(source_image, vk::ImageLayout::eUndefined,
                                     vk::ImageLayout::eTransferSrcOptimal);
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
  // TODO(https://github.com/flutter/flutter/issues/120134): Support generating
  // mipmaps on Vulkan.
  IMPELLER_UNIMPLEMENTED;
  return true;
}

// END: BlitGenerateMipmapCommandVK

}  // namespace impeller
