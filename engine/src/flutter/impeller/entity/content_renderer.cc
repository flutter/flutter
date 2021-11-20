// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/content_renderer.h"

namespace impeller {

ContentRenderer::ContentRenderer(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  // Pipelines whose default descriptors work fine for the entity framework.
  gradient_fill_pipeline_ = std::make_unique<GradientFillPipeline>(*context_);
  solid_fill_pipeline_ = std::make_unique<SolidFillPipeline>(*context_);
  texture_pipeline_ = std::make_unique<TexturePipeline>(*context_);
  solid_stroke_pipeline_ = std::make_unique<SolidStrokePipeline>(*context_);

  // Pipelines that are variants of the base pipelines with custom descriptors.
  if (auto solid_fill_pipeline = solid_fill_pipeline_->WaitAndGet()) {
    auto clip_pipeline_descriptor = solid_fill_pipeline->GetDescriptor();
    // Write to the stencil buffer.
    StencilAttachmentDescriptor stencil0;
    stencil0.stencil_compare = CompareFunction::kGreaterEqual;
    stencil0.depth_stencil_pass = StencilOperation::kSetToReferenceValue;
    clip_pipeline_descriptor.SetStencilAttachmentDescriptors(stencil0);
    // Disable write to all color attachments.
    auto color_attachments =
        clip_pipeline_descriptor.GetColorAttachmentDescriptors();
    for (auto& color_attachment : color_attachments) {
      color_attachment.second.write_mask =
          static_cast<uint64_t>(ColorWriteMask::kNone);
    }
    clip_pipeline_descriptor.SetColorAttachmentDescriptors(
        std::move(color_attachments));
    clip_pipeline_ = std::make_unique<ClipPipeline>(
        *context_, std::move(clip_pipeline_descriptor));
  } else {
    return;
  }

  is_valid_ = true;
}

ContentRenderer::~ContentRenderer() = default;

bool ContentRenderer::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Context> ContentRenderer::GetContext() const {
  return context_;
}

std::shared_ptr<Pipeline> ContentRenderer::GetGradientFillPipeline() const {
  if (!IsValid()) {
    return nullptr;
  }
  return gradient_fill_pipeline_->WaitAndGet();
}

std::shared_ptr<Pipeline> ContentRenderer::GetSolidFillPipeline() const {
  if (!IsValid()) {
    return nullptr;
  }

  return solid_fill_pipeline_->WaitAndGet();
}

std::shared_ptr<Pipeline> ContentRenderer::GetTexturePipeline() const {
  if (!IsValid()) {
    return nullptr;
  }

  return texture_pipeline_->WaitAndGet();
}

std::shared_ptr<Pipeline> ContentRenderer::GetSolidStrokePipeline() const {
  if (!IsValid()) {
    return nullptr;
  }

  return solid_stroke_pipeline_->WaitAndGet();
}

std::shared_ptr<Pipeline> ContentRenderer::GetClipPipeline() const {
  if (!IsValid()) {
    return nullptr;
  }

  return clip_pipeline_->WaitAndGet();
}

}  // namespace impeller
