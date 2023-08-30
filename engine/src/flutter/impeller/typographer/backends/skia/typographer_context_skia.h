// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

class TypographerContextSkia : public TypographerContext {
 public:
  static std::shared_ptr<TypographerContext> Make();

  TypographerContextSkia();

  ~TypographerContextSkia() override;

  // |TypographerContext|
  std::shared_ptr<GlyphAtlasContext> CreateGlyphAtlasContext() const override;

  // |TypographerContext|
  std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const FontGlyphMap& font_glyph_map) const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(TypographerContextSkia);
};

}  // namespace impeller
