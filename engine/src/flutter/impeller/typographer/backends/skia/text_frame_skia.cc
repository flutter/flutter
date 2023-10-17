// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "include/core/SkRect.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/src/core/SkStrikeSpec.h"    // nogncheck
#include "third_party/skia/src/core/SkTextBlobPriv.h"  // nogncheck

namespace impeller {

static Font ToFont(const SkTextBlobRunIterator& run) {
  auto& font = run.font();
  auto typeface = std::make_shared<TypefaceSkia>(font.refTypeface());

  SkFontMetrics sk_metrics;
  font.getMetrics(&sk_metrics);

  Font::Metrics metrics;
  metrics.point_size = font.getSize();
  metrics.embolden = font.isEmbolden();
  metrics.skewX = font.getSkewX();
  metrics.scaleX = font.getScaleX();

  return Font{std::move(typeface), metrics};
}

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

static constexpr Scalar kScaleSize = 100000.0f;

std::shared_ptr<TextFrame> MakeTextFrameFromTextBlobSkia(
    const sk_sp<SkTextBlob>& blob) {
  bool has_color = false;
  std::vector<TextRun> runs;
  for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
    // TODO(jonahwilliams): ask Skia for a public API to look this up.
    // https://github.com/flutter/flutter/issues/112005
    SkStrikeSpec strikeSpec = SkStrikeSpec::MakeWithNoDevice(run.font());
    SkBulkGlyphMetricsAndPaths paths{strikeSpec};

    const auto glyph_count = run.glyphCount();
    const auto* glyphs = run.glyphs();
    switch (run.positioning()) {
      case SkTextBlobRunIterator::kFull_Positioning: {
        std::vector<SkRect> glyph_bounds;
        glyph_bounds.resize(glyph_count);
        SkFont font = run.font();
        auto font_size = font.getSize();
        // For some platforms (including Android), `SkFont::getBounds()` snaps
        // the computed bounds to integers. And so we scale up the font size
        // prior to fetching the bounds to ensure that the returned bounds are
        // always precise enough.
        font.setSize(kScaleSize);
        font.getBounds(glyphs, glyph_count, glyph_bounds.data(), nullptr);

        std::vector<TextRun::GlyphPosition> positions;
        positions.reserve(glyph_count);
        for (auto i = 0u; i < glyph_count; i++) {
          // kFull_Positioning has two scalars per glyph.
          const SkPoint* glyph_points = run.points();
          const auto* point = glyph_points + i;
          Glyph::Type type = paths.glyph(glyphs[i])->isColor()
                                 ? Glyph::Type::kBitmap
                                 : Glyph::Type::kPath;
          has_color |= type == Glyph::Type::kBitmap;

          positions.emplace_back(TextRun::GlyphPosition{
              Glyph{glyphs[i], type,
                    ToRect(glyph_bounds[i]).Scale(font_size / kScaleSize)},
              Point{point->x(), point->y()}});
        }
        TextRun text_run(ToFont(run), positions);
        runs.emplace_back(text_run);
        break;
      }
      default:
        FML_DLOG(ERROR) << "Unimplemented.";
        continue;
    }
  }
  return std::make_shared<TextFrame>(runs, ToRect(blob->bounds()), has_color);
}

}  // namespace impeller
