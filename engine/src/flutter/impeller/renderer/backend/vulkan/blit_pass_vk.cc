// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/blit_pass_vk.h"

#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/barrier_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "vulkan/vulkan_core.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

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

BlitPassVK::BlitPassVK(std::shared_ptr<CommandBufferVK> command_buffer,
                       std::shared_ptr<Allocator> allocator,
                       const WorkaroundsVK& workarounds)
    : command_buffer_(std::move(command_buffer)),
      allocator_(std::move(allocator)),
      workarounds_(workarounds) {}

BlitPassVK::~BlitPassVK() = default;

void BlitPassVK::OnSetLabel(std::string_view label) {}

// |BlitPass|
bool BlitPassVK::IsValid() const {
  return true;
}

// |BlitPass|
bool BlitPassVK::EncodeCommands() const {
  return true;
}

// |BlitPass|
bool BlitPassVK::OnCopyTextureToTextureCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<Texture> destination,
    IRect source_region,
    IPoint destination_origin,
    std::string_view label) {
  const auto& cmd_buffer = command_buffer_->GetCommandBuffer();

  const auto& src = TextureVK::Cast(*source);
  const auto& dst = TextureVK::Cast(*destination);

  if (!command_buffer_->Track(source) || !command_buffer_->Track(destination)) {
    return false;
  }

  BarrierVK src_barrier;
  src_barrier.cmd_buffer = cmd_buffer;
  src_barrier.new_layout = vk::ImageLayout::eTransferSrcOptimal;
  src_barrier.src_access = vk::AccessFlagBits::eTransferWrite |
                           vk::AccessFlagBits::eShaderWrite |
                           vk::AccessFlagBits::eColorAttachmentWrite;
  src_barrier.src_stage = vk::PipelineStageFlagBits::eTransfer |
                          vk::PipelineStageFlagBits::eFragmentShader |
                          vk::PipelineStageFlagBits::eColorAttachmentOutput;
  src_barrier.dst_access = vk::AccessFlagBits::eTransferRead;
  src_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  BarrierVK dst_barrier;
  dst_barrier.cmd_buffer = cmd_buffer;
  dst_barrier.new_layout = vk::ImageLayout::eTransferDstOptimal;
  // Wait for any prior buffer-to-image transfer writes to this destination
  // before starting the image-to-image copy. In the atlas growth path,
  // BulkUpdateAtlasBitmap writes rows 0..new_height via
  // vkCmdCopyBufferToImage, then AddCopy(old->new) writes rows 0..old_height
  // via vkCmdCopyImage. These writes overlap in rows 0..old_height. Without
  // this barrier, the post-copy eTransfer->eFragmentShader barrier from
  // BulkUpdateAtlasBitmap does NOT create a transitive dependency here because
  // eTopOfPipe & eFragmentShader = empty - leaving a WAW hazard on AMD RDNA.
  dst_barrier.src_access = vk::AccessFlagBits::eTransferWrite;
  dst_barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  // dstAccessMask must only list accesses valid for TRANSFER_DST_OPTIMAL.
  // eShaderRead is not permitted in that layout; including it triggers AMD
  // best practices validation layer message ID -212008545 (0xF35D019F).
  dst_barrier.dst_access = vk::AccessFlagBits::eTransferWrite;
  dst_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  if (!src.SetLayout(src_barrier) || !dst.SetLayout(dst_barrier)) {
    VALIDATION_LOG << "Could not complete layout transitions.";
    return false;
  }

  vk::ImageCopy image_copy;

  image_copy.setSrcSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setDstSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));

  image_copy.srcOffset =
      vk::Offset3D(source_region.GetX(), source_region.GetY(), 0);
  image_copy.dstOffset =
      vk::Offset3D(destination_origin.x, destination_origin.y, 0);
  image_copy.extent =
      vk::Extent3D(source_region.GetWidth(), source_region.GetHeight(), 1);

  // Issue the copy command now that the images are already in the right
  // layouts.
  cmd_buffer.copyImage(src.GetImage(),          //
                       src_barrier.new_layout,  //
                       dst.GetImage(),          //
                       dst_barrier.new_layout,  //
                       image_copy               //
  );

  // If this is an onscreen texture, do not transition the layout
  // back to shader read.
  if (dst.IsSwapchainImage()) {
    return true;
  }

  BarrierVK barrier;
  barrier.cmd_buffer = cmd_buffer;
  barrier.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;
  // Flush the transfer write cache so that subsequent shader reads see the
  // newly copied data. TOP_OF_PIPE with empty src_access does not flush the
  // transfer write cache on AMD RDNA, leaving the DCC metadata stale.
  barrier.src_access = vk::AccessFlagBits::eTransferWrite;
  barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  barrier.dst_access = vk::AccessFlagBits::eShaderRead;
  barrier.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

  return dst.SetLayout(barrier);
}

// |BlitPass|
bool BlitPassVK::OnCopyTextureToBufferCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<DeviceBuffer> destination,
    IRect source_region,
    size_t destination_offset,
    std::string_view label) {
  const auto& cmd_buffer = command_buffer_->GetCommandBuffer();

  // cast source and destination to TextureVK
  const auto& src = TextureVK::Cast(*source);

  if (!command_buffer_->Track(source) || !command_buffer_->Track(destination)) {
    return false;
  }

  BarrierVK barrier;
  barrier.cmd_buffer = cmd_buffer;
  barrier.new_layout = vk::ImageLayout::eTransferSrcOptimal;
  barrier.src_access = vk::AccessFlagBits::eShaderWrite |
                       vk::AccessFlagBits::eTransferWrite |
                       vk::AccessFlagBits::eColorAttachmentWrite;
  barrier.src_stage = vk::PipelineStageFlagBits::eFragmentShader |
                      vk::PipelineStageFlagBits::eTransfer |
                      vk::PipelineStageFlagBits::eColorAttachmentOutput;
  barrier.dst_access = vk::AccessFlagBits::eTransferRead;
  barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  const auto& dst = DeviceBufferVK::Cast(*destination);

  vk::BufferImageCopy image_copy;
  image_copy.setBufferOffset(destination_offset);
  image_copy.setBufferRowLength(0);
  image_copy.setBufferImageHeight(0);
  image_copy.setImageSubresource(
      vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
  image_copy.setImageOffset(
      vk::Offset3D(source_region.GetX(), source_region.GetY(), 0));
  image_copy.setImageExtent(
      vk::Extent3D(source_region.GetWidth(), source_region.GetHeight(), 1));

  if (!src.SetLayout(barrier)) {
    VALIDATION_LOG << "Could not encode layout transition.";
    return false;
  }

  cmd_buffer.copyImageToBuffer(src.GetImage(),      //
                               barrier.new_layout,  //
                               dst.GetBuffer(),     //
                               image_copy           //
  );

  // If the buffer is used for readback, then apply a transfer -> host memory
  // barrier.
  if (destination->GetDeviceBufferDescriptor().readback) {
    vk::MemoryBarrier barrier;
    barrier.srcAccessMask = vk::AccessFlagBits::eTransferWrite;
    barrier.dstAccessMask = vk::AccessFlagBits::eHostRead;

    cmd_buffer.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                               vk::PipelineStageFlagBits::eHost, {}, 1,
                               &barrier, 0, {}, 0, {});
  }

  return true;
}

bool BlitPassVK::ConvertTextureToShaderRead(
    const std::shared_ptr<Texture>& texture) {
  const auto& cmd_buffer = command_buffer_->GetCommandBuffer();

  BarrierVK barrier;
  barrier.cmd_buffer = cmd_buffer;
  barrier.src_access = vk::AccessFlagBits::eTransferWrite;
  barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  barrier.dst_access = vk::AccessFlagBits::eShaderRead;
  barrier.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

  barrier.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;

  const auto& texture_vk = TextureVK::Cast(*texture);

  if (!command_buffer_->Track(texture)) {
    return false;
  }

  return texture_vk.SetLayout(barrier);
}

// |BlitPass|
bool BlitPassVK::OnCopyBufferToTextureCommand(
    BufferView source,
    std::shared_ptr<Texture> destination,
    IRect destination_region,
    std::string_view label,
    uint32_t mip_level,
    uint32_t slice,
    bool convert_to_read) {
  const auto& cmd_buffer = command_buffer_->GetCommandBuffer();

  // cast destination to TextureVK
  const auto& dst = TextureVK::Cast(*destination);
  const auto& src = DeviceBufferVK::Cast(*source.GetBuffer());

  std::shared_ptr<const DeviceBuffer> source_buffer = source.TakeBuffer();
  if ((source_buffer && !command_buffer_->Track(source_buffer)) ||
      !command_buffer_->Track(destination)) {
    return false;
  }

  BarrierVK dst_barrier;
  dst_barrier.cmd_buffer = cmd_buffer;
  dst_barrier.new_layout = vk::ImageLayout::eTransferDstOptimal;
  // The src_access and src_stage must match the texture's current layout.
  // When multiple copies target the same texture within a single blit pass
  // (e.g. GlyphAtlas updates with convert_to_read=false), the texture is
  // already in eTransferDstOptimal after the first copy - using eShaderRead
  // as src_access in that case violates BestPractices-ImageBarrierAccessLayout.
  if (dst.GetLayout() == vk::ImageLayout::eTransferDstOptimal) {
    // WAW hazard: drain the prior transfer write before starting the next.
    dst_barrier.src_access = vk::AccessFlagBits::eTransferWrite;
    dst_barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  } else {
    // Normal path: texture was last sampled in a fragment shader.
    dst_barrier.src_access = vk::AccessFlagBits::eShaderRead;
    dst_barrier.src_stage = vk::PipelineStageFlagBits::eFragmentShader;
  }
  // dstAccessMask must only list accesses valid for TRANSFER_DST_OPTIMAL.
  // eShaderRead is not permitted in that layout; including it triggers AMD
  // best practices validation layer message ID -212008545 (0xF35D019F).
  dst_barrier.dst_access = vk::AccessFlagBits::eTransferWrite;
  dst_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  vk::BufferImageCopy image_copy;
  image_copy.setBufferOffset(source.GetRange().offset);
  image_copy.setBufferRowLength(0);
  image_copy.setBufferImageHeight(0);
  image_copy.setImageSubresource(vk::ImageSubresourceLayers(
      vk::ImageAspectFlagBits::eColor, mip_level, slice, 1));
  image_copy.imageOffset.x = destination_region.GetX();
  image_copy.imageOffset.y = destination_region.GetY();
  image_copy.imageOffset.z = 0u;
  image_copy.imageExtent.width = destination_region.GetWidth();
  image_copy.imageExtent.height = destination_region.GetHeight();
  image_copy.imageExtent.depth = 1u;

  // Workaround for Mesa dzn (D3D12 translation layer) drivers that report
  // minImageTransferGranularity of (0,0,0) and reject sub-region
  // vkCmdCopyBufferToImage with VK_ERROR_OUT_OF_HOST_MEMORY. When the copy
  // targets a sub-region, a staging image is used as an intermediary:
  //   1. Full-region buffer -> staging image (not rejected)
  //   2. vkCmdCopyImage staging -> destination at sub-region offset
  //      (image-to-image copies are not subject to transfer granularity)
  bool is_sub_region = false;
  if (workarounds_.skip_sub_region_buffer_to_image_copy) {
    const auto& dst_desc = destination->GetTextureDescriptor();
    is_sub_region =
        (destination_region.GetX() != 0 || destination_region.GetY() != 0 ||
         static_cast<uint32_t>(destination_region.GetWidth()) !=
             dst_desc.size.width ||
         static_cast<uint32_t>(destination_region.GetHeight()) !=
             dst_desc.size.height);
  }

  if (is_sub_region && allocator_) {
    // Staging image path: create a texture matching the sub-region.
    TextureDescriptor staging_desc;
    staging_desc.format = destination->GetTextureDescriptor().format;
    staging_desc.size =
        ISize{static_cast<int64_t>(destination_region.GetWidth()),
              static_cast<int64_t>(destination_region.GetHeight())};
    staging_desc.storage_mode = StorageMode::kDevicePrivate;
    staging_desc.usage = TextureUsage::kShaderRead;

    auto staging_texture = allocator_->CreateTexture(staging_desc);
    if (!staging_texture) {
      VALIDATION_LOG << "Failed to create staging texture for sub-region copy.";
      return false;
    }
    staging_texture->SetLabel("SubRegionStaging");

    if (!command_buffer_->Track(staging_texture)) {
      return false;
    }

    const auto& staging_vk = TextureVK::Cast(*staging_texture);

    // Transition staging to transfer-dst.
    BarrierVK staging_dst_barrier;
    staging_dst_barrier.cmd_buffer = cmd_buffer;
    staging_dst_barrier.new_layout = vk::ImageLayout::eTransferDstOptimal;
    staging_dst_barrier.src_access = {};
    staging_dst_barrier.src_stage = vk::PipelineStageFlagBits::eTopOfPipe;
    staging_dst_barrier.dst_access = vk::AccessFlagBits::eTransferWrite;
    staging_dst_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

    if (!staging_vk.SetLayout(staging_dst_barrier)) {
      VALIDATION_LOG << "Could not transition staging image layout.";
      return false;
    }

    // Full-region buffer -> staging (offset 0,0 - not a sub-region copy).
    vk::BufferImageCopy staging_copy;
    staging_copy.setBufferOffset(source.GetRange().offset);
    staging_copy.setBufferRowLength(0);
    staging_copy.setBufferImageHeight(0);
    staging_copy.setImageSubresource(
        vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
    staging_copy.imageOffset = vk::Offset3D(0, 0, 0);
    staging_copy.imageExtent =
        vk::Extent3D(static_cast<uint32_t>(destination_region.GetWidth()),
                     static_cast<uint32_t>(destination_region.GetHeight()), 1u);

    cmd_buffer.copyBufferToImage(src.GetBuffer(),                 //
                                 staging_vk.GetImage(),           //
                                 staging_dst_barrier.new_layout,  //
                                 staging_copy                     //
    );

    // Transition staging to transfer-src.
    BarrierVK staging_src_barrier;
    staging_src_barrier.cmd_buffer = cmd_buffer;
    staging_src_barrier.new_layout = vk::ImageLayout::eTransferSrcOptimal;
    staging_src_barrier.src_access = vk::AccessFlagBits::eTransferWrite;
    staging_src_barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
    staging_src_barrier.dst_access = vk::AccessFlagBits::eTransferRead;
    staging_src_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

    if (!staging_vk.SetLayout(staging_src_barrier)) {
      VALIDATION_LOG << "Could not transition staging image to transfer-src.";
      return false;
    }

    // Transition destination to transfer-dst.
    if (!dst.SetLayout(dst_barrier)) {
      VALIDATION_LOG << "Could not encode layout transition.";
      return false;
    }

    // Image-to-image copy: staging -> destination at sub-region offset.
    // vkCmdCopyImage is not subject to minImageTransferGranularity.
    vk::ImageCopy img_copy;
    img_copy.setSrcSubresource(
        vk::ImageSubresourceLayers(vk::ImageAspectFlagBits::eColor, 0, 0, 1));
    img_copy.setDstSubresource(vk::ImageSubresourceLayers(
        vk::ImageAspectFlagBits::eColor, mip_level, slice, 1));
    img_copy.srcOffset = vk::Offset3D(0, 0, 0);
    img_copy.dstOffset =
        vk::Offset3D(destination_region.GetX(), destination_region.GetY(), 0);
    img_copy.extent =
        vk::Extent3D(static_cast<uint32_t>(destination_region.GetWidth()),
                     static_cast<uint32_t>(destination_region.GetHeight()), 1u);

    cmd_buffer.copyImage(staging_vk.GetImage(),           //
                         staging_src_barrier.new_layout,  //
                         dst.GetImage(),                  //
                         dst_barrier.new_layout,          //
                         img_copy                         //
    );
  } else {
    // Direct buffer-to-image copy (normal path).
    if (!dst.SetLayout(dst_barrier)) {
      VALIDATION_LOG << "Could not encode layout transition.";
      return false;
    }

    cmd_buffer.copyBufferToImage(src.GetBuffer(),         //
                                 dst.GetImage(),          //
                                 dst_barrier.new_layout,  //
                                 image_copy               //
    );
  }

  // Transition to shader-read.
  if (convert_to_read) {
    BarrierVK barrier;
    barrier.cmd_buffer = cmd_buffer;
    barrier.src_access = vk::AccessFlagBits::eTransferWrite;
    barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
    barrier.dst_access = vk::AccessFlagBits::eShaderRead;
    barrier.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

    barrier.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;

    if (!dst.SetLayout(barrier)) {
      VALIDATION_LOG << "Failed to set destination texture layout to "
                        "eShaderReadOnlyOptimal after blit.";
      return false;
    }
  }

  return true;
}

// |BlitPass|
bool BlitPassVK::ResizeTexture(const std::shared_ptr<Texture>& source,
                               const std::shared_ptr<Texture>& destination) {
  const auto& cmd_buffer = command_buffer_->GetCommandBuffer();

  const auto& src = TextureVK::Cast(*source);
  const auto& dst = TextureVK::Cast(*destination);

  if (!command_buffer_->Track(source) || !command_buffer_->Track(destination)) {
    return false;
  }

  BarrierVK src_barrier;
  src_barrier.cmd_buffer = cmd_buffer;
  src_barrier.new_layout = vk::ImageLayout::eTransferSrcOptimal;
  src_barrier.src_access = vk::AccessFlagBits::eTransferWrite |
                           vk::AccessFlagBits::eShaderWrite |
                           vk::AccessFlagBits::eColorAttachmentWrite;
  src_barrier.src_stage = vk::PipelineStageFlagBits::eTransfer |
                          vk::PipelineStageFlagBits::eFragmentShader |
                          vk::PipelineStageFlagBits::eColorAttachmentOutput;
  src_barrier.dst_access = vk::AccessFlagBits::eTransferRead;
  src_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  BarrierVK dst_barrier;
  dst_barrier.cmd_buffer = cmd_buffer;
  dst_barrier.new_layout = vk::ImageLayout::eTransferDstOptimal;
  dst_barrier.src_access = {};
  dst_barrier.src_stage = vk::PipelineStageFlagBits::eTopOfPipe;
  // dstAccessMask must only list accesses valid for TRANSFER_DST_OPTIMAL.
  // eShaderRead is not permitted in that layout; including it triggers AMD
  // best practices validation layer message ID -212008545 (0xF35D019F).
  dst_barrier.dst_access = vk::AccessFlagBits::eTransferWrite;
  dst_barrier.dst_stage = vk::PipelineStageFlagBits::eTransfer;

  if (!src.SetLayout(src_barrier) || !dst.SetLayout(dst_barrier)) {
    VALIDATION_LOG << "Could not complete layout transitions.";
    return false;
  }

  vk::ImageBlit blit;
  blit.srcSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
  blit.srcSubresource.baseArrayLayer = 0u;
  blit.srcSubresource.layerCount = 1u;
  blit.srcSubresource.mipLevel = 0;

  blit.dstSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
  blit.dstSubresource.baseArrayLayer = 0u;
  blit.dstSubresource.layerCount = 1u;
  blit.dstSubresource.mipLevel = 0;

  // offsets[0] is origin.
  blit.srcOffsets[1].x = std::max<int32_t>(source->GetSize().width, 1u);
  blit.srcOffsets[1].y = std::max<int32_t>(source->GetSize().height, 1u);
  blit.srcOffsets[1].z = 1u;

  // offsets[0] is origin.
  blit.dstOffsets[1].x = std::max<int32_t>(destination->GetSize().width, 1u);
  blit.dstOffsets[1].y = std::max<int32_t>(destination->GetSize().height, 1u);
  blit.dstOffsets[1].z = 1u;

  cmd_buffer.blitImage(src.GetImage(),          //
                       src_barrier.new_layout,  //
                       dst.GetImage(),          //
                       dst_barrier.new_layout,  //
                       1,                       //
                       &blit,                   //
                       vk::Filter::eLinear

  );

  // Convert back to shader read

  BarrierVK barrier;
  barrier.cmd_buffer = cmd_buffer;
  barrier.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;
  // Flush the transfer write cache after blitImage so AMD RDNA DCC metadata
  // is coherent before the next shader read.
  barrier.src_access = vk::AccessFlagBits::eTransferWrite;
  barrier.src_stage = vk::PipelineStageFlagBits::eTransfer;
  barrier.dst_access = vk::AccessFlagBits::eShaderRead;
  barrier.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

  return dst.SetLayout(barrier);
}

// |BlitPass|
bool BlitPassVK::OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                                         std::string_view label) {
  auto& src = TextureVK::Cast(*texture);

  const auto size = src.GetTextureDescriptor().size;
  uint32_t mip_count = src.GetTextureDescriptor().mip_count;

  if (mip_count < 2u) {
    return true;
  }

  const auto& image = src.GetImage();
  const auto& cmd = command_buffer_->GetCommandBuffer();

  if (!command_buffer_->Track(texture)) {
    return false;
  }

  // Initialize all mip levels to be in TransferDst mode. Later, in a loop,
  // after writing to that mip level, we'll first switch its layout to
  // TransferSrc to prepare the mip level after it, use the image as the source
  // of the blit, before finally switching it to ShaderReadOnly so its available
  // for sampling in a shader.
  //
  // The src_access mask and src_stage are selected based on the image's current
  // layout to produce a precise barrier that satisfies only the actual
  // producing operation. This avoids BestPractices-ImageBarrierAccessLayout
  // validation warnings that occur when using a broad OR of all possible
  // stages. The dst_access is eTransferWrite (not eTransferRead) because the
  // blit *writes* into the destination mip levels.
  vk::AccessFlags mip_src_access;
  vk::PipelineStageFlags mip_src_stage;
  if (src.GetLayout() == vk::ImageLayout::eTransferDstOptimal) {
    mip_src_access = vk::AccessFlagBits::eTransferWrite;
    mip_src_stage = vk::PipelineStageFlagBits::eTransfer;
  } else if (src.GetLayout() == vk::ImageLayout::eColorAttachmentOptimal) {
    mip_src_access = vk::AccessFlagBits::eColorAttachmentWrite;
    mip_src_stage = vk::PipelineStageFlagBits::eColorAttachmentOutput;
  } else {
    // Default: texture was last sampled in a fragment shader
    // (eShaderReadOnlyOptimal) or is newly created (eUndefined).
    mip_src_access = vk::AccessFlagBits::eShaderRead;
    mip_src_stage = vk::PipelineStageFlagBits::eFragmentShader;
  }
  InsertImageMemoryBarrier(
      /*cmd=*/cmd,
      /*image=*/image,
      /*src_access_mask=*/mip_src_access,
      /*dst_access_mask=*/vk::AccessFlagBits::eTransferWrite,
      /*old_layout=*/src.GetLayout(),
      /*new_layout=*/vk::ImageLayout::eTransferDstOptimal,
      /*src_stage=*/mip_src_stage,
      /*dst_stage=*/vk::PipelineStageFlagBits::eTransfer,
      /*base_mip_level=*/0u,
      /*mip_level_count=*/mip_count);

  vk::ImageMemoryBarrier barrier;
  barrier.image = image;
  barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  barrier.subresourceRange.baseArrayLayer = 0;
  barrier.subresourceRange.layerCount = 1;
  barrier.subresourceRange.levelCount = 1;

  // Blit from the mip level N - 1 to mip level N.
  size_t width = size.width;
  size_t height = size.height;
  for (size_t mip_level = 1u; mip_level < mip_count; mip_level++) {
    barrier.subresourceRange.baseMipLevel = mip_level - 1;
    barrier.oldLayout = vk::ImageLayout::eTransferDstOptimal;
    barrier.newLayout = vk::ImageLayout::eTransferSrcOptimal;
    barrier.srcAccessMask = vk::AccessFlagBits::eTransferWrite;
    barrier.dstAccessMask = vk::AccessFlagBits::eTransferRead;

    // We just finished writing to the previous (N-1) mip level or it was the
    // base mip level. These were initialized to TransferDst earler. We are now
    // going to read from it to write to the current level (N) . So it must be
    // converted to TransferSrc.
    cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                        vk::PipelineStageFlagBits::eTransfer, {}, {}, {},
                        {barrier});

    vk::ImageBlit blit;
    blit.srcSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.srcSubresource.baseArrayLayer = 0u;
    blit.srcSubresource.layerCount = 1u;
    blit.srcSubresource.mipLevel = mip_level - 1;

    blit.dstSubresource.aspectMask = vk::ImageAspectFlagBits::eColor;
    blit.dstSubresource.baseArrayLayer = 0u;
    blit.dstSubresource.layerCount = 1u;
    blit.dstSubresource.mipLevel = mip_level;

    // offsets[0] is origin.
    blit.srcOffsets[1].x = std::max<int32_t>(width, 1u);
    blit.srcOffsets[1].y = std::max<int32_t>(height, 1u);
    blit.srcOffsets[1].z = 1u;

    width = width / 2;
    height = height / 2;
    if (width <= 1 || height <= 1) {
      // Continue to make sure everything is placed into eTransferSrcOptimal.
      continue;
    }

    // offsets[0] is origin.
    blit.dstOffsets[1].x = std::max<int32_t>(width, 1u);
    blit.dstOffsets[1].y = std::max<int32_t>(height, 1u);
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

  // Switch the last one to eTransferSrcOptimal.
  barrier.subresourceRange.baseMipLevel = mip_count - 1;
  barrier.subresourceRange.levelCount = 1;
  barrier.oldLayout = vk::ImageLayout::eTransferDstOptimal;
  barrier.newLayout = vk::ImageLayout::eTransferSrcOptimal;
  barrier.srcAccessMask = vk::AccessFlagBits::eTransferWrite;
  barrier.dstAccessMask = vk::AccessFlagBits::eTransferRead;

  cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                      vk::PipelineStageFlagBits::eTransfer, {}, {}, {},
                      {barrier});

  // Now everything is in eTransferSrcOptimal, switch everything to
  // eShaderReadOnlyOptimal.
  barrier.subresourceRange.baseMipLevel = 0;
  barrier.subresourceRange.levelCount = mip_count;
  barrier.oldLayout = vk::ImageLayout::eTransferSrcOptimal;
  barrier.newLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
  barrier.srcAccessMask = vk::AccessFlagBits::eTransferRead;
  barrier.dstAccessMask = vk::AccessFlagBits::eShaderRead;

  cmd.pipelineBarrier(vk::PipelineStageFlagBits::eTransfer,
                      vk::PipelineStageFlagBits::eFragmentShader, {}, {}, {},
                      {barrier});

  // We modified the layouts of this image from underneath it. Tell it its new
  // state so it doesn't try to perform redundant transitions under the hood.
  src.SetLayoutWithoutEncoding(vk::ImageLayout::eShaderReadOnlyOptimal);
  src.SetMipMapGenerated();

  return true;
}

}  // namespace impeller
