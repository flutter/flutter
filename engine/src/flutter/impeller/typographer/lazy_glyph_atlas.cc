// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/lazy_glyph_atlas.h"

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"
#include "impeller/typographer/typographer_context.h"

#include <memory>
#include <utility>

namespace impeller {

static const std::shared_ptr<GlyphAtlas> kNullGlyphAtlas = nullptr;

LazyGlyphAtlas::LazyGlyphAtlas(
    std::shared_ptr<TypographerContext> typographer_context)
    : typographer_context_(std::move(typographer_context)),
      alpha_data_(typographer_context_
                      ? typographer_context_->CreateGlyphAtlasContext(
                            GlyphAtlas::Type::kAlphaBitmap)
                      : nullptr),
      color_data_(typographer_context_
                      ? typographer_context_->CreateGlyphAtlasContext(
                            GlyphAtlas::Type::kColorBitmap)
                      : nullptr) {}

LazyGlyphAtlas::~LazyGlyphAtlas() = default;

void LazyGlyphAtlas::AddTextFrame(
    const std::shared_ptr<TextFrame>& frame,
    Point position,
    const Matrix& transform,
    const std::optional<GlyphProperties>& properties) {
  FML_DCHECK(alpha_data_.atlas == nullptr && color_data_.atlas == nullptr);
  AtlasData& data = GetData(frame->GetAtlasType());
  data.renderable_frames.emplace_back(
      frame, transform * Matrix::MakeTranslation(position), properties);
}

void LazyGlyphAtlas::ResetTextFrames() {
  alpha_data_.reset();
  color_data_.reset();
}

const std::shared_ptr<GlyphAtlas>& LazyGlyphAtlas::CreateOrGetGlyphAtlas(
    Context& context,
    HostBuffer& data_host_buffer,
    GlyphAtlas::Type type) {
  AtlasData& data = GetData(type);
  if (data.atlas) {
    return data.atlas;
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

  data.atlas = typographer_context_->CreateGlyphAtlas(
      context, type, data_host_buffer, data.context, data.renderable_frames);
  if (!data.atlas || !data.atlas->IsValid()) {
    VALIDATION_LOG << "Could not create valid atlas.";
    return kNullGlyphAtlas;
  }
  return data.atlas;
}

LazyGlyphAtlas::AtlasData::AtlasData(std::shared_ptr<GlyphAtlasContext> context)
    : context(std::move(context)) {}

LazyGlyphAtlas::AtlasData::~AtlasData() = default;

void LazyGlyphAtlas::AtlasData::reset() {
  renderable_frames.clear();
  atlas.reset();
}

LazyGlyphAtlas::AtlasData& LazyGlyphAtlas::GetData(GlyphAtlas::Type type) {
  switch (type) {
    case GlyphAtlas::Type::kAlphaBitmap:
      return alpha_data_;
    case GlyphAtlas::Type::kColorBitmap:
      return color_data_;
  }
  FML_UNREACHABLE();
}

}  // namespace impeller
