// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/typographer/text_render_context.h"

namespace impeller {

class TextRenderContextSkia : public TextRenderContext {
 public:
  static std::shared_ptr<TextRenderContext> Make();

  TextRenderContextSkia();

  ~TextRenderContextSkia() override;

  // |TextRenderContext|
  std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const FontGlyphPair::Set& font_glyph_pairs) const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(TextRenderContextSkia);
};

}  // namespace impeller
