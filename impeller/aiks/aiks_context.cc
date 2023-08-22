// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_context.h"

#include "impeller/aiks/picture.h"
#include "impeller/typographer/text_render_context.h"

namespace impeller {

AiksContext::AiksContext(std::shared_ptr<Context> context,
                         std::shared_ptr<TextRenderContext> text_render_context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  content_context_ = std::make_unique<ContentContext>(
      context_, std::move(text_render_context));
  if (!content_context_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

AiksContext::~AiksContext() = default;

bool AiksContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Context> AiksContext::GetContext() const {
  return context_;
}

ContentContext& AiksContext::GetContentContext() const {
  return *content_context_;
}

bool AiksContext::Render(const Picture& picture, RenderTarget& render_target) {
  if (!IsValid()) {
    return false;
  }

  if (picture.pass) {
    return picture.pass->Render(*content_context_, render_target);
  }

  return true;
}

}  // namespace impeller
