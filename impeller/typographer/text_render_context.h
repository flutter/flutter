// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
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
class TextRenderContext {
 public:
  virtual ~TextRenderContext();

  virtual bool IsValid() const;

  // TODO(dnfield): Callers should not need to know which type of atlas to
  // create. https://github.com/flutter/flutter/issues/111640

  virtual std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const FontGlyphPair::Set& font_glyph_pairs) const = 0;

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Create a new context to render text that talks to an
  ///             underlying graphics context.
  ///
  TextRenderContext();

 private:
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TextRenderContext);
};

}  // namespace impeller
