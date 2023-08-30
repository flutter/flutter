// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/glyph_atlas.h"

#include <numeric>
#include <utility>

namespace impeller {

GlyphAtlasContext::GlyphAtlasContext()
    : atlas_(std::make_shared<GlyphAtlas>(GlyphAtlas::Type::kAlphaBitmap)),
      atlas_size_(ISize(0, 0)) {}

GlyphAtlasContext::~GlyphAtlasContext() {}

std::shared_ptr<GlyphAtlas> GlyphAtlasContext::GetGlyphAtlas() const {
  return atlas_;
}

const ISize& GlyphAtlasContext::GetAtlasSize() const {
  return atlas_size_;
}

std::shared_ptr<RectanglePacker> GlyphAtlasContext::GetRectPacker() const {
  return rect_packer_;
}

void GlyphAtlasContext::UpdateGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas,
                                         ISize size) {
  atlas_ = std::move(atlas);
  atlas_size_ = size;
}

void GlyphAtlasContext::UpdateRectPacker(
    std::shared_ptr<RectanglePacker> rect_packer) {
  rect_packer_ = std::move(rect_packer);
}

GlyphAtlas::GlyphAtlas(Type type) : type_(type) {}

GlyphAtlas::~GlyphAtlas() = default;

bool GlyphAtlas::IsValid() const {
  return !!texture_;
}

GlyphAtlas::Type GlyphAtlas::GetType() const {
  return type_;
}

const std::shared_ptr<Texture>& GlyphAtlas::GetTexture() const {
  return texture_;
}

void GlyphAtlas::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

void GlyphAtlas::AddTypefaceGlyphPosition(const FontGlyphPair& pair,
                                          Rect rect) {
  font_atlas_map_[pair.scaled_font].positions_[pair.glyph] = rect;
}

std::optional<Rect> GlyphAtlas::FindFontGlyphBounds(
    const FontGlyphPair& pair) const {
  const auto& found = font_atlas_map_.find(pair.scaled_font);
  if (found == font_atlas_map_.end()) {
    return std::nullopt;
  }
  return found->second.FindGlyphBounds(pair.glyph);
}

const FontGlyphAtlas* GlyphAtlas::GetFontGlyphAtlas(const Font& font,
                                                    Scalar scale) const {
  const auto& found = font_atlas_map_.find({font, scale});
  if (found == font_atlas_map_.end()) {
    return nullptr;
  }
  return &found->second;
}

size_t GlyphAtlas::GetGlyphCount() const {
  return std::accumulate(font_atlas_map_.begin(), font_atlas_map_.end(), 0,
                         [](const int a, const auto& b) {
                           return a + b.second.positions_.size();
                         });
}

size_t GlyphAtlas::IterateGlyphs(
    const std::function<bool(const ScaledFont& scaled_font,
                             const Glyph& glyph,
                             const Rect& rect)>& iterator) const {
  if (!iterator) {
    return 0u;
  }

  size_t count = 0u;
  for (const auto& font_value : font_atlas_map_) {
    for (const auto& glyph_value : font_value.second.positions_) {
      count++;
      if (!iterator(font_value.first, glyph_value.first, glyph_value.second)) {
        return count;
      }
    }
  }
  return count;
}

std::optional<Rect> FontGlyphAtlas::FindGlyphBounds(const Glyph& glyph) const {
  const auto& found = positions_.find(glyph);
  if (found == positions_.end()) {
    return std::nullopt;
  }
  return found->second;
}

}  // namespace impeller
