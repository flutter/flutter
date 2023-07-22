// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "include/core/SkFontTypes.h"
#include "include/core/SkRect.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/src/core/SkStrikeSpec.h"    // nogncheck
#include "third_party/skia/src/core/SkTextBlobPriv.h"  // nogncheck

namespace impeller {

static Font ToFont(const SkTextBlobRunIterator& run) {
  auto& font = run.font();
  auto typeface = std::make_shared<TypefaceSkia>(font.refTypefaceOrDefault());

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

TextFrame TextFrameFromTextBlob(const sk_sp<SkTextBlob>& blob) {
  if (!blob) {
    return {};
  }

  TextFrame frame;

  for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
    TextRun text_run(ToFont(run));

    // TODO(jonahwilliams): ask Skia for a public API to look this up.
    // https://github.com/flutter/flutter/issues/112005
    SkStrikeSpec strikeSpec = SkStrikeSpec::MakeWithNoDevice(run.font());
    SkBulkGlyphMetricsAndPaths paths{strikeSpec};

    const auto glyph_count = run.glyphCount();
    const auto* glyphs = run.glyphs();
    switch (run.positioning()) {
      case SkTextBlobRunIterator::kDefault_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
      case SkTextBlobRunIterator::kHorizontal_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
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

        for (auto i = 0u; i < glyph_count; i++) {
          // kFull_Positioning has two scalars per glyph.
          const SkPoint* glyph_points = run.points();
          const auto* point = glyph_points + i;
          Glyph::Type type = paths.glyph(glyphs[i])->isColor()
                                 ? Glyph::Type::kBitmap
                                 : Glyph::Type::kPath;

          text_run.AddGlyph(
              Glyph{glyphs[i], type,
                    ToRect(glyph_bounds[i]).Scale(font_size / kScaleSize)},
              Point{point->x(), point->y()});
        }
        break;
      }
      case SkTextBlobRunIterator::kRSXform_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
      default:
        FML_DLOG(ERROR) << "Unimplemented.";
        continue;
    }
    frame.AddTextRun(text_run);
  }

  return frame;
}

}  // namespace impeller
