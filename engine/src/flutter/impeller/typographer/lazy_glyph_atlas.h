// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_LAZY_GLYPH_ATLAS_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_LAZY_GLYPH_ATLAS_H_

#include "impeller/geometry/rational.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"
#include "impeller/typographer/typographer_context.h"

namespace impeller {

class LazyGlyphAtlas {
 public:
  explicit LazyGlyphAtlas(
      std::shared_ptr<TypographerContext> typographer_context);

  ~LazyGlyphAtlas();

  void AddTextFrame(const std::shared_ptr<TextFrame>& frame,
                    Point position,
                    const Matrix& transform,
                    const std::optional<GlyphProperties>& properties);

  void ResetTextFrames();

  const std::shared_ptr<GlyphAtlas>& CreateOrGetGlyphAtlas(
      Context& context,
      HostBuffer& host_buffer,
      GlyphAtlas::Type type);

 private:
  std::shared_ptr<TypographerContext> typographer_context_;

  struct AtlasData {
    explicit AtlasData(std::shared_ptr<GlyphAtlasContext> context);

    ~AtlasData();

    std::vector<RenderableText> renderable_frames;
    std::shared_ptr<GlyphAtlasContext> context;
    std::shared_ptr<GlyphAtlas> atlas;

    void reset();
  };

  AtlasData alpha_data_;
  AtlasData color_data_;

  AtlasData& GetData(GlyphAtlas::Type type);

  LazyGlyphAtlas(const LazyGlyphAtlas&) = delete;

  LazyGlyphAtlas& operator=(const LazyGlyphAtlas&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_LAZY_GLYPH_ATLAS_H_
