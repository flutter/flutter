// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_render_context_skia.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/allocation.h"
#include "impeller/renderer/allocator.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/src/core/SkIPoint16.h"   //nogncheck
#include "third_party/skia/src/gpu/GrRectanizer.h"  //nogncheck

namespace impeller {

TextRenderContextSkia::TextRenderContextSkia(std::shared_ptr<Context> context)
    : TextRenderContext(std::move(context)) {}

TextRenderContextSkia::~TextRenderContextSkia() = default;

static FontGlyphPair::Set CollectUniqueFontGlyphPairsSet(
    TextRenderContext::FrameIterator frame_iterator) {
  FontGlyphPair::Set set;
  while (auto frame = frame_iterator()) {
    for (const auto& run : frame->GetRuns()) {
      auto font = run.GetFont();
      for (const auto& glyph_position : run.GetGlyphPositions()) {
        set.insert({font, glyph_position.glyph});
      }
    }
  }
  return set;
}

static FontGlyphPair::Vector CollectUniqueFontGlyphPairs(
    TextRenderContext::FrameIterator frame_iterator) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  FontGlyphPair::Vector vector;
  auto set = CollectUniqueFontGlyphPairsSet(frame_iterator);
  vector.reserve(set.size());
  for (const auto& item : set) {
    vector.emplace_back(std::move(item));
  }
  return vector;
}

static bool PairsFitInAtlasOfSize(const FontGlyphPair::Vector& pairs,
                                  size_t atlas_size,
                                  std::vector<Rect>& glyph_positions) {
  if (atlas_size == 0u) {
    return false;
  }

  auto rect_packer = std::unique_ptr<GrRectanizer>(
      GrRectanizer::Factory(atlas_size, atlas_size));

  glyph_positions.clear();
  glyph_positions.reserve(pairs.size());

  for (const auto& pair : pairs) {
    const auto glyph_size =
        ISize::Ceil(pair.font.GetMetrics().GetBoundingBox().size *
                    pair.font.GetMetrics().scale);
    SkIPoint16 location_in_atlas;
    if (!rect_packer->addRect(glyph_size.width,   //
                              glyph_size.height,  //
                              &location_in_atlas  //
                              )) {
      return false;
    }
    glyph_positions.emplace_back(Rect::MakeXYWH(location_in_atlas.x(),  //
                                                location_in_atlas.y(),  //
                                                glyph_size.width,       //
                                                glyph_size.height       //
                                                ));
  }

  return true;
}

static size_t OptimumAtlasSizeForFontGlyphPairs(
    const FontGlyphPair::Vector& pairs,
    std::vector<Rect>& glyph_positions) {
  static constexpr auto kMinAtlasSize = 8u;
  static constexpr auto kMaxAtlasSize = 4096u;

  TRACE_EVENT0("impeller", __FUNCTION__);

  size_t current_size = kMinAtlasSize;
  do {
    if (PairsFitInAtlasOfSize(pairs, current_size, glyph_positions)) {
      return current_size;
    }
    current_size = Allocation::NextPowerOfTwoSize(current_size + 1);
  } while (current_size <= kMaxAtlasSize);
  return 0u;
}

static std::shared_ptr<SkBitmap> CreateAtlasBitmap(const GlyphAtlas& atlas,
                                                   size_t atlas_size) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  auto bitmap = std::make_shared<SkBitmap>();
  auto image_info = SkImageInfo::MakeA8(atlas_size, atlas_size);
  if (!bitmap->tryAllocPixels(image_info)) {
    return nullptr;
  }
  auto surface = SkSurface::MakeRasterDirect(bitmap->pixmap());
  if (!surface) {
    return nullptr;
  }
  auto canvas = surface->getCanvas();
  if (!canvas) {
    return nullptr;
  }

  atlas.IterateGlyphs([canvas](const FontGlyphPair& font_glyph,
                               const Rect& location) -> bool {
    const auto position = SkPoint::Make(location.origin.x, location.origin.y);
    SkGlyphID glyph_id = font_glyph.glyph.index;

    SkFont sk_font(
        TypefaceSkia::Cast(*font_glyph.font.GetTypeface()).GetSkiaTypeface(),
        font_glyph.font.GetMetrics().point_size *
            font_glyph.font.GetMetrics().scale);

    const auto& metrics = font_glyph.font.GetMetrics();

    auto glyph_color = SK_ColorWHITE;

    SkPaint glyph_paint;
    glyph_paint.setColor(glyph_color);
    canvas->drawGlyphs(
        1u,         // count
        &glyph_id,  // glyphs
        &position,  // positions
        SkPoint::Make(-metrics.min_extent.x * metrics.scale,
                      -metrics.ascent * metrics.scale),  // origin
        sk_font,                                         // font
        glyph_paint                                      // paint
    );
    return true;
  });

  return bitmap;
}

static std::shared_ptr<Texture> UploadGlyphTextureAtlas(
    std::shared_ptr<Allocator> allocator,
    std::shared_ptr<SkBitmap> bitmap,
    size_t atlas_size) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!allocator) {
    return nullptr;
  }

  FML_DCHECK(bitmap != nullptr);
  const auto& pixmap = bitmap->pixmap();

  TextureDescriptor texture_descriptor;
  texture_descriptor.format = PixelFormat::kA8UNormInt;
  texture_descriptor.size = ISize::MakeWH(atlas_size, atlas_size);

  if (pixmap.rowBytes() * pixmap.height() !=
      texture_descriptor.GetByteSizeOfBaseMipLevel()) {
    return nullptr;
  }

  auto texture =
      allocator->CreateTexture(StorageMode::kHostVisible, texture_descriptor);
  if (!texture || !texture->IsValid()) {
    return nullptr;
  }
  texture->SetLabel("GlyphAtlas");

  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(bitmap->getAddr(0, 0)),  // data
      texture_descriptor.GetByteSizeOfBaseMipLevel(),           // size
      [bitmap](auto, auto) mutable { bitmap.reset(); }          // proc
  );

  if (!texture->SetContents(mapping)) {
    return nullptr;
  }
  return texture;
}

std::shared_ptr<GlyphAtlas> TextRenderContextSkia::CreateGlyphAtlas(
    FrameIterator frame_iterator) const {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!IsValid()) {
    return nullptr;
  }

  auto glyph_atlas = std::make_shared<GlyphAtlas>();

  // ---------------------------------------------------------------------------
  // Step 1: Collect unique font-glyph pairs in the frame.
  // ---------------------------------------------------------------------------

  auto font_glyph_pairs = CollectUniqueFontGlyphPairs(frame_iterator);
  if (font_glyph_pairs.empty()) {
    return glyph_atlas;
  }

  // ---------------------------------------------------------------------------
  // Step 2: Get the optimum size of the texture atlas.
  // ---------------------------------------------------------------------------
  std::vector<Rect> glyph_positions;
  const auto atlas_size =
      OptimumAtlasSizeForFontGlyphPairs(font_glyph_pairs, glyph_positions);
  if (atlas_size == 0u) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 3: Find location of font-glyph pairs in the atlas. We have this from
  // the last step. So no need to do create another rect packer. But just do a
  // sanity check of counts. This could also be just an assertion as only a
  // construction issue would cause such a failure.
  // ---------------------------------------------------------------------------
  if (glyph_positions.size() != font_glyph_pairs.size()) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 4: Record the positions in the glyph atlas.
  // ---------------------------------------------------------------------------
  for (size_t i = 0, count = glyph_positions.size(); i < count; i++) {
    glyph_atlas->AddTypefaceGlyphPosition(font_glyph_pairs[i],
                                          glyph_positions[i]);
  }

  // ---------------------------------------------------------------------------
  // Step 5: Draw font-glyph pairs in the correct spot in the atlas.
  // ---------------------------------------------------------------------------
  auto bitmap = CreateAtlasBitmap(*glyph_atlas, atlas_size);
  if (!bitmap) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 6: Upload the atlas as a texture.
  // ---------------------------------------------------------------------------
  auto texture = UploadGlyphTextureAtlas(GetContext()->GetTransientsAllocator(),
                                         bitmap, atlas_size);
  if (!texture) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 7: Record the texture in the glyph atlas.
  // ---------------------------------------------------------------------------
  glyph_atlas->SetTexture(std::move(texture));

  return glyph_atlas;
}

}  // namespace impeller
