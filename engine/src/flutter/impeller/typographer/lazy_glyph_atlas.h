// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class LazyGlyphAtlas {
 public:
  LazyGlyphAtlas();

  ~LazyGlyphAtlas();

  void AddTextFrame(const TextFrame& frame, Scalar scale);

  void ResetTextFrames();

  std::shared_ptr<GlyphAtlas> CreateOrGetGlyphAtlas(
      GlyphAtlas::Type type,
      std::shared_ptr<Context> context) const;

 private:
  FontGlyphPair::Set alpha_set_;
  FontGlyphPair::Set color_set_;
  std::shared_ptr<GlyphAtlasContext> alpha_context_;
  std::shared_ptr<GlyphAtlasContext> color_context_;
  mutable std::unordered_map<GlyphAtlas::Type, std::shared_ptr<GlyphAtlas>>
      atlas_map_;

  FML_DISALLOW_COPY_AND_ASSIGN(LazyGlyphAtlas);
};

}  // namespace impeller
