// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/blit_command_vk.h"

#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
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

bool BlitCopyTextureToTextureCommandVK::Encode(
    CommandEncoderVK& encoder) const {
  const auto& cmd_buffer = encoder.GetCommandBuffer();

  const auto& src = TextureVK::Cast(*source);
  const auto& dst = TextureVK::Cast(*destination);

  if (!encoder.Track(source) || !encoder.Track(destination)) {
    return false;
  }

  LayoutTransition src_tran;
  src_tran.cmd_buffer = cmd_buffer;
  src_tran.new_layout = vk::ImageLayout::eTransferSrcOptimal;
  src_tran.src_access = vk::AccessFlagBits::eTransferWrite |
                        vk::AccessFlagBits::eShaderWrite |
                        vk::AccessFlagBits::eColorAttachmentWrite;
  src_tran.src_stage = vk::PipelineStageFlagBits::eTransfer |
                       vk::PipelineStageFlagBits::eFragmentShader |
                       vk::PipelineStageFlagBits::eColorAttachmentOutput;
  src_tran.dst_access = vk::AccessFlagBits::eTransferRead;
  src_tran.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  LayoutTransition dst_tran;
  dst_tran.cmd_buffer = cmd_buffer;
  dst_tran.new_layout = vk::ImageLayout::eTransferDstOptimal;
  dst_tran.src_access = {};
  dst_tran.src_stage = vk::PipelineStageFlagBits::eTopOfPipe;
  dst_tran.dst_access = vk::AccessFlagBits::eShaderRead;
  dst_tran.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

  if (!src.SetLayout(src_tran) || !dst.SetLayout(dst_tran)) {
    VALIDATION_LOG << "Could not complete layout transitions.";
    return false;
  }

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

  // Issue the copy command now that the images are already in the right
  // layouts.
  cmd_buffer.copyImage(src.GetImage(),       //
                       src_tran.new_layout,  //
                       dst.GetImage(),       //
                       dst_tran.new_layout,  //
                       image_copy            //
  );

  return true;
}

//------------------------------------------------------------------------------
/// BlitCopyTextureToBufferCommandVK
///

BlitCopyTextureToBufferCommandVK::~BlitCopyTextureToBufferCommandVK() = default;

std::string BlitCopyTextureToBufferCommandVK::GetLabel() const {
  return label;
}

bool BlitCopyTextureToBufferCommandVK::Encode(CommandEncoderVK& encoder) const {
  const auto& cmd_buffer = encoder.GetCommandBuffer();

  // cast source and destination to TextureVK
  const auto& src = TextureVK::Cast(*source);

  if (!encoder.Track(source) || !encoder.Track(destination)) {
    return false;
  }

  LayoutTransition transition;
  transition.cmd_buffer = cmd_buffer;
  transition.new_layout = vk::ImageLayout::eTransferSrcOptimal;
  transition.src_access = vk::AccessFlagBits::eShaderWrite |
                          vk::AccessFlagBits::eTransferWrite |
                          vk::AccessFlagBits::eColorAttachmentWrite;
  transition.src_stage = vk::PipelineStageFlagBits::eFragmentShader |
                         vk::PipelineStageFlagBits::eTransfer |
                         vk::PipelineStageFlagBits::eColorAttachmentOutput;
  transition.dst_access = vk::AccessFlagBits::eShaderRead;
  transition.dst_stage = vk::PipelineStageFlagBits::eVertexShader |
                         vk::PipelineStageFlagBits::eFragmentShader;

  const auto& dst = DeviceBufferVK::Cast(*destination);

  vk::BufferImageCopy image_copy;
  image_copy.setBufferOffset(destination_offset);
  image_copy.setBufferRowLength(0);
  image_copy.setBufferImageHeight(0);
  image_copy.setImageSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setImageOffset(
      vk::Offset3D(source_region.origin.x, source_region.origin.y, 0));
  image_copy.setImageExtent(
      vk::Extent3D(source_region.size.width, source_region.size.height, 1));

  if (!src.SetLayout(transition)) {
    VALIDATION_LOG << "Could not encode layout transition.";
    return false;
  }

  cmd_buffer.copyImageToBuffer(src.GetImage(),         //
                               transition.new_layout,  //
                               dst.GetBuffer(),        //
                               image_copy              //
  );

  return true;
}

//------------------------------------------------------------------------------
/// BlitCopyBufferToTextureCommandVK
///

BlitCopyBufferToTextureCommandVK::~BlitCopyBufferToTextureCommandVK() = default;

std::string BlitCopyBufferToTextureCommandVK::GetLabel() const {
  return label;
}

bool BlitCopyBufferToTextureCommandVK::Encode(CommandEncoderVK& encoder) const {
  const auto& cmd_buffer = encoder.GetCommandBuffer();

  // cast destination to TextureVK
  const auto& dst = TextureVK::Cast(*destination);
  const auto& src = DeviceBufferVK::Cast(*source.buffer);

  if (!encoder.Track(source.buffer) || !encoder.Track(destination)) {
    return false;
  }

  LayoutTransition dst_tran;
  dst_tran.cmd_buffer = cmd_buffer;
  dst_tran.new_layout = vk::ImageLayout::eTransferDstOptimal;
  dst_tran.src_access = {};
  dst_tran.src_stage = vk::PipelineStageFlagBits::eTopOfPipe;
  dst_tran.dst_access =
      vk::AccessFlagBits::eShaderRead | vk::AccessFlagBits::eTransferWrite;
  dst_tran.dst_stage = vk::PipelineStageFlagBits::eFragmentShader |
                       vk::PipelineStageFlagBits::eTransfer;

  vk::BufferImageCopy image_copy;
  image_copy.setBufferOffset(source.range.offset);
  image_copy.setBufferRowLength(0);
  image_copy.setBufferImageHeight(0);
  image_copy.setImageSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setImageOffset(
      vk::Offset3D(destination_origin.x, destination_origin.y, 0));
  image_copy.setImageExtent(vk::Extent3D(destination->GetSize().width,
                                         destination->GetSize().height, 1));

  if (!dst.SetLayout(dst_tran)) {
    VALIDATION_LOG << "Could not encode layout transition.";
    return false;
  }

  cmd_buffer.copyBufferToImage(src.GetBuffer(),      //
                               dst.GetImage(),       //
                               dst_tran.new_layout,  //
                               image_copy            //
  );

  return true;
}

//------------------------------------------------------------------------------
/// BlitGenerateMipmapCommandVK
///

BlitGenerateMipmapCommandVK::~BlitGenerateMipmapCommandVK() = default;

std::string BlitGenerateMipmapCommandVK::GetLabel() const {
  return label;
}

static void InsertImageMemoryBarrier(const vk::CommandBuffer& cmd,
                                     const vk::Image& image,
                                     vk::AccessFlags src_access_mask,
                                     vk::AccessFlags dst_access_mask,
                                     vk::ImageLayout old_layout,
                                     vk::ImageLayout new_layout,
                                     vk::PipelineStageFlags src_stage,
                                     vk::PipelineStageFlags dst_stage,
                                     uint32_t base_mip_level,
                                     uint32_t mip_level_count = 1u) {
  if (old_layout == new_layout) {
    return;
  }

  vk::ImageMemoryBarrier barrier;
  barrier.srcAccessMask = src_access_mask;
  barrier.dstAccessMask = dst_access_mask;
  barrier.oldLayout = old_layout;
  barrier.newLayout = new_layout;
  barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.image = image;
  barrier.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  barrier.subresourceRange.baseMipLevel = base_mip_level;
  barrier.subresourceRange.levelCount = mip_level_count;
  barrier.subresourceRange.baseArrayLayer = 0u;
  barrier.subresourceRange.layerCount = 1u;

  cmd.pipelineBarrier(src_stage, dst_stage, {}, nullptr, nullptr, barrier);
}

bool BlitGenerateMipmapCommandVK::Encode(CommandEncoderVK& encoder) const {
  auto& src = TextureVK::Cast(*texture);

  const auto size = src.GetTextureDescriptor().size;
  uint32_t mip_count = src.GetTextureDescriptor().mip_count;

  if (mip_count < 2u) {
    return true;
  }

  const auto& image = src.GetImage();
  const auto& cmd = encoder.GetCommandBuffer();

  if (!encoder.Track(texture)) {
    return false;
  }

  // Transition the base mip level to transfer-src layout so we can read from
  // it and transition the rest to dst-optimal since they are going to be
  // written to.
  InsertImageMemoryBarrier(
      cmd,                                   // command buffer
      image,                                 // image
      vk::AccessFlagBits::eTransferWrite,    // src access mask
      vk::AccessFlagBits::eTransferRead,     // dst access mask
      src.GetLayout(),                       // old layout
      vk::ImageLayout::eTransferSrcOptimal,  // new layout
      vk::PipelineStageFlagBits::eTransfer,  // src stage
      vk::PipelineStageFlagBits::eTransfer,  // dst stage
      0u                                     // mip level
  );
  InsertImageMemoryBarrier(
      cmd,                                   // command buffer
      image,                                 // image
      {},                                    // src access mask
      vk::AccessFlagBits::eTransferWrite,    // dst access mask
      vk::ImageLayout::eUndefined,           // old layout
      vk::ImageLayout::eTransferDstOptimal,  // new layout
      vk::PipelineStageFlagBits::eTransfer,  // src stage
      vk::PipelineStageFlagBits::eTransfer,  // dst stage
      1u,                                    // mip level
      mip_count - 1                          // mip level count
  );

  // Blit from the base mip level to all other levels.
  for (size_t mip_level = 1u; mip_level < mip_count; mip_level++) {
    vk::ImageBlit blit;

    blit.srcSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.srcSubresource.baseArrayLayer = 0u;
    blit.srcSubresource.layerCount = 1u;
    blit.srcSubresource.mipLevel = 0u;

    blit.dstSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.dstSubresource.baseArrayLayer = 0u;
    blit.dstSubresource.layerCount = 1u;
    blit.dstSubresource.mipLevel = mip_level;

    // offsets[0] is origin.
    blit.srcOffsets[1].x = size.width;
    blit.srcOffsets[1].y = size.height;
    blit.srcOffsets[1].z = 1u;

    // offsets[0] is origin.
    blit.dstOffsets[1].x = std::max<int32_t>(size.width >> mip_level, 1u);
    blit.dstOffsets[1].y = std::max<int32_t>(size.height >> mip_level, 1u);
    blit.dstOffsets[1].z = 1u;

    cmd.blitImage(image,                                 // src image
                  vk::ImageLayout::eTransferSrcOptimal,  // src layout
                  image,                                 // dst image
                  vk::ImageLayout::eTransferDstOptimal,  // dst layout
                  1u,                                    // region count
                  &blit,                                 // regions
                  vk::Filter::eLinear                    // filter
    );
  }

  // Transition all mip levels to shader read. The base mip level has a
  // different "old" layout than the rest now.
  InsertImageMemoryBarrier(
      cmd,                                         // command buffer
      image,                                       // image
      vk::AccessFlagBits::eTransferWrite,          // src access mask
      vk::AccessFlagBits::eShaderRead,             // dst access mask
      vk::ImageLayout::eTransferSrcOptimal,        // old layout
      vk::ImageLayout::eShaderReadOnlyOptimal,     // new layout
      vk::PipelineStageFlagBits::eTransfer,        // src stage
      vk::PipelineStageFlagBits::eFragmentShader,  // dst stage
      0u                                           // mip level
  );
  InsertImageMemoryBarrier(
      cmd,                                         // command buffer
      image,                                       // image
      vk::AccessFlagBits::eTransferWrite,          // src access mask
      vk::AccessFlagBits::eShaderRead,             // dst access mask
      vk::ImageLayout::eTransferDstOptimal,        // old layout
      vk::ImageLayout::eShaderReadOnlyOptimal,     // new layout
      vk::PipelineStageFlagBits::eTransfer,        // src stage
      vk::PipelineStageFlagBits::eFragmentShader,  // dst stage
      1u,                                          // mip level
      mip_count - 1                                // mip level count
  );

  // We modified the layouts of this image from underneath it. Tell it its new
  // state so it doesn't try to perform redundant transitions under the hood.
  src.SetLayoutWithoutEncoding(vk::ImageLayout::eShaderReadOnlyOptimal);

  return true;
}

}  // namespace impeller
