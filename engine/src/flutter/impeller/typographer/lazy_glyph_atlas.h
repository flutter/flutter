// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class LazyGlyphAtlas {
 public:
  LazyGlyphAtlas();

  ~LazyGlyphAtlas();

  void AddTextFrame(TextFrame frame);

  std::shared_ptr<GlyphAtlas> CreateOrGetGlyphAtlas(
      std::shared_ptr<Context> context) const;

 private:
  std::vector<TextFrame> frames_;
  mutable std::shared_ptr<GlyphAtlas> atlas_;

  FML_DISALLOW_COPY_AND_ASSIGN(LazyGlyphAtlas);
};

}  // namespace impeller
