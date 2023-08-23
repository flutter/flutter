// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/glyph_atlas_context_skia.h"

#include "third_party/skia/include/core/SkBitmap.h"

namespace impeller {

GlyphAtlasContextSkia::GlyphAtlasContextSkia() = default;

GlyphAtlasContextSkia::~GlyphAtlasContextSkia() = default;

std::shared_ptr<SkBitmap> GlyphAtlasContextSkia::GetBitmap() const {
  return bitmap_;
}

void GlyphAtlasContextSkia::UpdateBitmap(std::shared_ptr<SkBitmap> bitmap) {
  bitmap_ = std::move(bitmap);
}

}  // namespace impeller
