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

  gradient_fill_pipeline_ = std::make_unique<GradientFillPipeline>(*context_);
  solid_fill_pipeline_ = std::make_unique<SolidFillPipeline>(*context_);
  texture_pipeline_ = std::make_unique<TexturePipeline>(*context_);

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

}  // namespace impeller
