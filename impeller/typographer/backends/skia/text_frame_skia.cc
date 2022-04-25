// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include "flutter/fml/logging.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/src/core/SkTextBlobPriv.h"  // nogncheck

namespace impeller {

static Font ToFont(const SkFont& font, Scalar scale) {
  auto typeface = std::make_shared<TypefaceSkia>(font.refTypefaceOrDefault());

  SkFontMetrics sk_metrics;
  font.getMetrics(&sk_metrics);

  Font::Metrics metrics;
  metrics.scale = scale;
  metrics.point_size = font.getSize();
  metrics.ascent = sk_metrics.fAscent;
  metrics.descent = sk_metrics.fDescent;
  metrics.min_extent = {sk_metrics.fXMin, sk_metrics.fTop};
  metrics.max_extent = {sk_metrics.fXMax, sk_metrics.fBottom};

  return Font{std::move(typeface), std::move(metrics)};
}

TextFrame TextFrameFromTextBlob(sk_sp<SkTextBlob> blob, Scalar scale) {
  if (!blob) {
    return {};
  }

  TextFrame frame;

  for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
    TextRun text_run(ToFont(run.font(), scale));
    const auto glyph_count = run.glyphCount();
    const auto* glyphs = run.glyphs();
    switch (run.positioning()) {
      case SkTextBlobRunIterator::kDefault_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
      case SkTextBlobRunIterator::kHorizontal_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
      case SkTextBlobRunIterator::kFull_Positioning:
        for (auto i = 0u; i < glyph_count; i++) {
          // kFull_Positioning has two scalars per glyph.
          const SkPoint* glyph_points = run.points();
          const auto* point = glyph_points + i;
          text_run.AddGlyph(glyphs[i], Point{point->x(), point->y()});
        }
        break;
      case SkTextBlobRunIterator::kRSXform_Positioning:
        FML_DLOG(ERROR) << "Unimplemented.";
        break;
      default:
        FML_DLOG(ERROR) << "Unimplemented.";
        continue;
    }
    frame.AddTextRun(std::move(text_run));
  }

  return frame;
}

}  // namespace impeller
