// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The graphics context necessary to render text.
///
///             This is necessary to create and reference resources related to
///             rendering text on the GPU.
///
///
class TypographerContext {
 public:
  virtual ~TypographerContext();

  virtual bool IsValid() const;

  virtual std::shared_ptr<GlyphAtlasContext> CreateGlyphAtlasContext()
      const = 0;

  // TODO(dnfield): Callers should not need to know which type of atlas to
  // create. https://github.com/flutter/flutter/issues/111640

  virtual std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const FontGlyphMap& font_glyph_map) const = 0;

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Create a new context to render text that talks to an
  ///             underlying graphics context.
  ///
  TypographerContext();

 private:
  bool is_valid_ = false;

  TypographerContext(const TypographerContext&) = delete;

  TypographerContext& operator=(const TypographerContext&) = delete;
};

}  // namespace impeller
