// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_renderer.h"

#include "impeller/aiks/picture.h"

namespace impeller {

AiksRenderer::AiksRenderer(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  content_renderer_ = std::make_unique<ContentRenderer>(context_);
  if (!content_renderer_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

AiksRenderer::~AiksRenderer() = default;

bool AiksRenderer::IsValid() const {
  return is_valid_;
}

bool AiksRenderer::Render(const Picture& picture, RenderPass& parent_pass) {
  if (!IsValid()) {
    return false;
  }

  if (picture.pass) {
    return picture.pass->Render(*content_renderer_, parent_pass);
  }

  return true;
}

}  // namespace impeller
