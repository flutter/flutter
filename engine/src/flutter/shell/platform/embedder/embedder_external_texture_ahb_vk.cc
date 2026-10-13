// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_vk.h"

#include <cstdint>

#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"

namespace flutter {

EmbedderExternalTextureAHBVK::EmbedderExternalTextureAHBVK(
    const std::shared_ptr<impeller::ContextVK>& impeller_context,
    int64_t id,
    EmbedderAndroidHardwareBufferSource source)
    : EmbedderExternalTextureAHB(id, source),
      impeller_context_(impeller_context) {}

EmbedderExternalTextureAHBVK::~EmbedderExternalTextureAHBVK() {}

void EmbedderExternalTextureAHBVK::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    // First processed frame we are attached.
    state_ = AttachmentState::kAttached;
  }
}

void EmbedderExternalTextureAHBVK::Detach() {}

void EmbedderExternalTextureAHBVK::ProcessFrame(PaintContext& context,
                                                const SkRect& bounds) {
  // Releases the buffer when this function returns.
  std::unique_ptr<AcquiredFrame> frame = AcquireFrame();
  if (!frame) {
    return;
  }
  AHardwareBuffer* latest_hardware_buffer =
      static_cast<AHardwareBuffer*>(frame->buffer());

  auto hb_desc =
      impeller::android::HardwareBuffer::Describe(latest_hardware_buffer);
  std::optional<HardwareBufferKey> key =
      impeller::android::HardwareBuffer::GetSystemUniqueID(
          latest_hardware_buffer);
  auto existing_image = image_lru_.FindImage(key);
  if (existing_image != nullptr || !hb_desc.has_value()) {
    dl_image_ = existing_image;
    return;
  }

  auto texture_source = std::make_shared<impeller::AHBTextureSourceVK>(
      impeller_context_, latest_hardware_buffer, hb_desc.value());
  if (!texture_source->IsValid()) {
    return;
  }

  auto texture =
      std::make_shared<impeller::TextureVK>(impeller_context_, texture_source);
  // Transition the layout to shader read.
  {
    auto buffer = impeller_context_->CreateCommandBuffer();
    impeller::CommandBufferVK& buffer_vk =
        impeller::CommandBufferVK::Cast(*buffer);

    impeller::BarrierVK barrier;
    barrier.cmd_buffer = buffer_vk.GetCommandBuffer();
    barrier.src_access = impeller::vk::AccessFlagBits::eColorAttachmentWrite |
                         impeller::vk::AccessFlagBits::eTransferWrite;
    barrier.src_stage =
        impeller::vk::PipelineStageFlagBits::eColorAttachmentOutput |
        impeller::vk::PipelineStageFlagBits::eTransfer;
    barrier.dst_access = impeller::vk::AccessFlagBits::eShaderRead;
    barrier.dst_stage = impeller::vk::PipelineStageFlagBits::eFragmentShader;

    barrier.new_layout = impeller::vk::ImageLayout::eShaderReadOnlyOptimal;

    if (!texture->SetLayout(barrier)) {
      return;
    }
    if (!impeller_context_->GetCommandQueue()->Submit({buffer}).ok()) {
      return;
    }
  }

  dl_image_ = impeller::DlImageImpeller::Make(texture);
  if (key.has_value()) {
    image_lru_.AddImage(dl_image_, key.value());
  }
}

}  // namespace flutter
