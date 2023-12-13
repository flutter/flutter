// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_GLYPH_ATLAS_CONTEXT_STB_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_GLYPH_ATLAS_CONTEXT_STB_H_

#include "impeller/base/backend_cast.h"
#include "impeller/typographer/glyph_atlas.h"

namespace impeller {

class BitmapSTB {
 public:
  BitmapSTB();

  ~BitmapSTB();

  BitmapSTB(size_t width, size_t height, size_t bytes_per_pixel);

  uint8_t* GetPixels();

  uint8_t* GetPixelAddress(TPoint<size_t> coords);

  size_t GetRowBytes() const;

  size_t GetWidth() const;

  size_t GetHeight() const;

  size_t GetSize() const;

 private:
  size_t width_ = 0;
  size_t height_ = 0;
  size_t bytes_per_pixel_ = 0;
  std::vector<uint8_t> pixels_;
};

class GlyphAtlasContextSTB
    : public GlyphAtlasContext,
      public BackendCast<GlyphAtlasContextSTB, GlyphAtlasContext> {
 public:
  GlyphAtlasContextSTB();

  ~GlyphAtlasContextSTB() override;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the previous (if any) BitmapSTB instance.
  std::shared_ptr<BitmapSTB> GetBitmap() const;

  void UpdateBitmap(std::shared_ptr<BitmapSTB> bitmap);

 private:
  std::shared_ptr<BitmapSTB> bitmap_;

  GlyphAtlasContextSTB(const GlyphAtlasContextSTB&) = delete;

  GlyphAtlasContextSTB& operator=(const GlyphAtlasContextSTB&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_GLYPH_ATLAS_CONTEXT_STB_H_
