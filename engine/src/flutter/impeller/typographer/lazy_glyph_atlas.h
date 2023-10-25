// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

class LazyGlyphAtlas {
 public:
  explicit LazyGlyphAtlas(
      std::shared_ptr<TypographerContext> typographer_context);

  ~LazyGlyphAtlas();

  void AddTextFrame(const TextFrame& frame, Scalar scale);

  void ResetTextFrames();

  std::shared_ptr<GlyphAtlas> CreateOrGetGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type) const;

 private:
  std::shared_ptr<TypographerContext> typographer_context_;

  FontGlyphMap alpha_glyph_map_;
  FontGlyphMap color_glyph_map_;
  std::shared_ptr<GlyphAtlasContext> alpha_context_;
  std::shared_ptr<GlyphAtlasContext> color_context_;
  mutable std::unordered_map<GlyphAtlas::Type, std::shared_ptr<GlyphAtlas>>
      atlas_map_;

  LazyGlyphAtlas(const LazyGlyphAtlas&) = delete;

  LazyGlyphAtlas& operator=(const LazyGlyphAtlas&) = delete;
};

}  // namespace impeller
