// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/glyph_atlas.h"

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

std::shared_ptr<SkBitmap> GlyphAtlasContext::GetBitmap() const {
  return bitmap_;
}

std::shared_ptr<skgpu::Rectanizer> GlyphAtlasContext::GetRectPacker() const {
  return rect_packer_;
}

void GlyphAtlasContext::UpdateGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas,
                                         ISize size) {
  atlas_ = std::move(atlas);
  atlas_size_ = size;
}

void GlyphAtlasContext::UpdateBitmap(std::shared_ptr<SkBitmap> bitmap) {
  bitmap_ = std::move(bitmap);
}

void GlyphAtlasContext::UpdateRectPacker(
    std::shared_ptr<skgpu::Rectanizer> rect_packer) {
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
  positions_[pair] = rect;
}

std::optional<Rect> GlyphAtlas::FindFontGlyphBounds(
    const FontGlyphPair& pair) const {
  const auto& found = positions_.find(pair);
  if (found == positions_.end()) {
    return std::nullopt;
  }
  return found->second;
}

size_t GlyphAtlas::GetGlyphCount() const {
  return positions_.size();
}

size_t GlyphAtlas::IterateGlyphs(
    const std::function<bool(const FontGlyphPair& pair, const Rect& rect)>&
        iterator) const {
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
