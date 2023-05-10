// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/lazy_glyph_atlas.h"

#include "impeller/base/validation.h"
#include "impeller/typographer/text_render_context.h"
#include "lazy_glyph_atlas.h"

#include <utility>

namespace impeller {

LazyGlyphAtlas::LazyGlyphAtlas() = default;

LazyGlyphAtlas::~LazyGlyphAtlas() = default;

void LazyGlyphAtlas::AddTextFrame(const TextFrame& frame) {
  FML_DCHECK(atlas_map_.empty());
  if (frame.GetAtlasType() == GlyphAtlas::Type::kAlphaBitmap) {
    alpha_frames_.emplace_back(frame);
  } else {
    color_frames_.emplace_back(frame);
  }
}

std::shared_ptr<GlyphAtlas> LazyGlyphAtlas::CreateOrGetGlyphAtlas(
    GlyphAtlas::Type type,
    std::shared_ptr<GlyphAtlasContext> atlas_context,
    std::shared_ptr<Context> context) const {
  {
    auto atlas_it = atlas_map_.find(type);
    if (atlas_it != atlas_map_.end()) {
      return atlas_it->second;
    }
  }

  auto text_context = TextRenderContext::Create(std::move(context));
  if (!text_context || !text_context->IsValid()) {
    return nullptr;
  }
  size_t i = 0;
  auto frames =
      type == GlyphAtlas::Type::kAlphaBitmap ? alpha_frames_ : color_frames_;
  TextRenderContext::FrameIterator iterator = [&]() -> const TextFrame* {
    if (i >= frames.size()) {
      return nullptr;
    }
    const auto& result = frames[i];
    i++;
    return &result;
  };
  auto atlas =
      text_context->CreateGlyphAtlas(type, std::move(atlas_context), iterator);
  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Could not create valid atlas.";
    return nullptr;
  }
  atlas_map_[type] = atlas;
  return atlas;
}

}  // namespace impeller
