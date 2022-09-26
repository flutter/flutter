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

  void AddTextFrame(const TextFrame& frame);

  std::shared_ptr<GlyphAtlas> CreateOrGetGlyphAtlas(
      GlyphAtlas::Type type,
      std::shared_ptr<Context> context) const;

  bool HasColor() const;

 private:
  std::vector<TextFrame> frames_;
  mutable std::unordered_map<GlyphAtlas::Type, std::shared_ptr<GlyphAtlas>>
      atlas_map_;
  bool has_color_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(LazyGlyphAtlas);
};

}  // namespace impeller
