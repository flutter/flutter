// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/glyph.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/src/core/SkStrikeSpec.h"    // nogncheck
#include "third_party/skia/src/core/SkTextBlobPriv.h"  // nogncheck

namespace impeller {

/// @brief Convert a Skia axis alignment into an Impeller alignment.
///
///        This does not include a case for AxisAlignment::kNone, that should
///        be used if SkFont::isSubpixel is false.
static AxisAlignment ToAxisAligment(SkAxisAlignment aligment) {
  switch (aligment) {
    case SkAxisAlignment::kNone:
      // Skia calls this case none, meaning alignment in both X and Y.
      // Impeller will call it "all" since that is less confusing. "none"
      // is reserved for no subpixel alignment.
      return AxisAlignment::kAll;
    case SkAxisAlignment::kX:
      return AxisAlignment::kX;
    case SkAxisAlignment::kY:
      return AxisAlignment::kY;
  }
  FML_UNREACHABLE();
}

static Font ToFont(const SkTextBlobRunIterator& run, AxisAlignment alignment) {
  auto& font = run.font();
  auto typeface = std::make_shared<TypefaceSkia>(font.refTypeface());

  SkFontMetrics sk_metrics;
  font.getMetrics(&sk_metrics);

  Font::Metrics metrics;
  metrics.point_size = font.getSize();
  metrics.embolden = font.isEmbolden();
  metrics.skewX = font.getSkewX();
  metrics.scaleX = font.getScaleX();

  return Font{std::move(typeface), metrics, alignment};
}

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

std::shared_ptr<TextFrame> MakeTextFrameFromTextBlobSkia(
    const sk_sp<SkTextBlob>& blob) {
  bool has_color = false;
  std::vector<TextRun> runs;
  for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
    // TODO(jonahwilliams): ask Skia for a public API to look this up.
    // https://github.com/flutter/flutter/issues/112005
    SkStrikeSpec strikeSpec = SkStrikeSpec::MakeWithNoDevice(run.font());
    SkBulkGlyphMetricsAndPaths paths{strikeSpec};
    AxisAlignment alignment = AxisAlignment::kNone;
    if (run.font().isSubpixel()) {
      alignment = ToAxisAligment(
          strikeSpec.createScalerContext()->computeAxisAlignmentForHText());
    }

    const auto glyph_count = run.glyphCount();
    const auto* glyphs = run.glyphs();
    switch (run.positioning()) {
      case SkTextBlobRunIterator::kFull_Positioning: {
        std::vector<TextRun::GlyphPosition> positions;
        positions.reserve(glyph_count);
        for (auto i = 0u; i < glyph_count; i++) {
          // kFull_Positioning has two scalars per glyph.
          const SkPoint* glyph_points = run.points();
          const SkPoint* point = glyph_points + i;
          Glyph::Type type = paths.glyph(glyphs[i])->isColor()
                                 ? Glyph::Type::kBitmap
                                 : Glyph::Type::kPath;
          has_color |= type == Glyph::Type::kBitmap;
          positions.emplace_back(
              TextRun::GlyphPosition{Glyph{glyphs[i], type}, Point{
                                                                 point->x(),
                                                                 point->y(),
                                                             }});
        }
        TextRun text_run(ToFont(run, alignment), positions);
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
