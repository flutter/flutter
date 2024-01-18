// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/lazy_glyph_atlas.h"

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/typographer_context.h"

#include <utility>

namespace impeller {

static const std::shared_ptr<GlyphAtlas> kNullGlyphAtlas = nullptr;

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
  FML_DCHECK(alpha_atlas_ == nullptr && color_atlas_ == nullptr);
  if (frame.GetAtlasType() == GlyphAtlas::Type::kAlphaBitmap) {
    frame.CollectUniqueFontGlyphPairs(alpha_glyph_map_, scale);
  } else {
    frame.CollectUniqueFontGlyphPairs(color_glyph_map_, scale);
  }
}

void LazyGlyphAtlas::ResetTextFrames() {
  alpha_glyph_map_.clear();
  color_glyph_map_.clear();
  alpha_atlas_.reset();
  color_atlas_.reset();
}

const std::shared_ptr<GlyphAtlas>& LazyGlyphAtlas::CreateOrGetGlyphAtlas(
    Context& context,
    GlyphAtlas::Type type) const {
  {
    if (type == GlyphAtlas::Type::kAlphaBitmap && alpha_atlas_) {
      return alpha_atlas_;
    }
    if (type == GlyphAtlas::Type::kColorBitmap && color_atlas_) {
      return color_atlas_;
    }
  }

  if (!typographer_context_) {
    VALIDATION_LOG << "Unable to render text because a TypographerContext has "
                      "not been set.";
    return kNullGlyphAtlas;
  }
  if (!typographer_context_->IsValid()) {
    VALIDATION_LOG
        << "Unable to render text because the TypographerContext is invalid.";
    return kNullGlyphAtlas;
  }

  auto& glyph_map = type == GlyphAtlas::Type::kAlphaBitmap ? alpha_glyph_map_
                                                           : color_glyph_map_;
  const std::shared_ptr<GlyphAtlasContext>& atlas_context =
      type == GlyphAtlas::Type::kAlphaBitmap ? alpha_context_ : color_context_;
  std::shared_ptr<GlyphAtlas> atlas = typographer_context_->CreateGlyphAtlas(
      context, type, atlas_context, glyph_map);
  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Could not create valid atlas.";
    return kNullGlyphAtlas;
  }
  if (type == GlyphAtlas::Type::kAlphaBitmap) {
    alpha_atlas_ = std::move(atlas);
    return alpha_atlas_;
  }
  if (type == GlyphAtlas::Type::kColorBitmap) {
    color_atlas_ = std::move(atlas);
    return color_atlas_;
  }
  FML_UNREACHABLE();
}

}  // namespace impeller
