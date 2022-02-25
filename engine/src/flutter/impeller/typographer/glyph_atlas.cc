// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/glyph_atlas.h"

namespace impeller {

GlyphAtlas::GlyphAtlas() = default;

GlyphAtlas::~GlyphAtlas() = default;

bool GlyphAtlas::IsValid() const {
  return !!texture_;
}

const std::shared_ptr<Texture>& GlyphAtlas::GetTexture() const {
  return texture_;
}

void GlyphAtlas::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

void GlyphAtlas::AddTypefaceGlyphPosition(FontGlyphPair pair, Rect rect) {
  positions_[pair] = rect;
}

std::optional<Rect> GlyphAtlas::FindFontGlyphPosition(
    const FontGlyphPair& pair) const {
  auto found = positions_.find(pair);
  if (found == positions_.end()) {
    return std::nullopt;
  }
  return found->second;
}

size_t GlyphAtlas::GetGlyphCount() const {
  return positions_.size();
}

size_t GlyphAtlas::IterateGlyphs(
    std::function<bool(const FontGlyphPair& pair, const Rect& rect)> iterator)
    const {
  if (!iterator) {
    return 0u;
  }

  size_t count = 0u;
  for (const auto& position : positions_) {
    count++;
    if (!iterator(position.first, position.second)) {
      return count;
    }
  }
  return count;
}

}  // namespace impeller
