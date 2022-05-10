// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/content_context.h"

#include <sstream>

#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

ContentContext::ContentContext(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  // Pipelines whose default descriptors work fine for the entity framework.
  gradient_fill_pipelines_[{}] =
      std::make_unique<GradientFillPipeline>(*context_);
  solid_fill_pipelines_[{}] = std::make_unique<SolidFillPipeline>(*context_);
  texture_blend_pipelines_[{}] =
      std::make_unique<TextureBlendPipeline>(*context_);
  texture_blend_screen_pipelines_[{}] =
      std::make_unique<TextureBlendScreenPipeline>(*context_);
  texture_pipelines_[{}] = std::make_unique<TexturePipeline>(*context_);
  gaussian_blur_pipelines_[{}] =
      std::make_unique<GaussianBlurPipeline>(*context_);
  border_mask_blur_pipelines_[{}] =
      std::make_unique<BorderMaskBlurPipeline>(*context_);
  solid_stroke_pipelines_[{}] =
      std::make_unique<SolidStrokePipeline>(*context_);
  glyph_atlas_pipelines_[{}] = std::make_unique<GlyphAtlasPipeline>(*context_);

  // Pipelines that are variants of the base pipelines with custom descriptors.
  // TODO(98684): Rework this API to allow fetching the descriptor without
  //              waiting for the pipeline to build.
  if (auto solid_fill_pipeline = solid_fill_pipelines_[{}]->WaitAndGet()) {
    auto clip_pipeline_descriptor = solid_fill_pipeline->GetDescriptor();
    clip_pipeline_descriptor.SetLabel("Clip Pipeline");
    // Disable write to all color attachments.
    auto color_attachments =
        clip_pipeline_descriptor.GetColorAttachmentDescriptors();
    for (auto& color_attachment : color_attachments) {
      color_attachment.second.write_mask =
          static_cast<uint64_t>(ColorWriteMask::kNone);
    }
    clip_pipeline_descriptor.SetColorAttachmentDescriptors(
        std::move(color_attachments));
    clip_pipelines_[{}] =
        std::make_unique<ClipPipeline>(*context_, clip_pipeline_descriptor);
  } else {
    return;
  }

  is_valid_ = true;
}

ContentContext::~ContentContext() = default;

bool ContentContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Texture> ContentContext::MakeSubpass(
    ISize texture_size,
    SubpassCallback subpass_callback) const {
  auto context = GetContext();

  auto subpass_target = RenderTarget::CreateOffscreen(*context, texture_size);
  auto subpass_texture = subpass_target.GetRenderTargetTexture();
  if (!subpass_texture) {
    return nullptr;
  }

  auto sub_command_buffer = context->CreateRenderCommandBuffer();
  sub_command_buffer->SetLabel("Offscreen Contents Command Buffer");
  if (!sub_command_buffer) {
    return nullptr;
  }

  auto sub_renderpass = sub_command_buffer->CreateRenderPass(subpass_target);
  if (!sub_renderpass) {
    return nullptr;
  }
  sub_renderpass->SetLabel("OffscreenContentsPass");

  if (!subpass_callback(*this, *sub_renderpass)) {
    return nullptr;
  }

  if (!sub_renderpass->EncodeCommands(context->GetTransientsAllocator())) {
    return nullptr;
  }

  if (!sub_command_buffer->SubmitCommands()) {
    return nullptr;
  }

  return subpass_texture;
}

std::shared_ptr<Context> ContentContext::GetContext() const {
  return context_;
}

}  // namespace impeller
