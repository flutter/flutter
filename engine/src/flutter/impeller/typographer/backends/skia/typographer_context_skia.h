// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_SKIA_TYPOGRAPHER_CONTEXT_SKIA_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_SKIA_TYPOGRAPHER_CONTEXT_SKIA_H_

#include "impeller/typographer/typographer_context.h"

namespace impeller {

class TypographerContextSkia : public TypographerContext {
 public:
  static std::shared_ptr<TypographerContext> Make();

  TypographerContextSkia();

  ~TypographerContextSkia() override;

  // |TypographerContext|
  std::shared_ptr<GlyphAtlasContext> CreateGlyphAtlasContext(
      GlyphAtlas::Type type) const override;

  // |TypographerContext|
  std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      HostBuffer& host_buffer,
      const std::shared_ptr<GlyphAtlasContext>& atlas_context,
      const std::vector<RenderableText>& renderable_texts) const override;

 private:
  struct NewGlyphData {
    FontGlyphPair pair;
    Rect position;
    Rect bounds;
  };

  // Because we can't grow the skyline packer horizontally, pick a reasonable
  // large width for all atlases.
  static constexpr int64_t kAtlasWidth = 4096;
  static constexpr int64_t kMinAtlasHeight = 1024;

  static std::vector<NewGlyphData> CollectNewGlyphs(
      const std::shared_ptr<GlyphAtlas>& atlas,
      const std::vector<RenderableText>& renderable_texts);

  /// Append all of the glyphs to the rectangle packer, growing it as needed
  /// to fit them all and return a boolean indicating success.
  static bool AppendSizesAndGrowPacker(
      const std::shared_ptr<RectanglePacker>& rect_packer,
      std::vector<TypographerContextSkia::NewGlyphData>& glyphs,
      int max_packer_height);

  static bool UpdateAtlasBitmap(const GlyphAtlas& atlas,
                                std::shared_ptr<BlitPass>& blit_pass,
                                HostBuffer& data_host_buffer,
                                const std::shared_ptr<Texture>& texture,
                                const std::vector<NewGlyphData>& new_glyphs);

  static bool BulkUpdateAtlasBitmap(
      const GlyphAtlas& atlas,
      std::shared_ptr<BlitPass>& blit_pass,
      HostBuffer& data_host_buffer,
      const std::shared_ptr<Texture>& texture,
      const std::vector<NewGlyphData>& new_glyphs);

  TypographerContextSkia(const TypographerContextSkia&) = delete;

  TypographerContextSkia& operator=(const TypographerContextSkia&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_SKIA_TYPOGRAPHER_CONTEXT_SKIA_H_
