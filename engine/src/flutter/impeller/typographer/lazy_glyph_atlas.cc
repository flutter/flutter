// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/lazy_glyph_atlas.h"

#include "impeller/base/validation.h"
#include "impeller/typographer/typographer_context.h"

#include <utility>

namespace impeller {

LazyGlyphAtlas::LazyGlyphAtlas(
    std::shared_ptr<TypographerContext> typographer_context)
    : typographer_context_(std::move(typographer_context)),
      alpha_context_(typographer_context_
                         ? typographer_context_->CreateGlyphAtlasContext()
                         : nullptr),
      color_context_(typographer_context_
                         ? typographer_context_->CreateGlyphAtlasContext()
                         : nullptr) {}

LazyGlyphAtlas::~LazyGlyphAtlas() = default;

void LazyGlyphAtlas::AddTextFrame(const TextFrame& frame, Scalar scale) {
  FML_DCHECK(atlas_map_.empty());
  if (frame.GetAtlasType() == GlyphAtlas::Type::kAlphaBitmap) {
    frame.CollectUniqueFontGlyphPairs(alpha_set_, scale);
  } else {
    frame.CollectUniqueFontGlyphPairs(color_set_, scale);
  }
}

void LazyGlyphAtlas::ResetTextFrames() {
  alpha_set_.clear();
  color_set_.clear();
  atlas_map_.clear();
}

std::shared_ptr<GlyphAtlas> LazyGlyphAtlas::CreateOrGetGlyphAtlas(
    Context& context,
    GlyphAtlas::Type type) const {
  {
    auto atlas_it = atlas_map_.find(type);
    if (atlas_it != atlas_map_.end()) {
      return atlas_it->second;
    }
  }

  if (!typographer_context_) {
    VALIDATION_LOG << "Unable to render text because a TypographerContext has "
                      "not been set.";
    return nullptr;
  }
  if (!typographer_context_->IsValid()) {
    VALIDATION_LOG
        << "Unable to render text because the TypographerContext is invalid.";
    return nullptr;
  }

  auto& set = type == GlyphAtlas::Type::kAlphaBitmap ? alpha_set_ : color_set_;
  auto atlas_context =
      type == GlyphAtlas::Type::kAlphaBitmap ? alpha_context_ : color_context_;
  auto atlas =
      typographer_context_->CreateGlyphAtlas(context, type, atlas_context, set);
  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Could not create valid atlas.";
    return nullptr;
  }
  atlas_map_[type] = atlas;
  return atlas;
}

}  // namespace impeller
