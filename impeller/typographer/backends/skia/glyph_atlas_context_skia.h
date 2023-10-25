// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/base/backend_cast.h"
#include "impeller/typographer/glyph_atlas.h"

class SkBitmap;

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A container for caching a glyph atlas across frames.
///
class GlyphAtlasContextSkia
    : public GlyphAtlasContext,
      public BackendCast<GlyphAtlasContextSkia, GlyphAtlasContext> {
 public:
  GlyphAtlasContextSkia();

  ~GlyphAtlasContextSkia() override;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the previous (if any) SkBitmap instance.
  std::shared_ptr<SkBitmap> GetBitmap() const;

  void UpdateBitmap(std::shared_ptr<SkBitmap> bitmap);

 private:
  std::shared_ptr<SkBitmap> bitmap_;

  GlyphAtlasContextSkia(const GlyphAtlasContextSkia&) = delete;

  GlyphAtlasContextSkia& operator=(const GlyphAtlasContextSkia&) = delete;
};

}  // namespace impeller
