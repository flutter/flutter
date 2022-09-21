// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/lazy_glyph_atlas.h"

#include "impeller/base/validation.h"
#include "impeller/typographer/text_render_context.h"

namespace impeller {

LazyGlyphAtlas::LazyGlyphAtlas() = default;

LazyGlyphAtlas::~LazyGlyphAtlas() = default;

void LazyGlyphAtlas::AddTextFrame(TextFrame frame) {
  FML_DCHECK(!atlas_);
  frames_.emplace_back(std::move(frame));
}

std::shared_ptr<GlyphAtlas> LazyGlyphAtlas::CreateOrGetGlyphAtlas(
    std::shared_ptr<Context> context) const {
  if (atlas_) {
    return atlas_;
  }

  auto text_context = TextRenderContext::Create(std::move(context));
  if (!text_context || !text_context->IsValid()) {
    return nullptr;
  }
  size_t i = 0;
  TextRenderContext::FrameIterator iterator = [&]() -> const TextFrame* {
    if (i >= frames_.size()) {
      return nullptr;
    }
    const auto& result = frames_[i];
    i++;
    return &result;
  };
  auto atlas = text_context->CreateGlyphAtlas(iterator);
  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Could not create valid atlas.";
    return nullptr;
  }
  atlas_ = std::move(atlas);
  return atlas_;
}

}  // namespace impeller
