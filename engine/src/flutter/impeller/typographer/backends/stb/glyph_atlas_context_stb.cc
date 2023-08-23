// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/stb/glyph_atlas_context_stb.h"

namespace impeller {

BitmapSTB::BitmapSTB() = default;

BitmapSTB::~BitmapSTB() = default;

BitmapSTB::BitmapSTB(size_t width, size_t height, size_t bytes_per_pixel)
    : width_(width),
      height_(height),
      bytes_per_pixel_(bytes_per_pixel),
      pixels_(std::vector<uint8_t>(width * height * bytes_per_pixel, 0)) {}

uint8_t* BitmapSTB::GetPixels() {
  return pixels_.data();
}

uint8_t* BitmapSTB::GetPixelAddress(TPoint<size_t> coords) {
  FML_DCHECK(coords.x < width_);
  FML_DCHECK(coords.x < height_);

  return &pixels_.data()[(coords.x + width_ * coords.y) * bytes_per_pixel_];
}

size_t BitmapSTB::GetRowBytes() const {
  return width_ * bytes_per_pixel_;
}

size_t BitmapSTB::GetWidth() const {
  return width_;
}

size_t BitmapSTB::GetHeight() const {
  return height_;
}

size_t BitmapSTB::GetSize() const {
  return width_ * height_ * bytes_per_pixel_;
}

GlyphAtlasContextSTB::GlyphAtlasContextSTB() = default;

GlyphAtlasContextSTB::~GlyphAtlasContextSTB() = default;

std::shared_ptr<BitmapSTB> GlyphAtlasContextSTB::GetBitmap() const {
  return bitmap_;
}

void GlyphAtlasContextSTB::UpdateBitmap(std::shared_ptr<BitmapSTB> bitmap) {
  bitmap_ = std::move(bitmap);
}

}  // namespace impeller
